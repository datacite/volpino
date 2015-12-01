require "net/smtp"
require "timeout"

class Heartbeat < Sinatra::Base
  get "" do
    content_type :json

    { services: services,
      status: human_status(services_up?) }.to_json
  end

  def services
    { mysql: human_status(mysql_up?),
      redis: human_status(redis_up?),
      sidekiq: human_status(sidekiq_up?) }
  end

  def human_status(service)
    service ? "OK" : "failed"
  end

  def services_up?
    [mysql_up?, redis_up?, sidekiq_up?].all?
  end

  def mysql_up?
    Mysql2::Client.new(
      host: ENV["DB_HOST"],
      port: ENV["DB_PORT"],
      username: ENV["DB_USERNAME"],
      password: ENV["DB_PASSWORD"]
    )
    true
  rescue
    false
  end

  def redis_up?
    redis_client = Redis.new
    redis_client.ping == "PONG"
  rescue
    false
  end

  def sidekiq_up?
    sidekiq_client = Sidekiq::ProcessSet.new
    sidekiq_client.size > 0
  rescue
    false
  end
end
