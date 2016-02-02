class UserJob < ActiveJob::Base
  queue_as :high

  def perform(user)
    ActiveRecord::Base.connection_pool.with_connection do
      user.process_data
    end
  rescue => error
    # send error message to bugsnag with problematic uid
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_tab(:user, {
        user: user.uid
      })
    }
    raise error
  end
end
