# frozen_string_literal: true

# Provides common code for filtering data
# The base filter class consists of the most common methods for filtering
class BaseFilter
  include ActiveModel::Model
  include ActiveModel::Translation
  include ReferenceDataLookup
  include DateFormatting
  include StripAttributes

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
end
