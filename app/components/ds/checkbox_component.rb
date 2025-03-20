# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # This supports those occasions where you only have one toggle checkbox, this is unusual mostly you would have a
  # group. The use case for this is normally around declarations
  # see {https://designsystem.gov.scot/components/checkboxes}
  class CheckboxComponent < Core::CheckboxComponent
    # see {Core::CheckboxComponent#initialize}
    def initialize(builder:, method:, readonly: false, one_question: false, interpolations: {},
                   checked_value: 'Y', unchecked_value: 'N')
      super
    end
  end
end
