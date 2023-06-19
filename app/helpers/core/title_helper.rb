# frozen_string_literal: true

module Core
  # This module provides supporting helpers for the page titles
  module TitleHelper
    # Derives the page title
    # This is either the label as a title or derived from the content_for set on the page
    # @return [String] The page title
    def page_title
      content_for(:label_as_title) || content_for(:notification_panel_as_title) ||
        content_for(:page_title) || 'PAGE TITLE NOT SET OR IS NOT THE FIRST CONTENT FOR'
    end

    # This sets the page title in the heading section
    # If there is an error it prefixes error
    # Otherwise it shows the page title (from the page) followed by the service name
    def head_page_title
      prefix = "#{t('errors.error')}:" if content_for?(:error_summary)
      "#{prefix}#{page_title} - #{t('service_name')}".html_safe
    end
  end
end
