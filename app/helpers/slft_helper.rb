# frozen_string_literal: true

# This is where most of the methods helper related to the slft will be placed
module SlftHelper
  # This is used for the waste_description page, modifies the query and id of the url
  def slft_waste_description_url(link_path)
    # Removes all the query strings and id of the path.
    remove_id_and_all_query(link_path, 'waste_description')
  end
end
