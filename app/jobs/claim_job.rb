class ClaimJob < ActiveJob::Base
  queue_as :default

  def perform(claim)

    # send error message to bugsnag with problematic xml
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_tab(:claim, {
        claim: claim.to_xml
      })
    }
  end
end
