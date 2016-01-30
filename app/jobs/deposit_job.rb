class DepositJob < ActiveJob::Base
  queue_as :default

  def perform(deposit)
    ActiveRecord::Base.connection_pool.with_connection do
      deposit.start

      if deposit.message_action == 'delete'
        deposit.delete_contributions
      else
        deposit.update_contributions
      end

      deposit.finish
    end
  rescue => error
    deposit.error
    raise error
  end
end
