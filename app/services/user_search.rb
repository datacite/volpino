class UserSearch < Base
  attr_reader :uid, :name, :family_name, :given_names, :github, :created_at, :updated_at

  def initialize(item, options={})
    @uid = item.dig("orcid-profile", "orcid-identifier", "path")
    @family_name = item.dig("orcid-profile", "orcid-bio", "personal-details", "family-name", "value")
    @given_names = item.dig("orcid-profile", "orcid-bio", "personal-details", "given-names", "value")
    if item.dig("orcid-bio", "personal-details", "credit-name").present?
      @name = item.dig("orcid-profile", "orcid-bio", "personal-details", "credit-name", "value")
    elsif @given_names.present? || @family_name.present?
      @name = [@given_names, @family_name].join(" ")
    else
      @name = @uid
    end
    @github = nil
    @created_at = nil
    @updated_at = Date.today
  end

  def orcid
    uid
  end

  def self.get_query_url(options={})
    query = options.fetch(:query, nil).present? ? "#{options.fetch(:query)}" : nil
    rows = options.dig(:page, :size)
    offset = (options.dig(:page, :number) - 1) * rows
    params = { q: query,
               rows: rows,
               start:  offset }.compact
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
      total = result.body.dig("data", "orcid-search-results", "num-found")

      { data: parse_items(items), meta: { total: total } }
    end
  end

  def self.url
    "#{ENV["ORCID_API_URL"]}/v1.2/search/orcid-bio/"
  end
end
