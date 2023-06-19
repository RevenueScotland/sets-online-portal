# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Renders a group of buttons
  # see {https://designsystem.gov.scot/components/button}
  class ButtonGroupComponent < ViewComponent::Base
    renders_many :buttons, DS::ButtonComponent
  end
end
