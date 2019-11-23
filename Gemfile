source 'https://rubygems.org'

gem 'rails', '~> 5.2.0'
gem 'bootsnap', '~> 1.4', '>= 1.4.4', require: false
gem 'mysql2', '~> 0.4.4'

gem "dotenv", '~> 2.1'
gem "config"
gem 'tzinfo-data'
gem 'rake', '~> 12.0'
gem 'sentry-raven', '~> 2.9'
gem 'orcid_client', '~> 0.5', '>= 0.8'
gem 'addressable', "~> 2.3"
gem 'postrank-uri', '~> 1.0', '>= 1.0.23'
gem 'nilify_blanks', '~> 1.3'
gem 'aasm', '~> 5.0', '>= 5.0.1'
gem 'shoryuken', '~> 4.0'
gem "aws-sdk-s3", require: false
gem 'aws-sdk-sqs', '~> 1.3'
gem 'active_model_serializers', '~> 0.10.4'
gem 'fast_jsonapi', '~> 1.3'
gem 'colorize', '~> 0.8.1'
gem 'pwqgen.rb', '~> 0.1.0'
gem 'base32-crockford-checksum', '~> 0.2.3'
gem 'flipper', '~> 0.16'
gem 'flipper-redis'
gem 'flipper-api'
gem 'flipper-ui'
gem 'flipper-active_support_cache_store'

gem 'kaminari', '~> 1.0', '>= 1.0.1'
gem "simple_form", "~> 4.1.0"
gem 'country_select', '~> 2.5', '>= 2.5.1'
gem 'nokogiri', '~> 1.8'
gem "github-markdown", "~> 0.6.3"
gem 'rouge', '~> 3.9'
gem 'hashie', '~> 3.5.0'
gem 'bergamasco', '~> 0.3.17'
gem 'dalli', '~> 2.7', '>= 2.7.6'
gem 'namae', '~> 1.0'
gem 'lograge', '~> 0.10.0'
gem 'logstash-event', '~> 1.2', '>= 1.2.02'
gem 'logstash-logger', '~> 0.26.1'
gem 'rack-cors', '~> 1.0', :require => 'rack/cors'

gem 'devise', '~> 4.7'
gem 'omniauth-github', '~> 1.1.2'
gem "omniauth-orcid", '~> 2.0'
gem 'omniauth-globus', '~> 0.8.3'
gem 'omniauth', '~> 1.3', '>= 1.3.1'
gem 'oauth2', '~> 1.4'
gem 'validates_email_format_of', '~> 1.6', '>= 1.6.3'
gem 'jwt', '~> 2.2', '>= 2.2.1'
gem 'cancancan', '~> 2.0'
gem 'mailgun-ruby', '~> 1.1'
gem 'gravtastic', '~> 3.2', '>= 3.2.6'

gem 'maremma', '>= 4.3'
gem 'elasticsearch', '~> 7.1.0'
gem 'elasticsearch-model', '~> 7.0', require: 'elasticsearch/model'
gem 'elasticsearch-rails', '~> 7.0'
gem 'faraday_middleware-aws-sigv4', '~> 0.2.4'
gem 'rack-utf8_sanitizer', '~> 1.6'
gem 'graphql', '~> 1.9', '>= 1.9.4'
gem 'graphql-errors', '~> 0.3.0'
gem 'graphql-batch', '~> 0.4.0'
gem 'batch-loader', '~> 1.4', '>= 1.4.1'
gem 'graphql-cache', '~> 0.6.0', git: "https://github.com/stackshareio/graphql-cache"
gem 'apollo-federation', '~> 0.4.0'
gem 'google-protobuf', '3.10.0.rc.1'

gem 'sprockets', '~> 3.7', '>= 3.7.2'
gem 'sprockets-rails', '~> 3.2', '>= 3.2.1', :require => 'sprockets/railtie'
gem 'coffee-rails', '~> 4.1', '>= 4.1.1'
gem 'sassc-rails', '>= 2.1.0'
gem 'uglifier', '~> 2.7', '>= 2.7.2'
gem 'mini_magick', '~> 4.5', '>= 4.5.1'
gem 'remotipart', '~> 1.2'
gem 'rack-jwt'
gem 'git', '~> 1.5'

group :development do
  gem 'pry-rails', '~> 0.3.2'
  gem 'better_errors', '~> 2.0.0'
  gem 'binding_of_caller', '~> 0.7.2'
  gem 'hologram', '~> 1.4'
  gem 'web-console', '~> 3.7'
  gem 'httplog', '~> 1.3'
end

group :development, :test do
  gem 'rspec-rails', '~> 3.8', '>= 3.8.2'
  gem 'byebug'
  gem 'spring'
  gem 'teaspoon-jasmine', '~> 2.2.0'
  gem 'brakeman', '~> 4.6', '>= 4.6.1', :require => false
  gem 'rubocop', '~> 0.68', require: false
  gem 'rubocop-performance', '~> 1.2', require: false
  gem 'listen', '~> 3.1', '>= 3.1.5'
end

group :test do
  gem "factory_bot_rails", "~> 4.8", :require => false
  gem 'capybara', '~> 3.28'
  gem 'capybara-screenshot', '~> 1.0', '>= 1.0.23'
  gem 'database_cleaner', '~> 1.7'
  gem "launchy", "~> 2.4.2"
  gem "email_spec", "~> 1.6.0"
  gem 'rack-test', '~> 1.1', :require => "rack/test"
  gem 'simplecov', '~> 0.1'
  gem 'codeclimate-test-reporter', '~> 1.0', '>= 1.0.8'
  gem "shoulda-matchers", "~> 2.7.0", :require => false
  gem 'webmock', '~> 3.7'
  gem 'vcr', '~> 3.0', '>= 3.0.3'
  gem 'poltergeist', '~> 1.15'
  gem "with_env", "~> 1.1.0"
  gem 'elasticsearch-extensions', '~> 0.0.29'
end
