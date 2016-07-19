require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'syslog/logger'

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
ENV['SESSION_KEY'] ||= "_#{ENV['APPLICATION']}_session"
ENV['SESSION_DOMAIN'] ||= ""
# ENV['SESSION_ENCRYPTED_COOKIE_SALT'] ||= SecureRandom.hex(15)
# ENV['SESSION_ENCRYPTED_SIGNED_COOKIE_SALT'] ||= SecureRandom.hex(15)
ENV['SITENAMELONG'] ||= "DataCite Profiles"
ENV['LOG_LEVEL'] ||= "info"
ENV['GITHUB_URL'] ||= "https://github.com/datacite/volpino"
ENV['TRUSTED_IP'] ||= "10.0.10.1"

module Volpino
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # add assets installed via bower
    config.assets.paths << "#{Rails.root}/vendor/bower_components"

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Use a different cache store
    # dalli uses ENV['MEMCACHE_SERVERS']
    ENV['MEMCACHE_SERVERS'] ||= ENV['HOSTNAME']
    config.cache_store = :dalli_store, nil, { :namespace => ENV['APPLICATION'], :compress => true }

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:api_key, :jwt]

    # See everything in the log (default is :info)
    log_level = ENV["LOG_LEVEL"] ? ENV["LOG_LEVEL"].to_sym : :info
    config.log_level = log_level

    # Use a different logger for distributed setups
    config.lograge.enabled = true
    config.logger = Syslog::Logger.new(ENV['APPLICATION'])

    # compress responses with deflate or gzip
    config.middleware.use Rack::Deflater

    # set Active Job queueing backend
    config.active_job.queue_adapter = :sidekiq

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # parameter keys that are not explicitly permitted will raise error
    config.action_controller.action_on_unpermitted_parameters = :raise
  end
end
