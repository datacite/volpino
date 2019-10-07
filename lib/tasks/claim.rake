# frozen_string_literal: true

namespace :claim do
  desc "Create index for claims"
  task create_index: :environment do
    puts Claim.create_index
  end

  desc "Delete index for claims"
  task delete_index: :environment do
    puts Claim.delete_index
  end

  desc "Upgrade index for claims"
  task upgrade_index: :environment do
    puts Claim.upgrade_index
  end

  desc "Show index stats for claims"
  task index_stats: :environment do
    puts Claim.index_stats
  end

  desc "Switch index for claims"
  task switch_index: :environment do
    puts Claim.switch_index
  end

  desc "Return active index for claims"
  task active_index: :environment do
    puts Claim.active_index + " is the active index."
  end

  desc "Start using alias indexes for claims"
  task start_aliases: :environment do
    puts Claim.start_aliases
  end

  desc "Monitor reindexing for claims"
  task monitor_reindex: :environment do
    puts Claim.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for claims"
  task finish_aliases: :environment do
    puts Claim.finish_aliases
  end

  desc 'Import all claims'
  task import: :environment do
    Claim.import(index: Claim.inactive_index)
  end

  desc "Push all stale claims"
  task :stale => :environment do
    Claim.stale.find_each do |claim|
      ClaimJob.perform_later(claim)
      puts "Pushing stale claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Push all failed claims"
  task :failed => :environment do
    Claim.failed.find_each do |claim|
      ClaimJob.perform_later(claim)
      puts "Pushing failed claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Push all ignored claims"
  task :ignored => :environment do
    Claim.ignored.find_each do |claim|
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
