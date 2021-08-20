# frozen_string_literal: true

# Class for validating bank account number
class AccountNumberValidator < ActiveModel::EachValidator
  # Regex for account number 99999999
  ACCOUNT_NUMBER = /\A\d{8}\z/i.freeze

  # Validation for Sort code
  #
  # Verifies the given bank sort code is in 99999999 format
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  #
  # To use this validation pattern, add "account_number: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example see LbttReturn model
  #   validates :account_number, presence: true, account_number: true, on: :account_holder_name
  def validate_each(record, attribute, value)
    return if value.blank? || value&.match?(ACCOUNT_NUMBER)

    record.errors.add(attribute, :account_number_is_invalid)
  end
end
