# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component this consists of one header and many rows
  class TableComponent
    # One cell in a header row
    class HeaderCellComponent < ViewComponent::Base
      include Core::ListValidator

      delegate :label_text, to: :labeller

      # Allowed alignments, only right as left is assumed otherwise
      ALLOWED_ALIGNMENT = %i[right].freeze

      # @param klass [Class] the name of the klass for the header, can be used for deriving labels
      # @param method [Symbol] The name of the method, used to derive the label
      # @param align [Symbol] Is the cell right aligned, default is left
      # @param interpolations [Hash] Hash of options that are passed down to @see LabellerDelegate
      def initialize(klass: nil, method: nil, align: nil, cell_as_header: false, interpolations: {})
        super()

        @klass = klass
        @method = method
        @interpolations = interpolations
        @options = { scope: 'col' }
        @options[:align] =  self.class.fetch_or_fallback(ALLOWED_ALIGNMENT, align, :left) if align
        @cell_as_header = cell_as_header
      end

      # sets up the LabellerDelegate using the view_context
      def before_render
        return unless @klass && @method

        @labeller = Core::LabellerDelegate.new(klass_or_model: @klass, method: @method,
                                               action_name: view_context&.action_name&.to_sym,
                                               interpolations: @interpolations)
      end

      # Renders the cell
      def call
        body = safe_join([(labeller ? label_text : ''), content])
        @cell_as_header ? tag.th(body, **@options, class: 'rs_cell_as_header') : tag.th(body, **@options)
      end

      private

      attr_reader :labeller, :options
    end
  end
end
