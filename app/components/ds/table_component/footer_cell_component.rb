# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component this consists of one header and many rows with one footer
  class TableComponent
    # One cell in a footer row
    class FooterCellComponent < ViewComponent::Base
      include Core::ListValidator

      delegate :label_text, to: :labeller

      # Allowed alignments, only right as left is assumed otherwise
      ALLOWED_ALIGNMENT = %i[right].freeze

      # @param model [Object] The model being rendered
      # @param method [Symbol] The name of the method, used to derive the label
      # @param align [Symbol] Is the cell right aligned, default is left
      # @param colspan [Integer] How many columns this cell should span
      # @param interpolations [Hash] Hash of options that are passed down to @see LabellerDelegate
      def initialize(model: nil, method: nil, align: nil, type: :automatic, colspan: nil, interpolations: {})
        super()

        value_and_type(model, method, type)
        @interpolations = interpolations
        @options = { scope: 'col' }
        @options[:align] =  self.class.fetch_or_fallback(ALLOWED_ALIGNMENT, align, :left) if align
        @options[:colspan] = colspan if colspan
      end

      # @param model [Object] The model being rendered, normally defaulted from the summary list, may be overridden
      # @param method [Symbol] The method being rendered
      # @param type  [Symbol] If :lookup looks up the value based on the standard ref data
      # @return [String] The value to display
      # @return [Symbol] The type
      def value_and_type(model, method, type)
        return unless model && method

        if type == :lookup
          @formatter = Core::FormatterDelegate.new(value: model.lookup_ref_data_value(method), type: :automatic)
        else
          # The below allows for arbitrary fields that aren't on the object
          value = model.send(method) if model.respond_to?(method)
          @formatter = Core::FormatterDelegate.new(value: value, type: type)
        end
      end

      # sets up the LabellerDelegate using the view_context
      def before_render
        return unless @model && @method

        @labeller = Core::LabellerDelegate.new(klass_or_model: @model, method: @method,
                                               action_name: view_context&.action_name&.to_sym,
                                               interpolations: @interpolations)
      end

      # Renders the cell
      def call
        # Not we have to use safe join as the value is from the user
        body = safe_join([(if formatter
                             formatter.formatted_value
                           else
                             (labeller ? label_text : '')
                           end), content])

        body.empty? ? tag.td(body, **@options, class: 'rs_empty_cell_width') : tag.td(body, **@options)
      end

      private

      attr_reader :formatter, :labeller
    end
  end
end
