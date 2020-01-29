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
         effective_date effective_date_from effective_date_to]
    end

    # Fields that can be set on a financial transaction filter
    attribute_list.each { |attr| attr_accessor attr }

    validates :related_reference, length: { maximum: 30 }
    validates :actual_date, :actual_date_from, :actual_date_to, :effective_date, :effective_date_from,
              :effective_date_to, custom_date: true
    validates :effective_date_from, compare_date: { end_date_attr: :effective_date_to }
    validates :actual_date_from, compare_date: { end_date_attr: :actual_date_to }

    # validates all the attributes that are currency data-types
    validates :amount, :minimum_amount, :maximum_amount,
              format: { with: /(?=.*?\d)\A-?(([1-9]\d{0,2}(,\d{3})*)|\d+)?(\.\d{1,2})?\z/ },
              allow_blank: true, length: { maximum: 20 }, allow_nil: true, two_dp_pattern: true

    # Provides permitted filter request params
    def self.params(params)
      params.permit(dashboard_financial_transaction_filter:
        %i[related_reference
           minimum_amount maximum_amount amount
           actual_date actual_date_from actual_date_to
           effective_date effective_date_from effective_date_to])[:dashboard_financial_transaction_filter]
    end

    # Custom override setter for include_outstanding_only to default of false if it's not been set.
    def include_outstanding_only
      @include_outstanding_only || false
    end

    # Custom override setter for exclude_transfers to default of false if it's not been set.
    def exclude_transfers
      @exclude_transfers || false
    end

    # Custom override setter for exclude_holds to default of false if it's not been set.
    def exclude_holds
      @exclude_holds || false
    end

    # Custom override setter for actual_date_to to make sure that if an exact date is to be checked,
    # then it will populate the actual_date_to (and date_from, on its own method) as a search for both
    # a date range and an exact date filtering cannot be done.
    def actual_date_to
      return @actual_date unless @actual_date.blank?

      @actual_date_to
    end

    # Custom override setter for actual_date_from to make sure that if an exact date is to be checked,
    # then it will populate the actual_date_from (and date_to, on its own method) as a search for both
    # a date range and an exact date filtering cannot be done.
    def actual_date_from
      return @actual_date unless @actual_date.blank?

      @actual_date_from
    end

    # Custom override setter for effective_date_to to make sure that if an exact date is to be checked,
    # then it will populate the effective date to (and date from, on its own method) as a search for both
    # a date range and an exact date filtering cannot be done.
    def effective_date_to
      return @effective_date unless @effective_date.blank?

      @effective_date_to
    end

    # Custom override setter for effective_date_from to make sure that if an exact date is to be checked,
    # then it will populate the effective date from (and date to, on its own method) as a search for both
    # a date range and an exact date filtering cannot be done.
    def effective_date_from
      return @effective_date unless @effective_date.blank?

      @effective_date_from
    end

    # Custom override setter for maximum_amount to make sure that if an exact amount is to be checked,
    # it will populate the maximum (and minimum) amount as it makes sense this way.
    # This is also the only way to request for the exact amount.
    # @return [String] the maximum amount or the amount.
    def maximum_amount
      return @amount unless @amount.blank?

      @maximum_amount
    end

    # Custom override setter for minimum_amount to make sure that if an exact amount is to be checked,
    # it will populate the minimum (and maximum) amount as it makes sense this way.
    # This is also the only way to request for the exact amount.
    # @return [String] the minimum amount or the amount.
    def minimum_amount
      return @amount unless @amount.blank?

      @minimum_amount
    end
  end
end
