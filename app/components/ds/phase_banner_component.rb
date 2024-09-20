# frozen_string_literal: true

# DS specific parts of the UI
module DS
  # Back to top component that floats at the end of the page
  # see {https://designsystem.gov.scot/components/phase-banner}
  class PhaseBannerComponent < ViewComponent::Base
    attr_reader :banner_tag_text, :banner_text

    # @param banner_tag_text [String] The text to be shown in the phase
    # @param banner_text [String] The text to be shown in the main part of the banner
    def initialize(banner_tag_text:, banner_text:)
      super()
      @banner_tag_text = banner_tag_text
      @banner_text = banner_text
    end
  end
end
