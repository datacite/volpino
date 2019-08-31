class ClaimJob < ActiveJob::Base
  queue_as :volpino

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError, Faraday::TimeoutError do
    retry_job wait: 5.minutes, queue: :volpino
  end

  def perform(claim)
    ActiveRecord::Base.connection_pool.with_connection do
      claim.process_data
    end
  end
end
