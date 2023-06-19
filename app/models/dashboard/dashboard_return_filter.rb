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

    strip_attributes :tare_reference, :agent_reference

    validates :tare_reference, length: { maximum: 30 }
    validates :agent_reference, length: { maximum: 30 }
    validates :description, length: { maximum: 255 }
    validates :from_return_date, :to_return_date, custom_date: true
    validates :from_return_date, compare_date: { end_date_attr: :to_return_date }

    # @param attributes [Hash] a hash of objects that uses Active model
    def initialize(attributes = {})
      super
      # Default the all returns and draft only as the back office always expects these to be set
      @all_versions ||= 'N'
      @draft_only ||= 'N'
    end

    # Define the ref data codes associated with the attributes not to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def uncached_ref_data_codes
      { all_versions: YESNO_COMP_KEY,
        outstanding_balance: YESNO_COMP_KEY,
        draft_only: YESNO_COMP_KEY }
    end

    # Provides permitted filter request params
    def self.params(params)
      params.fetch(:dashboard_dashboard_return_filter, {}).permit(
        :tare_reference, :agent_reference, :return_status, :all_versions, :description,
        :from_return_date, :to_return_date
      )
    end
  end
end
