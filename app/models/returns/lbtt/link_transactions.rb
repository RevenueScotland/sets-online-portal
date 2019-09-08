# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for link transaction records
    class LinkTransactions < FLApplicationRecord
      include NumberFormatting
      include PrintData
      include CommonValidation

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[return_reference consideration_amount npv_inc premium_inc]
      end
      attribute_list.each { |attr| attr_accessor attr }

      # amount validations @see #validation_status
      validates :consideration_amount, numericality: {
        greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true
      }, presence: true, format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: 'CONVEY'
      validates :npv_inc, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000,
                                          allow_blank: true }, presence: true,
                          format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: :NON_CONVEY
      validates :premium_inc, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000,
                                              allow_blank: true }, presence: true,
                              format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: :NON_CONVEY
      validate  :return_reference_valid?, on: :NON_CONVEY

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :linked_transactions, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :return_reference,
                          key_scope: %i[returns lbtt_transactions linked_transactions] },
                        { code: :consideration_amount, format: :money, when: :flbt_type, is: ['CONVEY'],
                          key_scope: %i[returns lbtt_transactions linked_transactions] },
                        { code: :npv_inc, format: :money, when: :flbt_type, is_not: ['CONVEY'],
                          key_scope: %i[returns lbtt_transactions linked_transactions] },
                        { code: :premium_inc, format: :money, when: :flbt_type, is_not: ['CONVEY'],
                          key_scope: %i[returns lbtt_transactions linked_transactions] }] }]
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        return nil if validation_status(nil) == :empty

        output = {}

        output['ins1:Reference'] = @return_reference unless @return_reference.blank?
        output['ins1:ConsiderationAmount'] = or_zero(@consideration_amount) unless @consideration_amount.blank?
        output['ins1:NetPresentValue'] = or_zero(@npv_inc) unless @npv_inc.blank?
        output['ins1:LeasePremium'] = or_zero(@premium_inc) unless @premium_inc.blank?

        output
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(output)
        output[:return_reference] = output[:reference] unless output[:reference].blank?
        output[:npv_inc] = output[:net_present_value] unless output[:net_present_value].blank?
        output[:premium_inc] = output[:lease_premium] unless output[:lease_premium].blank?

        # strip out attributes we don't want yet
        delete = %i[reference net_present_value lease_premium]
        delete.each { |key| output.delete(key) }

        # Create new instance
        LinkTransactions.new_from_fl(output)
      end

      def return_reference_valid?
        return if @return_reference.blank? || valid_reference?(@return_reference)

        errors.add(:return_reference, :format_is_invalid)
      end

      # Summarises the state of this link transaction.
      # NB return reference can be nil but if it's set then a value must be provided so we return :missing.
      # @param context [@flbt_type] the validation context (LBTT type)
      # @return :good, :missing (value missing), :bad (fails validation) or :empty (no value).
      def validation_status(context)
        validation_count = 0

        # check if any of the values fields are present (not return reference, that can be blank)
        [@consideration_amount, @npv_inc, @premium_inc].each { |r| validation_count += 1 if r.present? }

        # translate count into a symbol for calling methods to use
        if validation_count.zero?
          # if the return ref is set then an amount must be given
          return :missing if @return_reference.present?

          return :empty
        end

        # there is a value so ensure it's valid and return good only if it is ok
        context = :NON_CONVEY unless context == 'CONVEY'
        return :good if valid?(context)

        :bad
      end
    end
  end
end
