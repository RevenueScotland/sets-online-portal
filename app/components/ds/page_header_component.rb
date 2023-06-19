# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Page Header Component
  # SEE{https://designsystem.gov.scot/components/page-header}
  class PageHeaderComponent < ViewComponent::Base
    attr_reader :page_title

    # @param page_title [String] The title of the page
    def initialize(page_title:)
      super()
      @page_title = page_title
    end

    # Do not render if the label or notification panel is used as a title
    def render?
      !(content_for?(:label_as_title) || content_for?(:notification_panel_as_title))
    end
  end
end
