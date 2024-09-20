# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component this consists of one header and many rows
  class TableComponent
    # A header component consisting of many cells
    # @see {FormRowComponent} which is similar
    class RowComponent < ViewComponent::Base
      renders_many :cells, lambda { |**args|
        RowCellComponent.new(model: @model, **args)
      }

      # @param model [Object] the model being rendered, can be used for deriving values
      def initialize(model: nil)
        super()
        @model = model
      end
    end
  end
end
