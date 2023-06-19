# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a table of financial transactions from {Dashboard::FinancialTransaction} in one of two formats
  class FinancialTransactionTableComponent < ViewComponent::Base
    include DS::ComponentHelpers
    include Core::ListValidator

    # Formats are used to reduce set of columns
    ALLOWED_FORMATS = %i[financial_transactions related_transaction].freeze

    attr_reader :financial_transactions, :caption, :id, :small_screen, :pagination_collection,
                :page_name, :format

    # @param financial_transactions [Array] The array of transactions
    # @param caption [String] The caption to use on the table
    # @param id [String] The id of the table used for anchoring
    # @param small_screen [Symbol] How to display the table on a small screen
    # @param pagination_collection [Object] The pagination information used to render a pagination collection
    # @param page_name [String] The identifier used for paging the correct region on the page
    # @param format [Symbol] Are we rendering the financial_transactions as a related_transactions or normal
    def initialize(financial_transactions:, caption:, id:, small_screen: nil,
                   pagination_collection: nil, page_name: nil, format: :financial_transactions)
      super()

      @financial_transactions = financial_transactions
      @caption = caption
      @id = id
      @small_screen = small_screen
      @pagination_collection = pagination_collection
      @page_name = page_name
      @format = self.class.fetch_or_fallback(ALLOWED_FORMATS, format, :financial_transactions)
    end

    # Only render the table if the user has VIEW_RETURNS
    def render?
      return true if can?(RS::AuthorisationHelper::VIEW_RETURNS)

      false
    end

    delegate :can?, to: :helpers
  end
end
