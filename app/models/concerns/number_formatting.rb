# frozen_string_literal: true

# Usually Rails has enough methods for formatting, however sometimes it doesn't so this concern contains
# our custom number formatting methods.
module NumberFormatting
  # Truncate to 2 decimal places without rounding up.
  # Based on: https://stackoverflow.com/questions/15900537/to-d-to-always-return-2-decimals-places-in-ruby
  # but adapted from there as that has issues with long numbers.  Uses Strings as input/output so as not
  # to have issues with arithmetic precision (and since our form inputs are Strings unless we say otherwise).
  #
  # Good for when we want to represent money (2dp) but don't want to round up (since 1/2 pennies aren't used anymore)
  # so anything after the 2nd decimal place is considered an input mistake.
  # @example to_money_format('5.555') # '5.55'
  # @example to_money_format('4.1') # '4.10'
  # @param number [String] input float
  # @return [String] output truncated to 2dp
  def self.to_money_format(number)
    number ||= '0'
    truncated = number.to_d.truncate(2).to_s
    split_parts = truncated.split('.')
    formatted_2dp = format('%#.02f', ".#{split_parts[1]}")
    just_dp = formatted_2dp.split('.')[1]
    "#{split_parts[0]}.#{just_dp}"
  end

  # Helpful method to parse a number and return 0 if it's not set (good for display or back office requests).
  # @param value [Integer] number to check
  # @return the value if it's not blank or else return 0
  def or_zero(value)
    value.blank? ? 0 : value
  end
end
