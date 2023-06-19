# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a table for the various LBTT parties for the LBTT summary page
  class PartyTableComponent < ViewComponent::Base
    include DS::ComponentHelpers
    include Core::ListValidator

    attr_reader :parties, :party_type, :id, :small_screen

    # @param parties [Array] The array of parties
    # @param party_type [Symbol] The party_type being rendered (used for messages and links)
    # @param id [String] The id of the table used for anchoring
    # @param small_screen [Symbol] How to display the table on a small screen
    def initialize(parties:, party_type:, id: nil, small_screen: 'scrolling')
      super()

      @parties = parties
      @party_type = party_type
      @id = id
      @small_screen = small_screen
    end
  end
end
