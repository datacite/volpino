class UserTokenJob < ApplicationJob
  queue_as :volpino

  rescue_from ActiveJob::DeserializationError, ActiveRecord::ConnectionTimeoutError, Faraday::TimeoutError do
    retry_job wait: 5.minutes, queue: :volpino
  end

  def perform(user)
    ActiveRecord::Base.connection_pool.with_connection do
      user.update(orcid_expires_at: "1970-01-01", orcid_token: nil),
    end
  end
end
