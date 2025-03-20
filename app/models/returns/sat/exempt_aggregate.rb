# frozen_string_literal: true

module Returns
  module Sat
    # Sites contain exempt aggregate specific information.  There can be multiple sites per period
    class ExemptAggregate < FLApplicationRecord
      include PrintData

      # Attributes for this class, in list so can re-use
      def self.attribute_list
        %i[tlb_refno attribute_type aggregate_type exempt_type exempt_tonnage]
      end

      # Attributes used when exporting or importing waste as a CSV file
      # @see post_csv_import for processing of other attributes
      def self.csv_attribute_list
        %i[aggregate_type exempt_type exempt_tonnage exempt_aggregate]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      strip_attributes :exempt_tonnage

      # Not including in the attribute_list so it can't be posted on every sat form, ie to prevent data injection.
      # uuid represents the exempt aggregate entry in a site (ie just for keeping track of it during editing).
      # site_name, rate_date are also denormalised mainly so it can be displayed on the page during edits
      attr_accessor :uuid, :rate_date, :site_name

      # exempt aggregate details validations
      validates :aggregate_type, presence: true, on: :aggregate_type
      validates :exempt_type, presence: true, on: :exempt_type
      validates :exempt_tonnage, presence: true, on: :exempt_tonnage
      # exempt tonnage validations, blank or 2dp decimals >= 0
      validates :exempt_tonnage, numericality: { greater_than_or_equal_to: 0,
                                                 less_than: 1_000_000_000_000_000_000,
                                                 allow_blank: true },
                                 two_dp_pattern: true, on: :exempt_tonnage

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
        { exempt_type: comp_key('EXEMPTREASON', 'SAT', 'RSTU') }
      end

      # gets the aggregate type and formats it for use in a lov
      # @return [array] The aggregate types list indexed
      def aggregate_types_list
        aggregate_types_lov = []
        @aggregate_type_rates.map do |obj|
          aggregate_types_lov.push(ReferenceData::ReferenceValue.new(code: obj[:code],
                                                                     value: obj[:description]))
        end
        aggregate_types_lov
      end

      # Returns the aggregate type selected
      # @return [String] the aggregate type value
      def aggregate_type_display
        ReferenceData::ReferenceValue.lookup('AGGREGATE TYPE', 'SAT', 'RSTU')[@aggregate_type].value
      end

      # Returns the exempt type selected
      # @return [String] the exempt type value
      def exempt_type_display
        lookup_ref_data_value :exempt_type
      end

      # Display method for the exempt tonnage
      # @return [String] the exempt tonnage upto 2 decimal
      def exempt_tonnage_display
        format_tonnage_value(@exempt_tonnage)
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        # doesn't include '@total_tonnage as that's always derived
        { 'ins0:TlbRefno': @tlb_refno, 'ins0:AttributeType': 'EXAG',
          'ins0:AggregateType': @aggregate_type, 'ins0:ExemptType': @exempt_type,
          'ins0:ExemptTonnage': @exempt_tonnage }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [{ code: :exempt_aggregate,
           divider: true,
           display_title: true,
           type: :table,
           key: :taxable_aggregate_title,
           key_scope: %i[returns sat exempt_aggregate],
           row_cells: [{ list_items: [{ code: :aggregate_type_display, action_name: :pdf_label }] },
                       { list_items: [{ code: :exempt_type, lookup: true }] },
                       { list_items: [{ code: :exempt_tonnage }] }] }]
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
