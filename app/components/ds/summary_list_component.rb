# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A summary list component consists of many items which can be based on a method or provided information
  #
  # A summary list can have an options title and also an optional description, the description can either
  # be provided as content as as text. If provided as content then it should be wrapped ib a paragraph
  # if text is provided then it is wrapped automatically
  #
  # @example Providing content
  # <%= ds_summary_list(model: @my_model, title: 'My model title') do |s|%>
  #   <% s.with_description do %>
  #       <%= tag.p('Here are the details of my model') %>
  #   <% end %>
  #   <% s.with_item_base(label_text: 'My Label', value: 'My Value') %>
  #   <% s.with_item_method(method: :my_method) %>
  # <% end %>
  #
  # @example Providing text
  # <%= ds_summary_list(model: @my_model, title: 'My model title') do |s|%>
  #   <% s.with_description(text: 'Here are the details of my model') %>
  #   <% s.with_item_base(label_text: 'My Label', value: 'My Value') %>
  #   <% s.with_item_method(method: :my_method) %>
  # <% end %>
  #
  # see {https://designsystem.gov.scot/components/summary-list/}
  # see {SummaryListComponent::MethodItemComponent}
  # see {SummaryListComponent::BaseItemComponent}
  class SummaryListComponent < ViewComponent::Base
    renders_many :items, types: {
      method: lambda { |**args|
                # Note order of merge to allow for object to be overridden
                DS::SummaryListComponent::MethodItemComponent.new(model: @model, **args)
              },
      base: DS::SummaryListComponent::BaseItemComponent
    }

    renders_one :description, DS::SummaryListComponent::DescriptionComponent

    attr_reader :title, :show_border

    # @param title [String] The heading of the region
    # @param model [Object] The model being rendered (if any), passed to the item components
    # @param show_border [Boolean] Show the border
    def initialize(title: nil, model: nil, show_border: true)
      super()

      @title = title
      @model = model
      @show_border = show_border
    end
  end
end
