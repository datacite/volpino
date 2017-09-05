class Role < Base
  attr_reader :id, :name, :updated_at

  ROLES =
  ROLES_DATE = "2017-09-05"

  def initialize(attributes, options={})
    @id = attributes.fetch("id")
    @name = attributes.fetch("name", nil)
    @updated_at = ROLES_DATE + "T00:00:00Z"
  end

  def self.get_data(options = {})
    [
      { "id" => "staff_admin", "name" => "Staff Admin", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "provider_admin", "name" => "Provider Admin", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "client_admin", "name" => "Client Admin", "updated_at" => ROLES_DATE + "T00:00:00Z" },
      { "id" => "user", "name" => "User", "updated_at" => ROLES_DATE + "T00:00:00Z" } ]
  end

  def self.parse_data(items, options={})
    if options[:id]
      item = items.find { |i| i["id"] == options[:id] }
      return nil if item.nil?

      { data: parse_item(item) }
    else
      { data: parse_items(items), meta: { total: items.length } }
    end
  end
end
