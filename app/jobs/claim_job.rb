class ClaimJob < ActiveJob::Base
  queue_as :volpino

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError, Faraday::TimeoutError, RuntimeError do |error|
    logger = Logger.new(STDOUT)
    logger.error error.message
  end

  def perform(claim)
    ActiveRecord::Base.connection_pool.with_connection do
      claim.process_data
    end
  end
end
