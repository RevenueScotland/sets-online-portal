# frozen_string_literal: true

module Dashboard
  # Models the financial transaction filter to be used by in the financial transaction page
  class FinancialTransactionFilter < BaseFilter
    # Attributes for this class, in list so can re-use as permitted params list in the controller
    def self.attribute_list
      %i[transaction_reference
         include_outstanding_only exclude_transfers exclude_holds
         customer_reference transaction_type transaction_type_group related_reference
         amount minimum_amount maximum_amount
         actual_date actual_date_from actual_date_to
         effective_date effective_date_from effective_date_to my_returns_transactions_only
         return_type trans_sort_by srv_code]
    end

    # Fields that can be set on a financial transaction filter
    attribute_list.each { |attr| attr_accessor attr }

    # For each of the numeric fields create a setter, don't do this if there is already a setter
    strip_attributes :amount, :minimum_amount, :maximum_amount

    validates :related_reference, length: { maximum: 30 }
    validates :actual_date, :actual_date_from, :actual_date_to, :effective_date, :effective_date_from,
              :effective_date_to, custom_date: true
    validates :effective_date_from, compare_date: { end_date_attr: :effective_date_to }
    validates :actual_date_from, compare_date: { end_date_attr: :actual_date_to }

    # validates all the attributes that are currency data-types
    validates :amount, :minimum_amount, :maximum_amount,
              numericality: { greater_than: -1_000_000_000_000_000_000,
                              less_than: 1_000_000_000_000_000_000,
                              allow_blank: true },
              two_dp_pattern: true

    # Provides permitted filter request params
    def self.params(params)
      params.fetch(:dashboard_financial_transaction_filter, {}).permit(
        :related_reference, :minimum_amount, :maximum_amount, :amount,
        :actual_date, :actual_date_from, :actual_date_to,
        :effective_date, :effective_date_from, :effective_date_to,
        :my_returns_transactions_only, :include_outstanding_only,
        :return_type, :transaction_type_group, :trans_sort_by, :srv_code
      )
    end

    # Define the ref data codes associated with the attributes to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def cached_ref_data_codes
      { trans_sort_by: comp_key('TRANSACTIONS_SORT', 'SYS', 'RSTU'),
        return_type: comp_key('ALL RETURN TYPE', srv_code, 'RSTU'),
        transaction_group: comp_key('TRANSACTION GROUPS TEXT', srv_code, 'RSTU') }
    end

    # Financial transaction filter elements to be passed onto backoffice calls
    # in order to retrieve more specific data
    def request_elements
      { includeOutstandingOnly: include_outstanding_only?,
        excludeTransfers: exclude_transfers,
        excludeHolds: exclude_holds }
        .merge(request_optional_elements)
        .merge(request_date_elements)
    end

    private

    # Custom override setter for include_outstanding_only to default of false if it's not been set.
    def include_outstanding_only?
      include_outstanding_only == 'Y'
    end

    # Custom override setter for exclude_transfers to default of false if it's not been set.
    def exclude_transfers
      @exclude_transfers || false
    end

    # Custom override setter for exclude_holds to default of false if it's not been set.
    def exclude_holds
      @exclude_holds || false
    end

    # Custom override setter for my_returns_transactions to default of false if it's not been set.
    def my_returns_transactions_only?
      my_returns_transactions_only == 'Y'
    end

    # Filter optional elements
    def request_optional_elements
      { TransactionReference: transaction_reference,
        CustomerReference: customer_reference, TransactionType: transaction_type,
        TransactionTypeGroup: transaction_type_group, RelatedReference: related_reference,
        MinimumAmount: amount.presence || minimum_amount,
        MaximumAmount: amount.presence || maximum_amount,
        TransactionsForMyReferencesOnly: my_returns_transactions_only?,
        RelatedReferenceType: return_type,
        SortBy: trans_sort_by }
    end

    # Filter optional date elements
    def request_date_elements
      { ActualDateFrom: DateFormatting.to_xml_date_format(actual_date.presence || actual_date_from),
        ActualDateTo: DateFormatting.to_xml_date_format(actual_date.presence || actual_date_to),
        EffectiveDateFrom: DateFormatting.to_xml_date_format(effective_date.presence || effective_date_from),
        EffectiveDateTo: DateFormatting.to_xml_date_format(effective_date.presence || effective_date_to) }
    end
  end
end
