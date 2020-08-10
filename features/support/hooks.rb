# frozen_string_literal: true

# set up the savon mocks each mock should be given a descriptive tag name
# This file contains the core processing for mocking
require 'savon/mock/spec_helper'

def start_mock
  @savon ||= Savon::SpecHelper::Interface.new
  @savon.mock!
  Rails.logger.debug { "Mocking started :  #{@savon.inspect}" }
end

FIXTURES_MOCK_ROOT = 'test/fixtures/mocks/'

# Clear the mocks after each scenario
After do
  @savon&.unmock!
  Rails.logger.debug { "Mocking ended :  #{@savon&.inspect}" }
end
