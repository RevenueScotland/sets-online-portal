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
    value.presence || 0
  end

  # convert a string in money format to pence for to allow integer arithmetic
  # @param value [String] The number to convert
  # @return [Integer] the value in pence
  def to_pence(value)
    (value.to_f * 100).to_i
  end

  # convert a pence value back to a money format
  # @param value [Integer] The value in pence
  # @return [String] the pence value converted to a string 2 DP value
  def from_pence(value)
    (value / 100.0).to_s
  end

  # convert a pence value back to a money format, but with an advantageous round
  # to whole pounds, i.e negative round up and positive round down
  # @param value [Integer] The value in pence
  # @return [String] the pence value converted to a string 2 DP value
  def from_pence_advantageous_round(value)
    value = (value / 100.0)
    if value.positive?
      value.floor.to_s
    else
      value.ceil.to_s
    end
  end
end
