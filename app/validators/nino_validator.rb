# frozen_string_literal: true

# Class for validating national insurance number
class NinoValidator < ActiveModel::EachValidator
  # Regex for National Insurance Number validation
  NINO_REGEX = /\A(?!BG|GB|NK|KN|TN|NT|ZZ)[A-CEGHJ-PR-TW-Z][A-CEGHJ-NPR-TW-Z](?:\s*\d{2}){3}\s*[A-D]\z/i.freeze

  # Validation for NINO - checks if the format is valid
  #
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "nino: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example refer Party model, to check national insurance number validation
  #   validates :nino, nino: true, on: :nino
  def validate_each(record, attribute, value)
    return if value.blank?

    record.errors.add(attribute, :is_invalid) && return unless value&.match?(NINO_REGEX)
  end
end
