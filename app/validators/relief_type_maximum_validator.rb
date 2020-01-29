# frozen_string_literal: true

# Class for validating Relief Claim amount should not exceed upper limit for returntype
class ReliefTypeMaximumValidator < ActiveModel::EachValidator
  # Validation for relief amount
  #
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "relief_type_maximum: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example validates :non_ads_relief_claims, relief_type_maximum: true
  def validate_each(record, attribute, value)
    return if value.blank?

    relief_amount = value
    relief_type = record.relief_type
    upper_limit = get_relief_amount_upper_limit(relief_type)
    return if upper_limit.nil?

    record.errors.add(attribute, :amount_exceed, upper_limit: upper_limit) if relief_amount.to_f > upper_limit.to_f
  end

  # find relief upper limit need for for maximum validation
  # @return [int] relief upper limit , it return null if it is not specified.
  def get_relief_amount_upper_limit(relief_type)
    relief_types = ReferenceData::TaxReliefType.lookup('RELIEF_TYPES', 'LBTT', 'RSTU')[relief_type]

    return nil if relief_types&.upper_limit.nil?

    relief_types.upper_limit
  end
end
