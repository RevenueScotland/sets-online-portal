# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Implements https://designsystem.gov.scot/components/cookie-banner/
  class CookieBannerComponent < ViewComponent::Base
    attr_reader :show_success

    # @param show_success [Boolean] forces the display of the success banner, used
    #  on the cookie page
    def initialize(show_success: false)
      super()
      @show_success = show_success || false
    end
  end
end
