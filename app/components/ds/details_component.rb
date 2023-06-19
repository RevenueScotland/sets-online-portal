# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Details Component
  # Based on GDS Pattern {https://design-system.service.gov.uk/components/details/}
  # On Digital Scotland backlog {https://designsystem.gov.scot/backlog/}
  class DetailsComponent < ViewComponent::Base
    attr_reader :header

    def initialize(header:)
      super()
      @header = header
    end
  end
end
