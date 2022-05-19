# frozen_string_literal: true

# Allows you to compare dates for validation
# @see Returns::Lbtt::LbttReturn
#
# To validate the date is greater than the date given by the earliest_start_date configured date
# (Rails.configuration.x.earliest_start_date)
# Use the compare_date: true option
# @example To check the date is after the date in the configuration parameter
#   validates :effective_date, compare_date: true, on: :effective_date
#
# To compare the date is less than another date (start and end date ranges)
# Then pass the end date attribute
# @example To check a start and end date range
#   validates :lease_start_date, compare_date: { end_date_attr: :lease_end_date}
#
# To compare a date is equal to another date then pass the equal_date_attr
# @example To check a date is equal to another date
#   validates :lease_end_date, compare_date: { equal_date_attr: :relevant_date}
#
# To compare a date is a triennial anniversary of another date (29th feb matches to either 28th Feb or 1st March
# on anniversary)
# @example To check a date is a triennial anniversary of another date
#   validates :relevant_date, compare_date: { triennial_date_attr: :effective_date}
class CompareDateValidator < ActiveModel::EachValidator
  include DateFormatting

  # Validates dates against various rules
  #
  # @param record [object] object on which validation to perform
  # @param compare_date_attr [Symbol] the name of the attribute of the object to be checked for validation
  #   which is the start date
  # @param compare_date [String] value of the starting date
  #
  def validate_each(record, compare_date_attr, compare_date)
    validated = false
    # Look for particular validations in the options key, otherwise check general rule
    options.slice(:end_date_attr, :equal_date_attr, :triennial_date_attr).each_pair do |key, attr_name|
      validated = true
      validate_with_key(record, compare_date_attr, compare_date, key, attr_name)
    end
    validate_date_after_configured_date(record, compare_date_attr, compare_date) unless validated
  end

  private

  # Runs the validation given by the hash options
  #
  # @param record [object] object on which validation to perform
  # @param compare_date_attr [Symbol] the name of the attribute of the object to be checked for validation
  #   which is the start date
  # @param compare_date [String] value of the starting date
  # @param key [Symbol] key in the hash, indicates validation rule being triggered
  # @param attr_name [String] the name of the attribute holding another date string
  #
  def validate_with_key(record, compare_date_attr, compare_date, key, attr_name)
    case key
    when :end_date_attr # compare_date: { end_date_attr: :lease_end_date}
      validate_date_range(record, compare_date_attr, compare_date, attr_name)
    when :equal_date_attr # compare_date: { equal_date_attr: :relevant_date}
      validate_dates_equal(record, compare_date_attr, compare_date, attr_name)
    when :triennial_date_attr # compare_date: { equal_date_attr: :relevant_date}
      validate_triennial_dates(record, compare_date_attr, compare_date, attr_name)
    end
  end

  # Validates the date that it should not be before the configured date
  # @param record [object] object on which validation to perform
  # @param date_attr [Symbol] the name of the attribute of the object to be checked for validation
  # @param date [Value] actual date value which need to check
  #
  def validate_date_after_configured_date(record, date_attr, date)
    return if date.blank?

    return if date_start_before_end?(Rails.configuration.x.earliest_start_date, date)

    record.errors.add(date_attr, :past_date_error, start_date: Rails.configuration.x.earliest_start_date_long_format)
  end

  # Validates a date range
  # @param record [object] object on which validation to perform
  # @param start_date_attr [Symbol] the name of the start date attribute
  # @param start_date [Value] actual date value which needs to be checked
  # @param end_date_attr [Symbol] the name of the end date attribute
  def validate_date_range(record, start_date_attr, start_date, end_date_attr)
    # retrieve end_date value
    end_date = record.send(end_date_attr)

    return if date_start_before_end?(start_date, end_date)

    record.errors.add(start_date_attr, :before_date_error)
    record.errors.add(end_date_attr, :after_date_error)
  end

  # Validates equal dates
  # @param record [object] object on which validation to perform
  # @param date_attr [Symbol] the name of the start date attribute
  # @param date [Value] actual date value which needs to be checked
  # @param equal_date_attr [Symbol] the name of the end date attribute
  def validate_dates_equal(record, date_attr, date, equal_date_attr)
    # retrieve equal_date value
    equal_date = record.send(equal_date_attr)
    return if dates_equal?(date, equal_date)

    record.errors.add(date_attr, :equal_date_error)
  end

  # Validates date is a triennial anniversary of the comparison date
  # @param record [object] object on which validation to perform
  # @param date_attr [Symbol] the name of the start date attribute
  # @param date [Value] actual date value which needs to be checked
  # @param triennial_date_attr [Symbol] the name of the end date attribute
  def validate_triennial_dates(record, date_attr, date, triennial_date_attr)
    # retrieve equal_date value
    equal_date = record.send(triennial_date_attr)
    return if dates_triennial?(date, equal_date)

    record.errors.add(date_attr, :triennial_date_error)
  end

  # Check whether the start date is before the end date
  # @param start_date [String] the name of the start date attribute
  # @param end_date [String] actual date value which needs to be checked
  # @return [Boolean] Is the start date before the end date
  def date_start_before_end?(start_date, end_date)
    return true if start_date.blank? || end_date.blank?
    return true unless date_parsable?(end_date) && date_parsable?(start_date)

    Date.parse(end_date) >= Date.parse(start_date)
  end

  # Check whether dates are equal
  # @param date1 [String] the name of the start date attribute
  # @param date2 [String] actual date value which needs to be checked
  # @return [Boolean] Are the dates equal
  def dates_equal?(date1, date2)
    return true if date1.blank? || date2.blank?
    return true unless date_parsable?(date1) && date_parsable?(date2)

    Date.parse(date1) == Date.parse(date2)
  end

  # Check whether anniversary date is triennial anniversary date of the source date
  # For a source of the 29th Feb then both 28th Feb and 1st March match
  # @param anniversary_date_string [String] the anniversary date to be checked
  # @param source_date_string [String] The original source date
  # @return [Boolean] Is the anniversary date a triennial anniversary of the source date
  def dates_triennial?(anniversary_date_string, source_date_string)
    return true if anniversary_date_string.blank? || source_date_string.blank?
    return true unless date_parsable?(anniversary_date_string) && date_parsable?(source_date_string)

    anniversary_date = Date.parse(anniversary_date_string)
    source_date = Date.parse(source_date_string)

    triennial_date, triennial_date_plus_one = calculate_nearest_triennial_date(anniversary_date, source_date)
    return true if triennial_date == anniversary_date || triennial_date_plus_one == anniversary_date

    false
  end

  # Calculate the nearest triennial date (3rd, 6th etc anniversary date) to the provided
  # anniversary date to the source date
  # if the source date is the 29th feb also provide the 1st march date
  # @param anniversary_date [Date] the anniversary date to be checked
  # @param source_date [Date] The original source date
  # @return [Date,Date] The triennial date(s), if the source date is not the 29th then both dates are the same
  def calculate_nearest_triennial_date(anniversary_date, source_date)
    # Work out which 3rd year anniversary this is closest to (3,9,12 etc)
    diff = ((anniversary_date - source_date) / (365 * 3)).round
    # Work out what the actual triennial date is from the source date
    # 0 is not a valid date so use 1 as a min
    triennial_date, triennial_date_plus_one = source_date + ([diff, 1].max * 3.years)

    triennial_date_plus_one = triennial_date + 1 if source_date.day == 29 && source_date.month == 2
    [triennial_date, triennial_date_plus_one]
  end
end
