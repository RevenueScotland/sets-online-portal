# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # This supports those occasions where you only have one toggle checkbox, this is unusual mostly you would have a
  # group. The use case for this is normally around declarations
  class CheckboxComponent < BaseFieldComponent
    delegate :label_text, :label_visually_hidden, :hint_text, :hint_id, :error_list, :error_id,
             :add_html_options, to: :wrapper

    attr_reader :checked_value, :unchecked_value

    # see {BaseFieldComponent#initialize}
    # @param checked_value [String] Override the default rails checked value
    # @param unchecked_value [String] Override the default rails unchecked value
    def initialize(builder:, method:, readonly: false, one_question: false, interpolations: {},
                   checked_value: '1', unchecked_value: '0')
      super(builder: builder, method: method, readonly: readonly, one_question: one_question,
            interpolations: interpolations)
      @builder = builder
      @checked_value = checked_value
      @unchecked_value = unchecked_value
    end

    # Set up the wrapper using the view context
    def before_render
      # The wrapper needs the view context
      @wrapper = WrapperDelegate.new(builder: @builder, method: @method,
                                     optional: @optional, interpolations: @interpolations, view_context: view_context,
                                     readonly: @readonly)
    end

    private

    attr_reader :wrapper
  end
end
