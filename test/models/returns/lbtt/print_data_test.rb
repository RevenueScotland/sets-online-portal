# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'print_data_test_helper'

# Run tests that are included only in this file by:
#   $ ruby -I test test/models/returns/lbtt/print_data_test.rb
module Returns
  # Part of the slft module
  module Lbtt
    # Tests PrintData data
    class PrintDataTest < ActiveSupport::TestCase
      include PrintDataTestHelper
      # Tests the Conveyance return with the following data:
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
      # - Tenant is an Other organisation: Partnership
      # - New tenant is an Other organisation: Company (not registreded with UK companies house)
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

      # Overriding the insert_values method of the print_data_test_helper
      def insert_values(object)
        insert_cached_ref_data(object)
      end

      # Inserts the cached_ref_data to the parties, properties and the lbtt_return object itself.
      def insert_cached_ref_data(object)
        cache_json = File.read(print_test_path + '/cached_ref_data.json')
        cache_hash = Serializer.from_json_to_object(cache_json)
        object.cached_ref_data = cache_hash['cached_ref_data']
        object = insert_parties_cached_ref_data(object, cache_hash)
        unless object.properties.blank?
          object.properties.each do |_, property|
            property.cached_ref_data = cache_hash['properties']['cached_ref_data']
          end
        end
        object
      end

      # Inserts the cached_ref_data to all the party types if they exist.
      def insert_parties_cached_ref_data(object, cache_hash)
        parties = %w[buyers sellers tenants new_tenants landlords]
        parties.each do |party_string|
          party_hash = object.send(party_string)
          next if party_hash.blank?

          party_hash.each { |_, party| party.cached_ref_data ||= cache_hash['parties']['cached_ref_data'] }
          object.send("#{party_string}=", party_hash)
        end
        object
      end

      # Print data options specific to lbtt
      def print_data_options(object, layout)
        { print_layout: { account_type: object.account_type, flbt_type: object.flbt_type },
          print_layout_receipt: { receipt: :receipt } }[layout]
      end
    end
  end
end
