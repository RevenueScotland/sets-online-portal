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
    assert_equal [{ field1: 'one', field2: 'two' }, { field1: 'three', field2: 'four' }],
                 result_array, 'Could not iterate hash of arrays'
  end

  test 'can flatten single hash' do
    result_array = []
    ServiceClient.iterate_element(single: { field1: 'one', field2: 'two' }) do |element|
      result_array << element
    end
    assert_equal [{ field1: 'one', field2: 'two' }], result_array, 'Could not iterate single hash'
  end

  test 'can handle nil input' do
    result_array = []
    ServiceClient.iterate_element(nil) do |element|
      result_array << element
    end
    assert_equal [], result_array, 'Could not handle nil entry'
  end

  # testing for extract errors

  # Dummy test class to test ServiceClient as part of FLApplicationRecord
  class DummyTest < FLApplicationRecord
    # make extract errors public so it can be tested
    public :extract_errors

    # need to touch errors for it to exist
    def initialize
      super
      @errors = ActiveModel::Errors.new(self)
    end
  end

  test 'can extract one error' do
    test_instance = DummyTest.new

    test_instance.extract_errors(
      success: false, messages: { message: { text: 'This is message one', severity: 'VAL', code: 'SEC-1' } },
      '@xmlns': 'http://northgate-is.com/FL/MaintainUser', '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      '@xmlns:core': 'http://northgate-is.com/FL/Core'
    )

    assert_equal ['This is message one'], test_instance.errors.full_messages, 'Could not extract one message'
  end

  test 'can extract no errors' do
    test_instance = DummyTest.new

    test_instance.extract_errors(
      success: false, messages: nil,
      '@xmlns': 'http://northgate-is.com/FL/MaintainUser', '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      '@xmlns:core': 'http://northgate-is.com/FL/Core'
    )

    assert_equal [], test_instance.errors.full_messages, 'Could not extract no messages'
  end

  test 'can extract no element' do
    test_instance = DummyTest.new

    test_instance.extract_errors(
      success: false,
      '@xmlns': 'http://northgate-is.com/FL/MaintainUser', '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      '@xmlns:core': 'http://northgate-is.com/FL/Core'
    )

    assert_equal [], test_instance.errors.full_messages, 'Could not extract no message element'
  end

  test 'can extract two errors' do
    test_instance = DummyTest.new

    test_instance.extract_errors(
      success: false, messages: { message:
      [{ text: 'This is message one', severity: 'VAL', code: 'SEC-1' },
       { text: 'This is message two', severity: 'VAL', code: 'SEC-2' }] },
      '@xmlns': 'http://northgate-is.com/FL/MaintainUser', '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      '@xmlns:core': 'http://northgate-is.com/FL/Core'
    )

    assert_equal ['This is message one', 'This is message two'], test_instance.errors.full_messages,
                 'Could not extract two messages'
  end

  # ORA errors are serious, must raise an exception if happens at class level
  test 'ora errors at class level result in exception raised' do
    mes = { success: 'false',
            messages: { message: { text: 'Oracle drained your bank account', severity: 'VAL', code: 'ORA-1234' } },
            '@xmlns': 'http://northgate-is.com/FL/MaintainUser', '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
            '@xmlns:core': 'http://northgate-is.com/FL/Core' }
    assert_raises(Error::AppError) do
      ServiceClient.assert_not_failure(false, mes)
    end
  end

  # ORA errors are not something we want to show users, must add a user-friendly message if happens at instance
  test 'ora errors on model instance result in user friendly message' do
    test_instance = DummyTest.new
    mes = { success: 'false',
            messages: { message: { text: 'Oracle drained your bank account', severity: 'VAL', code: 'ORA-1234' } },
            '@xmlns': 'http://northgate-is.com/FL/MaintainUser', '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
            '@xmlns:core': 'http://northgate-is.com/FL/Core' }

    test_instance.extract_errors(mes)

    assert test_instance.errors&.present?, 'expected errors message missing'
    assert_match(
      /Something unexpected happened, you can try again in a few minutes or to report this error quote : \d\d\d\d\d/,
      test_instance.errors.map(&:message).first, 'Unexpected message'
    )
  end

  # When the back office returns success = false but doesn't provide any error message details
  # we want to treat it as an error, check the code raises a the appropriate error message.
  # Can't implement as an autotest because we want a successful autotest run to not have ERROR reported in the logs.
  test 'failure without messages results in user friendly message' do
    test_instance = DummyTest.new
    mes = { success: 'false',
            '@xmlns': 'http://northgate-is.com/FL/MaintainUser', '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
            '@xmlns:core': 'http://northgate-is.com/FL/Core' }

    test_instance.send(:ensure_message_on_fail, false, mes)
    test_instance.send(:extract_errors, mes)

    assert test_instance.errors&.present?, 'expected errors message missing'
    assert_match(
      /Something unexpected happened, you can try again in a few minutes or to report this error quote : \d\d\d\d\d/,
      test_instance.errors.map(&:message).first, 'Unexpected message'
    )
  end
end
