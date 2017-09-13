class Provider < Base
  attr_reader :id, :name, :description, :region, :country, :year, :logo_url, :email, :website, :phone, :created_at, :updated_at

  # include helper module for caching infrequently changing resources
  include Cacheable

  def initialize(item, options={})
    @id = item.fetch("id")
    attributes = item.fetch('attributes', {})

    @name = attributes.fetch("name", nil)
    @description = Provider.sanitize(attributes.fetch("description", nil))
    @region = attributes.fetch("region", nil)
    @country = attributes.fetch("country", nil)
    @year = attributes.fetch("year", nil)
    @logo_url = attributes.fetch("logo-url", nil)
    @website = attributes.fetch("website", nil)
    @email = attributes.fetch("email", nil)
    @phone = attributes.fetch("phone", nil)
    @created_at = attributes.fetch("created", nil)
    @updated_at = attributes.fetch("updated", nil)
  end

  def self.get_query_url(options={})
    if options[:id].present?
      "#{url}/#{options[:id]}"
    else
      params = { query: options.fetch(:query, nil),
                 region: options.fetch(:region, nil),
                 year: options.fetch(:year, nil),
                 sort: options.fetch(:sort, nil) || 'name',
                 "page[size]" => options.dig(:page, :size) || 100,
                 "page[number]" => options.dig(:page, :number) }.compact
      url + "?" + URI.encode_www_form(params)
    end
  end

  def self.parse_data(result, options={})
    return nil if result.blank? || result['errors']

    if options[:id].present?
      item = result.body.fetch("data", {})
      return nil unless item.present?

      { data: parse_item(item) }
    else
      items = result.body.fetch("data", [])
      meta = result.body.fetch("meta", {})

      { data: parse_items(items), meta: meta }
    end
  end

  def self.url
    "#{ENV["LUPO_URL"]}/providers"
  end
end
