class Role < Base
  attr_reader :id, :name, :updated_at

  ROLES =
    ROLES_DATE = "2017-09-13".freeze

  def initialize(attributes, _options = {})
    @id = attributes.fetch("id")
    @name = attributes.fetch("name", nil)
    @updated_at = ROLES_DATE + "T00:00:00Z"
  end

  def self.get_data(_options = {})
    [
      { "id" => "staff_admin", "name" => "Staff Admin", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "staff_user", "name" => "Staff User", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "provider_admin", "name" => "Provider Admin", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "provider_user", "name" => "Provider User", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "client_admin", "name" => "Client Admin", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "client_user", "name" => "Client User", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "user", "name" => "User", "updated_at" => ROLES_DATE + "T00:00:00Z" },
    ]
  end

  def self.parse_data(items, options = {})
    if options[:id]
      item = items.detect { |i| i["id"] == options[:id] }
      return nil if item.nil?

      { data: parse_item(item) }
    else
      if options[:scope] == "provider"
        items = items.select { |i| %w(provider_admin provider_user client_admin client_user user).include?(i["id"]) }
      elsif options[:scope] == "client"
        items = items.select { |i| %w(client_admin client_user user).include?(i["id"]) }
      end

      { data: parse_items(items), meta: { total: items.length } }
    end
  end
end
