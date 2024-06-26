# frozen_string_literal: true

RESCUABLE_EXCEPTIONS = [CanCan::AccessDenied,
                        CanCan::AuthorizationNotPerformed,
                        ActiveModelSerializers::Adapter::JsonApi::Deserialization::InvalidDocument,
                        JWT::DecodeError,
                        JWT::VerificationError,
                        JSON::ParserError,
                        Nokogiri::XML::SyntaxError,
                        NoMethodError,
                        SocketError,
                        ActionDispatch::Http::Parameters::ParseError,
                        ActiveRecord::RecordNotUnique,
                        ActiveRecord::RecordNotFound,
                        AbstractController::ActionNotFound,
                        ActionController::UnknownFormat,
                        ActionController::RoutingError,
                        ActionController::ParameterMissing,
                        ActionController::UnpermittedParameters].freeze

# Format used for DOI validation
# The prefix is 10.x where x is 4-5 digits. The suffix can be anything, but can"t be left off
DOI_FORMAT = %r(\A10\.\d{4,5}/.+)

# Format used for URL validation
URL_FORMAT = %r(\A(http|https|ftp):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?\z)

# Form queue options
QUEUE_OPTIONS = ["high", "default", "low"].freeze

# Version of ORCID API
ORCID_VERSION = "3.0"

# ORCID schema
ORCID_SCHEMA = "https://raw.githubusercontent.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.2.xsd"

# CrossRef types from http://api.crossref.org/types
CROSSREF_TYPE_TRANSLATIONS = {
  "proceedings" => nil,
  "reference-book" => nil,
  "journal-issue" => nil,
  "proceedings-article" => "paper-conference",
  "other" => nil,
  "dissertation" => "thesis",
  "dataset" => "dataset",
  "edited-book" => "book",
  "journal-article" => "article-journal",
  "journal" => nil,
  "report" => "report",
  "book-series" => nil,
  "report-series" => nil,
  "book-track" => nil,
  "standard" => nil,
  "book-section" => "chapter",
  "book-part" => nil,
  "book" => "book",
  "book-chapter" => "chapter",
  "standard-series" => nil,
  "monograph" => "book",
  "component" => nil,
  "reference-entry" => "entry-dictionary",
  "journal-volume" => nil,
  "book-set" => nil,
}.freeze

# DataCite resourceTypeGeneral from DataCite metadata schema: http://dx.doi.org/10.5438/0010
DATACITE_TYPE_TRANSLATIONS = {
  "Audiovisual" => "motion_picture",
  "Collection" => nil,
  "Dataset" => "dataset",
  "Event" => nil,
  "Image" => "graphic",
  "InteractiveResource" => nil,
  "Model" => nil,
  "PhysicalObject" => nil,
  "Service" => nil,
  "Software" => nil,
  "Sound" => "song",
  "Text" => "report",
  "Workflow" => nil,
  "Other" => nil,
}.freeze

# Map of DataCite work types to the CASRAI-based ORCID type vocabulary
# https://members.orcid.org/api/supported-work-types
TYPE_OF_WORK = {

  "Audiovisual" => "other",
  "Collection" => "other",
  "Dataset" => "data-set",
  "Event" => "other",
  "Image" => "other",
  "InteractiveResource" => "online-resource",
  "Model" => "other",
  "PhysicalObject" => "other",
  "Service" => "other",
  "Software" => "other",
  "Sound" => "other",
  "Text" => "other",
  "Workflow" => "other",
  "Other" => "other",

  # Legacy types from older schema versions
  "Film" => "other",
  ## V3.0 https://info.orcid.org/faq/what-work-types-does-orcid-support/
  "Dissertation" => "dissertation-thesis",
  # pick up other legacy types as we go along
}.freeze

# regions used by countries gem
REGIONS = {
  "APAC" => "Asia and Pacific",
  "EMEA" => "Europe, Middle East and Africa",
  "AMER" => "Americas",
}.freeze
