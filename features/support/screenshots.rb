# frozen_string_literal: true

# Setup for handling screen shots in cucumber

require 'capybara-screenshot/cucumber'

Capybara::Screenshot.register_filename_prefix_formatter(:cucumber) do |scenario|
  "screenshot_#{scenario.name.tr(' ', '-')}"
end

Capybara.save_path = ENV['CAPYBARA_SAVE_PATH'] unless ENV['CAPYBARA_SAVE_PATH'].nil?

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run
