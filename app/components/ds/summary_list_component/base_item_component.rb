# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A summary list component consists of many items which can be based on a method or provided information
  class SummaryListComponent
    # A base item forms part of a summary list
    #
    # Each item has a label, a value and one or more optional actions. The actions can be links see {DS::LinkComponent}
    # The default name for an action is 'Change' but it can be overridden by providing a name for the action
    #
    # @example Using Change
    #   <% s.with_item_base(label_text: 'My Label', value: 'My Value') do |i| %>
    #     <% i.with_action_link(url: my_method_path) %>
    #  <% end %>
    #
    # @example Passing a name
    #   <% s.with_item_method(method: :my_method) do |i| %>
    #     <% i.with_action_link(url: my_method_path, name: "My name") %>
    #  <% end %>
    class BaseItemComponent < ViewComponent::Base
      attr_reader :label_text

      renders_many :actions, types: {
        link: lambda { |**args|
                args[:name] = t('.change') unless args.key?(:name)
                args[:name] = html_escape("#{args[:name]} ") + tag.span(t('.your_answer_for') + tag.q(label_text),
                                                                        class: 'visually-hidden')
                DS::LinkComponent.new(**args)
              }
      }

      delegate :formatted_value, to: :formatter

      # @param label_text [String] The label for the item
      # @param value [String] The value being displayed
      # @param type  [Symbol] The type of the value if it cannot be auto-detected
      # @param display_nil [Boolean] if false don't display nil values
      def initialize(label_text:, value:, type: :automatic, display_nil: true)
        super
        @label_text = label_text
        @value = value
        @display_nil = display_nil
        @formatter = Core::FormatterDelegate.new(value: @value, type: type)
      end

      # Don't display nil items if not requested
      def render?
        @display_nil || @value.present?
      end

      private

      attr_reader :formatter
    end
  end
end
