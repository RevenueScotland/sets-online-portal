# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Standard text field field
  # see {https://designsystem.gov.scot/components/radio-buttons/}
  # see {BaseFieldComponent}
  class RadioGroupComponent < BaseFieldComponent
    include Core::ListValidator

    attr_reader :options_list, :code_method, :value_method, :field_group_type, :data_action

    # Support alignments, default is vertical
    ALLOWED_ALIGNMENTS = %i[vertical horizontal].freeze

    # (see DS::BaseFieldComponent#initialize)
    # @param options_list [Array] The array of objects for the radio group it should respond to code and value for the
    #   code to be used and the value to be displayed
    # @param alignment [Symbol] use :horizontal to align the radio group across the page
    # @param conditional_visibility [Symbol] The radio group acts as a conditional visibility control
    # We cannot make a radio group readonly so when we pass readonly as true, we are removing all of the
    # non checked radio buttons for that question. The readonly flag will also change the colour of the
    # checked marker to the readonly grey
    def initialize(builder:, method:, options_list:, one_question: false, interpolations: {}, width: nil,
                   autocomplete: nil, alignment: :vertical, conditional_visibility: false, readonly: false)
      super(builder: builder, method: method, one_question: one_question, autocomplete: autocomplete,
            interpolations: interpolations, width: width, readonly: readonly)
      @options_list = options_list
      alignment = self.class.fetch_or_fallback(ALLOWED_ALIGNMENTS, alignment, :vertical)
      @field_group_type = (alignment == :horizontal ? :field_group_inline : :field_group)
      @code_method = :code
      @value_method = :value
      @data_action = (conditional_visibility ? { 'data-action': 'visibility#toggleRegion' } : {})
      @options_list.delete_if { |a| a.send(@code_method) != builder.object.send(method) } if readonly
    end

    # Gets the code of the first option of a radio list
    def first_options_code
      @options_list[0].send(@code_method).to_s.downcase
    end
  end
end
