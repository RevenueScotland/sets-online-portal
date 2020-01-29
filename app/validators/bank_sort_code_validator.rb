# frozen_string_literal: true

# Class for validating bank sort code number
class BankSortCodeValidator < ActiveModel::EachValidator
  # Regex for Sort Code validation
  SORT_CODE = /\A(?!(?:0{6}))(?:\d\d-\d\d-\d\d)\z/i.freeze

  # Validation for Sort code
  #
  # Verifies the given bank sort code is in 99-99-99 format
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  #
  # To use this validation pattern, add "bank_sort_code: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example see LbttReturn model
  #   validates :branch_code, presence: true, bank_sort_code: true, on: :account_holder_name
  def validate_each(record, attribute, value)
    return if value.blank? || value&.match?(SORT_CODE)

    record.errors.add(attribute, :is_invalid)
  end
end
