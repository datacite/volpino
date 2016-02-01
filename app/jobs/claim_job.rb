class ClaimJob < ActiveJob::Base
  queue_as :default

  def perform(claim)
    ActiveRecord::Base.connection_pool.with_connection do
      claim.start
      claim.process_data
      claim.finish
    end
  rescue => error
    claim.error
    # send error message to bugsnag with problematic xml
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_tab(:claim, {
        claim: claim.data
      })
    }
    raise error
  end
end
