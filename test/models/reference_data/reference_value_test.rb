# frozen_string_literal: true

require 'test_helper'

# Since ReferenceValue extends SystemParameter, we only need to test the differences between those two classes here.
class ReferenceValueTest < ActiveSupport::TestCase
  test 'cache_key is correct on class' do
    assert_equal('ReferenceData::ReferenceValue', ReferenceData::ReferenceValue.cache_key)
  end
end
