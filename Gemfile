# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'
# Use Puma as the app server
gem 'puma', '~> 6.0'
# Use propshaft for asset management, currently using a forked version due to https://github.com/rails/propshaft/issues/103
# gem 'propshaft', git: 'https://github.com/rails/propshaft', branch: 'asset-host'
gem 'propshaft', git: 'https://github.com/markstanley-nps/propshaft', branch: 'relative-url-root'
# gem 'propshaft', path: '../propshaft'
# Transpile app-like JavaScript. Read more: https://github.com/rails/jsbundling-rails
# We build the css using sass-loader so not cssbundling-rails
gem 'jsbundling-rails'
# Turbo https://github.com/hotwired/turbo-rails
gem 'turbo-rails'
# Stimulus https://github.com/hotwired/stimulus-rails
gem 'stimulus-rails'
# Include view component
gem 'view_component'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9'
# Use Redis for caching and session storage
gem 'redis'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.4', require: false

# HTTP user agent parser
gem 'useragent', '~> 0.16'
# Used for making SOAP calls
# Locked to 1.12 see RSTP-1065
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
  gem 'rubocop-capybara', require: false
  gem 'rubocop-performance', require: false
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
# Remove platform check following ruby 3.1 upgrade https://github.com/rubygems/rubygems/issues/5269
gem 'tzinfo-data' # , platforms: %i[mingw mswin x64_mingw jruby]
