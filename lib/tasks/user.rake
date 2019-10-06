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

  desc "Start using alias indexes for users"
  task start_aliases: :environment do
    puts User.start_aliases
  end

  desc "Monitor reindexing for users"
  task monitor_reindex: :environment do
    puts User.monitor_reindex
  end

  desc "Wrap up starting using alias indexes for users"
  task finish_aliases: :environment do
    puts User.finish_aliases
  end

  desc 'Import all users'
  task import: :environment do
    User.import(index: User.inactive_index)
  end
end