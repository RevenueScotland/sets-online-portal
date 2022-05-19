# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

use Rack::RubyProf, path: 'log/profile' if ENV.key?('PROFILE') || File.exist?('tmp/run_with_profile')

if ENV.key?('APPLICATION_DOCROOT')
  map "/#{ENV.fetch('APPLICATION_DOCROOT', nil)}" do
    run Rails.application
  end
else
  run Rails.application
end
