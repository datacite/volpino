class DepositJob < ActiveJob::Base
  queue_as :default

  def perform(claim)
    ActiveRecord::Base.connection_pool.with_connection do
      claim.lagotto_post
    end
  end
end
