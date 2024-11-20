# frozen_string_literal: true

source "https://rubygems.org"

gem "bootsnap", "~> 1.4", ">= 1.4.4", require: false
gem "msgpack", "~> 1.4.4"
gem "mysql2", "~> 0.5.0"
gem "rails", "~> 7.1", ">= 7.1.3"

gem "aasm", "~> 5.0", ">= 5.0.6"
gem "active_model_serializers", "~> 0.10.10"
gem "addressable", "~> 2.7"
gem "aws-sdk-s3", require: false
gem "aws-sdk-sqs", "~> 1.23", ">= 1.23.1"
gem "base32-crockford-checksum", "~> 0.2.3"
gem "config", "~> 5.4"
gem "dotenv", "~> 2.7", ">= 2.7.5"
# IMPORTANT!!!
# We have monkey patched this gem -> config/initializers/serialization_core.rb
# Please check this before upgrading/downgrading versions
gem "jsonapi-serializer", "~> 2.2"
gem "flipper", "~> 1.3"
gem "flipper-active_support_cache_store"
gem "flipper-api"
gem "flipper-redis"
gem "flipper-ui"
gem "nilify_blanks", "~> 1.3"
gem "oj", ">= 2.8.3"
gem "oj_mimic_json", "~> 1.0", ">= 1.0.1"
gem "orcid_client", "~> 0.15.0"
gem "postrank-uri", "~> 1.1"
gem "pwqgen.rb", "~> 0.1.0"
gem "rake", "~> 12.0"
gem "sentry-raven", "~> 3.1", ">= 3.1.2"
gem "shoryuken", "~> 5.0", ">= 5.0.3"
gem "strip_attributes", "~> 1.9", ">= 1.9.2"
gem "tzinfo-data", "~> 1.2019", ">= 1.2019.3"

gem "commonmarker", "~> 0.21.0"
gem "country_select", "~> 4.0"
gem "dalli", "~> 2.7", ">= 2.7.10"
gem "hashie"
gem "kaminari", "~> 1.2"
gem "lograge", "~> 0.11.2"
gem "logstash-event", "~> 1.2", ">= 1.2.02"
gem "logstash-logger", "~> 0.26.1"
gem "namae", "~> 1.0", ">= 1.0.1"
gem "nokogiri", "~> 1.10", ">= 1.10.7"
gem "rack-cors", "~> 1.0", require: "rack/cors"
gem "rouge", "~> 3.15"
gem "simple_form", "~> 4.1.0"

gem "cancancan", "~> 3.0"
gem "devise", "~> 4.8", ">= 4.8.1"
gem "gravtastic", "~> 3.2", ">= 3.2.6"
gem "jwt", "~> 2.2", ">= 2.2.1"
gem "mailgun-ruby", "~> 1.2"
gem "oauth2", "~> 1.4"
gem "omniauth", "~> 2.0", ">= 2.0.4"
gem "omniauth-github", "~> 2.0"
gem "omniauth-globus", "~> 0.9.1"
gem "omniauth-orcid", "~> 2.0"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "repost", "~> 0.3.7"
gem "validates_email_format_of", "~> 1.6", ">= 1.6.3"

gem "apollo-federation", "~> 1.0"
gem "batch-loader", "~> 1.4", ">= 1.4.1"
gem "elasticsearch", "~> 7.1.0"
gem "elasticsearch-model", "~> 7.0", require: "elasticsearch/model"
gem "elasticsearch-rails", "~> 7.0"
gem "faraday_middleware-aws-sigv4", "~> 0.3.0"
gem "google-protobuf", "3.19.6"
gem "graphql", "~> 1.9", ">= 1.9.16"
gem "graphql-batch", "~> 0.4.1"
gem "graphql-cache", "~> 0.6.0"
gem "graphql-errors", "~> 0.4.0"
gem "maremma", "~> 5.0"
gem "rack-utf8_sanitizer", "~> 1.6"

gem "coffee-rails", "~> 4.1", ">= 4.1.1"
gem "git", "~> 1.5"
gem "mini_magick", "~> 4.5", ">= 4.5.1"
gem "rack-jwt"
gem "remotipart", "~> 1.2"
gem "sprockets", "~> 3.7", ">= 3.7.2"
gem "sprockets-rails", "~> 3.2", ">= 3.2.1", require: "sprockets/railtie"
gem "uglifier", "~> 2.7", ">= 2.7.2"

group :development, :test do
  gem "better_errors"
  gem "binding_of_caller"
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-benchmark", "~> 0.4.0"
  gem "rspec-graphql_matchers", "~> 1.4"
  gem "rspec-rails", "~> 6.1", ">= 6.1.1"
  gem "rubocop", "~> 1.3", ">= 1.3.1"
  gem "rubocop-performance", "~> 1.5", ">= 1.5.1"
  gem "rubocop-rails", "~> 2.8", ">= 2.8.1"
  gem "rubocop-packaging", "~> 0.5.1"
  gem "rubocop-rspec", "~> 2.0", require: false
end

group :development do
  gem "listen", "~> 3.9"
  gem "spring"
  gem "spring-commands-rspec"
  gem "spring-watcher-listen", "~> 2.1"
end

group :test do
  gem "capybara", "~> 3.31"
  gem "capybara-screenshot", "~> 1.0", ">= 1.0.24"
  gem "cuprite", "~> 0.9"
  gem "database_cleaner"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "elasticsearch-extensions", "~> 0.0.29"
  gem "email_spec", "~> 2.2"
  gem "factory_bot_rails", "~> 4.8", ">= 4.8.2"
  gem "hashdiff", [">= 1.0.0.beta1", "< 2.0.0"]
  gem "shoulda-matchers", "~> 4.1", ">= 4.1.2"
  gem "simplecov", "~> 0.22.0"
  gem "test-prof", "~> 0.10.2"
  gem "vcr", "~> 6.1"
  gem "webmock", "~> 3.1"
  gem "with_env", "~> 1.1"
end
