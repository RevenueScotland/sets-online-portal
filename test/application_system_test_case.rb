# frozen_string_literal: true

require 'test_helper'

# Base Application level test class
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
end
