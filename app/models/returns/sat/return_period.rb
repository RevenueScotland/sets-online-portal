# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise SAT return models
  module Sat
    # Model for the SAT return
    class ReturnPeriod < FLApplicationRecord
      # Attributes for this class, in list so can re-use
      def self.attribute_list
        %i[trs_refno period_start period_end sites enrm_par_ref]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # Maps the backoffice data to the data hash
      def self.map_bo_hash(body, data_hash)
        # we convert the period breakdowns into sites to flatten it
        data_hash[:sites] = convert_period_breakdowns(data_hash.delete(:period_breakdowns))
        data_hash[:enrm_par_ref] = body[:enrm_par_ref]
        new_from_fl(data_hash)
      end

      # Calls the back office and returns the site and period data
      # makes the call to the bo and returns an array of the tax return schedule models
      # @param user  [User] user to check
      # returns The back office (sites) data for the selected period
      def self.all(user)
        output = []

        call_params = { EnrmRefno: user.portal_object_reference, PartyRef: user.party_refno, Username: user.username }
        call_ok?(:get_return_periods_and_sites, call_params) do |body|
          # if no data is returned from the back office then exit here
          # this is catered for in sat_return.user_periods
          return nil if body.blank?

          ServiceClient.iterate_element(body[:return_periods]) do |data_hash|
            output << map_bo_hash(body, data_hash)
          end
        end
        output
      end

      # converts the bo hash for the period breakdowns
      # returns sites hash returns a index hash of period objects
      def self.convert_period_breakdowns(period_breakdowns) # call from above # rubocop:disable Metrics/MethodLength
        sites = {}

        ServiceClient.iterate_element(period_breakdowns) do |period_data|
          ServiceClient.iterate_element(period_data[:sites]) do |site_data|
            %i[period_bdown_start period_bdown_end rate_date].each do |key|
              site_data[key] = period_data[key]
            end
            site = Sat::Sites.new_from_fl(site_data)
            # Using UUID as the reference as the site can be in the hash multiple times
            # in different combinations as a result the site refno is not unique in this hash
            sites[SecureRandom.uuid] = site
          end
        end

        sites
      end
    end
  end
end
