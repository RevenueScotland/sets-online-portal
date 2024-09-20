# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a table for the various LBTT parties for the LBTT summary page
  class PartyTableComponent < ViewComponent::Base
    include DS::ComponentHelpers
    include Core::ListValidator

    attr_reader :parties, :party_type, :id, :small_screen, :hide_link, :hide_delete_link

    # @param parties [Array] The array of parties
    # @param party_type [Symbol] The party_type being rendered (used for messages and links)
    # @param id [String] The id of the table used for anchoring
    # @param small_screen [Symbol] How to display the table on a small screen
    # @param hide_link [Boolean] Hide the add or edit link on the right of the title
    # @param hide_delete_link [Boolean] Hide the delete link for the rows of the table
    def initialize(parties:, party_type:, id: nil, small_screen: 'scrolling', hide_link: false, hide_delete_link: false)
      super()

      @parties = parties
      @party_type = party_type
      @id = id
      @small_screen = small_screen
      @hide_link = hide_link
      @hide_delete_link = hide_delete_link
    end
  end
end
