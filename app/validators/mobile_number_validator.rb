# frozen_string_literal: true

# Class for validating mobile number
class MobileNumberValidator < ActiveModel::EachValidator
  # Regex for UK mobile number validation
  MOBILE_REGEX = /\A(\+44\s?7\d{3}|\(?07\d{3}\)?)\s?\d{3}\s?\d{3}\z/i.freeze

  # Validation for mobile number
  #
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "mobile_number: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example
  #   validates :mobile, mobile_number: true, on: :mobile
  def validate_each(record, attribute, value)
    return if value.blank? || value&.match?(MOBILE_REGEX)

    record.errors.add(attribute, :is_invalid)
  end
end
