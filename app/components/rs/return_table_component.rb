# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a table of dashboard returns from {Dashboard::DashboardReturn} in one of two formats
  # Dashboard returns are a cut down version model for the full return
  class ReturnTableComponent < ViewComponent::Base
    include DS::ComponentHelpers
    include Core::ListValidator

    # Format of the returns draft is a reduced set of columns
    ALLOWED_FORMATS = %i[returns draft].freeze
    # allows list of links to show
    ALLOWED_LINKS = %i[all_returns all_transactions none].freeze

    attr_reader :returns, :caption, :show_link, :id, :link, :small_screen, :pagination_collection, :page_name, :format

    # @param returns [Array] The array of returns
    # @param caption [String] The caption to use on the table
    # @param id [String] The id of the table used for anchoring
    # @param show_link [Symbol] Show the all returns or all transactions link
    # @param small_screen [Symbol] How to display the table on a small screen
    # @param pagination_collection [Object] The pagination information used to render a pagination collection
    # @param page_name [String] The identifier used for paging the correct region on the page
    # @param format [Symbol] Are we rendering the returns as a draft list or normal
    def initialize(returns:, caption:, id:, show_link: :none, small_screen: nil, pagination_collection: nil,
                   page_name: nil, format: :returns)
      super()

      @returns = returns
      @caption = caption
      @id = id
      @show_link = self.class.fetch_or_fallback(ALLOWED_LINKS, show_link, :none)
      @small_screen = small_screen
      @pagination_collection = pagination_collection
      @page_name = page_name
      @format = self.class.fetch_or_fallback(ALLOWED_FORMATS, format, :returns)
    end

    # Only render the table if the user has VIEW_RETURNS
    def render?
      return true if can?(RS::AuthorisationHelper::VIEW_RETURNS)

      false
    end

    delegate :can?, to: :helpers
  end
end
