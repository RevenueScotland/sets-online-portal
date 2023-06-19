# frozen_string_literal: true

# Main handling all of the core functions to support an application
module Core
  # A select component on the page
  class SelectComponent < BaseFieldComponent
    attr_reader :select_options, :include_blank

    # expose readonly as this is needed in the template
    attr_reader :readonly

    # see {BaseFieldComponent#initialize}
    # @param select_options [Array|ActiveSupport::SafeBuffer|Object] The array of select options in the
    #  format [[value, code], [value,code]]
    #  Or will accept the output from options_for_select
    #  Or will select a hash of objects that responds for code and value and transform it
    #  see {transform_options}
    # @param readonly [Boolean] Select components don't respond to read only in the expected way, this uses disabled
    #   instead and a hidden field
    # @param include_blank [Boolean] Include a blank entry
    def initialize(builder:, method:, select_options:, include_blank: true, one_question: false, optional: false,
                   show_label: true, readonly: false, disabled: false, autocomplete: nil, data_options: {})
      super(builder: builder, method: method, one_question: one_question, autocomplete: autocomplete,
            optional: optional, show_label: show_label, disabled: disabled || readonly, readonly: readonly,
            data_options: data_options)
      @select_options = if select_options.is_a?(ActiveSupport::SafeBuffer) || select_options[0].is_a?(Array)
                          select_options
                        else
                          Rails.logger.debug { "Field #{method}: transforming #{select_options[0].class}" }

                          transform_options(select_options)
                        end

      @include_blank = include_blank
    end

    private

    # Utility function to help transform an array of objects into the array that is needed for the select_options
    # It will run a transform that assumes the array of object responds to value and code methods, like the standard
    # ReferenceValue objects.
    # For non standard objects then use the standard Rails options_for_select helper
    #
    # @param object_array [Array] the array of objects to be transformed
    def transform_options(object_array)
      unless object_array[0].respond_to?(:value) && object_array[0].respond_to?(:code)
        raise ArgumentError,
              'select_option is not not an array and cannot be transformed automatically ' \
              'use <Hash>.collect to transform'
      end

      object_array.collect { |o| [o.value, o.code] }
    end
  end
end
