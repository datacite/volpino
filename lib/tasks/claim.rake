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
      sandbox: (ENV['ORCID_URL'] == "https://sandbox.orcid.org"))
    notification_access_token = response.body.fetch("data", {}).fetch("access_token", nil)
    puts "The new notification_access_token is #{notification_access_token}"
  end

  desc "Create claim for notification"
  task :create => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    if ENV['ORCID'].nil?
      puts "ENV['ORCID'] is required"
      exit
    end

    claim = Claim.where(orcid: ENV['ORCID'],
                        doi: ENV['DOI']).first_or_initialize
    claim.assign_attributes(state: 0,
                            source_id: "orcid_search",
                            claim_action: "create")
    claim.save

    puts "Claim for ORCID ID #{ENV['ORCID']} and DOI #{ENV['DOI']} created."
  end

  desc "Queue claim jobs for all users"
  task :all => :environment do
    User.find_each do |user|
      user.queue_claim_jobs
      puts "Claim jobs for ORCID ID #{ENV['ORCID']} queued."
    end
  end

  desc "Queue claim jobs for one user"
  task :one => :environment do |_, args|
    if ENV['ORCID'].nil?
      puts "ENV['ORCID'] is required"
      exit
    end

    user = User.where(uid: ENV['ORCID']).first
    if user.nil?
      puts "User with ORCID #{ENV['ORCID']} does not exist"
      exit
    end

    user.queue_claim_jobs
    puts "Claim jobs for ORCID ID #{ENV['ORCID']} queued."
  end
end
