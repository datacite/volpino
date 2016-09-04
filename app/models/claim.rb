require 'nokogiri'
require 'bibtex'
require 'oauth2'

class Claim < ActiveRecord::Base
  # include view helpers
  include ActionView::Helpers::TextHelper

  # include helper module for DOI resolution
  include Resolvable

  # include helper module for date and time calculations
  include Dateable

  # include helper module for author name parsing
  include Authorable

  # include helper module for work type
  include Typeable

  # include helper module for ORCID claims
  include Orcidable

  belongs_to :user, foreign_key: "orcid", primary_key: "uid", inverse_of: :claims

  before_create :create_uuid
  after_commit :queue_claim_job, on: [:create, :update], if: Proc.new { |claim| claim.waiting? }

  validates :orcid, :doi, :source_id, presence: true

  delegate :uid, to: :user
  delegate :authentication_token, to: :user

  state_machine :initial => :waiting do
    state :waiting, value: 0
    state :working, value: 1
    state :failed, value: 2
    state :done, value: 3
    state :ignored, value: 4

    event :start do
      transition [:waiting] => :working
      transition any => same
    end

    event :finish do
      transition [:working] => :done
      transition any => same
    end

    event :error do
      transition any => :failed
    end

    event :skip do
      transition any => :ignored
    end
  end

  scope :by_state, ->(state) { where("state = ?", state) }
  scope :order_by_date, -> { order("claimed_at DESC") }

  scope :waiting, -> { by_state(0).order_by_date }
  scope :working, -> { by_state(1).order_by_date }
  scope :failed, -> { by_state(2).order_by_date }
  scope :done, -> { by_state(3).order_by_date }
  scope :ignored, -> { by_state(4).order_by_date }
  scope :stale, -> { where("state < 2").order_by_date }
  scope :total, ->(duration) { where(updated_at: (Time.zone.now.beginning_of_hour - duration.hours)..Time.zone.now.beginning_of_hour) }

  scope :query, ->(query) { where("doi like ?", "%#{query}%") }
  scope :search_and_link, -> { where(source_id: "orcid_search").where("claimed_at IS NOT NULL") }
  scope :auto_update, -> { where(source_id: "orcid_update").where("claimed_at IS NOT NULL") }

  serialize :error_messages, JSON

  def queue_claim_job
    ClaimJob.perform_later(self)
  end

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  # push to deposit API if no error and we have collected works
  def lagotto_post
    Maremma.post ENV['ORCID_UPDATE_URL'], data: deposit.to_json,
                                          token: ENV['ORCID_UPDATE_TOKEN'],
                                          content_type: 'json'
  end

  def process_data(options={})
    self.start
    if collect_data["errors"]
      write_attribute(:error_messages, collect_data["errors"])

      # send notification to Bugsnag
      if ENV['BUGSNAG_KEY']
        Bugsnag.notify(RuntimeError.new(collect_data["errors"].first["title"]))
      end

      self.error
    elsif collect_data["data"]
      update_attributes(claimed_at: Time.zone.now) unless claimed_at.present?
      lagotto_post
      self.finish
    else
      self.skip
    end
  end

  def collect_data
    # already claimed
    return { "data" => data } if claimed_at.present?

    # user has not signed up yet or authentication_token is missing
    return {} unless user.present? && user.authentication_token.present?

    # user has not given permission for auto-update
    return {} if source_id == "orcid_update" && user && !user.auto_update

    # missing data raise errors
    return { "errors" => [{ "title" => "Missing data" }] } if data.nil?

    # validate data
    return { "errors" => validation_errors.map { |error| { "title" => error } }} if validation_errors.present?

    # create or delete entry in ORCID record
    if claim_action == "delete"
      oauth_client_delete(data)
    else
      oauth_client_post(data)
    end
  end

  def create_uuid
    write_attribute(:uuid, SecureRandom.uuid) if uuid.blank?
  end

  def metadata
    @metadata ||= get_metadata(doi, 'datacite')
  end

  def contributors
    Array(metadata.fetch('author', nil)).map do |contributor|
      { orcid: contributor.fetch('ORCID', nil),
        credit_name: get_credit_name(contributor),
        role: nil }
    end
  end

  def author_string
    Array(metadata.fetch('author', nil)).map do |contributor|
      get_full_name(contributor)
    end.join(" and ")
  end

  def title
    metadata.fetch('title', nil)
  end

  def container_title
    metadata.fetch('container-title', nil)
  end

  def publisher_id
    metadata.fetch('publisher_id', nil)
  end

  def publication_date
    get_year_month_day(metadata.fetch('published', nil))
  end

  def description
    Array(metadata.fetch('description', nil)).first
  end

  def type
    orcid_work_type(metadata.fetch('type', nil), metadata.fetch('subtype', nil))
  end

  def citation
    return nil unless contributors && title && container_title && publication_date

    url = "http://doi.org/#{doi}"

    # generate citation in bibtex format. Don't use DOI content negotiation as
    # author name formatting is broken. Use the url as bibtex key.
    # TODO set correct bibtex type

    BibTeX::Entry.new({
      bibtex_type: :data,
      bibtex_key: url,
      author: author_string,
      title: title,
      publisher: container_title,
      doi: doi,
      url: url,
      year: publication_date['year']
    }).to_s.gsub("\n",'').gsub(/\s+/, ' ')
  end

  def data
    # check for DataCite required metadata
    return nil unless doi && contributors && title && container_title && publication_date

    Nokogiri::XML::Builder.new do |xml|
      xml.send(:'orcid-message', root_attributes) do
        xml.send(:'message-version', ORCID_VERSION)
        xml.send(:'orcid-profile') do
          xml.send(:'orcid-activities') do
            xml.send(:'orcid-works') do
              xml.send(:'orcid-work') do
                insert_work(xml)
              end
            end
          end
        end
      end
    end.to_xml
  end

  def deposit
    { "deposit" => { "subj_id" => orcid_as_url(orcid),
                     "obj_id" => doi_as_url(doi),
                     "source_id" => "datacite_search_link",
                     "publisher_id" => publisher_id,
                     "message_type" => "contribution",
                     "prefix" => doi[/^10\.\d{4,5}/],
                     "source_token" => ENV['ORCID_UPDATE_UUID'] } }
  end

  def insert_work(xml)
    insert_titles(xml)
    insert_description(xml)
    insert_citation(xml)
    insert_type(xml)
    insert_pub_date(xml)
    insert_ids(xml)
    insert_contributors(xml)
  end

  def insert_titles(xml)
    if title
      xml.send(:'work-title') do
        xml.title(title)
      end
    end

    xml.send(:'journal-title', container_title) if container_title
  end

  def insert_description(xml)
    return nil unless description.present?

    xml.send(:'short-description', truncate(description, length: 2500, separator: ' '))
  end

  def insert_citation(xml)
    return nil unless citation.present?

    xml.send(:'work-citation') do
      xml.send(:'work-citation-type', 'bibtex')
      xml.citation(citation)
    end
  end

  def insert_type(xml)
    xml.send(:'work-type', type)
  end

  def insert_pub_date(xml)
    if publication_date['year']
      xml.send(:'publication-date') do
        xml.year(publication_date.fetch('year'))
        xml.month(publication_date.fetch('month', nil)) if publication_date['month']
        xml.day(publication_date.fetch('day', nil)) if publication_date['month'] && publication_date['day']
      end
    end
  end

  def insert_ids(xml)
    xml.send(:'work-external-identifiers') do
      insert_id(xml, 'doi', doi)
    end
  end

  def insert_id(xml, id_type, value)
    xml.send(:'work-external-identifier') do
      xml.send(:'work-external-identifier-type', id_type)
      xml.send(:'work-external-identifier-id', value)
    end
  end

  def insert_contributors(xml)
    return nil unless contributors.present?

    xml.send(:'work-contributors') do
      contributors.each do |contributor|
        xml.contributor do
          insert_contributor(xml, contributor)
        end
      end
    end
  end

  def insert_contributor(xml, contributor)
    #xml.send(:'contributor-orcid', contributor[:orcid]) if contributor[:orcid]
    xml.send(:'credit-name', contributor[:credit_name])
    if contributor[:role]
      xml.send(:'contributor-attributes') do
        xml.send(:'contributor-role', contributor[:role])
      end
    end
  end

  def without_control(s)
    r = ''
    s.each_codepoint do |c|
      if c >= 32
        r << c
      end
    end
    r
  end
end
