# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for relief claim records
    class ReliefClaim < FLApplicationRecord
      include NumberFormatting
      include PrintData

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[relief_type relief_amount relief_override_amount]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      # relief_amount has a setter
      strip_attributes :relief_override_amount

      # We validate relief_type_auto so the linking works on the page
      validates :relief_type_auto, presence: true
      validates :relief_override_amount, relief_type_maximum: true
      validates :relief_override_amount,
                numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true },
                two_dp_pattern: true, presence: true, on: :relief_override_amount

      validates :relief_amount,
                presence: true,
                numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true },
                two_dp_pattern: true, unless: :auto_calculated?

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
                        { code: :relief_override_amount, format: :money }] }]
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

        output
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_for_main_calc
        output = {}
        output['ins1:ReliefType'] = @relief_type
        output['ins1:ReliefAmount'] = @relief_amount if @relief_amount.present?
        output
      end

      # @return a hash suitable for use in calc request for the relief type to teh back office
      def request_for_relief_type_calc
        output = {}
        output['ins1:ReliefType'] = @relief_type
        output['ins1:ReliefAmount'] = @relief_amount if @relief_amount.present?
        output['ins1:ReliefOverrideAmount'] = @relief_override_amount if @relief_override_amount.present?
        output
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(output)
        output[:relief_type] = output[:type] if output[:type].present?
        output[:relief_override_amount] = output[:amount] if output[:amount].present?
        output[:relief_amount] = output[:orig_amount] if output[:orig_amount].present?
        # strip out attributes we don't want yet
        delete = %i[type amount orig_amount]
        delete.each { |key| output.delete(key) }

        # Create new instance
        ReliefClaim.new_from_fl(output)
      end
    end
  end
end
