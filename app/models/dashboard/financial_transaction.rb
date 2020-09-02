# frozen_string_literal: true

# The financial transaction that is part of the dashboard
module Dashboard
  # Models a Financial transaction object
  class FinancialTransaction < FLApplicationRecord
    include NumberFormatting
    include Pagination

    # The below attributes are in the response from the back office but we don't use them
    # :reason, :type, :start, :end,
    # :reference_number, :process_id, :bacs_process,
    attr_accessor :transaction_reference, :customer_reference,
                  :related_reference, :related_sub_reference, :related_reference_type,
                  :transfer_indicator, :hold_indicator, :paid_by_dd,
                  :effective_date, :actual_date, :amount, :outstanding_balance,
                  :description, :transaction_type_code, :transaction_type_group,
                  :related_transactions

    # Looks for a specific financial transaction by its transaction reference.
    # @param requested_by [Object] is the user who is currently logged in and is requesting for the data.
    # @param transaction_ref [String] is the id of the transaction to be searched for.
    # return [Object] returns the financial transaction with the specified id.
    def self.find(requested_by, transaction_ref)
      list_all_transactions(requested_by, FinancialTransactionFilter.new(transaction_reference: transaction_ref))
    end

    # the to_param function needs to return the primary key and is used to build the links
    # @return [String] the escaped URL-encoded code
    def to_param
      CGI.escape(transaction_reference)
    end

    # Lists all the financial transactions, or a single financial transaction when the filter param consists of
    # filtering for transaction_reference.
    # @param requested_by [Object] is the user who is currently logged in and is requesting for the data.
    # @return [Hash||Object] a hash of financial transactions by their id with the correct pagination, or a single
    #   FinancialTransaction object ready to be used for related transactions page.
    def self.list_all_transactions(requested_by, filter, page = 1, num_rows = 10)
      # Initialise pagination is used for requesting with pagination from back office
      pagination = Pagination.initialise_pagination(num_rows, page)
      # Checks if the filter fields consists of valid data
      return unless filter.valid?

      all_transactions, back_office_pagination = back_office_data(requested_by, filter, pagination)
      all_transactions = all_transactions.values
      # Gets a single transaction for the related financial transactions page.
      # The way of doing the pagination in this method does not apply to it, therefor it doesn't need to be returned.
      return all_transactions[0] unless filter.transaction_reference.blank?

      # This completes the pagination as we get pagination data from the back office
      pagination = Pagination.paginate_back_office(pagination, back_office_pagination)

      [all_transactions, pagination]
    end

    # Gets the financial transaction data from the back office with it's related transaction data.
    # @return [Array] contains two values: a hash of transactions object with it's related transactions stored as
    #   a hash too in an attribute of the transactions object, second value contains the pagination all derived from
    #   the back office web service.
    private_class_method def self.back_office_data(requested_by, filter, pagination)
      transactions, pagination_return = {}
      call_ok?(:get_transactions, request_elements(requested_by, filter, pagination)) do |body|
        break if body.blank?

        pagination_return = body[:pagination]
        ServiceClient.iterate_element(body[:transactions]) do |transaction|
          # Stores the financial transaction object into a hash of transactions
          transactions[transaction[:transaction_reference]] = financial_transaction_object(transaction)
        end
      end
      [transactions, pagination_return]
    end

    # Creates a Financial transaction object according to the transaction data from the back office response.
    #
    # It also iterates through the related transactions of the financial transaction and stores it as a hash of objects
    # in the Financial transaction where it's derived from.
    # @return [Object] Financial transaction
    private_class_method def self.financial_transaction_object(transaction)
      object = FinancialTransaction.new_from_fl(convert_back_office_hash(transaction))
      # Empties the related transactions hash, so that the related transaction objects can be stored here
      object.related_transactions = {}
      ServiceClient.iterate_element(transaction[:related_transactions]) do |related_transaction|
        # Stores a hash of related transactions in to an attribute of the transaction object
        object.related_transactions[related_transaction[:transaction_reference]] =
          RelatedTransaction.new_from_fl(convert_back_office_hash(related_transaction))
      end
      object
    end

    # Flattens the back office financial transaction data and stores it in a hash. Also used for the related
    # financial transactions as they both have similar data.
    private_class_method def self.convert_back_office_hash(transaction)
      # separate output object so that back office changes won't break FL record loading
      output = {}
      output.merge!(transaction)
      output.delete(:direct_debit)

      move_to_root(output, :transaction_type)

      output
    end

    # The request elements to get data from the backoffice
    private_class_method def self.request_elements(requested_by, filter, pagination)
      { RequestUser: requested_by.username, ParRefno: requested_by.party_refno,
        includeOutstandingOnly: filter.include_outstanding_only, excludeTransfers: filter.exclude_transfers,
        excludeHolds: filter.exclude_holds }.merge(request_optional_elements(pagination, filter))
    end

    # These are the request elements which are optional but also used to get back office data
    private_class_method def self.request_optional_elements(pagination, filter)
      { Pagination: { 'ins1:StartRow' => pagination.start_row, 'ins1:NumRows' => pagination.num_rows },
        TransactionReference: filter.transaction_reference,
        CustomerReference: filter.customer_reference, TransactionType: filter.transaction_type,
        TransactionTypeGroup: filter.transaction_type_group, RelatedReference: filter.related_reference,
        MinimumAmount: filter.minimum_amount,
        MaximumAmount: filter.maximum_amount }.merge(request_date_elements(filter))
    end

    # These are the request elements for the date which are optional and used to specify the data
    # to be retrieved from back office
    private_class_method def self.request_date_elements(filter)
      { ActualDateFrom: DateFormatting.to_xml_date_format(filter.actual_date_from),
        ActualDateTo: DateFormatting.to_xml_date_format(filter.actual_date_to),
        EffectiveDateFrom: DateFormatting.to_xml_date_format(filter.effective_date_from),
        EffectiveDateTo: DateFormatting.to_xml_date_format(filter.effective_date_to) }
    end
  end
end
