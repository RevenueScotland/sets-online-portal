# frozen_string_literal: true

# Class for validating email address
class EmailAddressValidator < ActiveModel::EachValidator
  # Regex for email address validation
  EMAIL_ADDRESS_REGEX = /\A[a-zA-Z0-9_!#$%&’*+=?`{|}~^.-]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}\z/i.freeze
  # The backoffice's email length validation can be different for each attribute, and the lowest
  # max-length of an email address is 100, so that is what we'll be using for all email address attributes.
  EMAIL_ADDRESS_LENGTH = 100

  # Validation for email addresses
  #
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "email_address: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example refer Party model, to check email validation
  #   validates :email_address, presence: true, email_address: true
  def validate_each(record, attribute, value)
    return if value.blank?

    record.errors.add(attribute, :is_invalid) && return unless value&.match?(EMAIL_ADDRESS_REGEX)
    return unless value.length > EMAIL_ADDRESS_LENGTH

    record.errors.add(attribute, :too_long, count: EMAIL_ADDRESS_LENGTH)
  end
end
