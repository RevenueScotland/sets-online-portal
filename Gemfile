# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'
# Use Puma as the app server
gem 'puma', '~> 5.6'
# Use SASSC rails for stylesheets, sass-rails points to this gem now https://github.com/rails/sass-rails/pull/424
gem 'sassc-rails'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'duktape'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9'
gem 'jquery-rails'
# @see Read more: https://github.com/jquery-ui-rails/jquery-ui-rails
gem 'jquery-ui-rails'
# Use Redis for caching and session storage
gem 'redis', '~> 4.1'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.4', require: false

# HTTP user agent parser
gem 'useragent', '~> 0.16'
# Used for making SOAP calls
gem 'savon', '~> 2.12'
# Wraps warden for security
gem 'rails_warden', '~> 0.6'
# Used for making REST calls
gem 'httparty', '~> 0.17'
# Read more: https://rubygems.org/gems/ruby-prof/versions/1.0.0
# See https://github.com/ruby-prof/ruby-prof/issues/269
# You may need to install this separately to use the non windows version
# gem install ruby-prof --platform RUBY
# bundle update --local
gem 'ruby-prof', '~> 1.0'

# Ruby ZIP utils
gem 'rubyzip', '~> 2.0'

# Ruby/ClamAV wrapper
gem 'clamby'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem 'brakeman', require: false
  gem 'rack-mini-profiler'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '~> 4.0'
  gem 'yard', require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.29'
  gem 'capybara-screenshot', require: false
  gem 'cucumber-rails', require: false
  gem 'selenium-webdriver'
  # add code coverage
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
