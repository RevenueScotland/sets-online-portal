# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Notification Banner Component
  # see https://designsystem.gov.scot/components/notification-banner/}
  class NotificationBannerComponent < ViewComponent::Base
    attr_reader :notifications

    # @param notifications [Array] The array of notices to display must respond to
    #   title and link
    def initialize(notifications:)
      super()

      @notifications = notifications
    end

    def render?
      notifications.any?
    end
  end
end
