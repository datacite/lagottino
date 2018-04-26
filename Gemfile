source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# ruby '2.4.4'

gem 'rails', '~> 5.2.0'
gem 'mysql2', '~> 0.4.4'
gem 'dotenv'
gem 'multi_json'
gem 'json', '~> 1.8', '>= 1.8.5'
gem 'oj', '~> 2.18', '>= 2.18.1'
gem 'jsonlint', '~> 0.2.0'
gem 'active_model_serializers', '~> 0.10.0'
gem 'dalli', '~> 2.7', '>= 2.7.6'
gem 'lograge', '~> 0.5'
gem 'maremma', '>= 3.5'
gem 'bolognese', '~> 0.9', '>= 0.9'
gem 'cancancan', '~> 2.0'
gem 'jwt'
gem 'librato-rails', '~> 1.4.2'
gem 'kaminari', '~> 1.0', '>= 1.0.1'
gem 'base32-url', '~> 0.3'
gem 'mailgun-ruby', '~> 1.1', '>= 1.1.8'
gem 'aasm', '~> 4.12', '>= 4.12.3'
gem 'shoryuken', '~> 3.2', '>= 3.2.2'
gem "aws-sdk-s3", require: false
gem 'aws-sdk-sqs', '~> 1.3'
gem 'bugsnag', '~> 6.1', '>= 6.1.1'
gem 'strip_attributes', '~> 1.8'
gem 'slack-notifier', '~> 2.1'
gem 'mini_magick', '~> 4.8'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'rack-cors', '~> 1.0', '>= 1.0.2', :require => 'rack/cors'

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