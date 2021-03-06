source 'https://rubygems.org'

gem 'rails', '~> 5.2.0'
gem 'mysql2', '~> 0.4.4'
gem 'dotenv'
gem 'rake', '~> 12.0'
gem 'multi_json'
gem 'json', '~> 1.8', '>= 1.8.5'
gem 'oj', '~> 2.18', '>= 2.18.1'
gem 'jsonlint', '~> 0.2.0'
gem 'active_model_serializers', '~> 0.10.0'
gem 'fast_jsonapi', '~> 1.3'
gem 'dalli', '~> 2.7', '>= 2.7.6'
gem 'lograge', '~> 0.10.0'
gem 'logstash-event', '~> 1.2', '>= 1.2.02'
gem 'logstash-logger', '~> 0.26.1'
gem 'maremma', '>= 4.1'
gem 'bolognese', '~> 1.0'
gem 'cancancan', '~> 2.0'
gem 'jwt'
gem 'kaminari', '~> 1.0', '>= 1.0.1'
gem 'base32-url', '~> 0.3'
gem 'mailgun-ruby', '~> 1.1', '>= 1.1.8'
gem 'aasm', '~> 4.12', '>= 4.12.3'
gem 'shoryuken', '~> 4.0'
gem "aws-sdk-s3", require: false
gem 'aws-sdk-sqs', '~> 1.3'
gem 'sentry-raven', '~> 2.9'
gem 'strip_attributes', '~> 1.8'
gem 'slack-notifier', '~> 2.1'
gem 'mini_magick', '~> 4.8'
gem 'iso8601', '~> 0.9.1'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'rack-cors', '~> 1.0', '>= 1.0.2', :require => 'rack/cors'
gem 'elasticsearch-model', '~> 6.0', '>= 6.0.0', require: 'elasticsearch/model'
gem 'elasticsearch-rails', '~> 6.0', '>= 6.0.0'
gem 'faraday_middleware-aws-sigv4', '~> 0.2.4'
gem 'rack-utf8_sanitizer', '~> 1.6'
gem 'oj_mimic_json', '~> 1.0', '>= 1.0.1'
gem 'git', '~> 1.5'

group :development, :test do
  gem 'rspec-rails', '~> 3.5', '>= 3.5.2'
  gem "better_errors"
  gem "binding_of_caller"
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'capybara'
  gem 'webmock', '~> 3.1'
  gem 'vcr', '~> 3.0.3'
  gem 'codeclimate-test-reporter', '~> 1.0.0'
  gem 'simplecov'

  gem 'factory_bot_rails', '~> 4.8', '>= 4.8.2'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'database_cleaner'
end