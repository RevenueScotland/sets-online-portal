# frozen_string_literal: true

# Class for validating enrolment reference of SAT services
class EnrolmentReferenceValidator < ActiveModel::EachValidator
  # Regex for enrolment reference number
  ENROLMENT_REF_REGEX = /\ASAT\d{7,13}\w{4}\z/i

  # Validation for enrolment reference
  #
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "enrolment_reference: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example see Account model
  #   validates :enrolment_ref, presence: true, enrolment_reference: true, on: :enrolment_ref
  def validate_each(record, attribute, value)
    return if value.blank? || value&.match?(ENROLMENT_REF_REGEX)

    record.errors.add(attribute, :format_is_invalid)
  end
end
