# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Standard text area
  # see {Core::TextAreaComponent}
  # see {https://designsystem.gov.scot/components/textarea}
  class TextAreaComponent < Core::TextAreaComponent
    include DS::Classes
    include DS::ComponentHelpers

    # (see Core::TextAreaComponent#initialize)
    # @param width [String|Integer] The width of the field, either a string for relative widths or a
    #   number for absolute widths you can only use values supported by the govuk-front end see
    #   {https://designsystem.gov.scot/components/text-input}
    def initialize(builder:, method:, readonly: false, rows: 3, one_question: false, optional: false,
                   width: 'two-thirds', show_label: true, disabled: false, autocomplete: nil, interpolations: {},
                   data_options: {})
      super(builder: builder, method: method, readonly: readonly, rows: rows, one_question: one_question,
            optional: optional, show_label: show_label, disabled: disabled, autocomplete: autocomplete,
            interpolations: interpolations, data_options: data_options)
      self.ds_width = width
    end
  end
end
