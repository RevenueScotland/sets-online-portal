# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Error Summary for the top of the page.
  # This relies on the error_summary_list content_for having been populated by the rendering of individual fields
  # see {FieldWrapperComponent}
  # @note this is rendered into the error_summary content for so it can be rendered outside of the form block
  class ErrorSummaryComponent < ViewComponent::Base
    # @return [HTML] The errors formatted as an HTML list
    attr_reader :summary_error_list

    # Processing before the component is rendered
    def before_render
      # Only have the view context available here
      @summary_error_list = view_context.content_for(:summary_error_list)
    end

    # Only render the error summary if there are errors
    def render?
      return false unless @summary_error_list

      true
    end
  end
end
