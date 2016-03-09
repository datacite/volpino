require 'nokogiri'
require 'bibtex'
require 'oauth2'

class Claim < ActiveRecord::Base
  # include helper module for DOI resolution
  include Resolvable

  # include helper module for date and time calculations
  include Dateable

  # include helper module for author name parsing
  include Authorable

  # include helper module for work type
  include Typeable

  belongs_to :user, foreign_key: "orcid", primary_key: "uid", inverse_of: :claims

  before_create :create_uuid
  after_commit :queue_claim_job, :on => :create

  validates :orcid, :doi, :source_id, presence: true

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
  scope :total, ->(duration) { where(updated_at: (Time.zone.now.beginning_of_hour - duration.hours)..Time.zone.now.beginning_of_hour) }

  scope :query, ->(query) { where("doi like ?", "%#{query}%") }
  scope :search_and_link, -> { where(source_id: "orcid_search").where("claimed_at IS NOT NULL") }
  scope :auto_update, -> { where(source_id: "orcid_update").where("claimed_at IS NOT NULL") }

  def queue_claim_job
    ClaimJob.perform_later(self)
  end

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  def access_token
    client = OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                                ENV['ORCID_CLIENT_SECRET'],
                                site: ENV['ORCID_API_URL'])
    OAuth2::AccessToken.new(client, user.authentication_token)
  end

  def oauth_client_get
    response = access_token.get "#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{user.uid}/orcid-works" do |get|
      get.headers['Accept'] = 'application/json'
    end

    return { "data" => JSON.parse(response.body) } if response.status == 200

    { "errors" => [{ "title" => "Error fetching ORCID record" }] }
  rescue OAuth2::Error => e
    { "errors" => [{ "title" => e.message }] }
  end

  def oauth_client_post(data)
    response = access_token.post("#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{user.uid}/orcid-works") do |post|
      post.headers['Content-Type'] = 'application/orcid+xml'
      post.body = data
    end

    return { "data" => Hash.from_xml(data) } if response.status == 201

    { "errors" => [{ "title" => "Error depositing claim" }] }
  rescue OAuth2::Error => e
    { "errors" => [{ "title" => e.message }] }
  end

  def process_data(options={})
    self.start
    if collect_data["errors"]
      write_attribute(:error_messages, collect_data["errors"])
      self.error
    elsif collect_data["data"]
      update_attributes(claimed_at: Time.zone.now) unless claimed_at.present?
      self.finish
    else
      self.skip
    end
  end

  def collect_data
    # already claimed
    return { "data" => data } if claimed_at.present?

    # user has not given permission for auto-update
    return {} if source_id == "orcid_update" && user && !user.auto_update

    # missing data raise errors
    return { "errors" => [{ "title" => "Missing user" }] } if user.nil?
    return { "errors" => [{ "title" => "Missing data" }] } if data.nil?

    oauth_client_post(data)
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

  def publication_date
    get_parts_from_date_parts(metadata.fetch('issued', {}))
  end

  def description
    metadata.fetch('description', nil)
  end

  def type
    orcid_work_type(metadata.fetch('type', nil), metadata.fetch('subtype', nil))
  end

  def citation
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

  def root_attributes
    { :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.2.xsd',
      :'xmlns' => 'http://www.orcid.org/ns/orcid' }
  end

  def data
    return nil unless doi && contributors && title && publication_date

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
    xml.send(:'short-description', description)
  end

  def insert_citation(xml)
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

  def insert_id(xml, type, value)
    xml.send(:'work-external-identifier') do
      xml.send(:'work-external-identifier-type', type)
      xml.send(:'work-external-identifier-id', value)
    end
  end

  def insert_contributors(xml)
    xml.send(:'work-contributors') do
      contributors.each do |contributor|
        xml.contributor do
          insert_contributor(xml, contributor)
        end
      end
    end
  end

  def insert_contributor(xml, contributor)
    xml.send(:'contributor-orcid', contributor[:orcid]) if contributor[:orcid]
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
