# frozen_string_literal: true

module Returns
  module Slft
    # SLfT returns contain site specific information.  There can be multiple sites per return
    # (the largest operator currently has 7 sites).
    class Site < FLApplicationRecord
      include AccountBasedCaching
      include PrintData

      # Attributes for this class, in list so can re-use
      def self.attribute_list
        %i[lasi_refno site_name wastes]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :site,
           name: { code: :site_name }, # as we are passing in a name then send in the name
           page_break: true,
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list,
           list_items: [{ code: :net_standard_tonnage, key_scope: %i[returns slft site_summary_table] },
                        { code: :net_lower_tonnage, key_scope: %i[returns slft site_summary_table] },
                        { code: :exempt_tonnage, key_scope: %i[returns slft site_summary_table] },
                        { code: :total_tonnage, key_scope: %i[returns slft site_summary_table] }] },
         { code: :wastes,
           type: :table }]
      end

      # Work out the lower_tonnage based on the waste entries
      def net_lower_tonnage
        sum_from_values(wastes, :net_lower_tonnage).to_i
      end

      # Work out the standard_tonnage based on the waste entries
      def net_standard_tonnage
        sum_from_values(wastes, :net_standard_tonnage).to_i
      end

      # Work out the standard_tonnage based on the waste entries
      def exempt_tonnage
        sum_from_values(wastes, :exempt_tonnage).to_i
      end

      # Work out the standard_tonnage based on the waste entries
      def total_tonnage
        sum_from_values(wastes, :total_tonnage).to_i
      end

      # override string output to help with debugging.
      def to_s
        "Site:#{lasi_refno} (#{site_name}) has waste entries : #{wastes}"
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        # doesn't include '@total_tonnage as that's always derived
        output = { 'ins1:SiteName': @site_name, 'ins1:LASIRefno': @lasi_refno,
                   'ins1:TotalLowerTonnage': net_lower_tonnage, 'ins1:TotalStandardTonnage': net_standard_tonnage,
                   'ins1:TotalExemptTonnage': sum_from_values(wastes, :exempt_tonnage).to_i,
                   'ins1:TotalWaterTonnage': sum_from_values(wastes, :water_tonnage).to_i }

        # don't include wastes section if there's no wastes data
        return output if wastes.blank?

        output['ins1:SiteSpecificWastes'] = { 'ins1:SiteSpecificWaste': wastes.values.map(&:request_save) }
        output
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_calc
        { 'ins1:SiteID': @lasi_refno,
          'ins1:StandardTonnage': net_standard_tonnage,
          'ins1:LowerTonnage': net_lower_tonnage }
      end

      # Create a new instance based on a back office style hash (@see SlftReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(raw_hash)
        # strip out attributes we don't want yet
        delete = %i[total_lower_tonnage total_standard_tonnage total_exempt_tonnage total_water_tonnage total]
        delete.each { |key| raw_hash.delete(key) }

        # convert wastes data to Waste objects hashed by EWC_Code (and rename incomming XML's redundant
        # name for this section).
        raw_hash[:wastes] = convert_wastes(raw_hash.delete(:site_specific_wastes))

        # Create new instance
        Site.new_from_fl(raw_hash)
      end

      # @!method self.convert_wastes(site_specific_wastes)
      # Convert the wastes data (raw hash) into Waste objects hashed by EWC_CODE.
      # @param site_specific_wastes [Hash] the back office data
      # @return [Hash] Wastes objects indexed by the waste's ewc_codes (or else an empty hash if parameter was blank)
      private_class_method def self.convert_wastes(site_specific_wastes)
        return {} if site_specific_wastes.blank?

        # if there's only 1 it doesn't put it into an array which the next part expects, so put it into an array
        raw_waste = site_specific_wastes[:site_specific_waste]
        raw_waste = [raw_waste] if raw_waste.is_a?(Hash)

        output = {}
        raw_waste.each do |raw_hash|
          # don't attempt to create Waste object with an empty hash
          continue if raw_hash.blank?

          waste = Waste.convert_back_office_hash(raw_hash)
          output[waste.uuid] = waste
        end

        output
      end

      private

      # @!method self.back_office_data(requested_by)
      # Gets users sites data from the back office for the account of the given user.
      # @param requested_by [User] is usually the current_user, who is requesting the data
      # @note return list of sites for the account
      private_class_method def self.back_office_data(requested_by)
        sites = []
        request = { ParRefno: requested_by.party_refno, Username: requested_by.username }
        call_ok?(:get_sites, request) do |body|
          return sites if sites_response_empty?(body, request)

          # use service client to make sure the singleton hash is turned into an array
          ServiceClient.iterate_element(body[:slft_sites]) do |data|
            # Only interested in the id and name from the site ref data
            site = new(lasi_refno: data[:lasi_refno].to_i, site_name: data[:site_name], wastes: {})
            sites << site
          end
        end
        sites
      end

      # @return true if the back office response didn't contain slft_sites (ie no sites exist for ParRefno).
      private_class_method def self.sites_response_empty?(body, request)
        if body[:slft_sites].nil?
          Rails.logger.debug("No sites returned for #{request}")
          return true
        end

        false
      end
    end
  end
end
