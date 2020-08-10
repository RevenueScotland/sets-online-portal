# frozen_string_literal: true

require 'test_helper'
require 'print_data_test_helper'
require 'savon/mock/spec_helper'
require 'models/reference_data/memory_cache_helper'

# Run tests that are included only in this file by:
#   $ ruby -I test test/models/returns/slft/print_data_test.rb
module Returns
  # Part of the slft module
  module Slft
    # Tests PrintData data
    class PrintDataTest < ActiveSupport::TestCase
      include ReferenceData::MemoryCacheHelper
      include PrintDataTestHelper

      # This test relies on the cache so clear the cache first
      # and mock the calls to the back office to populate
      setup do
        set_memory_cache

        @savon ||= Savon::SpecHelper::Interface.new
        @savon.mock!
        fixture = File.read('test/fixtures/mocks/reference_data/reference_values_response.xml')
        @savon.expects(:get_reference_values_wsdl).returns(fixture)
        fixture = File.read('test/fixtures/mocks/reference_data/system_parameters_response.xml')
        @savon.expects(:get_system_parameters_wsdl).returns(fixture)
        Rails.logger.debug { 'Mocking started' }

        # Overriding the setup_sites method as it calls the back office
        # We can't mock it as the object load ends up loading the site reference as a string while the webservice
        # returns a number and then they still don't match
        SlftReturn.class_eval do
          alias_method :setup_sites_original_method, :setup_sites
          def setup_sites
            nil
          end
        end
      end

      # Stop the mocking and reset the cache
      teardown do
        @savon&.unmock!
        Rails.logger.debug { 'Mocking ended' }
        restore_original_cache

        # Reset the set up sites
        SlftReturn.class_eval do
          alias_method :setup_sites, :setup_sites_original_method
          remove_method :setup_sites_original_method
        end
      end

      # SLfT return that includes the following details:
      # - Newly created
      # - No waste details added
      # - All information about credits are checked no
      # - Claimable
      test 'print slft return minimal pdf receipt data' do
        actual, expected = print_data_to_compare('slft_minimal_data', :print_layout_receipt)
        assert_equal(actual, expected, 'SLFT json strings do not match')
      end

      test 'print slft return minimal pdf data' do
        actual, expected = print_data_to_compare('slft_minimal_data')
        assert_equal(actual, expected, 'SLFT json strings do not match')
      end

      # SLfT created includes the following details:
      # - Newly created
      # - Waste details 1 added manually
      # - Waste details 2 added by upload
      # - All information about credits are checked yes
      # - Amendable
      test 'print slft return all details filled pdf data' do
        actual, expected = print_data_to_compare('slft_full')
        assert_equal(actual, expected, 'SLFT json strings do not match')
      end

      test 'print slft return all details filled pdf receipt data' do
        actual, expected = print_data_to_compare('slft_full', :print_layout_receipt)
        assert_equal(actual, expected, 'SLFT json strings do not match')
      end

      # The same reference number as above, but created through amending
      # - Created by amend
      # - Repayment on submit checked yes
      # - Claimable
      test 'print slft return amend pdf data' do
        actual, expected = print_data_to_compare('slft_amend')
        assert_equal(actual, expected, 'SLFT json strings do not match')
      end

      test 'print slft return amend pdf receipt data' do
        actual, expected = print_data_to_compare('slft_amend', :print_layout_receipt)
        assert_equal(actual, expected, 'SLFT json strings do not match')
      end
    end
  end
end
