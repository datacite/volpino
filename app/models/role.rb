class Role < Base
  attr_reader :id, :name, :updated_at

  ROLES =
  ROLES_DATE = "2017-09-13"

  def initialize(attributes, options={})
    @id = attributes.fetch("id")
    @name = attributes.fetch("name", nil)
    @updated_at = ROLES_DATE + "T00:00:00Z"
  end

  def self.get_data(options = {})
    [
      { "id" => "staff_admin", "name" => "Staff Admin", "updated_at" => ROLES_DATE + "T00:00:00Z", "order" => 1 },
      { "id" => "staff_user", "name" => "Staff User", "updated_at" => ROLES_DATE + "T00:00:00Z", "order" => 2 },
      { "id" => "provider_admin", "name" => "Provider Admin", "updated_at" => ROLES_DATE + "T00:00:00Z", "order" => 3 },
      { "id" => "provider_user", "name" => "Provider User", "updated_at" => ROLES_DATE + "T00:00:00Z", "order" => 4 },
      { "id" => "client_admin", "name" => "Client Admin", "updated_at" => ROLES_DATE + "T00:00:00Z", "order" => 5 },
      { "id" => "client_user", "name" => "Client User", "updated_at" => ROLES_DATE + "T00:00:00Z", "order" => 6 },
      { "id" => "user", "name" => "User", "updated_at" => ROLES_DATE + "T00:00:00Z", "order" => 7 } ]
  end

  def self.parse_data(items, options={})
    if options[:id]
      item = items.find { |i| i["id"] == options[:id] }
      return nil if item.nil?

      { data: parse_item(item) }
    else
      if options[:scope] == "provider"
        items = items.select { |i| %w(provider_admin provider_user client_admin client_user user).include?(i["id"]) }
      elsif options[:scope] == "client"
        items = items.select { |i| %w(client_admin client_user user).include?(i["id"]) }
      end
      items = items.sort { |a, b| a["order"] <=> b["order"] }
      { data: parse_items(items), meta: { total: items.length } }
    end
  end
end
