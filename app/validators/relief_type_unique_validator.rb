# frozen_string_literal: true

# Class for validating Relief Claim type is unique on the return
# Don't seem to be able to put this in the lbtt return module without it locking so it can only be used once
class ReliefTypeUniqueValidator < ActiveModel::EachValidator
  # Validation for relief type uniqueness
  #
  # @param _record [Object] an object to be checked for validation
  # @param _attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # To use this validation pattern, add "relief_claim: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example validates :relief_claims, relief_type_unique: true
  def validate_each(_record, _attribute, value)
    return if value.blank?

    used_hash = {}

    value.each_with_index do |obj, i|
      relief_type = obj.relief_type&.to_sym
      next if relief_type.nil?

      obj.errors.add(:relief_type_expanded, :is_duplicate) if used_hash.key?(relief_type)
      used_hash[relief_type] = i
    end
  end
end
