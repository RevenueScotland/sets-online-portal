# frozen_string_literal: true

require 'test_helper'
require 'print_data_test_helper'
require 'models/reference_data/memory_cache_helper'
require 'savon/mock/spec_helper'

# Run tests that are included only in this file by:
#   $ ruby -I test test/models/applications/slft/print_data_test.rb
module Applications
  # Part of the slft module
  module Slft
    # Unit test for the public slft application print data
    # This requires at least a model.json and printdata.json for each unit test
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
        Rails.logger.debug { 'Mocking started' }

        # Each unit test cases has their own setups after this, so see each test cases for their specific setups.
      end

      # Put cache configuration back
      teardown do
        @savon&.unmock!
        Rails.logger.debug { 'Mocking ended' }
        restore_original_cache
      end

      # Here are some information regarding this test:
      # - Applicant type: "Landfill operator"
      # - Application type: "Application for an alternative weighing method"
      # - Existing agreement: "No"
      # - Number of sites added: 2 sites
      # - Supporting documents checked: - Evidence of exception circumstances that make it impossible or impractical
      #                                   to use the available weighbridge on your site or one within close proximity
      #                                 - Evidence that your weighbridge or another nearby weighbridge has broken down,
      #                                   and you would incur unreasonable costs by using any other weighbridge
      test 'Landfill operator weighbridge application pdf data' do
        actual, expected = print_data_to_compare('application_lo_wb')

        assert_equal(actual, expected, 'Landfill operator weighbridge application json strings do not match')
      end

      # Here are some information regarding this test:
      # - Applicant type: "Landfill operator"
      # - Application type: "Application for a non-disposal area"
      # - Existing agreement: "Yes" previous_case_reference is available
      # - Number of sites added: 2 sites
      # - Supporting documents checked: - Identify non-disposal area(s) on a scale plan of the landfill site
      #                                 - Permit management plan
      #                                 - Evidence that boundaries for the area(s) have been set
      test 'Landfill operator non disposal application pdf data' do
        actual, expected = print_data_to_compare('application_lo_nd')

        assert_equal(actual, expected, 'Landfill operator non disposal application json strings do not match')
      end

      # Here are some information regarding this test:
      # - Applicant type: "Landfill operator"
      # - Application type: "Restoration notification"
      # - Existing agreement: "No"
      # - Number of sites added: 2 sites
      # - Number of wastes added per site: 2 wastes per site
      # - Supporting documents checked: - Details of how you have calculated the total of site restoration material
      #                                 - Submitted scaled plan of the area(s) under restoration
      #                                 - Evidence that boundaries for the area(s) have been set
      test 'Landfill operator restoration agreement application pdf data' do
        actual, expected = print_data_to_compare('application_lo_ra')

        assert_equal(actual, expected, 'Landfill operator restoration agreement application json strings do not match')
      end

      # Here are some information regarding this test:
      # - Applicant type: "Landfill operator"
      # - Application type: "Application to receive water discounted waste"
      # - Existing agreement: "No"
      # - Number of sites added: 1 site
      # - Number of wastes added per site: 1 wastes per site
      test 'Landfill operator water discount application pdf data' do
        actual, expected = print_data_to_compare('application_lo_wd')

        assert_equal(actual, expected, 'Landfill operator water discount application json strings do not match')
      end

      # Here are some information regarding this test:
      # - Applicant type: "Waste producer"
      # - Application type: "Application to receive water discounted waste"
      # - Existing agreement: "Yes"
      # - Renewal_or_review: "Review"
      # - Previous_case_reference: "1234"
      # - Number of sites added: 1 site
      # - Number of wastes added per site: 1 wastes per site
      # - Supporting documents checked: - Evidence of the water content (naturally and added) of the waste (mandatory)
      #                                 - Results of the quarterly analysis referred to in your approval
      #                                   letter (Review/Renew only)
      test 'Waste producer water discount application pdf data' do
        actual, expected = print_data_to_compare('application_wp_wd')

        assert_equal(actual, expected, 'Waste producer water discount application json strings do not match')
      end
    end
  end
end
