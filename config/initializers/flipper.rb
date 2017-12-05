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

Flipper.register(:staff_admins) do |actor|
  actor.respond_to?(:is_admin?) && actor.is_admin?
end

Flipper.register(:beta_testers) do |actor|
  actor.respond_to?(:is_beta_tester?) && actor.is_beta_tester?
end

Flipper::Instrumentation::LogSubscriber.logger = ActiveSupport::Logger.new(STDOUT)

# Rails.application.config.flipper = flipper
# Rails.application.config.middleware.use "FlipperEnabledMiddleware", flipper
