# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Notification Panel Component
  # see {https://designsystem.gov.scot/components/notification-panel/}
  class NotificationPanelComponent < ViewComponent::Base
    attr_reader :title, :reference, :header, :success

    # This wraps the content in a notification panel followed by an optional reference
    # @param title [String] The title of the notification panel
    # @param reference [String|Array] A reference, or an array of references, this is shown after the content
    # @param header [Boolean] Should this be rendered as the page header. The title
    #   is then recorded as a H1 and used for the page title
    # @param success [Boolean] Causes the panel to be rendered in green not the normal grey
    def initialize(title:, reference: nil, header: true, success: false)
      super()

      @title = title
      # ensure always an array for the template, unless nil
      @reference = [reference].flatten if reference
      @header = header
      @success = success
    end
  end
end
