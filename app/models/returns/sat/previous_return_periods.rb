# frozen_string_literal: true

# module to organise sat return models
module Returns
  # module to organise SAT return models
  module Sat
    # Model for the SAT return
    class PreviousReturnPeriods < FLApplicationRecord
      # Attributes for this class, in list so can re-use
      def self.attribute_list
        %i[tare_refno tare_reference trs_refno trs_strp_refno srpb_refno srpb_start_date srpb_end_date]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # converts the selected period dates back to a user readable value
      # @return [String] The dates in a user readable value
      def return_period_date_format
        # Need to format the date to show dd/mm/yy else the date will show as yyyy-mm-dd
        start_date = DateFormatting.to_display_date_format(@srpb_start_date)
        end_date = DateFormatting.to_display_date_format(@srpb_end_date)

        "#{start_date} to #{end_date}"
      end

      # use to display the values of select list
      # @return [String] date formats along with return reference
      def previous_return_period_display
        # Need to format the date to show dd/mm/yy else the date will show as yyyy-mm-dd
        start_date = DateFormatting.to_display_date_format(@srpb_start_date)
        end_date = DateFormatting.to_display_date_format(@srpb_end_date)

        "#{tare_reference} - #{start_date} to #{end_date}"
      end

      # Calls the back office and returns the previously submitted returns with periods
      # makes the call to the bo and returns an array of the previously submitted returns
      # @param user  [User] user to check
      # @param start_date [String] current period start date
      # returns The back office (previous returns) data for the selected enrolment
      def self.all(user, start_date)
        output = []

        call_params = { Username: user.username, ParRefno: user.party_refno, Service: 'SAT',
                        EnrmRefno: user.portal_object_reference, PeriodStart: start_date }
        call_ok?(:get_previous_return_breakdown_periods, call_params) do |body|
          # if no data is returned from the back office then exit here
          return nil if body.blank?

          ServiceClient.iterate_element(body[:return_periods]) do |data_hash|
            output << new_from_fl(data_hash)
          end
        end
        output
      end
    end
  end
end
