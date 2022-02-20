# frozen_string_literal: true

# Class for validating number with two decimal places
class TwoDpPatternValidator < ActiveModel::EachValidator
  # Regular Expression for 2DP decimals
  TWO_DP_PATTERN = /\A[-+]?\d+(?:\.\d{0,2})?\z/
  # Regular expression for general numeric
  NUMERIC_PATTERN = /\A[-+]?[0-9]*\.?[0-9]+\Z/

  # Validation for number with two decimal places
  #
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "two_dp_pattern: true" in the model specific to that attribute
  # similar to how we use presence: true
  # By default it won't raise an error if the value is not numeric it only checks the 2dp format
  # if you pass an option of validate_numeric: true then it will validate the value is numeric
  # @example see LbttReturn model with separate standard numericality validation
  #   validates :total_consideration, presence: true, two_dp_pattern: true,
  #   numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000 }, on: :total_consideration
  # @example see LbttReturn model without separate validation
  #   validates :total_consideration, presence: true, two_dp_pattern: {validate_numeric: true},
  #   on: :total_consideration
  def validate_each(record, attribute, value)
    return unless value_string?(value)

    # if the numeric validation is done separately exit if not numeric so we don't get two messages
    return unless value_numeric?(value) && !validate_numeric?(options)

    record.errors.add(attribute, :invalid_2dp) && return unless value&.match?(TWO_DP_PATTERN)
  end

  private

  # checks if the value is a non blank string so we can exit if it isn't
  def value_string?(value)
    return false if value.blank? || !value.is_a?(String)

    true
  end

  # validate numeric, are we validating that this value is numeric
  def validate_numeric?(options)
    options[:validate_numeric] || false
  end

  # checks if the passed value is numeric but doesn't check the decimal places
  def value_numeric?(value)
    value&.match?(NUMERIC_PATTERN)
  end
end
