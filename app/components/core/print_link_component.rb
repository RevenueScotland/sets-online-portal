# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Builds a print link
  class PrintLinkComponent < ViewComponent::Base
    attr_reader :name

    # @param name [String] the name to show on the link
    def initialize(name:)
      super()
      @name = name
    end
  end
end
