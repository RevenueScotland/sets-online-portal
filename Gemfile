# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 2.5.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SASSC rails for stylesheets replaces sass
gem 'sassc-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'duktape'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
# @see Read more: https://github.com/jquery-ui-rails/jquery-ui-rails
gem 'jquery-ui-rails'
# Use Redis for caching and session storage
gem 'redis', '~> 4.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# HTTP user agent parser
gem 'useragent', '~> 0.16.7'
# Used for making SOAP calls
gem 'savon', '~> 2.12.0'
# Wraps warden for security
gem 'rails_warden', '~> 0.6.0'
# Used for making REST calls
gem 'httparty', '~> 0.16.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capybara-screenshot', require: false
  gem 'cucumber-rails', require: false
  gem 'rubocop', require: false
  gem 'yard', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26.0'
  gem 'selenium-webdriver'
  # add code coverage
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Latest version prevents app from starting on windows at least, on next upgrade remove this restriction and try again
gem 'ruby-prof', '0.17.0'

# Ruby ZIP utils
gem 'rubyzip', '>= 1.3.0'

# Ruby/ClamAV wrapper
gem 'clamby'
