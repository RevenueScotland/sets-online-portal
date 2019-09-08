# frozen_string_literal: true

# Provides common code for filtering data
# The base filter class consists of the most common methods for filtering
class BaseFilter
  include ActiveModel::Model
  include ActiveModel::Translation
  include ReferenceDataLookup
  include CommonValidation
  include DateFormatting

  # Matches the values of the data from the object in the list of data and the filter values
  # by comparing those two string values matches to see if it either includes parts of it or
  # matches exact.
  # @note This was split from the string_matches? as for some filter we would like to filter
  #   by checking if filter value is a part of the object value too.
  def self.string_includes?(object_attribute, filter_attribute)
    return true if filter_attribute.nil? || (filter_attribute.blank? && object_attribute.blank?)

    return false if object_attribute.nil?

    object_attribute.upcase.include?(filter_attribute&.upcase)
  end

  # Matches the values of the data from the object in the list of data and filter values
  # by comparing those two string values matches to see if it matches exact.#
  # @note Used for filtering to get the exact match, great for select field as it always
  #   have the exact value when filtering using that type of field.
  def self.string_matches?(object_attribute, filter_attribute)
    return true if filter_attribute.nil?

    filter_attribute == '' || object_attribute == filter_attribute
  end

  # Used for comparing dates, yield is used for date validation
  # @example
  #   BaseFilter.date_matches?(messages.created_datetime, created_datetime, self)
  def self.date_matches?(object_attribute, filter_attribute, object)
    return true if filter_attribute.nil?

    return false unless object.valid?

    filter_attribute == '' || translate_date(object_attribute) == Date.parse(filter_attribute)
  end

  # This is only used for the BaseFilter.date_match? It translates the date which would be in
  # this format 'dd-mm-yyyy' or 'dd/mm/yyyy'
  private_class_method def self.translate_date(date)
    return if date.nil?

    year_int = date[6, 4].to_i
    month_int = date[3, 2].to_i
    day_int = date[0, 2].to_i

    Date.new(year_int, month_int, day_int)
  end

  # Used for filtering the amount.
  #
  # Some countermeasures were added so that even if the user wants to add the characters '&pound;', ' ' and ',' it
  # would still be able to do the checking fine as it should be valid.
  # @return [Boolean] if the filter amount matches the object's amount, it returns true.
  def self.amount_matches?(object_attribute, filter_attribute, object)
    return true if filter_attribute.blank?

    filter_attribute.tr!('£', '')
    filter_attribute.tr!(' ', '')

    return false unless object.valid?

    filter_attribute.tr!(',', '')

    filter_attribute == '' || check_amount_match(object_attribute, filter_attribute)
  end

  # Used for filtering to find the objects which have amount attribute that is greater than
  # the filter amount attribute.
  # @return [Boolean] if the object amount is greater than the filter amount, then true
  def self.amount_is_greater?(object_attribute, filter_attribute, object)
    return true if filter_attribute.blank?

    return false unless object.valid?

    object_attribute.to_f > filter_attribute.to_f
  end

  # Used for checking if the filter amount actually matches amount by converting both to float
  # so that it can check for when the user decided to add a point or not.
  # @return [Boolean] a boolean value that checks if object amount is equivalent to filter amount.
  private_class_method def self.check_amount_match(object_attribute, filter_attribute)
    object_attribute.to_f == filter_attribute.to_f
  end
end
