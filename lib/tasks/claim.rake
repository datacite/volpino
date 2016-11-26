namespace :claim do
  desc "Push all stale claims"
  task :stale => :environment do
    Claim.stale.each do |claim|
      ClaimJob.perform_later(claim)
      puts "Pushing stale claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Push all failed claims"
  task :failed => :environment do
    Claim.failed.each do |claim|
      ClaimJob.perform_later(claim)
      puts "Pushing failed claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Push all ignored claims"
  task :ignored => :environment do
    Claim.ignored.each do |claim|
      # skip if not user account
      next unless claim.user.present?

      ClaimJob.perform_later(claim)
      puts "Pushing ignored claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Get notification_access_token"
  task :get_notification_access_token => :environment do
    response = Claim.last.notification.get_notification_access_token(
      client_id: ENV['ORCID_CLIENT_ID'],
      client_secret: ENV['ORCID_CLIENT_SECRET'],
      sandbox: ENV['ORCID_SANDBOX'])
    notification_access_token = response.body.fetch("data", {}).fetch("access_token", nil)
    puts "The new notification_access_token is #{notification_access_token}"
  end
end
