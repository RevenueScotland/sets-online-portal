# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Provides support to format a value based on a type {ALLOWED_TYPES}.
  # The type can normally be automatically detected.
  # Ones that cannot be detected include boolean values based on 1 and 0 and password fields
  class FormatterDelegate
    include ListValidator
    include ActionView::Helpers::NumberHelper

    # List of allowed column types, this is only for those types where we need to know
    # and can't manage by auto detection. If in doubt leave blank
    ALLOWED_TYPES = %i[number string password boolean currency date breakable automatic].freeze

    # List of values that equate to a boolean true
    BOOLEAN_TRUE = [1, true].freeze

    # @param value [Object] The value being rendered
    # @param type [Symbol] The type of the value if it cannot be auto-detected
    # @param break_character [String] If type is breakable the break character
    def initialize(value:, type: :automatic, break_character: '/')
      @value = value
      @type = self.class.fetch_or_fallback(ALLOWED_TYPES, type, :automatic)
      @break_character = break_character
    end

    # Returns the formatted value associated with the wrapped object
    # @return [String] the value formatted with the default display characteristics
    def formatted_value
      return @value if @value.blank?

      set_type
    end

    # sets the type for the various types auto detects if not specified
    def set_type
      case @type
      when :password
        I18n.t('hidden_password')
      when :currency
        formatted_value_currency(@value)
      when :breakable
        formatted_value_breakable(@value, @break_character)
      else
        # Other types can be autodetected
        formatted_value_other(@value, @type)
      end
    end

    private

    # Returns a formatted value based on automatically guessing the type
    # @param value [Object] an object
    # @param type [Symbol] The type of the value if it cannot be auto-detected
    # @return [String] The formatted value
    def formatted_value_other(value, type)
      if type == :boolean || (type == :automatic && looks_like_boolean?(value))
        formatted_value_boolean(value)
      elsif type == :date || (type == :automatic && looks_like_date?(value))
        I18n.l(value)
      else # Number or String
        formatted_value_string(value)
      end
    end

    # Does the value look like a boolean
    def looks_like_boolean?(value)
      value.in?([true, false])
    end

    # Does the value look like a date or a date time
    def looks_like_date?(value)
      value.is_a?(Date) || value.is_a?(Time)
    end

    # Returns Yes or No based on an incoming boolean value
    # @param value [Object] an object that can be converted to a boolean
    # @return [String] Yes or No
    def formatted_value_boolean(value)
      (BOOLEAN_TRUE.include?(value) ? I18n.t('true') : I18n.t('false'))
    end

    # Formats a currency value
    # @param value [Object] an object that can be converted to a float
    # @return [String] Yes or No
    def formatted_value_currency(value)
      value.to_f.to_fs(:currency)
    end

    # This allows us to make the given string of characters a breakable character in a string by adding
    # a zero with space character
    # This used where we have items like references and may want e.g. a '/' to break which is the case in firefox
    # but not in other browsers
    # @param value [String] is a string that will be altered and returned.
    # @param break_character [String] is the character that is the break character
    def formatted_value_breakable(value, break_character)
      # always escape first
      value = ERB::Util.html_escape(value)
      # Create a regexp where the list of characters in the string is searched for
      value.gsub(Regexp.new("(?<c>[#{Regexp.escape(break_character)}])"), '\k<c>&#8203;')&.html_safe # rubocop:disable Rails/OutputSafety
    end

    # Formats a string (or other value) by replacing carriage returns with breaks
    # @param value [String] is a string that will be altered and returned.
    def formatted_value_string(value)
      return value unless value.to_s.include?("\n") || value.to_s.include?("\302")

      # replaces all of \n with a break line, but make sure it is escaped before marking as safe
      value = ERB::Util.html_escape(value)
      value.gsub!("\n", '<br>')
      value.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
