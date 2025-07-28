# frozen_string_literal: true

namespace :user do
  desc "Create index for users"
  task create_index: :environment do
    puts User.create_index
  end

  desc "Delete index for users"
  task delete_index: :environment do
    puts User.delete_index
  end

  desc "Upgrade index for users"
  task upgrade_index: :environment do
    puts User.upgrade_index
  end

  desc "Show index stats for users"
  task index_stats: :environment do
    puts User.index_stats
  end

  desc "Switch index for users"
  task switch_index: :environment do
    puts User.switch_index
  end

  desc "Return active index for users"
  task active_index: :environment do
    puts User.active_index + " is the active index."
  end

  desc "Monitor reindexing for users"
  task monitor_reindex: :environment do
    puts User.monitor_reindex
  end

  desc "Create alias for users"
  task create_alias: :environment do
    puts User.create_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "List aliases for users"
  task list_aliases: :environment do
    puts User.list_aliases
  end

  desc "Delete alias for users"
  task delete_alias: :environment do
    puts User.delete_alias(index: ENV["INDEX"], alias: ENV["ALIAS"])
  end

  desc "Import all users"
  task import: :environment do
    from_id = (ENV["FROM_ID"] || User.minimum(:id)).to_i
    until_id = (ENV["UNTIL_ID"] || User.maximum(:id)).to_i

    User.import_by_ids(from_id: from_id, until_id: until_id, index: ENV["INDEX"] || User.inactive_index)
  end

  desc "Delete expired ORCID tokens"
  task delete_expired_token: :environment do
    User.delete_expired_token(index: ENV["INDEX"] || User.inactive_index)
  end

  desc "Update all claims counts"
  task update_counts: :environment do
    User.find_each do |user|
      user.save
      puts "User #{user.uid} has #{user.claims_count} claims."
    end
  end

  desc "Nullify ORCID tokens for users who are not opted in to Auto-update (pre migration)"
  task nullify_orcid_tokens: :environment do
    users = User.where(auto_update: false).where.not(orcid_token: [nil, ""])
    puts "Users that have an orcid token but auto_update = false: #{users.count}"

    users.update_all(orcid_token: "")
    puts "Done"
  end

  desc "Nullify ORCID auto-update tokens for users who had not previously opted in to Auto-update (post migration)"
  task nullify_auto_update_tokens: :environment do
    users = User.where(auto_update: false).where.not(orcid_auto_update_access_token: [nil, ""])
    puts "Users that have an auto-update token but auto_update = false: #{users.count}"

    users.update_all(
      orcid_auto_update_access_token: nil,
      orcid_auto_update_refresh_token: nil,
      orcid_auto_update_expires_at: nil
    )
    puts "Done"
  end
end
