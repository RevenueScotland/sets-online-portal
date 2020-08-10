# frozen_string_literal: true

require 'test_helper'
require 'models/reference_data/memory_cache_helper'
require 'savon/mock/spec_helper'

# Unit tests for the wizard code that can't be tested via autotests.
class WizardTest < ActionController::TestCase
  include ReferenceData::MemoryCacheHelper

  # This tests caching behaviour so use memory cache
  # Also make sure that back office call returns nothing
  setup do
    set_memory_cache

    @savon ||= Savon::SpecHelper::Interface.new
    @savon.mock!
    Rails.logger.debug { 'Mocking started' }
  end

  teardown do
    restore_original_cache
    @savon&.unmock!
    Rails.logger.debug { 'Mocking ended' }
  end

  # Test version of the controller, includes Wizard.
  class WizardTestController < ApplicationController
    include Wizard
    skip_before_action :require_user # cleared globally for testing

    # Simulate the request session which isn't available in tests
    attr_accessor :session

    # Override method to not be private so can be called for test
    def wizard_cache_key(cache_index = self.class.name)
      super
    end

    # Override method to not be private so can be called for test
    def wizard_cache_expiry_time
      super
    end
  end

  # Another controller that includes Wizard.
  class AnotherWizardController
    include Wizard
    attr_accessor :session
    # Override method to not be private so can be called for test
    def wizard_cache_key(cache_index = self.class.name)
      super
    end
  end

  # Wizard model based on Abstract to override the lookup cache method
  class TestWizardModel < Returns::AbstractReturn
    attr_accessor :value
  end

  test 'cache_key provides unique id based on class name and wizard caching and merging works' do
    controller = WizardTestController.new
    controller.session = {}

    # save something
    slft = TestWizardModel.new
    controller.wizard_save(slft)

    # merge in something else
    controller.wizard_merge_and_save(controller.wizard_load, nil, 'tare_reference' => 'mars') { true }

    # save a decoy under another controller in the same session
    another = AnotherWizardController.new
    another.session = controller.session
    another.wizard_save(TestWizardModel.new)

    # check the cached has saved correctly
    cached_data = controller.wizard_load
    assert_equal('mars', cached_data.tare_reference, 'Saved and loaded data should exist')

    # change the value
    controller.wizard_merge_and_save(controller.wizard_load, nil, 'tare_reference' => 'under the sea') { true }
    cached_data = controller.wizard_load
    assert_equal('under the sea', cached_data.tare_reference, 'Overriding values should be allowed')

    # check can load data from other controllers in the same session
    cached_data = another.wizard_load(WizardTestController.name)
    assert_equal('under the sea', cached_data.tare_reference, 'Overriding values should be allowed')
  end

  test 'wizard_save overwrites cached value' do
    controller = WizardTestController.new
    controller.session = {}

    # save something
    model = TestWizardModel.new(value: 'world')
    controller.wizard_save(model)
    # save something completely different
    model.value = 'potter'
    controller.wizard_save(model)

    # check cache (should only have the last entry)
    model = controller.wizard_load
    assert_equal('potter', model.value)
  end

  # We shouldn't be going to the back office in this (or any) unit test so wizard_cache_expiry_time should
  # fail safe and return 10.hrs.  If the fail safe time is changed, this test should be updated.
  test 'wizard_cache_expiry_time returns the fail safe time of 10 hrs' do
    controller = WizardTestController.new
    assert_equal(10.hours, controller.wizard_cache_expiry_time, 'wizard_cache_expiry_time should return fail safe time')
  end

  test 'keys reproduction scenarios' do
    controller = WizardTestController.new
    controller.session = {}

    first_key = controller.wizard_cache_key
    assert(first_key.include?('WIZARD_WizardTest::WizardTestController_'),
           "cache key #{first_key} should be based on the wizard controller name #{WizardTestController.name}")

    second_key = controller.wizard_cache_key
    assert_equal(first_key, second_key, 'Cache key should be reproducible for the wizard and session')

    another = AnotherWizardController.new
    another.session = controller.session
    other_key = another.wizard_cache_key
    assert(other_key.include?('WIZARD_WizardTest::AnotherWizardController_'),
           "cache key #{other_key} should be based on the wizard controller name #{AnotherWizardController.name}")
    assert_not_equal(first_key, other_key, 'Different controllers should have different keys')

    # end one wizard session and restart it
    controller.wizard_end
    restarted_key = controller.wizard_cache_key
    assert_not_equal(restarted_key, second_key, 'New wizard/session should have a different cache key')
    assert_not_equal(restarted_key, other_key, 'New wizard/session should not have the wrong key')
  end
end
