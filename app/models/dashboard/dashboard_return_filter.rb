# frozen_string_literal: true

module Dashboard
  # Models the dashboard return filter to be used by showing what the user wants.
  class DashboardReturnFilter < BaseFilter
    # Attributes for this class, in list so can re-use as permitted params list in the controller.
    # The attributes all_versions, draft_only and outstanding_balance are all boolean values.
    def self.attribute_list
      %i[tare_reference agent_reference return_status
         all_versions draft_only outstanding_balance
         description from_return_date to_return_date]
    end

    # Fields that can be set on a financial transaction filter
    attribute_list.each { |attr| attr_accessor attr }

    validates :tare_reference, length: { maximum: 30 }
    validates :agent_reference, length: { maximum: 30 }
    validates :description, length: { maximum: 255 }
    validates :from_return_date, :to_return_date, custom_date: true
    validates :from_return_date, compare_date: { end_date_attr: :to_return_date }

    # Define the ref data codes associated with the attributes not to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def uncached_ref_data_codes
      { all_versions: YESNO_COMP_KEY,
        outstanding_balance: YESNO_COMP_KEY,
        draft_only: YESNO_COMP_KEY }
    end

    # custom setter to trim spaces from reference
    def tare_reference=(value)
      @tare_reference = value.strip
    end

    # custom setter to trim spaces from reference
    def agent_reference=(value)
      @agent_reference = value.strip
    end

    # Provides permitted filter request params
    def self.params(params)
      params.permit(dashboard_dashboard_return_filter:
        %i[tare_reference agent_reference return_status all_versions
           description from_return_date to_return_date])[:dashboard_dashboard_return_filter]
    end
  end
end
