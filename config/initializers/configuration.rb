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
ENV['MEMCACHE_SERVERS'] ||= "localhost:11211"
ENV['SITE_TITLE'] ||= "DataCite Profiles"
ENV['LOG_LEVEL'] ||= "info"
ENV['LUPO_URL'] ||= "https://api.datacite.org"
ENV['CDN_URL'] ||= "https://assets.datacite.org"
ENV['GITHUB_URL'] ||= "https://github.com/datacite/volpino"
ENV['TRUSTED_IP'] ||= "127.0.0.0/8"
ENV['MEMCACHE_SERVERS'] ||= "127.0.0.1"

Rails.application.config.log_level = ENV['LOG_LEVEL'].to_sym

# Use memcached as cache store
Rails.application.config.cache_store = :dalli_store, nil, { :namespace => ENV['APPLICATION'], :compress => true }
