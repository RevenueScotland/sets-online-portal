# frozen_string_literal: true

# Concerns for returns
module Returns
  # Helpful methods common to LBTT controllers.
  module LbttControllerFilterParamsHelper
    extend ActiveSupport::Concern

    # Return the parameter list filtered for the attributes of the LbttReturn model
    def filter_params(_sub_object_attribute = nil)
      required = :returns_lbtt_lbtt_return
      attribute_list = Lbtt::LbttReturn.attribute_list

      # Rubocop disable added as this breaks the functionality
      # https://github.com/rubocop/rubocop-rails/issues/1418
      params.require(required).permit(attribute_list) if params[required] # rubocop:disable Rails/StrongParametersExpect
    end
  end
end
