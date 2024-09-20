# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component this consists of one header and many rows
  class TableComponent
    # A header component consisting of many cells
    class HeaderComponent < ViewComponent::Base
      renders_many :cells, lambda { |**args, &block|
        HeaderCellComponent.new(klass: @klass, **args, &block)
      }

      # @param klass [Class] the name of the klass for the header, can be used for deriving labels
      # @param action_header [Boolean] should we render an action header
      def initialize(klass: nil, action_header: false)
        super()
        @klass = klass
        @action_header = action_header
      end

      private

      # Should the action header be shown
      def action_header?
        @action_header
      end

      # Returns the cell for the action header
      def action_header
        tag.th(t('.action'), scope: 'col')
      end
    end
  end
end
