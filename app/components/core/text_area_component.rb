# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Standard text area
  # see {BaseFieldComponent}
  class TextAreaComponent < BaseFieldComponent
    attr_accessor :rows

    # (see BaseFieldComponent#initialize)
    # @param rows [Number] The number of rows to display
    def initialize(builder:, method:, readonly: false, rows: 3, one_question: false, optional: false,
                   show_label: true, disabled: false, data_options: {}, autocomplete: nil, interpolations: {})
      super(builder: builder, method: method, readonly: readonly, one_question: one_question, optional: optional,
            show_label: show_label, disabled: disabled, data_options: data_options, autocomplete: autocomplete,
            interpolations: interpolations)
      @rows = rows
    end
  end
end
