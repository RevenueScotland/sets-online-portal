# frozen_string_literal: true

# Main handling all of the core functions to support an application
module RS
  # Percent field, based on the DS currency component
  # see {https://designsystem.gov.scot/components/text-input}
  # see {DS::BaseFieldComponent}
  class PercentComponent < DS::BaseFieldComponent
    # Override the default width for currency fields
    def initialize(**args)
      args[:width] = 10 # Hard code to 10 otherwise CSS positioning doesn't work
      super(**args)
    end
  end
end
