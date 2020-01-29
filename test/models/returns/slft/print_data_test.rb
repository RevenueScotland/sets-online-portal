# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'print_data_test_helper'

# Run tests that are included only in this file by:
#   $ ruby -I test test/models/returns/slft/print_data_test.rb
module Returns
  # Part of the slft module
  module Slft
    # Reopen the slft return class to ensure that the sites aren't deleted.
    SlftReturn.class_eval do
      # Overriding the setup_sites method as the sites are getting deleted when initialised.
      def setup_sites
        nil
      end
    end

    # Tests PrintData data
    class PrintDataTest < ActiveSupport::TestCase
      include PrintDataTestHelper
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
