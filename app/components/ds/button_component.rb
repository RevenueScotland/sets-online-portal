# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # see {Core::ButtonComponent}
  class ButtonComponent < Core::ButtonComponent
    # see {Core::ButtonComponent}
    # @param fixed [Boolean] is the width of the button fixed
    # @param extra_classes [String] Extra classes to add to the button, for example to change the borders
    # see {https://designsystem.gov.scot/components/button}
    def initialize(name: nil, type: :primary, url: nil, data_options: {}, fixed: true, extra_classes: nil)
      super(name: name, type: type, url: url, extra_classes: extra_classes, data_options: data_options)
      @fixed = fixed
    end

    # Returns specific Digital Scotland classes based on the button type
    def ds_classes
      type_class = case @type
                   when :secondary
                     ' ds_button--secondary'
                   when :cancel
                     ' ds_button--cancel'
                   end
      fixed_class = (@fixed ? ' ds_button--fixed' : nil)
      "ds_button#{type_class}#{fixed_class} #{extra_classes}"
    end
  end
end
