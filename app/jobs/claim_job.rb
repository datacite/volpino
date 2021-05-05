class ClaimJob < ApplicationJob
  queue_as :volpino

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError, Faraday::TimeoutError, RuntimeError do |error|
    Rails.logger.error error.message
  end

  def perform(claim)
    ActiveRecord::Base.connection_pool.with_connection do
      claim.process_data
    end
  end
end
