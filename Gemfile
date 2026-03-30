source "https://rubygems.org"

gem "bootsnap", "~> 1.23", require: false
gem "msgpack", "~> 1.8"
gem "mysql2", "~> 0.5.7"
gem "rails", "~> 8.1", ">= 8.1.2"

gem "aasm", "~> 5.5", ">= 5.5.2"
gem "active_model_serializers", "~> 0.10.16"
gem "addressable", "~> 2.8", ">= 2.8.9"
gem "aws-sdk-s3", "~> 1.215", require: false
gem "aws-sdk-sqs", "~> 1.111"
gem "config", "~> 5.6", ">= 5.6.1"
gem "connection_pool", "~> 3.0", ">= 3.0.2"
gem "dotenv", "~> 3.2"
# IMPORTANT!!!
# We have monkey patched this gem -> config/initializers/serialization_core.rb
# Please check this before upgrading/downgrading versions
gem "jsonapi-serializer", "~> 2.2"
gem "flipper", "~> 1.4"
gem "flipper-active_support_cache_store", "~> 1.4"
gem "flipper-redis", "~> 1.4"
gem "flipper-ui", "~> 1.4"
gem "oj", "~> 3.16", ">= 3.16.16"
gem "orcid_client", "~> 0.18.0"
gem "rake", "~> 13.3", ">= 13.3.1"
gem "sentry-ruby", "~> 6.4", ">= 6.4.1"
gem "sentry-rails", "~> 6.4", ">= 6.4.1"
gem "shoryuken", "~> 7.0", ">= 7.0.1"
gem "strip_attributes", "~> 1.9", ">= 1.9.2"
gem "tzinfo-data", "~> 1.2026", ">= 1.2026.1"

gem "dalli", "~> 5.0", ">= 5.0.2"
gem "hashie", "~> 5.1"
gem "kaminari", "~> 1.2", ">= 1.2.2"
gem "lograge", "~> 0.14.0"
gem "logstash-logger", "~> 1.0"

gem "namae", "~> 1.2"
gem "nokogiri", "~> 1.19", ">= 1.19.1"
gem "simple_form", "~> 5.4", ">= 5.4.1"

gem "cancancan", "~> 3.6", ">= 3.6.1"
gem "devise", "~> 5.0", ">= 5.0.2"
gem "jwt", "~> 3.1", ">= 3.1.2"
gem "mailgun-ruby", "~> 1.4", ">= 1.4.2" # not sure this is used
gem "omniauth", "~> 2.1", ">= 2.1.4"
gem "omniauth-github", "~> 2.0"
gem "omniauth-orcid", "~> 2.0"
gem "omniauth-rails_csrf_protection", "~> 2.0", ">= 2.0.1"
gem "repost", "~> 0.5.1"

gem "apollo-federation", "~> 3.10", ">= 3.10.3"
gem "elasticsearch", "~> 8.19", ">= 8.19.3"
gem "elasticsearch-model", "~> 8.0", ">= 8.0.1", require: "elasticsearch/model"
gem "elasticsearch-rails", "~> 8.0", ">= 8.0.1"
gem "elastic-transport", "~> 8.0", ">= 8.0.1"
gem "faraday_middleware-aws-sigv4", "~> 0.3.0"
gem "google-protobuf", "4.34"
gem "graphql", "~> 2.5", ">= 2.5.21"
gem "graphql-batch", "~> 0.6.1"
gem "maremma", "~> 6.0"

gem "mini_magick", "~> 5.3", ">= 5.3.1"
gem "sprockets", "~> 4.2", ">= 4.2.2"
gem "sprockets-rails", "~> 3.5", ">= 3.5.2", require: "sprockets/railtie"

group :development, :test do
  gem "better_errors", "~> 2.10", ">= 2.10.1"
  gem "binding_of_caller", "~> 2.0"
  gem "byebug", "~> 13.0", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails", "~> 8.0", ">= 8.0.4"
  gem "rubocop", "~> 1.85", ">= 1.85.1"
  gem "rubocop-performance", "~> 1.26", ">= 1.26.1"
  gem "rubocop-rails", "~> 2.34", ">= 2.34.3"
  gem "rubocop-packaging", "~> 0.6.0"
  gem "rubocop-rspec", "~> 3.9", require: false
end

group :development do
  gem "listen", "~> 3.10"
  gem "spring", "~> 4.4", ">= 4.4.2"
  gem "spring-watcher-listen", "~> 2.1"
end

group :test do
  gem "capybara", "~> 3.40"
  gem "capybara-screenshot", "~> 1.0", ">= 1.0.27"
  gem "cuprite", "~> 0.17"
  gem "database_cleaner-active_record", "~> 2.2", ">= 2.2.2"
  gem "email_spec", "~> 2.2"
  gem "factory_bot_rails", "~> 6.5", ">= 6.5.1"
  gem "shoulda-matchers", "~> 7.0", ">= 7.0.1"
  gem "simplecov", "~> 0.22.0"
  gem "test-prof", "~> 1.5", ">= 1.5.2"
  gem "vcr", "~> 6.4"
  gem "webmock", "~> 3.26", ">= 3.26.1"
end
