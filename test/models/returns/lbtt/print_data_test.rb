# frozen_string_literal: true

require 'test_helper'
require 'print_data_test_helper'
require 'savon/mock/spec_helper'

# Run tests that are included only in this file by:
#   $ ruby -I test test/models/returns/lbtt/print_data_test.rb
module Returns
  # Part of the slft module
  module Lbtt
    # Tests PrintData data
    class PrintDataTest < ActiveSupport::TestCase
      include PrintDataTestHelper

      # This test relies on the cache so clear the cache first
      # and mock the calls to the back office to populate
      setup do
        Rails.cache.clear

        @savon ||= Savon::SpecHelper::Interface.new
        @savon.mock!
        fixture = File.read('test/fixtures/mocks/reference_data/reference_values_response.xml')
        @savon.expects(:get_reference_values_wsdl).returns(fixture)
        fixture = File.read('test/fixtures/mocks/reference_data/tax_relief_types_response.xml')
        @savon.expects(:get_tax_relief_types_wsdl).returns(fixture)
        Rails.logger.debug { 'Mocking started' }
        # Force cache population for ref data and tax relief types
        ReferenceData::ReferenceValue.lookup('TITLES', 'SYS', 'RSTU')
        ReferenceData::TaxReliefType.lookup('RELIEF_TYPES', 'LBTT', 'RSTU')
      end

      # Stop the mocking and reset the cache
      teardown do
        @savon&.unmock!
        Rails.logger.debug { 'Mocking ended' }
      end

      # Tests the Conveyance return with the following data:
      # - Return is version 1 being saved from a draft
      # - New Conveyance
      # - Buyer is an Other organisation: Trust
      # - Seller is Organisation registered with Companies House
      # - Property has ADS
      # - Transaction details are:
      #   - Property type for transaction: Non-residential
      #   - Linked transactions: yes
      #   - Reliefs on this transaction: yes
      #   - Sale of business: yes
      # - Payment and submission: BACS
      test 'print lbtt conveyance return with ADS pdf data' do
        actual, expected = print_data_to_compare('lbtt_conveyance_a')

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      test 'print lbtt conveyance return with ADS receipt data' do
        actual, expected = print_data_to_compare('lbtt_conveyance_a', :print_layout_receipt)

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      # Tests the amended Conveyance return with the following data:
      # - Return is third version being submitted
      # - Added a Buyer that is an Other organisation: Club
      # - Added a Seller that is an Other organisation: Other
      # - Edit ADS -> amending the return: yes
      # - Submit return with Request a repayment from RS: yes
      test 'print an amended lbtt conveyance return pdf data' do
        actual, expected = print_data_to_compare('lbtt_conveyance_b')

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      test 'print an amended lbtt conveyance return receipt data' do
        actual, expected = print_data_to_compare('lbtt_conveyance_b', :print_layout_receipt)

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      # Test Conveyance return without ADS and with minimal data
      # - Return is second version being submitted with no draft
      # - New Conveyance
      # - Buyer and Seller are both Private Individuals
      # - Property has no ADS
      # - Transaction details are:
      #   - Property type for transaction: Residential
      #   - Linked transactions: no
      #   - Reliefs on this transaction: no
      #   - Sale of business: no
      # - Payment and submission: Cheque
      test 'print lbtt conveyance return without ads pdf data' do
        actual, expected = print_data_to_compare('lbtt_conveyance_c')

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      test 'print lbtt conveyance return without ads receipt data' do
        actual, expected = print_data_to_compare('lbtt_conveyance_c', :print_layout_receipt)

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      # Test Lease return
      # - Return is first version being submitted
      # - Tenant is an Other organisation: Charity
      # - Landlord is a Private Individual
      # - Transaction details are:
      #   - Property type for transaction: Residential
      #   - Linked transactions: yes
      #   - Reliefs on this transaction: yes
      #   - Rental years the same: no
      # - Payment and submission: Direct Debit
      test 'print lbtt lease pdf data' do
        actual, expected = print_data_to_compare('lbtt_lease')

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      test 'print lbtt lease receipt data' do
        actual, expected = print_data_to_compare('lbtt_lease', :print_layout_receipt)

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      # Test Assignation return
      # - Return is a draft of version 1
      # - Tenant is an Other organisation: Partnership
      # - New tenant is an Other organisation: Company (not registered with UK companies house)
      # - Transaction details are:
      #   - Linked transactions: no
      #   - Rental years the same: yes
      #   - Premium paid: yes
      # - Submit return with Request a repayment from RS: no
      # - Payment and submission: BACS
      test 'print lbtt assignation pdf data' do
        actual, expected = print_data_to_compare('lbtt_assignation')

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end

      test 'print lbtt assignation receipt data' do
        actual, expected = print_data_to_compare('lbtt_assignation', :print_layout_receipt)

        assert_equal(actual, expected, 'LBTT json strings do not match')
      end
    end
  end
end
