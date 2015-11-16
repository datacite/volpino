class Status < ActiveRecord::Base
  # include HTTP request helpers
  include Networkable

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
    self.users_new_count = User.where(created_at: Date.today).count
    self.claims_count = Claim.count
    self.claims_new_count = Claim.where(created_at: Date.today).count
    self.db_size = get_db_size
    self.version = Volpino::VERSION
    self.current_version = get_current_version unless current_version.present?
  end

  def get_current_version
    result = get_result(RELEASES_URL)
    result = result.is_a?(Array) ? result.first : nil
    result.to_h.fetch("tag_name", "v.#{version}")[2..-1]
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

  def services_ok?
    # web, mysql and memcached must be running if you can see services panel on status page
    if redis == "OK" && sidekiq == "OK" && postfix == "OK"
      true
    else
      false
    end
  end

  def redis
    redis_client = Redis.new
    redis_client.ping == "PONG" ? "OK" : "failed"
  rescue
    "failed"
  end

  def sidekiq
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
