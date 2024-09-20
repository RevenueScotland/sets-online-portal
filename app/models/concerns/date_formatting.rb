# frozen_string_literal: true

# Usually Rails has enough methods for formatting, however sometimes it doesn't so this concern contains
# our custom date formatting methods.
module DateFormatting
  # Checks if date is parsable, if date isn't parsable it could mean that its an invalid date.
  def date_parsable?(date)
    Date.parse(date.to_s)
    true
  rescue ArgumentError
    false
  end

  # Converts the xml date to the standard display date which is in this format: 'dd Month yyyy'
  # Should be used for displaying date in a non-date_field field.
  def self.to_display_full_month_date_format(date)
    return if date.blank?

    date = Date.parse(date) unless date.is_a? Date
    date.strftime('%d %B %Y')
  end

  # Converts the xml date to the standard display date which is in this format: 'dd/mm/yyyy'
  # Should be used for displaying date in a non-date_field field.
  def self.to_display_date_format(date)
    return if date.blank?

    date = Date.parse(date) unless date.is_a? Date
    date.strftime('%d/%m/%Y')
  end

  # Converts the xml date to the standard display date which is in this format: 'dd/mm/yyyy hh:mm'
  # Should be used for displaying date in a non-date_field field.
  def self.to_display_datetime_format(date)
    return if date.nil?

    date = Date.parse(date) unless date.is_a? Date
    date.strftime('%d/%m/%Y %H:%M')
  end

  # Converts the date to the date with suffix format
  # for example 01-Dec-2023 will be converted into 1st-December-2023
  def self.to_display_date_suffix_format(date)
    return if date.nil?

    date = Date.parse(date) unless date.is_a? Date
    date.strftime('<suffix> %B %Y').gsub('<suffix>', date.day.ordinalize)
  end

  # Converts the parsable date into the correct date format ready to be used for requests for the webservices
  # @return [String] date in the format of 'YYYY-MM-DD'
  def self.to_xml_date_format(date)
    return if date.blank?

    date = Date.parse(date) unless date.is_a? Date
    # The default string representation for a date is Y-M-D so no format is needed
    date.to_s
  end
end
