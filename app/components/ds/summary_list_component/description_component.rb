# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # A summary list component consists of many items which can be based on a method or provided information
  class SummaryListComponent
    # Provides a description for this summary item, you can either provide the text in which case it
    # will be rendered within a paragraph or provide content for the component
    class DescriptionComponent < ViewComponent::Base
      attr_reader :text

      # @param text [String] The description of the component
      def initialize(text: nil)
        super()
        @text = text
      end
    end
  end
end
