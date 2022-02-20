# frozen_string_literal: true

# Validator class for address model to validate scotland address
#
# This validator is inherit from ActiveModel::Validator and called using the validates_with method in the model
#
# This class is implementing the validate method which takes a record as an argument and performs the validation on it.
#
# In this validator, address is nothing but record.
# @example
#   class Address
#   validates_with ScotlandPostcodeValidator, on: :scotland_postcode_selected
#   where scotland_postcode_selected is validation context
#   refer(https://guides.rubyonrails.org/active_record_validations.html#performing-custom-validations)
class ScotlandPostcodeValidator < ActiveModel::Validator
  # Regex for Scotland Postcode Validation
  SCOTLAND_POSTCODE_REGEX = /\A((BT|ZE|KW|IV|HS|PH|AB|DD|PA|FK|G|KY|KA|EH|ML|TD|DG)[0-9])/i

  # Validation check for valid Scotland Address.
  # @param address [Object] an object to be checked for validation
  def validate(address)
    if (address.country.present? && scotland_country_code_valid?(address.country) == false) ||
       (address.postcode.present? && scotland_postcode_format_valid?(address.postcode) == false)
      address.errors.add(:postcode, :postcode_format_invalid)
    end
  end

  # Validation for checking format of postcode, whether it is of Scotland.
  def scotland_postcode_format_valid?(postcode)
    postcode.match?(SCOTLAND_POSTCODE_REGEX)
  end

  # Logic to check if country code is of Scotland.
  def scotland_country_code_valid?(country)
    country == Rails.configuration.x.allowed_property_country_code
  end
end
