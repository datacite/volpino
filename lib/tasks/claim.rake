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

  desc "Monitor reindexing for claims"
  task monitor_reindex: :environment do
    puts Claim.monitor_reindex
  end

  desc "Create alias for claims"
  task create_alias: :environment do
    puts Claim.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List aliases for claims"
  task list_aliases: :environment do
    puts Claim.list_aliases
  end

  desc "Delete alias for claims"
  task delete_alias: :environment do
    puts Claim.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Import all claims"
  task import: :environment do
    from_id = (ENV["FROM_ID"] || Claim.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || Claim.maximum(:id)).to_i

    Claim.import_by_ids(from_id: from_id, until_id: until_id, index: ENV["INDEX"] || Claim.inactive_index)
  end

  desc "Push all stale claims"
  task stale: :environment do
    Claim.stale.find_each do |claim|
      ClaimJob.perform_later(claim)
      puts "[#{claim.aasm_state}] Pushing stale claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Push all failed claims"
  task failed: :environment do
    Claim.failed.find_each do |claim|
      ClaimJob.perform_later(claim)
      puts "[#{claim.aasm_state}] Pushed failed claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Push all ignored claims"
  task ignored: :environment do
    Claim.ignored.find_each do |claim|
      # skip if not user account
      next if claim.user.blank?

      ClaimJob.perform_later(claim)
      puts "[#{claim.aasm_state}] Pushed ignored claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  # desc "Push all waiting claims"
  # task waiting: :environment do
  #   Claim.waiting.find_each do |claim|
  #     ClaimJob.perform_later(claim)
  #     puts "[#{claim.aasm_state}] Pushed waiting claim #{claim.doi} for user #{claim.orcid} to ORCID."
  #   end
  # end

  desc "Get notification_access_token"
  task get_notification_access_token: :environment do
    response = Claim.last.notification.get_notification_access_token(
      client_id: ENV["ORCID_CLIENT_ID"],
      client_secret: ENV["ORCID_CLIENT_SECRET"],
      sandbox: (ENV["ORCID_URL"] == "https://sandbox.orcid.org"),
    )
    notification_access_token = response.body.fetch("data", {}).fetch("access_token", nil)
    puts "The new notification_access_token is #{notification_access_token}"
  end

  desc "Create claim for notification"
  task create: :environment do
    if ENV["DOI"].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    if ENV["ORCID"].nil?
      puts "ENV['ORCID'] is required"
      exit
    end

    claim = Claim.where(orcid: ENV["ORCID"],
                        doi: ENV["DOI"]).first_or_initialize
    claim.assign_attributes(state: 0,
                            source_id: "orcid_search",
                            claim_action: "create")
    claim.save

    puts "Claim for ORCID ID #{ENV['ORCID']} and DOI #{ENV['DOI']} created."
  end


  desc "Force run claim"
  task claim: :environment do
    if ENV["DOI"].nil?
      puts "ENV['DOI'] is required"
      exit
    end

    if ENV["ORCID"].nil?
      puts "ENV['ORCID'] is required"
      exit
    end

    claim = Claim.where(orcid: ENV["ORCID"],
                        doi: ENV["DOI"]).first_or_initialize

    claim.process_data

    puts "Claim for ORCID ID #{ENV['ORCID']} and DOI #{ENV['DOI']} triggered."
  end

  desc "Queue claim jobs for all users"
  task all: :environment do
    User.find_each do |user|
      user.queue_claim_jobs
      puts "Claim jobs for ORCID ID #{ENV['ORCID']} queued."
    end
  end

  desc "Queue claim jobs for one user"
  task one: :environment do |_, _args|
    if ENV["ORCID"].nil?
      puts "ENV['ORCID'] is required"
      exit
    end

    user = User.where(uid: ENV["ORCID"]).first
    if user.nil?
      puts "User with ORCID #{ENV['ORCID']} does not exist"
      exit
    end

    user.queue_claim_jobs
    puts "Claim jobs for ORCID ID #{ENV['ORCID']} queued."
  end
end
