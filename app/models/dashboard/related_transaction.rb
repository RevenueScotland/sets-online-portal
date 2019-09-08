# frozen_string_literal: true

# The Related financial transaction that is part of the dashboard
module Dashboard
  # Models a Related financial transaction object
  class RelatedTransaction < FLApplicationRecord
    include NumberFormatting
    include Pagination
    attr_accessor :id, :transaction_reference, :parent_transaction_reference, :effective_date, :actual_date,
                  :description, :transaction_type_code, :transaction_type_group,
                  :matched_amount, :original_amount
  end
end
