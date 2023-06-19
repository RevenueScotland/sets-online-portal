# frozen_string_literal: true

# Main handling all of the DS functions to support an application
module RS
  # Inset Component
  #
  # If the inset component is conditionally visible then the stimulus data tags for the
  # visibility controller are added
  #
  # Based on Digital Scotland Pattern {https://designsystem.gov.scot/components/inset-text/}
  class ConditionalVisibilityComponent < ViewComponent::Base
    include DS::ComponentHelpers

    attr_reader :visible_value

    renders_one :visibility_control, types: {
      radio_group: lambda { |**args|
        DS::RadioGroupComponent.new(conditional_visibility: true, **args)
      },
      checkbox_group: lambda { |**args|
        DS::CheckboxGroupComponent.new(conditional_visibility: true, **args)
      }
    }

    # @param visible_value [String] The value of the control that makes the region visible
    def initialize(visible_value:)
      super()
      @visible_value = visible_value
    end
  end
end
