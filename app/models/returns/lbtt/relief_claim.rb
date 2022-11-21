# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for relief claim records
    class ReliefClaim < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[relief_type relief_amount relief_override_amount mdr_number_dwellings mdr_total_consideration
           mdr_number_dwellings_ads]
      end

      attribute_list.each { |attr| attr_accessor attr }

      attr_accessor :lbtt_return_ads_due # HACK: values copied from LbttReturn

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      # relief_amount has a setter
      strip_attributes :relief_override_amount, :mdr_number_dwellings, :mdr_total_consideration,
                       :mdr_number_dwellings_ads

      # We validate relief_type_auto so the linking works on the page
      validates :relief_type_auto, presence: true
      validates :relief_override_amount, relief_type_maximum: true
      validates :relief_override_amount,
                numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true },
                two_dp_pattern: true, presence: true, on: :relief_override_amount

      validates :relief_amount,
                numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true },
                presence: true, two_dp_pattern: true, unless: :auto_calculated?

      # MDR reliefs validation
      validates :mdr_number_dwellings,
                numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                allow_blank: true, only_integer: true },
                presence: true, on: :mdr_number_dwellings, if: :md_relief?
      validates :mdr_number_dwellings_ads, presence: true, on: :mdr_number_dwellings_ads,
                                           if: %i[md_relief? lbtt_return_ads_due]
      validates :mdr_number_dwellings_ads,
                numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                allow_blank: true, only_integer: true },
                on: :mdr_number_dwellings_ads, if: :md_relief?
      validates :mdr_total_consideration,
                numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                allow_blank: true },
                two_dp_pattern: true, presence: true, on: :mdr_total_consideration, if: :md_relief?

      # Text shown in relief amount field where amount is calculated by back office
      def self.calculated_text
        I18n.t('calculated', scope: [i18n_scope, :attributes, model_name.i18n_key])
      end

      # set relief type from selected value in drop down as we are storing code and flag to
      # indicated relief claim amount auto calculated
      def relief_type_auto=(value)
        return if value.nil?

        @relief_type, @auto_calculated = ReferenceData::TaxReliefType.split_code_auto(value)
      end

      # get relief type
      def relief_type_auto
        return if @relief_type.nil?

        "#{@relief_type}>$<#{auto_calculated?}"
      end

      # Override setter so that relief amount to 0 for auto calculated relief claim amount
      def relief_amount=(value)
        # Using strip to remove leading spaces as this is a numeric field
        @relief_amount = (value == ReliefClaim.calculated_text && auto_calculated? ? 0 : value.try(:strip) || value)
      end

      # Get relief amount
      # it is calculated from back office
      def relief_amount
        # require to show blank value on ui
        return ReliefClaim.calculated_text if auto_calculated?

        @relief_amount
      end

      # Indicator weather relief amount need to be calculated or the user is allowed to entered
      # This is also used on ui to read only relief amount text
      def auto_calculated?
        return false if @relief_type.blank?

        @auto_calculated ||= relief_type_hash[@relief_type].auto_calculated?
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [{ code: :relief_types, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :relief_type_description },
                        { code: :relief_override_amount, format: :money },
                        { code: :mdr_number_dwellings, when: :md_relief?, is: [true] },
                        { code: :mdr_number_dwellings_ads, when: :md_relief?, is: [true] },
                        { code: :mdr_total_consideration, format: :money, when: :md_relief?, is: [true] }] }]
      end

      # Obtain the description of this relief type
      # Used in the print data
      def relief_type_description
        @relief_type_description ||= relief_type_hash[@relief_type].description
      end

      # Obtain the class of this relief type.
      def relief_type_class
        return if @relief_type.blank?

        @relief_type_class ||= relief_type_hash[@relief_type].type_class
      end

      # check if relief is ads type or not.
      def ads?
        (relief_type_class == 'ADS')
      end

      # @return true if the relief type is Multiple Dwellings Relief (MDR)
      def md_relief?
        relief_type == 'MULTIPLE'
      end

      # Fetch claim relief type information from cache
      def relief_type_hash
        @relief_type_hash ||= ReferenceData::TaxReliefType.lookup('RELIEF_TYPES', 'LBTT', 'RSTU')
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        return {} if @relief_type.blank?

        output = {}
        output['ins1:Type'] = @relief_type
        output['ins1:OrigAmount'] = @relief_amount
        output['ins1:Amount'] = @relief_override_amount
        add_mdr_fields(output)
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_for_main_calc
        output = add_common_fields({})
        add_mdr_fields(output)
      end

      # @return a hash suitable for use in calc request for the relief type to teh back office
      def request_for_relief_type_calc
        output = add_common_fields({})
        output['ins1:ReliefOverrideAmount'] = @relief_override_amount if @relief_override_amount.present?
        add_mdr_fields(output)
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(output)
        # Change the name of those attributes which are different in the incoming hash
        output.transform_keys!(type: :relief_type, amount: :relief_override_amount, orig_amount: :relief_amount)

        # Create new instance
        ReliefClaim.new_from_fl(output)
      end

      private

      # Add the standard fields to an output hash
      # @param output [Hash] the current hash
      # @return [Hash] the revised hash
      def add_common_fields(output)
        output['ins1:ReliefType'] = @relief_type
        output['ins1:ReliefAmount'] = @relief_amount if @relief_amount.present?
        output
      end

      # Add the mdr fields to an output hash if this is an MDR
      # @param output [Hash] the current hash
      # @return [Hash] the revised hash
      def add_mdr_fields(output)
        return output unless md_relief?

        output['ins1:MdrNumberDwellings'] = @mdr_number_dwellings
        output['ins1:MdrTotalConsideration'] = @mdr_total_consideration
        output['ins1:MdrNumberDwellingsAds'] = @mdr_number_dwellings_ads
        output
      end
    end
  end
end
