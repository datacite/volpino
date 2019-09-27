require_relative 'boot'

require 'rails/all'
require "active_job/logging"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# load ENV variables from .env file if it exists
env_file = File.expand_path("../../.env", __FILE__)
if File.exist?(env_file)
  require 'dotenv'
  Dotenv.load! env_file
end

# load ENV variables from container environment if json file exists
# see https://github.com/phusion/baseimage-docker#envvar_dumps
env_json_file = "/etc/container_environment.json"
if File.exist?(env_json_file)
  env_vars = JSON.parse(File.read(env_json_file))
  env_vars.each { |k, v| ENV[k] = v }
end

# default values for some ENV variables
ENV['APPLICATION'] ||= "volpino"
ENV['HOSTNAME'] ||= "profiles.local"
ENV['SESSION_KEY'] ||= "_#{ENV['APPLICATION']}_session"
ENV['MEMCACHE_SERVERS'] ||= "memcached:11211"
ENV['SITE_TITLE'] ||= "DataCite Profiles"
ENV['LOG_LEVEL'] ||= "info"
ENV['ORCID_URL'] ||= "https://sandbox.orcid.org"
ENV['ORCID_API_URL'] ||= "https://api.sandbox.orcid.org"
ENV['BRACCO_URL'] ||= "https://doi.test.datacite.org"
ENV['API_URL'] ||= "https://api.test.datacite.org"
ENV['CDN_URL'] ||= "https://assets.test.datacite.org"
ENV['REDIS_URL'] ||= "redis://redis:6379/12"
ENV['GITHUB_URL'] ||= "https://github.com/datacite/volpino"
ENV['BLOG_URL'] ||= "https://blog.test.datacite.org"
ENV['MODE'] ||= "datacite"
ENV['TRUSTED_IP'] ||= "10.0.60.0/24"
ENV['MYSQL_DATABASE'] ||= "profiles"
ENV['MYSQL_USER'] ||= "root"
ENV['MYSQL_PASSWORD'] ||= ""
ENV['MYSQL_HOST'] ||= "mysql"
ENV['MYSQL_PORT'] ||= "3306"
ENV['ES_HOST'] ||= "elasticsearch:9200"
ENV['ES_NAME'] ||= "elasticsearch"

module Volpino
  class Application < Rails::Application
    # autoload files in lib folder
    config.autoload_paths << Rails.root.join('lib')

    # include graphql
    config.paths.add Rails.root.join('app', 'graphql', 'types').to_s, eager_load: true
    config.paths.add Rails.root.join('app', 'graphql', 'mutations').to_s, eager_load: true

    # add assets installed via node
    config.assets.paths << "#{Rails.root}/vendor/node_modules"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:jwt]

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # Write all logs to STDOUT instead of file
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
    config.log_level = ENV['LOG_LEVEL'].to_sym

    config.active_job.logger = config.logger

    # Use memcached as cache store
    config.cache_store = :dalli_store, nil, { :namespace => ENV['APPLICATION'], :compress => true }

    # compress responses with deflate or gzip
    config.middleware.use Rack::Deflater

    # set Active Job queueing backend
    if ENV['AWS_REGION']
      config.active_job.queue_adapter = :shoryuken
    else
      config.active_job.queue_adapter = :inline
    end
    config.active_job.queue_name_prefix = Rails.env
  end
end
