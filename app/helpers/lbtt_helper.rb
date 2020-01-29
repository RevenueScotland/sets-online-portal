# frozen_string_literal: true

# This is where most of the methods helper related to the lbtt will be placed
module LbttHelper
  # Used for the agent details page, modifies the query of the url.
  def lbtt_agent_details_url(link_path)
    remove_params(link_path, ['party_id'])
  end

  # This is used for the about_the_party page, modifies the id and query of the url
  def lbtt_about_the_party_url(link_path)
    remove_id_and_all_query(link_path, 'about_the_party')
  end

  # This is used for the property_address page, modifies the id and query of the url
  # by removing property_id from it
  def lbtt_property_address_url(link_path)
    remove_id_and_all_query(link_path, 'property_address')
  end
end
