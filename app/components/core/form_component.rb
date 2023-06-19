# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # This provides a wrapper for delivering a form based on the component architecture. This holds the core
  # functionality but it is normally used as a base class for a UI specific version
  #
  class FormComponent < ViewComponent::Base
    attr_reader :builder, :button_actions, :button_label, :autofocus, :file_upload, :data_options

    delegate :object, to: :builder

    # (see ApplicationComponent#initialize)
    # @param builder [FormBuilder] The current form builder being used
    # @param button_action [Symbol] The action to be used on the button (can be an array of actions)
    #   Using a button action of :none suppresses the button
    # @param button_label [String] Used to override the name of the button, only use if one button
    # @param autofocus [Boolean] If true sets focus on the submit button (if there are no errors)
    #   normally used with forms that return to the same page (e.g. find forms)
    # @param file_upload [Boolean] Sets file upload controller, use this on file upload pages where the user
    #   may forget to upload the file
    def initialize(builder:, button_action: :continue, button_label: nil, autofocus: false, file_upload: false)
      super()
      @builder = builder
      # We need to add the default on as the main form_with may pass nil down
      @button_actions = Array(button_action || :continue)
      @button_label = button_label
      @autofocus = autofocus
      @file_upload = file_upload || false
      @data_options = (@file_upload ? { action: 'file-upload#checkUpload' } : {})
    end

    # Derives the action type for the submit button based on the index and the number of actions
    # @return [Symbol] :primary, :secondary
    def action_type(index:)
      @actions_size ||= @button_actions.size
      if index.zero?
        :primary
      else
        :secondary
      end
    end

    # This routine is (and must be) run after the content has been rendered.
    # It extracts errors from the object that have not already been extracted from the attributes
    # in the form render and stores them in the summary_error_list with the attribute level ones
    # extracted as part of the {FieldWrapperComponent}
    def store_base_errors
      models_with_errors(@builder.object).each do |model|
        next unless model.errors.any?

        model.errors.each do |e|
          view_context.content_for(:summary_error_list,
                                   content_tag(:li, content_tag(:a, e.full_message, href: "##{e.detail[:link_id]}")))
        end
      end
    end

    private

    # @param object [Object] An object to look for error objects in
    # @return [Array] An array of objects with errors for the object (includes the object)
    def models_with_errors(object)
      (object.respond_to?(:error_objects) ? object.error_objects : [object])
    end
  end
end
