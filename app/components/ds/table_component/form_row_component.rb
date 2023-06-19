# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A table component this consists of one header and many rows
  class TableComponent
    # A header component consisting of many cells
    # @see {RowComponent} which is similar
    class FormRowComponent < ViewComponent::Base
      attr_reader :builder, :model, :index

      renders_many :cells, lambda { |**args, &block|
                             FormCellComponent.new(**{ builder: @builder }.merge(args), &block)
                           }

      # @param builder [Object] The current builder being used this is the one created by field_for
      # @param model [Object] The current model being rendered
      # @param index [Integer] The array index onto the model (starts at 1)
      # @param delete_link [Boolean] Should a delete link be rendered
      # @param data_options [Hash] A hash of data options primarily used for stimulus
      def initialize(builder:, model:, index:, delete_link: false, data_options: {})
        super()
        builder.fields_for(model, index: index) do |fields_for_builder|
          @builder = fields_for_builder
        end
        @model = model
        @index = index
        @delete_link = delete_link
        @data_options = data_options.transform_keys { |k| "data-#{k}" }
      end

      private

      attr_reader :data_options

      # Should the delete link be shown
      def delete_link?
        @delete_link
      end

      # Returns the standard delete link row
      def delete_link
        button_tag(t('.delete_row'), name: 'delete_row', class: 'ds_link', id: "delete_row_#{index}",
                                     value: index, 'aria-label' => "#{t('.delete_row')} #{index}")
      end
    end
  end
end
