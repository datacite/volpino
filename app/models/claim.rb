require 'nokogiri'

class Claim < ActiveRecord::Base
  # include HTTP request helpers
  include Networkable

  # include helper module for DOI resolution
  include Resolvable

  # include helper module for date and time calculations
  include Dateable

  # include helper module for author name parsing
  include Authorable

  belongs_to :user
  belongs_to :service

  before_create :create_uuid
  after_commit :queue_claim_job, :on => :create

  validates :user_id, :service_id, :work_id, presence: true

  state_machine :initial => :waiting do
    state :waiting, value: 0
    state :working, value: 1
    state :failed, value: 2
    state :done, value: 3

    after_transition :to => :failed do |claim|

    end

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
  end

  scope :by_state, ->(state) { where("state = ?", state) }
  scope :order_by_date, -> { order("updated_at DESC") }

  scope :waiting, -> { by_state(0).order_by_date }
  scope :working, -> { by_state(1).order_by_date }
  scope :failed, -> { by_state(2).order_by_date }
  scope :done, -> { by_state(3).order_by_date }
  scope :total, ->(duration) { where(updated_at: (Time.zone.now.beginning_of_hour - duration.hours)..Time.zone.now.beginning_of_hour) }

  def queue_claim_job
    ClaimJob.perform_later(self)
  end

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  def create_uuid
    write_attribute(:uuid, SecureRandom.uuid) if uuid.blank?
  end

  def metadata
    @metadata ||= get_metadata(work_id, 'datacite')
  end

  def title
    metadata.fetch(:title, nil)
  end

  def citation
    result = get_result("http://doi.org/#{doi}", content_type: "application/x-bibtex")
    return nil unless result.is_a?(String)

    without_control(result)
  end

  def root_attributes
    { :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.2.xsd',
      :'xmlns' => 'http://www.orcid.org/ns/orcid' }
  end

  def to_xml
    # return nil unless doi && creator && title && publisher && publication_year

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
    if title || subtitle
      xml.send(:'work-title') do
        xml.title(title) if title
        xml.subtitle(subtitle) if subtitle
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
    if publication_year
      xml.send(:'publication-date') do
        xml.year(publication_year)
        xml.month(publication_month) if publication_month
        xml.day(publication_day) if publication_month && publication_day
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
