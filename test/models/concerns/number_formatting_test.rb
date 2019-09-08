# frozen_string_literal: true

require 'test_helper'
# Unit test for the number formatting functions
class NumberFormattingTest < ActiveSupport::TestCase
  # test to check username validation
  test 'check truncate to 2dp' do
    # test doesn't round up or down, only truncates
    assert_equal '123.54', NumberFormatting.to_money_format('123.54999')
    assert_equal '123.54', NumberFormatting.to_money_format('123.541')
    # test ok with very large numbers (ie doesn't have issues with exponent characters)
    assert_equal '1234567890123456789.22', NumberFormatting.to_money_format('1234567890123456789.22222')
    # test pads with zeros
    assert_equal '123.50', NumberFormatting.to_money_format('123.5')
    assert_equal '123.00', NumberFormatting.to_money_format('123')
  end
end
