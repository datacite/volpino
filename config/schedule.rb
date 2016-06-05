# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# load ENV variables from .env file if it exists
env_file = File.expand_path("../../.env", __FILE__)
if File.exist?(env_file)
  require 'dotenv'
  Dotenv.load! env_file
end

env :PATH, ENV['PATH']
set :environment, ENV['RAILS_ENV']
set :output, "log/cron.log"

# every hour at 5 min past the hour
every "5 * * * *" do
  rake "cron:hourly"
end

# Learn more: http://github.com/javan/whenever
