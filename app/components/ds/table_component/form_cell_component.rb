# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component this consists of one header and many rows
  class TableComponent
    # One cell in a header row
    class FormCellComponent < RowCellComponent
      attr_reader :builder

      include DS::ComponentHelpers
      include DS::HiddenField

      # @param builder [Object] The current builder
      # @param method [Symbol] This will default the cell to displaying the value of the method
      # @param align [Symbol] The alignment of the value
      # @param header [Boolean] If this should be displayed as a header
      # @param colspan [Integer] How many columns this cell should span
      def initialize(builder:, method: nil, align: nil, header: false, colspan: nil)
        super(model: builder.object, method: method, align: align, header: header, colspan: colspan)
        @builder = builder
      end

      # Override the defaults to suppress the labels and width
      def form_component_defaults(_component_name)
        { show_label: false, width: nil }
      end
    end
  end
end
