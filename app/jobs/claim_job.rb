class ClaimJob < ActiveJob::Base
  queue_as :default

  def perform(claim)
    ActiveRecord::Base.connection_pool.with_connection do
      claim.process_data
    end
  end
end
