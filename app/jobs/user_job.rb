class UserJob < ActiveJob::Base
  queue_as :high

  def perform(user)
    ActiveRecord::Base.connection_pool.with_connection do
      user.process_data
    end
  end
end
