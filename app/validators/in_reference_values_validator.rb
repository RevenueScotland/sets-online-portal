# frozen_string_literal: true

# Class for validating that a value is in the list of reference values
class InReferenceValuesValidator < ActiveModel::EachValidator
  # Validation for reference values
  #
  # Verifies the given attribute value is in the list of reference values, also handles Y/N flags
  # normally this is covered by the UI only allowing them to pick this must be used where we
  # may get data from other sources
  # @note This assumes that the object is set up to use the ReferenceDataLookup concern
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  #
  # To use this validation pattern, add "InReferenceValues: true" in the model specific to that attribute
  # similar to how we use presence: true
  def validate_each(record, attribute, value)
    return if value.blank? || record.lookup_ref_data(attribute).key?(value)

    record.errors.add(attribute, :is_not_in_list, value: value)
  end
end
