# frozen_string_literal: true

require 'test_helper'
require 'print_data_test_helper'
require 'savon/mock/spec_helper'

# Run tests that are included only in this file by:
#   $ ruby -I test test/models/claim/print_data_test.rb
module Claim
  # Unit test for the claim pdf print data
  # This requires at least a model.json and printdata.json for each unit test
  # @note When getting the model.json make sure that we're excluding the filing_date as we're supposed to get
  #   that from the validate_return_reference_response.xml. If we don't do that then there will be an issue
  #   with the loading of the filing_date, it will be stored as a string and not as a date format.
  # @note make sure that we're only including the attributes we need for the test case.
  class PrintDataTest < ActiveSupport::TestCase
    include PrintDataTestHelper

    # This test relies on the cache so clear the cache first
    # and mock the calls to the back office to populate
    setup do
      Rails.cache.clear

      @savon ||= Savon::SpecHelper::Interface.new
      @savon.mock!

      # Each unit test cases has their own setups after this, so see each test cases for their specific setups.
    end

    # Put cache configuration back
    teardown do
      @savon&.unmock!
      Rails.logger.debug { 'Mocking ended' }

      # Not all unit test has had their unauthenticated_declarations= modified, so we only need to do this for the ones
      # that had theirs modified. This reverts the ClaimPayment back to it's original.
      if ClaimPayment.new.respond_to?(:unauthenticated_declarations_setter_original_method)
        ClaimPayment.class_eval do
          alias_method :unauthenticated_declarations=, :unauthenticated_declarations_setter_original_method
          remove_method :unauthenticated_declarations_setter_original_method
        end
      end
    end

    # Here are some information regarding this test:
    # - Account type: "AGENT"
    # - Return type: "LBTT"
    # - with ADS: true
    test 'print lbtt authenticated claim with ADS pdf data' do
      savon_expectations_reference_setup('validate_return_reference_response')

      actual, expected = print_data_to_compare('claim_authenticated_with_ads')
      assert_equal(actual, expected, 'Claim LBTT json strings do not match')
    end

    # Here are some information regarding this test:
    # - Account type: "AGENT"
    # - Return type: "LBTT"
    # - with ADS: false
    test 'print lbtt authenticated claim without ADS pdf data' do
      savon_expectations_reference_setup('validate_return_reference_non_ads_response')

      actual, expected = print_data_to_compare('claim_authenticated_non_ads')
      assert_equal(actual, expected, 'Claim LBTT json strings do not match')
    end

    # Here are some information regarding this test:
    # - Account type: "PUBLIC"
    # - Return type: "LBTT"
    test 'print lbtt unauthenticated claim pdf data' do
      modify_unauthenticated_claim_class_method
      savon_expectations_reference_setup('validate_return_reference_response')

      actual, expected = print_data_to_compare('claim_unauthenticated')
      assert_equal(actual, expected, 'unauthorised claim json strings do not match')
    end

    # Here are some information regarding this test:
    # - Account type: "TAXPAYER"
    # - Return type: "SLFT"
    test 'print slft claim pdf data' do
      savon_expectations_reference_setup

      actual, expected = print_data_to_compare('claim_slft')
      assert_equal(actual, expected, 'Claim SLfT json strings do not match')
    end

    # Overrides the method of the ClaimPayment for an unauthenticated claim test case
    def modify_unauthenticated_claim_class_method
      # Overriding the unauthenticated_declarations method as it calls the back office
      # We can't mock it as the object load ends up loading the site reference as a string while the webservice
      # returns a number and then they still don't match
      ClaimPayment.class_eval do
        alias_method :unauthenticated_declarations_setter_original_method, :unauthenticated_declarations=
        attr_writer :unauthenticated_declarations
      end
    end

    # Sets up the savon expectations for setting up the return reference on lbtt claim
    def savon_expectations_reference_setup(validate_return_reference_file_name = nil)
      unless validate_return_reference_file_name.nil?
        fixture = File.read("test/fixtures/mocks/claim/#{validate_return_reference_file_name}.xml")
        @savon.expects(:validate_return_reference_wsdl).with(message: :any).returns(fixture)
      end

      Rails.logger.debug { 'Mocking started' }
    end

    # Savon expectations for finding the user account type
    def savon_expectations_user_setup(current_user, srv_code)
      # As our account_type is 'PUBLIC' we won't have to hit the backoffice calls, so we can escape from here.
      return if current_user.nil?

      path_and_prefix = "test/fixtures/mocks/claim/#{srv_code}"

      fixture = File.read("#{path_and_prefix}_account_details_response.xml")
      message = { PartyRef: current_user.party_refno, 'ins1:Requestor': current_user.username }
      @savon.expects(:get_party_details_wsdl).with(message: message).returns(fixture)

      fixture = File.read("#{path_and_prefix}_list_all_users_response.xml")
      @savon.expects(:maintain_user_wsdl).with(message: :any).returns(fixture)
    end

    # Savon expectations for the reference values
    def savon_expectations_reference_values_setup
      fixture = File.read('test/fixtures/mocks/reference_data/reference_values_response.xml')
      @savon.expects(:get_reference_values_wsdl).returns(fixture)
    end

    # Savon expectations for the system parameters values
    def savon_expectations_system_parameters_setup
      fixture = File.read('test/fixtures/mocks/reference_data/system_parameters_response.xml')
      @savon.expects(:get_system_parameters_wsdl).returns(fixture)
    end

    # Object specific set up for this test
    def object_specific_setup(object)
      # Some of the savon expectations are needed to be placed here as this is the area where the object can be
      # accessed, and there are information needed from the object to get the correct responses.
      savon_expectations_reference_values_setup
      savon_expectations_system_parameters_setup
      savon_expectations_user_setup(object.current_user, object.srv_code.downcase)
    end
  end
end
