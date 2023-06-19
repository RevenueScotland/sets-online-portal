# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A summary list component consists of many items which can be based on a method or provided information
  class SummaryListComponent
    # A base item where all information is provided
    class MethodItemComponent < BaseItemComponent
      # @param model [Object] The model being rendered, normally defaulted from the summary list, may be overridden
      # @param method [Symbol] The method being rendered
      # @param type  [Symbol] The type of the value if it cannot be auto-detected. This also supports
      #   :lookup if the value is a standard reference value
      # @param display_nil [Boolean] if false don't display nil values
      # @param interpolations [Hash] Hash of options that are passed down to @see LabellerDelegate
      def initialize(model:, method:, type: :automatic, display_nil: true, interpolations: {})
        if model.nil?
          Rails.logger.debug { "Nil model passed to MethodItemComponent for method #{method} switching to display nil" }
          super(label_text: nil, value: nil, type: type, display_nil: false)
        else
          @model = model
          @method = method
          @interpolations = interpolations
          value, type = value_and_type(model, method, type)
          super(label_text: 'undefined', value: value, type: type, display_nil: display_nil)
        end
      end

      # sets up the LabellerDelegate using the view_context
      def before_render
        return unless @model && @method

        labeller = Core::LabellerDelegate.new(klass_or_model: @model, method: @method,
                                              action_name: view_context&.action_name&.to_sym,
                                              interpolations: @interpolations)
        @label_text = labeller.label_text
      end

      private

      # @param model [Object] The model being rendered, normally defaulted from the summary list, may be overridden
      # @param method [Symbol] The method being rendered
      # @param type  [Symbol] If :lookup looks up the value based on the standard ref data
      # @return [String] The value to display
      # @return [Symbol] The type
      def value_and_type(model, method, type)
        if type == :lookup
          [model.lookup_ref_data_value(method), :automatic]
        else
          [model.send(method), type]
        end
      end
    end
  end
end
