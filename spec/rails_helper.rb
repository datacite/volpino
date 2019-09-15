# set ENV variables for testing
ENV["RAILS_ENV"] = "test"
ENV['ORCID_URL'] = "https://sandbox.orcid.org"
ENV['ORCID_API_URL'] = "https://api.sandbox.orcid.org"

# set up Code Climate
require 'simplecov'
SimpleCov.start

require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "shoulda-matchers"
require "email_spec"
require "factory_bot_rails"
require "capybara/rspec"
require "capybara/rails"
require "capybara/poltergeist"
require "capybara-screenshot/rspec"
require "database_cleaner"
require "webmock/rspec"
require "rack/test"
require 'aasm/rspec'
require "devise"
require "colorize"
require "maremma"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    timeout: 180,
    inspector: true,
    debug: false,
    window_size: [1024, 768]
  })
end

Capybara.javascript_driver = :poltergeist
Capybara.default_selector = :css

Capybara.configure do |config|
  config.match = :prefer_exact
  config.ignore_hidden_elements = true
end

WebMock.disable_net_connect!(
  allow: ['codeclimate.com:443', ENV['PRIVATE_IP'], ENV['HOSTNAME']],
  allow_localhost: true
)

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.ignore_hosts "codeclimate.com"
  c.filter_sensitive_data("<ORCID_CLIENT_ID>") { ENV["ORCID_CLIENT_ID"] }
  c.filter_sensitive_data("<ORCID_CLIENT_SECRET>") { ENV["ORCID_CLIENT_SECRET"] }
  c.filter_sensitive_data("<ORCID_TOKEN>") { ENV["ORCID_TOKEN"] }
  c.filter_sensitive_data("<ACCESS_TOKEN>") { ENV["ACCESS_TOKEN"] }
  c.filter_sensitive_data("<NOTIFICATION_ACCESS_TOKEN>") { ENV["NOTIFICATION_ACCESS_TOKEN"] }
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  OmniAuth.config.test_mode = true
  config.before(:each) do
    OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new({
      provider: "orcid",
      uid: "0000-0002-1825-0097",
      info: { "name" => "Josiah Carberry" },
      extra: {},
      credentials: { token: "123",
                     expires_at: Time.zone.now + 20.years }
    })
  end

  # don't use transactions, use database_clear gem via support file
  config.use_transactional_fixtures = false

  config.fixture_path = "#{::Rails.root}/spec/fixtures/"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.order = :random

  # config.include WebMock::API
  config.include FactoryBot::Syntax::Methods

  config.include Rack::Test::Methods, :type => :api

  config.include Devise::Test::ControllerHelpers, :type => :controller
  config.include Rack::Test::Methods, :type => :controller

  config.include ActiveJob::TestHelper, type: :job

  def app
    Rails.application
  end

  # restore application-specific ENV variables after each example
  config.after(:each) do
    ENV_VARS.each { |k,v| ENV[k] = v }
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end
end
