# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for link transaction records
    class LinkTransactions < FLApplicationRecord
      include NumberFormatting
      include PrintData

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[return_reference consideration_amount npv_inc premium_inc]
      end
      attribute_list.each { |attr| attr_accessor attr }

      attr_accessor :convey

      # amount validations
      validates :consideration_amount, numericality: {
        greater_than_or_equal_to_zero: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true
      }, presence: true, two_dp_pattern: true, if: :convey
      validates :npv_inc, :premium_inc, numericality: {
        greater_than_or_equal_to_zero: 0, less_than: 1_000_000_000_000_000_000, allow_blank: true
      }, presence: true, two_dp_pattern: true, unless: :convey
      validates :return_reference, reference_number: true

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :linked_transactions, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :return_reference,
                          key_scope: %i[returns lbtt_transactions linked_transactions] },
                        { code: :consideration_amount, format: :money, when: :convey, is: [true],
                          key_scope: %i[returns lbtt_transactions linked_transactions] },
                        { code: :npv_inc, format: :money, when: :convey, is: [false],
                          key_scope: %i[returns lbtt_transactions linked_transactions] },
                        { code: :premium_inc, format: :money, when: :convey, is: [false],
                          key_scope: %i[returns lbtt_transactions linked_transactions] }] }]
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        output = {}

        xml_element_if_present(output, 'ins1:Reference', @return_reference)
        xml_element_if_present(output, 'ins1:ConsiderationAmount', @consideration_amount)
        xml_element_if_present(output, 'ins1:NetPresentValue', @npv_inc)
        xml_element_if_present(output, 'ins1:LeasePremium', @premium_inc)
        output
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(output, lbtt_return_type)
        output[:convey] = (lbtt_return_type == 'CONVEY')
        # rename some of the keys
        output[:return_reference] = output.delete(:reference)
        output[:npv_inc] = output.delete(:net_present_value)
        output[:premium_inc] = output.delete(:lease_premium)

        # Create new instance
        LinkTransactions.new_from_fl(output)
      end
    end
  end
end
