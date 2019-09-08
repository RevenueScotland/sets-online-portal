# frozen_string_literal: true

# Concerns for returns
module Returns
  # Helpful methods common to LBTTT controllers.
  module LbttControllerHelper
    extend ActiveSupport::Concern

    # Return the parameter list filtered for the attributes of the LbttReturn model
    def filter_params
      required = :returns_lbtt_lbtt_return
      attribute_list = Lbtt::LbttReturn.attribute_list

      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
