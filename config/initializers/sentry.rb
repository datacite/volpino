Raven.configure do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.release = "volpino:" + Volpino::Application::VERSION
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.transport_failure_callback = lambda { |event|
    Rails.logger.error "[Sentry Error]: " + event.inspect
  }
end
