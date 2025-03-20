# frozen_string_literal: true

module Returns
  module Sat
    # Sat returns contain site specific information.  There can be multiple sites per period
    class TaxableAggregate < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
      # Attributes for this class, in list so can re-use
      def self.attribute_list
        %i[tlb_refno attribute_type aggregate_type comm_exploitation_type exploited_tonnage water_tonnage mixed_ind rate
           taxable_tonnage tax_due taxable_aggregates]
      end

      # Attributes used when exporting or importing waste as a CSV file
      # @see post_csv_import for processing of other attributes
      def self.csv_attribute_list
        %i[aggregate_type comm_exploitation_type exploited_tonnage water_tonnage mixed_ind]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      strip_attributes :exploited_tonnage, :water_tonnage

      # Not including in the attribute_list so it can't be posted on every sat form, ie to prevent data injection.
      # uuid represents the taxable aggregate entry in a site (ie just for keeping track of it during editing).
      # site_name, rate_date are also denormalised mainly so it can be displayed on the page during edits
      attr_accessor :uuid, :rate_date, :site_name

      # aggregate_details validations
      validates :aggregate_type, presence: true, on: :aggregate_type
      validates :comm_exploitation_type, presence: true, on: :comm_exploitation_type

      # aggregate_tonnage validations
      validates :exploited_tonnage, presence: true, on: :exploited_tonnage
      validates :water_tonnage, presence: true, on: :water_tonnage
      validate  :validate_water_tonnage, on: :water_tonnage
      validates :mixed_ind, presence: true, on: :mixed_ind
      # aggregate_tonnage validations, blank or 2dp decimals >= 0
      validates :exploited_tonnage, numericality: { greater_than_or_equal_to: 0,
                                                    less_than: 1_000_000_000_000_000_000,
                                                    allow_blank: true },
                                    two_dp_pattern: true, on: :exploited_tonnage
      validates :water_tonnage, numericality: { greater_than_or_equal_to: 0,
                                                less_than: 1_000_000_000_000_000_000,
                                                allow_blank: true },
                                two_dp_pattern: true, on: :water_tonnage

      # Override constructor to set initial values to zero and provide a UUID
      def initialize(attributes = {})
        super

        # unless already set, provide a UUID
        @uuid = SecureRandom.uuid if @uuid.nil?
        aggregate_type_rates
      end

      # Overrides the param value passed into the id of the path when the instance of the object is used
      # as the parameter value of a path.
      def to_param
        @uuid
      end

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { comm_exploitation_type: comp_key('COMMEXPLOITREASON', 'SAT', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes but which won't be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { mixed_ind: YESNO_COMP_KEY }
      end

      # gets the aggregate types and formats it for use in a lov
      # @return [array] The aggregate type list indexed
      def aggregate_types_list
        aggregate_types_lov = []
        @aggregate_type_rates.map do |obj|
          aggregate_types_lov.push(ReferenceData::ReferenceValue.new(code: obj[:code],
                                                                     value: obj[:description]))
        end
        aggregate_types_lov
      end

      # Validation for transaction's remaining chargeable amount
      def validate_water_tonnage
        return if errors.any?

        return if @exploited_tonnage.to_f.abs == @water_tonnage.to_f.abs

        errors.add(:water_tonnage, :must_be_greater) if @exploited_tonnage.to_f < @water_tonnage.to_f
      end

      # Returns the aggregate type selected
      # @return [String] the selected aggregate type
      def aggregate_type_display
        ReferenceData::ReferenceValue.lookup('AGGREGATE TYPE', 'SAT', 'RSTU')[@aggregate_type].value
      end

      # Display the exploitation type selected
      # @return [String] the selected exploitation type
      def comm_exploitation_type_display
        lookup_ref_data_value :comm_exploitation_type
      end

      # Display the standard exploited tonnage to decimal value
      # @return [Integer] the decimal value of exploited tonnage
      def exploited_tonnage_display
        format_tonnage_value(@exploited_tonnage)
      end

      # Display the standard water tonnage to decimal value
      # @return [Integer] the decimal value of water tonnage
      def water_tonnage_display
        format_tonnage_value(@water_tonnage)
      end

      # Getter for standard taxable tonnage to decimal value
      # @return [Integer] the decimal value of taxable tonnage
      def taxable_tonnage
        # convert the difference value to be formatted
        format_tonnage_value((@exploited_tonnage.to_f - @water_tonnage.to_f).to_s)
      end

      # Getter for standard rate to return value for selected aggregate type
      # @return [Integer] the current rate
      def rate
        @aggregate_type_rates&.each do |obj|
          @rate = obj[:rate] if obj[:code] == @aggregate_type
        end

        @rate
      end

      # Getter for standard tax due to return decimal value(considering pennies)
      # @return [Integer] tax due value upto 2 decimal
      # use round to avoid funny trailing decimals
      def tax_due
        NumberFormatting.to_money_format taxable_tonnage.to_d * rate.to_d
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :taxable_aggregates,
           divider: true,
           display_title: true,
           type: :table,
           key: :taxable_aggregate_title,
           key_scope: %i[returns sat taxable_aggregates],
           row_cells: [{ list_items: [{ code: :aggregate_type_display, action_name: :pdf_label }] },
                       { list_items: [{ code: :comm_exploitation_type, lookup: true }] },
                       { list_items: [{ code: :exploited_tonnage }] },
                       { list_items: [{ code: :water_tonnage }] },
                       { list_items: [{ code: :mixed_ind, lookup: true, label: 'Alternative weighing method' }] },
                       { list_items: [{ code: :rate, format: :money }] },
                       { list_items: [{ code: :tax_due, format: :money }] }] }]
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        # doesn't include '@total_tonnage as that's always derived
        { 'ins0:TlbRefno': @tlb_refno, 'ins0:AttributeType': 'TAAG',
          'ins0:AggregateType': @aggregate_type, 'ins0:CommExploitationType': @comm_exploitation_type,
          'ins0:ExploitedTonnage': @exploited_tonnage, 'ins0:WaterTonnage': @water_tonnage,
          'ins0:MixedInd': @mixed_ind, 'ins0:Rate': rate, 'ins0:TaxDue': tax_due }
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_tax_calc
        { 'ins1:AggregateType': @aggregate_type, 'ins1:ExploitedTonnage': @exploited_tonnage,
          'ins1:WaterTonnage': @water_tonnage }
      end

      private

      # @return [Hash] elements used to specify what data we want to send to the back office
      def additional_parameters
        { Service: 'SAT', RateEffectiveDate: @rate_date }
      end

      # calls the back office to get the aggregate types data
      # @return [array] The bo data indexed
      def aggregate_type_rates
        # returns the data if the data exists this stops the code from doing another call
        # to the BO when data was pulled back
        return @aggregate_type_rates unless @aggregate_type_rates.nil?

        @aggregate_type_rates = []

        call_ok?(:get_aggregate_type_rates, additional_parameters) do |body|
          ServiceClient.iterate_element(body[:aggregate_types]) do |types|
            @aggregate_type_rates.push(types)
          end
        end
        @aggregate_type_rates
      end
    end
  end
end
