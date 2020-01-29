# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'print_data_test_helper'

# Run tests that are included only in this file by:
#   $ ruby -I test test/models/claim/print_data_test.rb
module Claim
  # Overrides the specific methods of the ClaimPayment class
  ClaimPayment.class_eval do
    # The filing date is converted to a string with format of "2017-12-07" however, that can't be used
    # with the subtraction of dates as it needs a date object (which could be in this format "Thu, 07 Dec 2017")
    def pre_claim?
      return false if filing_date.blank?

      # This is the only change made to the pre_claim? method.
      filing_days_old = (Date.today - filing_date.to_date).to_i.days
      # If the filing date is 365 days old or older then true (used for showing the claim)
      (filing_days_old <= Rails.configuration.x.returns.amendable_days)
    end

    # No need to do the validation as the unit test only needs to test the claim for the print_data output.
    def tare_reference=(value)
      @tare_reference = value
    end
  end

  # Unit test for the claim pdf print data
  class PrintDataTest < ActiveSupport::TestCase
    include PrintDataTestHelper
    test 'print lbtt claim with ADS and additional tax payer pdf data' do
      actual, expected = print_data_to_compare('claim_lbtt_a')
      assert_equal(actual, expected, 'Claim LBTT json strings do not match')
    end

    test 'print lbtt claim without ADS and without additional tax payer pdf data' do
      actual, expected = print_data_to_compare('claim_lbtt_b')
      assert_equal(actual, expected, 'Claim LBTT json strings do not match')
    end

    test 'print slft claim pdf data' do
      actual, expected = print_data_to_compare('claim_slft')
      assert_equal(actual, expected, 'Claim SLfT json strings do not match')
    end

    # Print data options specific to the claim
    def print_data_options(object, layout)
      { print_layout: { account_type: object.account_type }, print_layout_receipt: { receipt: :receipt } }[layout]
    end
  end
end
