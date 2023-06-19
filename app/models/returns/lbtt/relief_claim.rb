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
           mdr_number_dwellings_ads relief_amount_ads relief_override_amount_ads]
      end

      attribute_list.each { |attr| attr_accessor attr }

      attr_accessor :lbtt_return_ads_due, :lbtt_return_flbt_type # HACK: values copied from LbttReturn

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      # relief_amount has a setter
      # check them all
      strip_attributes :mdr_number_dwellings, :mdr_total_consideration,
                       :mdr_number_dwellings_ads

      # We validate relief_type_expanded so the linking works on the page
      validates :relief_type_expanded, presence: true
      validates :relief_type, presence: true, InReferenceValues: true, on: :relief_type
      validates :relief_override_amount, relief_type_maximum: true
      validates :relief_override_amount,
                numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true },
                two_dp_pattern: true, presence: true, on: :relief_override_amount, if: :lbtt_relief?

      validates :relief_amount,
                numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true },
                presence: true, two_dp_pattern: true, unless: :auto_calculated?, if: :lbtt_relief?

      # Validate the ADS
      validates :relief_amount_ads,
                numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true },
                presence: true, two_dp_pattern: true, unless: :auto_calculated?,
                if: :show_ads?

      validates :relief_override_amount_ads, relief_type_maximum: true
      validates :relief_override_amount_ads,
                numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true },
                two_dp_pattern: true, presence: true, on: :relief_override_amount_ads,
                if: :show_ads?

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

      # Text shown in relief amount field where relief type is not applicable for that relief
      def self.na_text
        I18n.t('na', scope: [i18n_scope, :attributes, model_name.i18n_key])
      end

      # set relief type from selected value in drop down as we are storing code and flag to
      # indicated relief claim amount auto calculated
      def relief_type_expanded=(value)
        return if value.nil?

        # Clear the override amounts if the relief type changes to avoid validation errors based on the
        # new type and old values
        relief_type, auto_calculated, relief_type_class = ReferenceData::TaxReliefType.split_code_expanded(value)
        if relief_type != @relief_type
          @relief_override_amount_ads = nil
          @relief_override_amount = nil
        end
        @relief_type = relief_type
        @auto_calculated = auto_calculated
        @relief_type_class = relief_type_class
      end

      # get relief type
      def relief_type_expanded
        return if @relief_type.nil?

        "#{@relief_type}>$<#{auto_calculated?}>$<#{relief_type_class}"
      end

      # set the relief override amount column to n/a if the relief type is ads
      def relief_override_amount
        lbtt_relief? ? @relief_override_amount : Returns::Lbtt::ReliefClaim.na_text
      end

      # set the relief override amount column to n/a if the relief type is LBTT
      def relief_override_amount_ads
        ads_relief? ? @relief_override_amount_ads : Returns::Lbtt::ReliefClaim.na_text
      end

      # Override setter so that ads relief amount to 0 for na relief claim amount
      def relief_override_amount_ads=(value)
        @relief_override_amount_ads = parse_text_na(value.try(:strip) || value, !ads_relief?)

        @relief_amount_ads = @relief_override_amount_ads unless auto_calculated?
      end

      # Override setter so that lbtt relief amount to 0 for na relief claim amount
      def relief_override_amount=(value)
        @relief_override_amount = parse_text_na(value.try(:strip) || value, !lbtt_relief?)

        @relief_amount = @relief_override_amount unless auto_calculated?
      end

      # Override setter so that relief amount to 0 for auto calculated relief claim amount or for na relief claim amount
      def relief_amount=(value)
        # Using strip to remove leading spaces as this is a numeric field
        @relief_amount = parse_text_calc(parse_text_na(value.try(:strip) || value, !lbtt_relief?))
      end

      # Override setter so that relief amount to 0 for auto calculated relief claim amount or for na relief claim amount
      def relief_amount_ads=(value)
        # Using strip to remove leading spaces as this is a numeric field
        @relief_amount_ads = parse_text_calc(parse_text_na(value.try(:strip) || value, !ads_relief?))
      end

      # Get relief amount from the back office
      # if the relief type is ads  then returns NA for the UI relief amount value
      # if the relief is auto calculated then shows calculated for the UI relief amount value
      # note the order is critical as the relief type can still be auto calculated and NA so NA takes precedence
      def relief_amount
        # require to show blank value on ui
        return ReliefClaim.na_text unless lbtt_relief?
        return ReliefClaim.calculated_text if auto_calculated?

        @relief_amount
      end

      # Get relief amount from the back office
      # if the relief type is LBTT then returns NA for the UI ads value
      # if the relief is auto calculated then shows calculated for the UI ads value
      # note the order is critical as the relief type can still be auto calculated and NA so NA takes precedence
      def relief_amount_ads
        # require to show blank value on ui
        return ReliefClaim.na_text unless ads_relief?
        return ReliefClaim.calculated_text if auto_calculated?

        @relief_amount_ads
      end

      # Indicator whether relief amount need to be calculated or the user is allowed to entered
      # This is also used on ui to read only relief amount text
      def auto_calculated?
        return false if @relief_type.blank?

        @auto_calculated ||= relief_type_hash[@relief_type].auto_calculated?
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [{ code: :relief_types, # section code
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :relief_type_description },
                        { code: :relief_override_amount, format: :money, when: :lbtt_relief?, is: [true] },
                        { code: :relief_override_amount_ads, format: :money, when: :show_ads?, is: [true] },
                        { code: :mdr_number_dwellings, when: :md_relief?, is: [true] },
                        { code: :mdr_total_consideration, format: :money, when: :md_relief?, is: [true] },
                        { code: :mdr_number_dwellings_ads, when: :md_relief?, is: [true] }] }]
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
      def ads_relief?
        return true if @relief_type.blank? || relief_type_class == 'ADS' || relief_type_class == 'STANDARD'

        false
      end

      # utility method used in print layout and validation
      def show_ads?
        return true if lbtt_return_ads_due && ads_relief?

        false
      end

      # check if relief is lbtt type or not.
      def lbtt_relief?
        return true if @relief_type.blank? || relief_type_class == 'LBTT' || relief_type_class == 'STANDARD'

        false
      end

      # @return true if the relief type is Multiple Dwellings Relief (MDR)
      def md_relief?
        relief_type == 'MULTIPLE'
      end

      # Fetch claim relief type information from cache
      # This method is different from look_up_ref_data as it contains non current tax relief types
      def relief_type_hash
        @relief_type_hash ||= ReferenceData::TaxReliefType.lookup('RELIEF_TYPES', 'LBTT', 'RSTU')
      end

      # Filters the reliefs based on the ADS flag
      # @param attribute the reference data type
      # @return [Hash] the revised hash
      def lookup_ref_data(attribute)
        unless attribute == :relief_type
          raise Error::AppError.new('ReliefClaim.lookup_ref_data',
                                    "#{attribute} is not supported")
        end
        relief_type_hash.select do |_key, value|
          value.filter_relief(lbtt_return_flbt_type,
                              current_only: true, show_ads_reliefs: lbtt_return_ads_due)
        end
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        return {} if @relief_type.blank?

        output = {}
        output['ins0:Type'] = @relief_type
        output['ins0:OrigAmount'] = @relief_amount
        output['ins0:Amount'] = @relief_override_amount
        add_mdr_fields(output)
        add_ads_fields(output)
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_for_main_calc
        output = add_common_fields_calc({})
        add_mdr_fields_calc(output)
      end

      # @return a hash suitable for use in calc request for the relief type to the back office
      def request_for_relief_type_calc
        output = add_common_fields_calc({})
        output['ins1:ReliefOverrideAmount'] = @relief_override_amount if @relief_override_amount.present?
        output['ins1:ReliefOverrideAmountAds'] = @relief_override_amount_ads if @relief_override_amount_ads.present?
        add_mdr_fields_calc(output)
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(output)
        # Change the name of those attributes which are different in the incoming hash
        output.transform_keys!(type: :relief_type, amount: :relief_override_amount, orig_amount: :relief_amount,
                               amount_ads: :relief_override_amount_ads, orig_amount_ads: :relief_amount_ads)

        # Create new instance
        ReliefClaim.new_from_fl(output)
      end

      private

      # Add the standard fields to an output hash
      # @param output [Hash] the current hash
      # @return [Hash] the revised hash
      def add_common_fields_calc(output)
        output['ins1:ReliefType'] = @relief_type
        output['ins1:ReliefAmount'] = @relief_amount if @relief_amount.present?
        output['ins1:ReliefAmountAds'] = @relief_amount_ads if @relief_amount_ads.present?
        output
      end

      # Add the mdr fields to an output hash if this is an MDR
      # @param output [Hash] the current hash
      # @return [Hash] the revised hash
      def add_mdr_fields(output)
        return output unless md_relief?

        output['ins0:MdrNumberDwellings'] = @mdr_number_dwellings
        output['ins0:MdrTotalConsideration'] = @mdr_total_consideration
        output['ins0:MdrNumberDwellingsAds'] = @mdr_number_dwellings_ads
        output
      end

      # Add the ads fields to an output hash
      # @param output [Hash] the current hash
      # @return [Hash] the revised hash
      def add_ads_fields(output)
        return output unless lbtt_return_ads_due

        output['ins0:OrigAmountAds'] = @relief_amount_ads
        output['ins0:AmountAds'] = @relief_override_amount_ads
        output
      end

      # Add the mdr fields to an output hash if this is an MDR
      # @param output [Hash] the current hash
      # @return [Hash] the revised hash
      def add_mdr_fields_calc(output)
        return output unless md_relief?

        output['ins1:MdrNumberDwellings'] = @mdr_number_dwellings
        output['ins1:MdrTotalConsideration'] = @mdr_total_consideration
        output['ins1:MdrNumberDwellingsAds'] = @mdr_number_dwellings_ads
        output
      end

      # checks to see if text equals calculated and relief is auto calculated
      # @param value the on screen value, can be user entered, na or calculated
      def parse_text_calc(value)
        return 0 if value == ReliefClaim.calculated_text && auto_calculated?

        value
      end

      # checks to see if text equals calculated and relief is lbtt or ads
      # @param value the on screen value, can be user entered, na or calculated
      # @param is_na [Boolean] is the relief type not applicable
      def parse_text_na(value, is_na)
        return 0 if value == ReliefClaim.na_text && is_na

        value
      end
    end
  end
end
