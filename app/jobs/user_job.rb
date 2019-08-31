class UserJob < ActiveJob::Base
  queue_as :volpino

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError, Faraday::TimeoutError do
    retry_job wait: 5.minutes, queue: :volpino
  end

  def perform(user)
    ActiveRecord::Base.connection_pool.with_connection do
      user.collect_data
    end
  end
end
