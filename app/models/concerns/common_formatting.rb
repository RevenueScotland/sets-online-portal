# frozen_string_literal: true

# This provides a concern for formatting Display Fields
# it is used in both the view helpers but also the form builder class so needs to be structured as a concern
# so we can call it in both
module CommonFormatting
  # formats text according to the format in the options field
  # used in display field and table display
  # @param text [Object] The object to be formatted
  # @param options [Hash] The current options being processed
  # @return [String] the formatted string
  def self.format_text(text, options)
    text = UtilityHelper.make_characters_breakable(text, options[:break_characters]) if options.key?(:break_characters)
    text = format_text_next_lines(text)
    return text if options.blank?

    format = options[:format]
    return text if text.blank? && format != :money # money is set to zero in the format if blank

    apply_format(text, format)
  end

  # @!method self.apply_format(text, format)
  # formats text according to the format in the options field
  # used in display field and table display
  # @param text [Object] The object to be formatted
  # @param format [Symbol] The format to be used
  # @return [String] the formatted string
  private_class_method def self.apply_format(text, format)
    return "£#{NumberFormatting.to_money_format(text)}" if format == :money
    return DateFormatting.to_display_date_format(text) if format == :date
    return DateFormatting.to_display_datetime_format(text) if format == :datetime
    return DateFormatting.to_display_full_month_date_format(text) if format == :full_month_date

    text
  end

  # For texts that should consist of new lines, this will put it on the next line down.
  # @return [String] a html safe string with the break line added
  private_class_method def self.format_text_next_lines(text)
    return text unless text.to_s.include?("\n") || text.to_s.include?("\302")

    # replaces all of \n with a break line, but make sure it is escaped before marking as safe
    text = ERB::Util.html_escape(text)
    text.gsub!("\n", '<br>')
    text.html_safe
  end
end
