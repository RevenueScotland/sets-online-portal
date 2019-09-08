# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for relief claim records
    class ReliefClaim < FLApplicationRecord
      include NumberFormatting
      include PrintData
      include CommonValidation

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[relief_type relief_amount]
      end
      attribute_list.each { |attr| attr_accessor attr }

      # amount validation
      validates :relief_amount, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000 },
                                format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { relief_type: 'RELIEFTYPES.LBTT.RSTU' }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [{ code: :relief_types, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :relief_type, lookup: true,
                          key_scope: %i[returns lbtt_transactions reliefs_on_transaction] },
                        { code: :relief_amount, format: :money,
                          key_scope: %i[returns lbtt_transactions reliefs_on_transaction] }] }]
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        return nil if validation_status == :empty

        output = {}

        output['ins1:Type'] = @relief_type unless @relief_type.blank?
        output['ins1:Amount'] = or_zero(@relief_amount) unless @relief_type.blank?

        output
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(output)
        output[:relief_type] = output[:type] unless output[:type].blank?
        output[:relief_amount] = output[:amount] unless output[:amount].blank?

        # strip out attributes we don't want yet
        delete = %i[type amount]
        delete.each { |key| output.delete(key) }

        # Create new instance
        ReliefClaim.new_from_fl(output)
      end

      # Reports on whether the relief_type and relief_amount are present and pass validation.
      # @return :good, :missing (ie type or value missing), :bad (fails validation) or :empty (no type AND no value).
      def validation_status # rubocop:disable Metrics/MethodLength
        validation_count = 0

        # adds 1 for each of the type and amount present (ie you get a result of 0, 1 or 2)
        [@relief_type, @relief_amount].each { |r| validation_count += 1 if r.present? }

        # translate count into a symbol for calling methods to use
        case validation_count
        when 0
          return :empty
        when 1
          return :missing
        when 2
          # if checks pass, ensure the amount is valid and return good only if it is ok
          return :good if valid?
        end

        :bad
      end

      # override string output to help with debugging.
      def to_s
        "#{@relief_type} = #{@relief_amount}"
      end
    end
  end
end
