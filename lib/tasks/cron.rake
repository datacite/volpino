namespace :cron do
  desc "Hourly cron task"
  task hourly: :environment do
    Rake::Task["cache:update"].invoke
    Rake::Task["cache:update"].reenable
  end
end
