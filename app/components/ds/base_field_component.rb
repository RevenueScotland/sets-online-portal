# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Defines a base field component with standard attributes, this is kept in synch with {FieldWrapperComponent}
  # as most of the options are passed through to that component for rendering
  class BaseFieldComponent < Core::BaseFieldComponent
    include DS::Classes
    include DS::ComponentHelpers

    # (see Core::BaseFieldComponent#initialize)
    # @param width [String|Integer] The width of the field, either a string for relative widths or a
    #   number for absolute widths you can only use values supported by the govuk-front end see
    #   {https://designsystem.gov.scot/components/text-input}
    def initialize(builder:, method:, readonly: false, disabled: false, one_question: false, width: 'two-thirds',
                   show_label: true, autocomplete: nil, optional: false, interpolations: {}, data_options: {})
      super(builder: builder, method: method, readonly: readonly, disabled: disabled, one_question: one_question,
            show_label: show_label, autocomplete: autocomplete, optional: optional, interpolations: interpolations,
            data_options: data_options)
      self.ds_width = width
    end
  end
end
