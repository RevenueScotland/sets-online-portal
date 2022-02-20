# frozen_string_literal: true

# This provides a concern for formatting Display Fields
# it is used in both the view helpers but also the form builder class so needs to be structured as a concern
# so we can call it in both
module CommonFormatting
  # formats text according to the format used in display field and table display
  # @param text [Object] The object to be formatted
  # @param format [String] The format being displayed
  # @param break_characters [String] The break characters to use in the text
  # @return [String] the formatted string
  def self.format_text(text, format: nil, break_characters: nil)
    text = UtilityHelper.make_characters_breakable(text, characters: break_characters) unless break_characters.nil?
    text = format_text_next_lines(text)

    apply_format(text, format: format)
  end

  # @!method self.apply_format(text, format)
  # formats text according to the format in the options field
  # used in display field and table display
  # @param text [Object] The object to be formatted
  # @param format [Symbol] The format to be used
  # @return [String] the formatted string
  private_class_method def self.apply_format(text, format: nil)
    # Apply number format first that turns blank into 0
    return "£#{NumberFormatting.to_money_format(text)}" if format == :money
    return text if text.blank? || format.blank?

    return DateFormatting.to_display_date_format(text) if format == :date
    return DateFormatting.to_display_datetime_format(text) if format == :datetime
    return DateFormatting.to_display_full_month_date_format(text) if format == :full_month_date

    text # Will hit this for a format not in the above list
  end

  # For texts that should consist of new lines, this will put it on the next line down.
  # @return [String] a html safe string with the break line added
  private_class_method def self.format_text_next_lines(text)
    return text unless text.to_s.include?("\n") || text.to_s.include?("\302")

    # replaces all of \n with a break line, but make sure it is escaped before marking as safe
    text = ERB::Util.html_escape(text)
    text.gsub!("\n", '<br>')
    text.html_safe # rubocop:disable Rails/OutputSafety
  end
end
