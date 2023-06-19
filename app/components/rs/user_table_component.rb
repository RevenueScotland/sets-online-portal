# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a table of users from {User} in one format
  class UserTableComponent < ViewComponent::Base
    include DS::ComponentHelpers
    include Core::ListValidator

    # Format of the returns draft is a reduced set of columns

    attr_reader :users, :caption, :region_name, :id, :link, :small_screen, :pagination_collection, :page_name, :format

    # @param users [Array] The array of user
    # @param caption [String] The caption to use on the table
    # @param id [String] The id of the table used for anchoring
    # @param link [HTML] A link to display below the tables, used for e.g. linking to all messages
    # @param small_screen [Symbol] How to display the table on a small screen
    # @param pagination_collection [Object] The pagination information used to render a pagination collection
    # @param page_name [String] The identifier used for paging the correct region on the page
    def initialize(users:, caption:, id:, link: nil, small_screen: nil, pagination_collection: nil, page_name: nil)
      super()

      @users = users
      @region_name = caption
      @caption = tag.h2(caption, class: 'ds_!_margin-bottom--0')
      @id = id
      @link = link
      @small_screen = small_screen
      @pagination_collection = pagination_collection
      @page_name = page_name
    end

    # Only render the table if the user has VIEW_ACCOUNTS
    def render?
      return true if can?(RS::AuthorisationHelper::VIEW_ACCOUNTS)

      false
    end

    delegate :can?, to: :helpers
  end
end
