# frozen_string_literal: true

# This is where most of the methods helper related to the lbtt will be placed
module LbttHelper
  # This is used for the about_the_party page, modifies the query of the url
  def lbtt_about_the_party_url(link_path)
    remove_params(link_path, %w[party_id new])
  end

  # This is used for the property_address page, modifies the query of the url
  # by removing property_id from it
  def lbtt_property_address_url(link_path)
    remove_params(link_path, %w[property_id])
  end
end
