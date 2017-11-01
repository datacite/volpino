class UserSearch < Base
  # include helper module for caching infrequently changing resources
  include Cacheable

  attr_reader :uid, :name, :family_name, :given_names, :github, :created_at, :updated_at

  def initialize(item, options={})
    @uid = item.dig("orcid-profile", "orcid-identifier", "path")
    @family_name = item.dig("orcid-profile", "orcid-bio", "personal-details", "family-name", "value")
    @given_names = item.dig("orcid-profile", "orcid-bio", "personal-details", "given-names", "value")
    if item.dig("orcid-profile", "orcid-bio", "personal-details", "credit-name").present?
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

  def orcid
    uid
  end

  def email
    nil
  end

  def provider_id
    nil
  end

  def doi_provider
    cached_provider_response(provider_id) if provider_id.present?
  end

  def provider_name
    doi_provider.name if doi_provider.present?
  end

  def client_id
    nil
  end

  def client
    cached_client_response(client_id) if client_id.present?
  end

  def client_name
    client.name if client.present?
  end

  def sandbox_id
    nil
  end

  def sandbox
    return nil unless sandbox_id.present?
    s = Client.where(id: sandbox_id)
    s[:data] if s.present?
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
      "#{ENV["ORCID_API_URL"]}/v1.2/#{options[:id]}/orcid-bio/"
    else
      query = options.fetch(:query, nil).present? ? "#{options.fetch(:query)}" : nil
      rows = options.dig(:page, :size) || 25
      offset = ((options.dig(:page, :number) || 1) - 1) * rows
      params = { q: query,
                 rows: rows,
                 start:  offset }.compact
      url + "?" + URI.encode_www_form(params)
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
      items = result.body.dig("data", "orcid-search-results", "orcid-search-result") || []
      total = result.body.dig("data", "orcid-search-results", "num-found")

      { data: parse_items(items), meta: { total: total } }
    end
  end

  def self.url
    "#{ENV["ORCID_API_URL"]}/v1.2/search/orcid-bio/"
  end
end
