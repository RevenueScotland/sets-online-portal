# frozen_string_literal: true

# Class for validating a range of date where the start date should be before the end date
class CompareDateValidator < ActiveModel::EachValidator
  include DateFormatting

  # Validates a range of date where the start date should be before the end date
  #
  # @param start_date_attr [Symbol] the name of the attribute of the object to be checked for validation
  #   which is the start date
  # @param start_date [Value] value of the starting date
  # @param record [object] object on which validation to perform
  #
  # To use this validation pattern, add compare_date syntax to date field in the model similar like presence: true
  # example
  # @see lbtt model,to check date must be after mentioned date in the configuration parameter
  #   validates :effective_date, compare_date: true, on: :effective_date
  #
  # To compare date with another date attribute in the model, we need to pass another date attribute name
  # as option in compare_date syntax.
  # example
  # @see LbttReturn model, validating lease_start_date must be before lease_end_date
  #   validates :lease_start_date, compare_date: { end_date_attr: :lease_end_date}
  def validate_each(record, start_date_attr, start_date)
    if options[:end_date_attr].blank? # compare_date: true
      date_after_mentioned_date(record, start_date_attr, start_date)
    else # compare_date: { end_date_attr: :lease_end_date}
      # retrieve value from options passed in compare_date function in the model
      end_date_attr = options[:end_date_attr]
      # retrieve end_date value
      end_date = record.send(end_date_attr)

      return if start_date.blank? || end_date.blank?

      return if date_start_before_end?(start_date, end_date)

      record.errors.add(start_date_attr, :before_date_error)
      record.errors.add(end_date_attr, :after_date_error)
    end
  end

  # Validates the date that it should not be before the mentioned date
  # in the configuration parameter
  # @param date_attr [Symbol] the name of the attribute of the object to be checked for validation
  # @param date [Value] actual date value which need to check
  # @param record [object] object on which validation to perform
  # example
  # Effective date of transaction must be after 01/04/2015
  # validates :effective_date, compare_date: true, on: :effective_date
  def date_after_mentioned_date(record, date_attr, date)
    return if date.blank?

    return if date_start_before_end?(Rails.configuration.x.earliest_start_date, date)

    record.errors.add(date_attr, :past_date_error, start_date: Rails.configuration.x.earliest_start_date_long_format)
  end

  # Check whether the start date is before the end date
  def date_start_before_end?(start_date, end_date)
    return unless date_parsable?(end_date) && date_parsable?(start_date)

    Date.parse(end_date) >= Date.parse(start_date)
  end
end
