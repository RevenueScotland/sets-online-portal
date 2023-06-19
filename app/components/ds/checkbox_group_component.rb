# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Standard text field field
  # see {https://designsystem.gov.scot/components/radio-buttons/}
  # see {BaseFieldComponent}
  class CheckboxGroupComponent < BaseFieldComponent
    attr_reader :options_list, :code_method, :value_method, :data_action

    # (see DS::BaseFieldComponent#initialize)
    # @param options_list [Array] The array of objects for the radio group it should respond to code and value for the
    #   code to be used and the value to be displayed
    # @param conditional_visibility [Symbol] The checkbox group acts as a conditional visibility control
    def initialize(builder:, method:, options_list:, readonly: false, disabled: false, one_question: false, width: nil,
                   optional: false, show_label: true, autocomplete: nil, interpolations: {}, data_options: {},
                   code_method: :code, value_method: :value, conditional_visibility: false)
      super(builder: builder, method: method, readonly: readonly, disabled: disabled, one_question: one_question,
            width: width, optional: optional, show_label: show_label, autocomplete: autocomplete,
            interpolations: interpolations, data_options: data_options)
      @options_list = options_list
      @code_method = code_method
      @value_method = value_method
      @data_action = (conditional_visibility ? { 'data-action': 'visibility#toggleRegion' } : {})
    end
  end
end
