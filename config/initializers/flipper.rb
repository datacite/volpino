require 'flipper'
require 'flipper/adapters/redis'
require "flipper/instrumentation/log_subscriber"
require "active_support/notifications"

Flipper.configure do |config|
  config.default do
    client = Redis.new(url: ENV['REDIS_URL'])
    adapter = Flipper::Adapters::Redis.new(client)
    flipper = Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)
  end
end

Flipper.register(:staff) do |actor|
  actor.respond_to?(:is_admin_or_staff?) && actor.is_admin_or_staff?
end

Flipper.register(:beta_testers) do |actor|
  actor.respond_to?(:is_beta_tester?) && actor.is_beta_tester?
end

Flipper::Instrumentation::LogSubscriber.logger = ActiveSupport::Logger.new(STDOUT)
