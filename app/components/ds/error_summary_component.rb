# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Error Summary for the top of the page.
  # SEE{https://designsystem.gov.scot/components/error-summary}
  # This relies on the error_summary_list content_for having been populated by the rendering of individual fields
  # see {FieldWrapperComponent}
  # @note this is rendered into the error_summary content for so it can be rendered outside of the form block
  class ErrorSummaryComponent < Core::ErrorSummaryComponent
  end
end
