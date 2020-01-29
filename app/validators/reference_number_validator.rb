# frozen_string_literal: true

# Class for validating reference number
class ReferenceNumberValidator < ActiveModel::EachValidator
  # Validation for reference number
  #
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "reference_number: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example see LbttReturn model
  #   validates :orig_return_reference, presence: true, reference_number: true, on: :orig_return_reference
  def validate_each(record, attribute, value)
    return if value.blank? || value&.match?(Rails.configuration.x.app_ref.validation_pattern)

    record.errors.add(attribute, :format_is_invalid)
  end
end
