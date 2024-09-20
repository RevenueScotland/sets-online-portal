# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Defines a base Core button component with standard attributes
  # This is normally used for links as button
  class ButtonComponent < ViewComponent::Base
    include ListValidator

    attr_reader :name, :type, :url, :extra_classes, :data_options

    # List of allowed button types
    ALLOWED_TYPES = %i[primary secondary cancel hidden].freeze

    # @param name [String] the name to appear on the button. This will default to continue
    # @param type [Symbol] the type of button
    # @param url [Path] the target (link) for the button
    # @param extra_classes [String] Extra classes to add to the button, for example to change the borders
    # @param data_options [Hash] A hash of one or more data options to add to the field, used for stimulus
    def initialize(name: nil, type: :primary, url: nil, extra_classes: nil, data_options: {})
      super()
      @name = name || :continue
      @type = self.class.fetch_or_fallback(ALLOWED_TYPES, type, :primary)
      @url = url
      @extra_classes = extra_classes
      @data_options = data_options.transform_keys { |k| "data-#{k}" }
    end

    # Translate the symbol to a proper name using the current component context
    def before_render
      @name = (@name.is_a?(Symbol) ? t(".#{@name}") : @name)
    end
  end
end
