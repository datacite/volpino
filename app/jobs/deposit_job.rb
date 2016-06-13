class DepositJob < ActiveJob::Base
  queue_as :default

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError do
    retry_job wait: 5.minutes, queue: :default
  end

  def perform(claim)
    ActiveRecord::Base.connection_pool.with_connection do
      claim.lagotto_post
    end
  end
end
