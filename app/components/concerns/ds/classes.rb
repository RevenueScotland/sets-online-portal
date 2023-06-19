# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Provides support for managing GDS classes where these are not straightforward
  # see the individual routines
  module Classes
    extend ActiveSupport::Concern
    include Core::ListValidator

    # Returns the DS width class for this object, based on the width set
    # Either govuk-!-width-[String] or govuk-input-width-[Number]
    # @return [String] The correct width class
    attr_reader :ds_width_class

    private

    # Allowed widths for the Digital Scotland width option if it is numeric
    ALLOWED_NUMERIC_WIDTHS = [2, 3, 4, 5, 10, 20].freeze
    # Allowed widths for the Digital Scotland width option if it is a string
    ALLOWED_STRING_WIDTHS = %w[three-quarters two-thirds one-half one-third one-quarter].freeze

    # Validates that the supplied width is one of the valid widths support by the Digital Scotland styles
    # and stores the correct width class in gds_width_class for later access
    # If the width supplied is invalid it return nil, or raises an error in development mode
    # @param width [String|Number] the provided width
    def ds_width=(width)
      list = (width.is_a?(String) ? ALLOWED_STRING_WIDTHS : ALLOWED_NUMERIC_WIDTHS)
      width = self.class.fetch_or_fallback(list, width, 'two_thirds') if width
      @ds_width_class = if width.is_a?(String)
                          "ds_input--fluid-#{width}"
                        elsif width
                          "ds_input--fixed-#{width}"
                        end
    end
  end
end
