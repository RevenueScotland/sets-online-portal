# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)

module DS
  # A table component this consists of one header and many rows
  class TableComponent
    # One cell in a header row
    class RowCellComponent < ViewComponent::Base
      delegate :formatted_value, to: :formatter
      delegate :label_text, to: :labeller

      # @param model [Object] The model being rendered
      # @param method [Symbol] The name of the method being rendered
      # @param type [Symbol] The type of the value if it cannot be auto-detected
      # @param align [Symbol] The alignment of the value
      # @param header [Boolean] If this should be displayed as a header, values are
      #   false [not a header], true [display as a header], or :label if the
      #   content is the label of the method
      # @param colspan [Integer] How many columns this cell should span
      # @param interpolations [Hash] Hash of options that are passed down to @see LabellerDelegate,
      #   only used if the header is :label type
      def initialize(model: nil, method: nil, type: :automatic, align: nil, header: false, colspan: nil,
                     cell_as_row: false, interpolations: {})
        super()
        @cell_as_row = cell_as_row
        header_or_value(header, model, method, interpolations, type)
        @options = {}
        @options[:scope] = 'row' if @header
        @options[:align] = align if align
        @options[:colspan] = colspan if colspan
      end

      # @param header [Boolean] If this should be displayed as a header, values are
      #   false [not a header], true [display as a header], or :label if the
      #   content is the label of the method
      # @param model [Object] The model being rendered
      # @param method [Symbol] The name of the method being rendered
      # @param interpolations [Hash] Hash of options that are passed down to @see LabellerDelegate,
      #   only used if the header is :label type
      # @param type [Symbol] The type of the value if it cannot be auto-detected
      def header_or_value(header, model, method, interpolations, type)
        if header == :label
          @header = true
          @method = method
          @interpolations = interpolations
          @model = model
        else
          value_and_type(model, method, type)
          @header = header
        end
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
        add_classes(body)
      end

      # add the classes to the specific component
      def add_classes(body)
        if @header
          tag.th(body, **@options)
        elsif @cell_as_row
          tag.td(body, **@options, class: 'rs_cell_as_row')
        else
          body.empty? ? tag.td(body, **@options, class: 'rs_empty_cell_width') : tag.td(body, **@options)
        end
      end

      private

      attr_reader :formatter, :labeller
    end
  end
end
