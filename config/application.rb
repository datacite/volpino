# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "active_job/logging"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# load ENV variables from .env file if it exists
env_file = File.expand_path("../.env", __dir__)
if File.exist?(env_file)
  require "dotenv"
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
ENV["APPLICATION"] ||= "volpino"
ENV["HOSTNAME"] ||= "profiles.local"
ENV["SESSION_KEY"] ||= "_#{ENV['APPLICATION']}_session"
ENV["MEMCACHE_SERVERS"] ||= "memcached:11211"
ENV["SITE_TITLE"] ||= "DataCite Profiles"
ENV["LOG_LEVEL"] ||= "info"
ENV["ORCID_URL"] ||= "https://sandbox.orcid.org"
ENV["ORCID_API_URL"] ||= "https://api.sandbox.orcid.org"
ENV["COMMONS_URL"] ||= "https://commons.stage.datacite.org"
ENV["API_URL"] ||= "https://api.stage.datacite.org"
ENV["CDN_URL"] ||= "https://assets.stage.datacite.org"
ENV["REDIS_URL"] ||= "redis://redis:6379/12"
ENV["GITHUB_URL"] ||= "https://github.com/datacite/volpino"
ENV["BLOG_URL"] ||= "https://blog.stage.datacite.org"
ENV["HOMEPAGE_URL"] ||= "https://www.stage.datacite.org"
ENV["MODE"] ||= "datacite"
ENV["TRUSTED_IP"] ||= "10.0.60.0/24"
ENV["MYSQL_DATABASE"] ||= "profiles"
ENV["MYSQL_USER"] ||= "root"
ENV["MYSQL_PASSWORD"] ||= ""
ENV["MYSQL_HOST"] ||= "mysql"
ENV["MYSQL_PORT"] ||= "3306"
ENV["ES_HOST"] ||= "elasticsearch:9200"
ENV["ES_SCHEME"] ||= "http"
ENV["ES_PORT"] ||= "80"
ENV["ES_NAME"] ||= "elasticsearch"
ENV["ES_PREFIX"] ||= ""
ENV["SANDBOX"] ||= nil

module Volpino
  class Application < Rails::Application
    # autoload files in lib folder
    config.autoload_paths << Rails.root.join("lib")

    # include graphql
    config.paths.add Rails.root.join("app", "graphql", "types").to_s, eager_load: true
    config.paths.add Rails.root.join("app", "graphql", "mutations").to_s, eager_load: true

    # add assets installed via node
    config.assets.paths << "#{Rails.root}/vendor/node_modules"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:jwt]

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # configure logging
    config.active_job.logger = nil
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Logstash.new
    config.lograge.logger = LogStashLogger.new(type: :stdout)
    config.logger = config.lograge.logger        ## LogStashLogger needs to be pass to rails logger, see roidrage/lograge#26
    config.log_level = ENV["LOG_LEVEL"].to_sym   ## Log level in a config level configuration

    config.lograge.ignore_actions = ["HeartbeatController#index", "IndexController#index"]
    config.lograge.ignore_custom = lambda do |event|
      event.payload.inspect.length > 100000
    end
    config.lograge.base_controller_class = ["ActionController::API", "ActionController::Base"]

    config.lograge.custom_options = lambda do |event|
      exceptions = %w(controller action format id)
      {
        params: event.payload[:params].except(*exceptions),
        uid: event.payload[:uid],
      }
    end

    # Use memcached as cache store
    config.cache_store = :dalli_store, nil, { namespace: ENV["APPLICATION"], compress: true }

    # compress responses with deflate or gzip
    config.middleware.use Rack::Deflater

    # set Active Job queueing backend
    config.active_job.queue_adapter = if ENV["AWS_REGION"]
      :shoryuken
    else
      :inline
    end
    queue_name_prefix = if Rails.env.stage?
      ENV["ES_PREFIX"].present? ? "stage" : "test"
    else
      Rails.env
    end
    config.active_job.queue_name_prefix = queue_name_prefix
  end
end
