class Status < ActiveRecord::Base
  RELEASES_URL = "https://api.github.com/repos/datacite/volpino/releases"

  before_create :collect_status_info, :create_uuid

  default_scope { order("status.created_at DESC") }

  def self.per_page
    1000
  end

  def to_param
    uuid
  end

  def collect_status_info
    self.users_count = User.count
    self.users_new_count = User.where("created_at >= ?", Time.zone.now.beginning_of_day).count
    self.claims_search_count = Claim.search_and_link.count
    self.claims_search_new_count = Claim.search_and_link.where("claimed_at >= ?", Time.zone.now.beginning_of_day).count
    self.claims_auto_count = Claim.auto_update.count
    self.claims_auto_new_count = Claim.auto_update.where("claimed_at >= ?", Time.zone.now.beginning_of_day).count
    self.members_emea_count = Member.where(region: "EMEA").count
    self.members_amer_count = Member.where(region: "AMER").count
    self.members_apac_count = Member.where(region: "APAC").count
    self.db_size = get_db_size
    self.version = Volpino::VERSION
    self.current_version = get_current_version unless current_version.present?
  end

  def members_count
    { "Americas" => members_amer_count,
      "Asia and Pacific" => members_apac_count,
      "EMEA" => members_emea_count }
  end

  def get_current_version
    response = Maremma.get RELEASES_URL
    response.body.is_a?(Array) ? response.body.first.to_h.fetch("tag_name", "v.#{version}")[2..-1] : nil
  end

  # get combined data and index size for all tables
  def get_db_size
    sql = "SELECT SUM(DATA_LENGTH + INDEX_LENGTH) as size FROM information_schema.TABLES where TABLE_SCHEMA = '#{ENV['DB_NAME'].to_s}';"
    result = ActiveRecord::Base.connection.exec_query(sql)
    result.rows.first.reduce(:+)
  end

  def outdated_version?
    Gem::Version.new(current_version) > Gem::Version.new(version)
  end

  def services_up?
    [memcached_up?, sidekiq_up?].all?
  end

  def memcached_up?
    host = ENV["MEMCACHE_SERVERS"]
    memcached_client = Dalli::Client.new("#{host}:11211")
    memcached_client.alive!
    true
  rescue
    false
  end

  def sidekiq_up?
    sidekiq_client = Sidekiq::ProcessSet.new
    sidekiq_client.size > 0 ? "OK" : "failed"
  rescue
    "failed"
  end

  def timestamp
    updated_at.utc.iso8601
  end

  def create_uuid
    write_attribute(:uuid, SecureRandom.uuid)
  end
end
