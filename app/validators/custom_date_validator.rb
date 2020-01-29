# frozen_string_literal: true

# Class for validating date format
class CustomDateValidator < ActiveModel::EachValidator
  include DateFormatting

  # Validate a date, a date is valid if the string can be parsed into a date
  #
  # @example here are some string examples of date format that can be parsed into the date
  #   '25-12-2018'
  #   '25/12/2018'
  #   '2018/12/25'
  #   '2018-12-25'
  # @param record [Object] an object to be checked for validation
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @param value [String] actual value of an object to be checked for validation
  # @see DateFormatting::date_parsable? to see how it is handling the checker of a parsable date
  # To use this validation pattern, add "custom_date: true" in the model specific to that attribute
  # similar to how we use presence: true
  # @example In LbttReturn model, to validate value in the effective_date is valid date or not
  #   validates :effective_date, custom_date: true, presence: true, on: :effective_date
  def validate_each(record, attribute, value)
    return if value.blank?

    # Check the date is parsable
    record.errors.add(attribute, :is_invalid) && return unless date_parsable? value

    # Checks the year has 4 digits
    return if Date.parse(value).year.to_s.length <= 4

    record.errors.add(attribute, :is_invalid)
  end
end
