# frozen_string_literal: true

# RS specific UI code
module RS
  # Adds helpers to the standard rails helpers to allow digital scotland components to be used in the
  # template file using rs_<name> rather than the full render command.
  # There is an equivalent that adds into a specific view component if needed
  # @see DS::ComponentHelpers
  module ViewComponentsHelper
    RS::ComponentHelpers::COMPONENT_LIST.merge(RS::ComponentHelpers::FORM_COMPONENT_LIST).each do |name, klass|
      define_method(name) do |*args, **kwargs, &block|
        capture do
          render(klass.constantize.new(*args, **kwargs)) do |com|
            block.call(com) if block.present?
          end
        end
      end
    end
  end
end
