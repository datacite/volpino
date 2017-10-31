class OrcidUser < Base
  attr_reader :id, :name, :family_name, :given_names, :updated_at

  def initialize(item, options={})
    @id = item.dig("orcid-profile", "orcid-identifier", "path")
    @family_name = item.dig("orcid-profile", "orcid-bio", "personal-details", "family-name", "value")
    @given_names = item.dig("orcid-profile", "orcid-bio", "personal-details", "given-names", "value")
    if item.dig("orcid-bio", "personal-details", "credit-name").present?
      @name = item.dig("orcid-profile", "orcid-bio", "personal-details", "credit-name", "value")
    elsif @given_names.present? || @family_name.present?
      @name = [@given_names, @family_name].join(" ")
    else
      @name = @uid
    end
    @updated_at = Date.today.to_s + "T00:00:00Z"
  end

  def self.get_query_url(options={})
    query = options.fetch(:query, nil).present? ? "#{options.fetch(:query)}" : nil
    params = { q: query,
               rows: options.dig(:page, :size) || 25,
               offset: options.dig(:page, :number) || 0 }.compact
    url + "?" + URI.encode_www_form(params)
  end

  def self.get_data(options={})
    query_url = get_query_url(options)
    Maremma.get(query_url, accept: 'json', bearer: ENV['ORCID_TOKEN'])
  end

  def self.parse_data(result, options={})
    return nil if result.blank? || result.body['errors']

    if options[:id].present?
      item = result.body.dig("data", "orcid-search-results", "orcid-search-result") || []
      return nil unless item.present?

      { data: parse_item(item) }
    else
      items = result.body.dig("data", "orcid-search-results", "orcid-search-result") || []

      { data: parse_items(items) }
    end
  end

  def self.url
    "#{ENV["ORCID_API_URL"]}/v1.2/search/orcid-bio/"
  end
end
