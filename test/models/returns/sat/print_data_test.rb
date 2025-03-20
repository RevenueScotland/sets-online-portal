# frozen_string_literal: true

require 'test_helper'
require 'print_data_test_helper'
require 'savon/mock/spec_helper'

# Run tests that are included only in this file by:
#   $ ruby -I test test/models/returns/sat/print_data_test.rb
module Returns
  # Part of the sat module
  module Sat
    # Tests PrintData data
    class PrintDataTest < ActiveSupport::TestCase
      include PrintDataTestHelper

      # This test relies on the cache so clear the cache first
      # and mock the calls to the back office to populate
      setup do # rubocop:disable Metrics/BlockLength
        Rails.cache.clear

        @savon ||= Savon::SpecHelper::Interface.new
        @savon.mock!
        fixture = File.read('test/fixtures/mocks/reference_data/reference_values_response.xml')
        @savon.expects(:get_reference_values_wsdl).returns(fixture)
        fixture = File.read('test/fixtures/mocks/reference_data/system_parameters_response.xml')
        @savon.expects(:get_system_parameters_wsdl).returns(fixture)
        fixture = File.read('test/fixtures/mocks/reference_data/aggregate_type_rates_response.xml')
        message = { Service: 'SAT', RateEffectiveDate: @rate_date }
        @savon.expects(:get_aggregate_type_rates_wsdl).with(message: message).returns(fixture)
        Rails.logger.debug { 'Mocking started' }
        # Force cache population for ref data and system parameters
        ReferenceData::ReferenceValue.lookup('TITLES', 'SYS', 'RSTU')
        ReferenceData::SystemParameter.lookup('PWS', 'SYS', 'RSTU')

        # Overriding the user_periods method as it calls the back office
        # We can't mock it as the object load ends up loading the user periods as a string while the web service
        # returns a number and then they still don't match
        SatReturn.class_eval do
          alias_method :user_periods_original_method, :user_periods
          def user_periods(_current_user)
            nil
          end
        end

        ExemptAggregate.class_eval do
          alias_method :aggregate_type_rates_original_method, :aggregate_type_rates
          def aggregate_type_rates
            nil
          end
        end

        CreditClaim.class_eval do
          alias_method :aggregate_type_rates_original_method, :aggregate_type_rates
          def aggregate_type_rates
            nil
          end
        end
      end

      # Stop the mocking and reset the cache
      teardown do
        @savon&.unmock!
        Rails.logger.debug { 'Mocking ended' }

        # Reset the set up sites
        SatReturn.class_eval do
          alias_method :user_periods, :user_periods_original_method
          remove_method :user_periods_original_method
        end
      end

      # SAT return that includes the following details:
      # - multiple sites
      # - single aggregates per site
      test 'print sat return minimal pdf data' do
        actual, expected = print_data_to_compare('sat_minimal_data')
        assert_equal(actual, expected, 'SAT json strings do not match')
      end

      test 'print sat return amend pdf receipt data' do
        actual, expected = print_data_to_compare('sat_minimal_data', :print_layout_receipt)
        assert_equal(actual, expected, 'SAT receipts json strings do not match')
      end
    end
  end
end
