# frozen_string_literal: true

# RS specific parts of the UI (normally referencing classes)
module RS
  # Notification Banner Component
  # see https://designsystem.gov.scot/components/notification-banner/}
  class NotificationBannerComponent < DS::NotificationBannerComponent
    # @param display_page [String] show notifications for this page
    def initialize(display_page:)
      # returns a list of all the notices available in cached memory, we don't want to error if there are none
      notices = ReferenceData::SystemNotice.list('PWS', 'SYS', 'RSTU', safe_lookup: true)

      # Returns a valid notice list banners among all notices
      notices = notices.select { |notice| notice.valid_notice?(display_page) }

      super(notifications: notices)
    end
  end
end
