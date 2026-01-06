# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner[:active_record].clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner[:active_record].strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner[:active_record].strategy = :truncation, { pre_count: true }
  end

  config.before(:each) do
    DatabaseCleaner[:active_record].start
  end

  config.after(:each) do
    DatabaseCleaner[:active_record].clean
  end
end
