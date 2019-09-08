# frozen_string_literal: true

require 'test_helper'

# Unit ts for AccountBasedCaching methods which can't be tested by autotest.
# NB doesn't (or at least shouldn't) actually access the rails cache.
class AccountBasedCachingTest < ActiveSupport::TestCase
  # Target class for tests
  class TestClass
    include AccountBasedCaching
  end

  # Test the cache_key method return a reproducible/expected result so lookups will work
  test 'cache_key produces expected result' do
    assert_equal('AccountBasedCachingTest::TestClass_1234', TestClass.cache_key('1234'),
                 'Cache key should be class + party ref no')
  end

  # cache_expiry_time must produce a time, either Rails.configuration.x.accounts.cache_expiry or 10.minutes.
  test 'expiry time produces valid results' do
    old_value = Rails.configuration.x.accounts.cache_expiry
    begin
      Rails.configuration.x.accounts.cache_expiry = 100.minutes
      assert_equal(100.minutes, TestClass.cache_expiry_time, 'cache expiry time should be 100.minutes')
      Rails.configuration.x.accounts.cache_expiry = nil
      assert_equal(10.minutes, TestClass.cache_expiry_time, 'cache expiry time should be the failsafe value')
    ensure
      # Put the configuration back to what it was before for other tests
      Rails.configuration.x.accounts.cache_expiry = old_value
    end
  end
end
