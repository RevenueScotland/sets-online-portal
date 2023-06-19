# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # This provides a wrapper for delivering a fields for based on the component architecture.
  # It is really only used a place holder for the UI specific version which holds the helpers
  #
  class FieldsForComponent < ViewComponent::Base
    attr_reader :builder

    delegate :object, to: :builder

    # (see ApplicationComponent#initialize)
    # @param builder [FormBuilder] The current form builder being used
    def initialize(builder:)
      super()
      @builder = builder
    end
  end
end
