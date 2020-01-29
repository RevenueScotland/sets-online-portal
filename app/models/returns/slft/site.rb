# frozen_string_literal: true

module Returns
  module Slft
    # SLfT returns contain site specific information.  There can be multiple sites per return
    # (the largest operator currently has 7 sites).
    class Site < FLApplicationRecord
      include PrintData
      include CsvHelper

      # Attributes for this class, in list so can re-use
      def self.attribute_list
        %i[lasi_refno site_name wastes]
      end

      attribute_list.each { |attr| attr_accessor attr }

      def initialize(attributes = {})
        super
        # make sure we have an empty hash for wastes
        @wastes ||= {}
      end

      # Overrides the param value of the Site object.
      # Normally used as the :site value of the returns_slft_site_waste_summary_path.
      # @example How the to_param is being used when passed into a path, which
      #   should build '/en/returns/slft/site_waste_summary/97' :
      #   @site = Returns::Slft::Site.new(lasi_refno: '97' site_name: '' wastes: '')
      #   returns_slft_site_waste_summary_path(@site)
      def to_param
        @lasi_refno
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [{ code: :site,
           name: { code: :site_name }, # as we are passing in a name then send in the name
           page_break: true,
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list,
           list_items: [{ code: :net_standard_tonnage },
                        { code: :net_lower_tonnage },
                        { code: :exempt_tonnage },
                        { code: :total_tonnage }] }]
      end

      # Work out the lower_tonnage based on the waste entries
      def net_lower_tonnage
        sum_from_values(wastes, :net_lower_tonnage, true)
      end

      # Work out the standard_tonnage based on the waste entries
      def net_standard_tonnage
        sum_from_values(wastes, :net_standard_tonnage, true)
      end

      # Work out the exempt_tonnage based on the waste entries
      def exempt_tonnage
        sum_from_values(wastes, :exempt_tonnage, true)
      end

      # Work out the water_tonnage based on the waste entries
      def water_tonnage
        sum_from_values(wastes, :water_tonnage, true)
      end

      # Work out the total_tonnage based on the waste entries
      def total_tonnage
        sum_from_values(wastes, :total_tonnage, true)
      end

      # Gets users sites data from the back office for the account of the given user
      # for the current period
      # The sites need to be reconciled with the current sites on the SLFT return this is done
      # in the slft return itself as we need to add an error if a site is removed
      # @param requested_by [User] is usually the current_user, who is requesting the data
      # @param year [Integer] the current year being requested
      # @param fape_period [String] the current quarter being requested
      def self.find(requested_by, year, fape_period)
        sites = []
        request = { ParRefno: requested_by.party_refno, Username: requested_by.username, Year: year,
                    Quarter: fape_period }
        call_ok?(:get_sites, request) do |body|
          # use service client to make sure the singleton hash is turned into an array
          ServiceClient.iterate_element(body[:slft_sites]) do |data|
            # Only interested in the id and name from the site ref data
            site = new(lasi_refno: data[:lasi_refno].to_i, site_name: data[:site_name])
            sites << site
          end
        end
        sites
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        # doesn't include '@total_tonnage as that's always derived
        output = { 'ins1:SiteName': site_name, 'ins1:LASIRefno': @lasi_refno,
                   'ins1:TotalLowerTonnage': net_lower_tonnage, 'ins1:TotalStandardTonnage': net_standard_tonnage,
                   'ins1:TotalExemptTonnage': exempt_tonnage, 'ins1:TotalWaterTonnage': water_tonnage }

        # don't include wastes section if there's no wastes data
        return output if wastes.blank?

        output['ins1:SiteSpecificWastes'] = { 'ins1:SiteSpecificWaste': wastes.values.map(&:request_save) }
        output
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_calc
        { 'ins1:SiteID': lasi_refno, 'ins1:StandardTonnage': net_standard_tonnage,
          'ins1:LowerTonnage': net_lower_tonnage }
      end

      # Loads the CSV file into an array of rows, which are themselves arrays of data.
      # @param resource_item [Object] A resource item that represents the CSV file to be imported, any errors
      #   at a file level (can't open file, not a well formed CSV file) will be added to this resource_item
      # return [Array] array of imported data
      def import_waste_csv_data(resource_item)
        csv_import resource_item, Returns::Slft::Waste
        @imported
      end

      # Export the site's wastes details as separate CSV files into the supplied parent folder
      # @param filename_prefix [String] used to prefix the output filename
      # @param parent_folder [String] the folder to put the CSV files into
      def export_waste_csv_data(filename_prefix, parent_folder)
        output_filename = csv_output_filename parent_folder, filename_prefix
        csv_export output_filename, Returns::Slft::Waste, @wastes.values
      end

      # Create a new instance based on a back office style hash (@see SlftReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(raw_hash)
        # strip out attributes we don't want yet
        %i[total_lower_tonnage total_standard_tonnage total_exempt_tonnage
           total_water_tonnage total].each { |key| raw_hash.delete(key) }

        # convert wastes data to Waste objects hashed by EWC_Code (and rename incoming XML's redundant
        # name for this section).
        raw_hash[:wastes] = convert_wastes(raw_hash.delete(:site_specific_wastes), raw_hash[:site_name])

        # Create new instance
        Site.new_from_fl(raw_hash)
      end

      # @!method self.convert_wastes(site_specific_wastes)
      # Convert the wastes data (raw hash) into Waste objects hashed by EWC_CODE.
      # @param site_specific_wastes [Hash] the back office data
      # @param site_name [String] the name of this site used to populate the waste model
      # @return [Hash] Wastes objects indexed by the waste's ewc_codes (or else an empty hash if parameter was blank)
      private_class_method def self.convert_wastes(site_specific_wastes, site_name)
        return {} if site_specific_wastes.blank?

        # if there's only 1 it doesn't put it into an array which the next part expects, so put it into an array
        raw_waste = site_specific_wastes[:site_specific_waste]
        raw_waste = [raw_waste] if raw_waste.is_a?(Hash)

        output = {}
        raw_waste.each do |raw_hash|
          # don't attempt to create Waste object with an empty hash
          continue if raw_hash.blank?

          waste = Waste.convert_back_office_hash(raw_hash, site_name)
          output[waste.uuid] = waste
        end

        output
      end

      private

      # Return the CSV output filename, which is made up of the parent path, the return reference (prefix), a sanitised
      # version of the site_name, the lasi_refno, and the .csv extension
      # @param parent_path [String] path where to store the file
      # @param prefix [String] the prefix for the filename, typically the return reference
      # @return [String] the filename
      def csv_output_filename(parent_path, prefix)
        sanitised_site_name = sanitise_filename @site_name
        File.join(parent_path, "#{prefix}_#{sanitised_site_name}_#{@lasi_refno}.csv")
      end

      # Sanitise a filename, based on
      #   https://stackoverflow.com/questions/1939333/how-to-make-a-ruby-string-safe-for-a-filesystem
      # Any sequence of characters beyond A-Z, a-z, 0-9 and - should be collapsed into a single _ (i.e. underscore is
      # itself regarded as a disallowed character)
      # @param filename [String] the filename to sanitise
      # @return [String] the sanitised filename
      def sanitise_filename(filename)
        filename.gsub(/[^a-z0-9\-]+/i, '_')
      end
    end
  end
end
