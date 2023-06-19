# frozen_string_literal: true

require 'test_helper'

module ReferenceData
  # Tests caching ReferenceData::SystemParameter
  class SystemParameterTest < ActiveSupport::TestCase
    setup do
      Rails.cache.clear
    end

    # actual_cache[ReferenceData::SystemParameter.cache_key][COMP_KEY_1][HASH_KEY]=TEST_HASH_VALUE
    COMP_KEY_1 = 'dom>$<ser>$<wor'
    COMP_KEY_2 = 'dom>$<ser>$<waa'
    COMP_KEY_3 = 'nds>$<rev>$<scot'

    TEST_VALUE_1 = ReferenceData::SystemParameter.new(code: 'T', value: 'test value data1')
    TEST_VALUE_2 = ReferenceData::SystemParameter.new(code: 'U', value: 'test value data2')
    TEST_VALUE_3 = ReferenceData::SystemParameter.new(code: 'V', value: 'test value data3')

    # Extend SystemParameter class so we can overwrite methods to make it safe for testing
    # (ie never contacts the back office or redis cache) and to populate it with test data.
    class TestSystemParameter < ReferenceData::SystemParameter
      # Overwrite the call_ok? method so we never try to go to the back office in the test
      # but instead return dummy data we can use to test the cache is working.
      def self.call_ok?(_config_key, _request)
        Rails.logger.debug('Returning test data to simulate successful call to back office after cache miss')
        data = {}
        data['single'] = [make_call_ok_data(COMP_KEY_1, TEST_VALUE_1),
                          data[1] = make_call_ok_data(COMP_KEY_2, TEST_VALUE_2)]
        body = {}
        body[:system_parameters] = data
        yield(body)
        true
      end

      # Overwrite application_values to add the last test value
      # (ie if the tests can find this data then we have checked application_values are included automatically).
      def self.application_values(_existing_values)
        output = {}
        output[COMP_KEY_3] = { TEST_VALUE_3.code => TEST_VALUE_3 }
        output
      end

      # Overwrite the cache_key method so we user a random cache location for tests rather
      # than risk changing develop data if using the same cache.
      def self.cache_key
        # only define the test key once
        @test_key ||= "system_parameter_test_#{Time.now.to_i}_#{rand(1..100)}"
        Rails.logger.debug { "Using cache key #{@test_key}" }
        @test_key
      end

      # Turn the test data into a call_ok? response data structure element
      # @param [String] comp_key - the composite key (domain.service.workplace codes)
      # @param [SystemParameter] test_value - the data for that key
      private_class_method def self.make_call_ok_data(comp_key, test_value)
        output = {}
        split_key = comp_key.split('>$<')
        output[:domain_code] = split_key[0]
        output[:service_code] = split_key[1]
        output[:workplace_code] = split_key[2]
        output[:code] = test_value.code
        output[:string_value] = test_value.value
        output
      end

      # Override private method to provide access
      public_class_method :make_object
    end

    test 'cache code works' do
      # paranoia check, is the cache empty
      assert_nil(Rails.cache.read(TestSystemParameter.cache_key), 'Cache should start empty')

      # just testing single lookup, will always use this code for this test
      hash_key = TEST_VALUE_1.code

      # will populate the cache and return it
      hash_result = TestSystemParameter.cached_values[COMP_KEY_1][hash_key]
      assert_equal(TEST_VALUE_1, hash_result, 'Cache should contain the application data')

      # change the returned data but cache result stays the same since it's not Java
      different_result = TestSystemParameter.new(code: 'CHANGED', value: 'unimportant')
      assert_equal(
        TEST_VALUE_1,
        TestSystemParameter.cached_values[COMP_KEY_1][hash_key],
        'Cache should not change since it is not Java'
      )

      # change cached data to check our cache is actually working correctly
      different_hash = { COMP_KEY_1 => { hash_key => different_result } }
      Rails.cache.write([TestSystemParameter.cache_key], different_hash)
      assert_equal(
        different_result,
        TestSystemParameter.cached_values[COMP_KEY_1][hash_key],
        'Cache should now contain different data'
      )

      # force refresh cache from dummy back office
      updated_ok = TestSystemParameter.refresh_cache!
      assert(updated_ok)
      assert_equal(
        TEST_VALUE_1,
        TestSystemParameter.cached_values[COMP_KEY_1][hash_key],
        'Cache should contain the original data again'
      )
    end

    # check return types map and list are correct
    test 'return types are correct' do
      keys = COMP_KEY_1.split('>$<')
      lookup_result = TestSystemParameter.lookup(keys[0], keys[1], keys[2])
      assert(lookup_result.is_a?(Hash))
      list_result = TestSystemParameter.list(keys[0], keys[1], keys[2])
      assert(list_result.is_a?(Array))
      assert(list_result[0].is_a?(ReferenceData::SystemParameter), list_result[0].class&.name)
    end

    test 'cache_key is correct on class' do
      assert_equal('ReferenceData::SystemParameter', ReferenceData::SystemParameter.cache_key)
    end

    # Check we can return multiple keys at once
    test 'lookup multiple system parameters' do
      keys = [COMP_KEY_1, COMP_KEY_2, COMP_KEY_3]
      result = TestSystemParameter.lookup_multiple(keys)
      assert(result.is_a?(Hash))

      assert_equal(TEST_VALUE_1, result[COMP_KEY_1][TEST_VALUE_1.code], 'Result 1 differs')
      assert_equal(TEST_VALUE_2, result[COMP_KEY_2][TEST_VALUE_2.code], 'Result 2 differs')
      assert_equal(TEST_VALUE_3, result[COMP_KEY_3][TEST_VALUE_3.code], 'Result 3 differs')
    end

    # Check we can return multiple keys as lists
    test 'list multiple system parameters' do
      keys = [COMP_KEY_1, COMP_KEY_2, COMP_KEY_3]
      result = TestSystemParameter.list_multiple(keys)
      assert(result.is_a?(Hash))

      assert_equal(TEST_VALUE_1, result[COMP_KEY_1][0], 'Result 1 differs')
      assert_equal(TEST_VALUE_2, result[COMP_KEY_2][0], 'Result 2 differs')
      assert_equal(TEST_VALUE_3, result[COMP_KEY_3][0], 'Result 3 differs')
    end

    test 'check make_object picks up on different value fields' do
      test_make_object(:string_value, 'test 1')
      test_make_object(:number_value, '2')
      test_make_object(:date_value, '03-03-2003') # HACK: guessing at date format
    end

    private

    # Helper for testing make object.  Asserts the value in is the value on the result of calling make_object.
    # @param data_field - which hash index to populate with the value
    # @param [String] value - the value to both set in the data and to check for in the assert
    def test_make_object(data_field, value)
      data = { :code => 'c', data_field => value }
      sys_param = TestSystemParameter.make_object(data)
      assert_equal(value, sys_param.value)
    end
  end
end
