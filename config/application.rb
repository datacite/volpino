require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

begin
  # make sure DOTENV is set
  ENV["DOTENV"] ||= "default"

  # load ENV variables from file specified by DOTENV
  # use .env with DOTENV=default
  filename = ENV["DOTENV"] == "default" ? ".env" : ".env.#{ENV['DOTENV']}"
  Dotenv.load! File.expand_path("../../#{filename}", __FILE__)
rescue Errno::ENOENT
  $stderr.puts "Please create #{filename} file, or use DOTENV=example for example configuration"
  exit
end

module Volpino
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # add assets installed via bower
    config.assets.paths << "#{Rails.root}/frontend/bower_components"

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

    # compress responses with deflate or gzip
    config.middleware.use Rack::Deflater

    # set Active Job queueing backend
    config.active_job.queue_adapter = :sidekiq

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
  end
end
