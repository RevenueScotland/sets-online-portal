# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Currency field
  # see {https://designsystem.gov.scot/components/text-input}
  # see {BaseFieldComponent}
  class CurrencyComponent < BaseFieldComponent
    # Override the default width for currency fields
    def initialize(**args)
      args[:width] = args[:width] || 20
      super(**args)
    end
  end
end
