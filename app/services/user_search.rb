class UserSearch < Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  attr_reader :uid, :name, :family_name, :given_names, :github, :created_at, :created, :updated_at

  def initialize(item, options={})
    @uid = item.dig("orcid-identifier", "path")
    @family_name = item.dig("person", "name", "family-name", "value")
    @given_names = item.dig("person", "name", "given-names", "value")
    if item.dig("persom", "name", "credit-name", "value").present?
      @name = item.dig("orcid-profile", "orcid-bio", "personal-details", "credit-name", "value")
    elsif @given_names.present? || @family_name.present?
      @name = [@given_names, @family_name].join(" ")
    else
      @name = @uid
    end
    @github = nil
    @created_at = nil
    @updated_at = Date.today.beginning_of_day
  end

  alias_method :created, :created_at

  def orcid
    uid
  end

  def is_active
    false
  end

  def email
    nil
  end

  def provider_id
    nil
  end

  def client_id
    nil
  end

  def role_id
   "user"
  end

  def role
    cached_role_response(role_id) if role_id.present?
  end

  def role_name
    role.name if role_id.present?
  end

  def self.get_query_url(options={})
    if options[:id].present?
      url + options[:id]
    else
      query = options.fetch(:query, nil).present? ? "#{options.fetch(:query)}" : nil
      rows = options.dig(:page, :size) || 25
      offset = ((options.dig(:page, :number) || 1) - 1) * rows
      params = { q: query,
                 rows: rows,
                 start:  offset }.compact
      url + "search/?" + URI.encode_www_form(params)
    end
  end

  def self.get_data(options={})
    query_url = get_query_url(options)
    Maremma.get(query_url, accept: 'json', bearer: ENV['ORCID_TOKEN'])
  end

  def self.parse_data(result, options={})
    return nil if result.blank? || result.body['errors']

    if options[:id].present?
      item = result.body.dig("data") || {}
      return nil unless item.present?

      { data: parse_item(item) }
    else
      items = result.body.dig("data", "result") || []
      total = result.body.dig("data", "num-found")

      { data: parse_items(items), meta: { total: total } }
    end
  end

  def self.url
    if ENV['ORCID_URL'] == "https://sandbox.orcid.org"
      "https://api.sandbox.orcid.org/v#{ORCID_VERSION}/"
    else
      "https://api.orcid.org/v#{ORCID_VERSION}/"
    end
  end
end
