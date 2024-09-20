# frozen_string_literal: true

module Dashboard
  # FinancialTransactionsController handles all the financial transaction and related financial transaction with it
  class FinancialTransactionsController < ApplicationController
    # This processes what financial transaction to list down in the index page.
    # It shows all of the financial transaction that are linked to logged in account
    # of the financial transaction chain.
    def index
      @transaction_filter = FinancialTransactionFilter.new(FinancialTransactionFilter.params(params))

      # Determines when the find functionality is executed in index page of financial transactions
      @on_filter_find = !params[:find].nil?

      # Setting default values only when Find button is not clicked
      default_filter(@transaction_filter) unless @on_filter_find

      # Call to BO is not needed as search is not performed
      return unless @on_filter_find || !@transaction_filter.related_reference.nil?

      @transactions, @pagination_collection =
        FinancialTransaction.list_all_transactions(current_user, @transaction_filter, params[:page])
    end

    # Set default filter values for transactions search
    def default_filter(filter)
      # No need to set default values when it is called with related reference
      return unless filter.related_reference.nil?

      filter.include_outstanding_only = 'Y'
      filter.my_returns_transactions_only = 'Y' if filter.srv_code == 'LBTT'
      filter.return_type = 'SLFTRETURN' if filter.srv_code == 'SLFT'
      filter.trans_sort_by = 'MostRecent'
    end

    # This processes the related financial transaction to find which should have been chosen from the index page.
    # The id is used to list down all the related financial transaction and the details of itself.
    def show
      @financial_transaction = FinancialTransaction.find(current_user, params[:id])
      @related_transactions = @financial_transaction.related_transactions.values
    end
  end
end
