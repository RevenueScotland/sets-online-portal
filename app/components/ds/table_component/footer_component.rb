# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component this consists of one header and many rows with one footer
  class TableComponent
    # A footer component consisting of many cells
    class FooterComponent < ViewComponent::Base
      renders_many :cells, lambda { |**args, &block|
        FooterCellComponent.new(model: @model, **args, &block)
      }

      # @param model [Object] the model being rendered, can be used for deriving values
      def initialize(model: nil)
        super()
        @model = model
      end
    end
  end
end
