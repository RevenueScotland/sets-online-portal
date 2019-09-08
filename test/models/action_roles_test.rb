# frozen_string_literal: true

require 'test_helper'

# Unit test for ActionRoles methods which can't be tested by autotest.
# NB doesn't (or at least shouldn't) actually access the rails cache.
class ActionRolesTest < ActiveSupport::TestCase
  # Target class for tests
  class TestClass < ActionRoles
  end

  # Test the cache_key method return a reproducible/expected result so lookups will work
  test 'cache_key produces expected result' do
    assert_equal('ActionRolesTest::TestClass#ACTION_CODE', TestClass.send(:cache_key, 'ACTION_CODE'),
                 'Cache key should be class + action_code')
  end

  # cache_expiry_time must produce a time, either Rails.configuration.x.authorisation.cache_expiry or 10.minutes.
  test 'expiry time produces valid results' do
    old_value = Rails.configuration.x.authorisation.cache_expiry
    begin
      Rails.configuration.x.authorisation.cache_expiry = 100.minutes
      assert_equal(100.minutes, TestClass.send(:cache_expiry_time), 'cache expiry time should be 100.minutes')
      Rails.configuration.x.authorisation.cache_expiry = nil
      assert_equal(10.minutes, TestClass.send(:cache_expiry_time), 'cache expiry time should be the failsafe value')
    ensure
      # Put the configuration back to what it was before for other tests
      Rails.configuration.x.authorisation.cache_expiry = old_value
    end
  end
end
