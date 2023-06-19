# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a table of messages from {Dashboard::Message}
  class MessageTableComponent < ViewComponent::Base
    include DS::ComponentHelpers

    attr_reader :messages, :caption, :id, :small_screen, :pagination_collection, :page_name

    # @param messages [Array] The array of messages
    # @param caption [String] The caption to use on the table
    # @param id [String] The id of the table used for anchoring
    # @param show_all_link [Boolean] Show the all messages link
    # @param small_screen [Symbol] How to display the table on a small screen
    # @param pagination_collection [Object] The pagination information used to render a pagination collection
    # @param page_name [String] The identifier used for paging the correct region on the page
    def initialize(messages:, caption:, id:, show_all_link: false, small_screen: nil, pagination_collection: nil,
                   page_name: nil)
      super()

      @messages = messages
      @caption = caption
      @id = id
      @show_all_link = show_all_link
      @small_screen = small_screen
      @pagination_collection = pagination_collection
      @page_name = page_name
    end

    # The region is only rendered if the user has VIEW_MESSAGES
    def render?
      return true if can?(RS::AuthorisationHelper::VIEW_MESSAGES)

      false
    end

    # Show the all link
    def show_all_link?
      @show_all_link
    end

    delegate :can?, to: :helpers
  end
end
