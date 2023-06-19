# frozen_string_literal: true

# Main handling all of the DS functions to support an application
module DS
  # Inset Component
  #
  # If the inset component is conditionally visible then the stimulus data tags for the
  # visibility controller are added
  #
  # Based on Digital Scotland Pattern {https://designsystem.gov.scot/components/inset-text/}
  class InsetTextComponent < ViewComponent::Base
    attr_reader :conditional_visibility

    # @param conditional_visibility [Boolean] Is the inset region visible conditionally
    def initialize(conditional_visibility: false)
      super()
      @conditional_visibility = conditional_visibility
    end
  end
end
