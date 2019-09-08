# frozen_string_literal: true

require 'test_helper'

# Test ServiceClient
class ServiceClientTest < ActiveSupport::TestCase
  # testing for iterate element
  test 'can flatten array of hashes' do
    result_array = []
    ServiceClient.iterate_element(single: [{ field1: 'one', field2: 'two' },
                                           { field1: 'three', field2: 'four' }]) do |element|
      result_array << element
    end
    assert_equal result_array, [{ field1: 'one', field2: 'two' },
                                { field1: 'three', field2: 'four' }], 'Could not iterate hash of arrays'
  end

  test 'can flatten single hash' do
    result_array = []
    ServiceClient.iterate_element(single: { field1: 'one', field2: 'two' }) do |element|
      result_array << element
    end
    assert_equal result_array, [{ field1: 'one', field2: 'two' }], 'Could not iterate single hash'
  end

  test 'can handle nil input' do
    result_array = []
    ServiceClient.iterate_element(nil) do |element|
      result_array << element
    end
    assert_equal result_array, [], 'Could not handle nil entry'
  end

  # testing for extract errors

  # Dummy test class to test ServiceClient as part of FLApplicationRecord
  class DummyTest < FLApplicationRecord
    # make extract errors public so it can be tested
    public :extract_errors # rubocop:disable Style/AccessModifierDeclarations

    # need to touch errors for it to exist
    def initialize
      @errors = ActiveModel::Errors.new(self)
    end
  end

  test 'can extract one error' do
    test_instance = DummyTest.new

    test_instance.extract_errors(
      success: false, messages: { message: { text: 'This is message one', severity: 'VAL', code: 'SEC-1' } },
      "@xmlns": 'http://northgate-is.com/FL/MaintainUser', "@xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance',
      "@xmlns:core": 'http://northgate-is.com/FL/Core'
    )

    assert_equal test_instance.errors.full_messages, ['This is message one'], 'Could not extract one message'
  end

  test 'can extract no errors' do
    test_instance = DummyTest.new

    test_instance.extract_errors(
      success: false, messages: nil,
      "@xmlns": 'http://northgate-is.com/FL/MaintainUser', "@xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance',
      "@xmlns:core": 'http://northgate-is.com/FL/Core'
    )

    assert_equal test_instance.errors.full_messages, [], 'Could not extract no messages'
  end

  test 'can extract no element' do
    test_instance = DummyTest.new

    test_instance.extract_errors(
      success: false,
      "@xmlns": 'http://northgate-is.com/FL/MaintainUser', "@xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance',
      "@xmlns:core": 'http://northgate-is.com/FL/Core'
    )

    assert_equal test_instance.errors.full_messages, [], 'Could not extract no message element'
  end

  test 'can extract two errors' do
    test_instance = DummyTest.new

    test_instance.extract_errors(
      success: false, messages: { message:
      [{ text: 'This is message one', severity: 'VAL', code: 'SEC-1' },
       { text: 'This is message two', severity: 'VAL', code: 'SEC-2' }] },
      "@xmlns": 'http://northgate-is.com/FL/MaintainUser', "@xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance',
      "@xmlns:core": 'http://northgate-is.com/FL/Core'
    )

    assert_equal test_instance.errors.full_messages,
                 ['This is message one', 'This is message two'], 'Could not extract two messages'
  end

  # ORA errors are serious, must raise an exception
  test 'ora errors result in exception raised' do
    test_instance = DummyTest.new
    mes = { success: 'false',
            messages: { message: { text: 'Oracle drained your bank account', severity: 'VAL', code: 'ORA-1234' } },
            "@xmlns": 'http://northgate-is.com/FL/MaintainUser', "@xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance',
            "@xmlns:core": 'http://northgate-is.com/FL/Core' }
    assert_raises(Error::AppError) do
      test_instance.extract_errors(mes)
    end
  end

  # When the back office returns success = false but doesn't provide any error message details
  # we want to treat it as a fatal error, check the code raises a the appropriate exception.
  # Can't implement as an autotest because we want a successful autotest run to not have ERROR reported in the logs.
  test 'failure without messages results in exception raised' do
    test_instance = DummyTest.new
    mes = { success: 'false',
            "@xmlns": 'http://northgate-is.com/FL/MaintainUser', "@xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance',
            "@xmlns:core": 'http://northgate-is.com/FL/Core' }
    assert_raises(Error::AppError) do
      test_instance.send(:assert_not_failure_without_messages, false, mes)
    end
  end
end
