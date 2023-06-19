# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Select List
  # see {https://designsystem.gov.scot/components/select}
  class SelectComponent < Core::SelectComponent
    include DS::Classes
    include DS::ComponentHelpers

    attr_reader :use_search

    # see {Core::SelectComponent#initialize}
    # @param use_search [Boolean] Changes the select to use a search component if javascript is available
    #   {https://designsystem.gov.scot/components/autocomplete/}
    # @param width [String|Integer] The width of the field, either a string for relative widths or a
    #   number for absolute widths you can only use values supported by the govuk-front end see
    #   {https://designsystem.gov.scot/components/text-input}
    def initialize(builder:, method:, select_options:, include_blank: true, one_question: false, optional: false,
                   width: 'two-thirds', show_label: true, readonly: false, disabled: false, autocomplete: nil,
                   use_search: false, data_options: {})
      super(builder: builder, method: method, select_options: select_options, include_blank: include_blank,
            one_question: one_question, optional: optional, show_label: show_label, readonly: readonly,
            disabled: disabled, autocomplete: autocomplete, data_options: data_options)
      @use_search = use_search
      self.ds_width = width
    end
  end
end
