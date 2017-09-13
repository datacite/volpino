class Client < Base
  attr_reader :id, :name, :domains, :provider_id, :provider, :year, :created_at, :updated_at

  # include helper module for caching infrequently changing resources
  include Cacheable

  def initialize(item, options={})
    @id = item.fetch("id")
    attributes = item.fetch('attributes', {})

    @name = attributes.fetch("name", nil)
    @provider_id = attributes.fetch("provider-id", nil)
    @domains = attributes.fetch("domains", []).presence
    @created_at = attributes.fetch("created", nil)
    @updated_at = attributes.fetch("updated", nil)
    @year = @created_at[0..3].to_i

    # associations
    @provider = Array(options[:providers]).find { |s| s.id == @provider_id }
  end

  def self.get_query_url(options={})
    if options[:id].present?
      "#{url}/#{options[:id]}"
    else
      params = { query: options.fetch(:query, nil),
                 "member-id": options.fetch("provider-id", nil),
                 year: options.fetch(:year, nil),
                 "page[size]" => options.dig(:page, :size),
                 "page[number]" => options.dig(:page, :number) }.compact
      url + "?" + URI.encode_www_form(params)
    end
  end

  def self.parse_data(result, options={})
    return nil if result.blank?

    if options[:id]
      item = result.body.fetch("data", {})
      Rails.logger.info item.inspect
      return nil if item.blank?

      { data: parse_item(item) }
    else
      items = result.body.fetch("data", [])
      meta = result.body.fetch("meta", {})

      page = (options.dig(:page, :number) || 1).to_i
      per_page = (options.dig(:page, :size) || 25).to_i
      total = meta.fetch("total", 0)
      total_pages = (total.to_f / per_page).ceil

      meta = { total: total,
               total_pages: total_pages,
               page: page,
               providers: meta.fetch("providers", []),
               years: meta.fetch("years", []) }

      { data: parse_items(items), meta: meta }
    end
  end

  def self.url
    "#{ENV["LUPO_URL"]}/clients"
  end
end
