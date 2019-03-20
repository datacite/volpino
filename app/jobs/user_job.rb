class UserJob < ActiveJob::Base
  queue_as :high

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError, Faraday::TimeoutError do
    retry_job wait: 5.minutes, queue: :default
  end

  def perform(user)
    ActiveRecord::Base.connection_pool.with_connection do
      user.collect_data
    end
  end
end
