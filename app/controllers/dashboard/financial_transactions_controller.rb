# frozen_string_literal: true

module Dashboard
  # FinancialTransactionsController handles all the financial transaction and related financial transaction with it
  class FinancialTransactionsController < ApplicationController
    # This processes what financial transaction to list down in the index page.
    # It shows all of the financial transaction that are linked to logged in account
    # of the financial transaction chain.
    def index
      @transaction_filter = FinancialTransactionFilter.new(FinancialTransactionFilter.params(params))
      @transactions, @pagination_collection =
        FinancialTransaction.list_all_transactions(current_user, @transaction_filter, params[:page])
      # Determines when the find functionality is executed in index page of financial transactions
      @on_filter_find = !params[:dashboard_financial_transaction_filter].nil?
    end

    # This processes the related financial transaction to find which should have been chosen from the index page.
    # The id is used to list down all the related financial transaction and the details of itself.
    def show
      @financial_transaction = FinancialTransaction.find(current_user, params[:id])
      @related_transactions = @financial_transaction.related_transactions.values
    end
  end
end
