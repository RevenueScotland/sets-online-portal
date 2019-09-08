# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

use Rack::RubyProf, path: 'log/profile' if ENV['PROFILE'].present? || File.exist?('tmp/run_with_profile')

if ENV['APPLICATION_DOCROOT'].present?
  map "/#{ENV['APPLICATION_DOCROOT']}" do
    run Rails.application
  end
else
  run Rails.application
end
