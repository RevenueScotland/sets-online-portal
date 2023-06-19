# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

use Rack::RubyProf, path: 'log/profile' if ENV.key?('PROFILE') || File.exist?('tmp/run_with_profile')

map ENV.fetch('APPLICATION_DOCROOT', '/') do
  run Rails.application
end
