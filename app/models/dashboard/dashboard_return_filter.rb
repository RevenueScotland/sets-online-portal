# frozen_string_literal: true

module Dashboard
  # Models the dashboard return filter to be used by showing what the user wants.
  class DashboardReturnFilter < BaseFilter
    # Attributes for this class, in list so can re-use as permitted params list in the controller.
    # The attributes all_versions, draft_only and outstanding_balance are all boolean values.
    def self.attribute_list
      %i[tare_reference return_date return_status
         all_versions draft_only outstanding_balance
         description from_return_date to_return_date]
    end

    # Fields that can be set on a financial transaction filter
    attribute_list.each { |attr| attr_accessor attr }

    validates :tare_reference, length: { maximum: 30 }
    validates :description, length: { maximum: 255 }

    validate :all_dates_valid?

    # Provides permitted filter request params
    def self.params(params)
      params.permit(dashboard_dashboard_return_filter:
        %i[tare_reference return_date return_status all_versions
           description from_return_date to_return_date])[:dashboard_dashboard_return_filter]
    end

    # Validation for each of the dates in the all returns page to check if they're all in the correct format
    # and also check that the from date is before the to date
    def all_dates_valid?
      date_format_valid? :return_date unless return_date.blank?
      date_format_valid? :from_return_date unless from_return_date.blank?
      date_format_valid? :to_return_date unless to_return_date.blank?
      date_start_before_end? :from_return_date, :to_return_date
    end

    # Sets the value of all_versions to a boolean value.
    def all_versions
      ['true', true].include?(@all_versions)
    end
  end
end
