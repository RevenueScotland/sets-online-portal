# frozen_string_literal: true

module Core
  # This module provides supporting helpers for the page titles
  module TranslationPathHelper
    # Utility helper to give the translation path for the current page.
    # This effectively exposes the virtual path
    # @see https://github.com/rails/rails/blob/56832e791f3ec3e586cf049c6408c7a183fdd3a1/actionview/lib/action_view/helpers/translation_helper.rb#L123
    def translation_path
      @virtual_path.gsub(%r{/_?}, '.') # rubocop:disable  Rails/HelperInstanceVariable
    end
  end
end
