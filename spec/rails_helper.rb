ENV['RAILS_ENV'] = 'test'

# set up Code Climate
require 'simplecov'
SimpleCov.start

require File.expand_path('../../config/environment', __FILE__)

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

require "rspec/rails"
require "shoulda-matchers"
require "webmock/rspec"
require "rack/test"
require "colorize"
require "database_cleaner"
require 'aasm/rspec'
require "strip_attributes/matchers"

# Checks for pending migration and applies them before tests are run.
ActiveRecord::Migration.maintain_test_schema!

WebMock.disable_net_connect!(
  allow: ['codeclimate.com:443', ENV['PRIVATE_IP'], ENV['ES_HOST']],
  allow_localhost: true
)

# configure shoulda matchers to use rspec as the test framework and full matcher libraries for rails
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # add `FactoryBot` methods
  config.include FactoryBot::Syntax::Methods
  config.include StripAttributes::Matchers
  config.include Rack::Test::Methods, :type => :request
  config.include Rack::Test::Methods, :type => :controller
  # don't use transactions, use database_clear gem via support file
  config.use_transactional_fixtures = false

  # add custom json method
  config.include RequestHelper, type: :request

  config.include JobHelper, type: :job

  ActiveJob::Base.queue_adapter = :test
end

VCR.configure do |c|
  mds_token = Base64.strict_encode64("#{ENV['MDS_USERNAME']}:#{ENV['MDS_PASSWORD']}")
  mailgun_token = Base64.strict_encode64("api:#{ENV['MAILGUN_API_KEY']}")
  sqs_host = "sqs.#{ENV['AWS_REGION'].to_s}.amazonaws.com"

  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.ignore_hosts "codeclimate.com", "api.mailgun.net", "elasticsearch", sqs_host
  c.filter_sensitive_data("<MAILGUN_TOKEN>") { mailgun_token }
  c.filter_sensitive_data("<SLACK_WEBHOOK_URL>") { ENV["SLACK_WEBHOOK_URL"] }
  c.configure_rspec_metadata!
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
