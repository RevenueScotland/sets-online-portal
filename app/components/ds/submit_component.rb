# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Standard DS main submit button
  # This is normally added automatically to the end of the form, the button defaults to continue
  # @see FormComponent
  class SubmitComponent < DS::ButtonComponent
    attr_reader :builder, :button_action, :autofocus

    # @param button_action [Symbol|String] The symbol for the button, the translation is
    #   picked up from button.<symbol> unless this is a string
    #   If you want to default to the normal rails submit functionality pass an action of submit
    # @param type [Boolean] :secondary, :primary, :warning, leave blank if there is only one button
    # (see DS::ButtonComponent#initialize)
    # @param fixed [Boolean] is the width of the button fixed
    # @param autofocus [Boolean] If true sets focus on the submit button, unless there are errors
    # @param button_label [String] If you want to provide a specific label for the button to override
    #  the default based on the action use this
    # @param extra_classes [String] Extra classes to add to the button, for example to change the borders
    # @param data_options [Hash] A hash of one or more data options to add to the field, used for stimulus
    def initialize(builder:, button_action: :continue, type: :primary, fixed: true, autofocus: false,
                   button_label: nil, extra_classes: nil, data_options: {})
      @button_action = button_action || :continue
      @builder = builder
      @autofocus = autofocus
      # providing a button label overrides the rails submit
      @submit = (@button_action == :submit) && button_label.nil?
      super(name: button_label || button_action, type: type, fixed: fixed, extra_classes: extra_classes,
            data_options: data_options)
    end

    # is this a standard rails submit
    def submit?
      @submit
    end

    # Clear the autofocus if errors
    def before_render
      super
      @autofocus = false if content_for?(:error_summary)
    end
  end
end
