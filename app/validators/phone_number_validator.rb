# frozen_string_literal: true

# Class for validating telephone number
class PhoneNumberValidator < ActiveModel::EachValidator
  # Regex for Uk telephone number validation
  # eg. 02079460654, +442079460654, 02079460654 #2789
  long_regex_pt1 = '\A(((\+|00)?44|0)([123578]{1}))(((\d{1}\s?\d{4}|\d{2}\s?\d{3})\s?\d{4})|(\d{3}\s?\d{2,3}\s?\d{3})|'
  long_regex_pt2 = '(\d{4}\s?\d{4,5}))(\s?(#|[xX]|[eE][xX][tT])(\d{4}|\d{3}))?\z'

  # Telephone regex is long, hence split it and combine
  TELEPHONE_REGEX = Regexp.new(long_regex_pt1 + long_regex_pt2)

  # Regex for international telephone number
  # Also allow Spanish telephone number (0034629629629 or +34629629629)
  INT_TELEPHONE_REGEX = /\A(?:00|\+)(?:[0-9] ?){6,14}[0-9]\z/i.freeze

  # Validation for telephone number
  #
  # it should check against Uk phone number and also international number
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "phone_number: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example refer Party model, to check phone number validation
  #   validates :telephone, presence: true, phone_number: true
  def validate_each(record, attribute, value)
    return if value.blank? || value&.match?(TELEPHONE_REGEX) || value&.match?(INT_TELEPHONE_REGEX)

    record.errors.add(attribute, :is_invalid)
  end
end
