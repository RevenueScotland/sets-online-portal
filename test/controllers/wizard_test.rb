# frozen_string_literal: true

require 'test_helper'
require 'models/reference_data/memory_cache_helper'

# Unit tests for the wizard code that can't be tested via autotests.
class WizardTest < ActionController::TestCase
  include ReferenceData::MemoryCacheHelper

  # Test sets an in-memory cache regardless of what the default environment setup is
  # ie so we don't try to access Redis in unit tests.
  setup do
    set_memory_cache
    prevent_system_parameter_calling_back_office
  end

  # Put cache configuration back
  teardown do
    restore_original_cache
    restore_system_parameter_calling_back_office
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
  end

  test 'cache_key provides unique id based on class name and wizard caching and merging works' do
    controller = WizardTestController.new
    controller.session = {}

    # save something
    slft = TestWizardModel.new
    controller.wizard_save(slft)

    # merge in something else
    controller.wizard_merge_and_save(controller.wizard_load, 'tare_reference' => 'mars') { true }

    # save a decoy under another controller in the same session
    another = AnotherWizardController.new
    another.session = controller.session
    another.wizard_save(TestWizardModel.new)

    # check the cached has saved correctly
    cached_data = controller.wizard_load
    assert_equal('mars', cached_data.tare_reference, 'Saved and loaded data should exist')

    # change the value
    controller.wizard_merge_and_save(controller.wizard_load, 'tare_reference' => 'under the sea') { true }
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
    controller.wizard_save('hello' => 'world')
    # save something completely different
    controller.wizard_save('harry' => 'potter')

    # check cache (should only have the last entry)
    cached = controller.wizard_load
    assert_equal(1, cached.length, 'Cache should only contain the last saved value since was not merged')
    assert_equal('potter', cached['harry'])
  end

  # We shouldn't be going to the back office in this (or any) unit test so wizard_cache_expiry_time should
  # failsafe and return 10.hrs.  If the failsafe time is changed, this test should be updated.
  test 'wizard_cache_expiry_time returns the failsafe time of 10 hrs' do
    controller = WizardTestController.new
    assert_equal(10.hours, controller.wizard_cache_expiry_time, 'wizard_cache_expiry_time should return failsafe time')
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
