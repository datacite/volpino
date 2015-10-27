require 'resolv-replace.rb'

Sidekiq.configure_server do |config|
  config.error_handlers << Proc.new do |exception, hash|
    unless ["ActiveRecord::RecordNotFound",
            "ActionController::RoutingError",
            "CustomError::TooManyRequestsError"].include?(exception.class.to_s)
      Notification.where(message: exception.message).where(unresolved: true).first_or_create(exception: exception)
    end
  end
  config.options[:concurrency] = ENV["CONCURRENCY"].to_i
end
