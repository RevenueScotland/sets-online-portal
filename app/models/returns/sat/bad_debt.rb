# frozen_string_literal: true

module Returns
  module Sat
    # Bad debt relative information
    class BadDebt < FLApplicationRecord
      include NumberFormatting
      include DateFormatting
      include PrintData

      attr_accessor :current_user

      # Attribute list
      def self.attribute_list
        %i[bad_debt_credit_amount bad_debt_details bad_debt_date bad_debt_declaration bad_debt_present]
      end

      attribute_list.each { |attr| attr_accessor attr }

      validates :bad_debt_present, presence: true, on: :bad_debt_present
      validates :bad_debt_details, presence: true, length: { maximum: 3000 }, on: :bad_debt_details
      validates :bad_debt_declaration, acceptance: { accept: ['Y'] }, on: :bad_debt_declaration
      validates :bad_debt_credit_amount, presence: true, numericality: { greater_than_or_equal_to: 0,
                                                                         less_than: 1_000_000_000_000_000_000,
                                                                         allow_blank: true },
                                         two_dp_pattern: true, on: :bad_debt_credit_amount

      # Define the ref data codes associated with the attributes not to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        {
          bad_debt_options: YESNO_COMP_KEY
        }
      end

      # @return [Hash] elements used to specify what data we want to send to the back office
      def additional_parameters
        { Service: 'SAT' }
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

      # @return declaration text if it's set, else return nil
      # This method is written specifically for Request save
      def debt_declaration_text
        bad_debt_present == 'Y' ? I18n.t('activemodel.attributes.returns/sat/bad_debt.bad_debt_declaration') : nil
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        { 'ins0:BadDebtCreditAmount': @bad_debt_credit_amount, 'ins0:BadDebtDetails': @bad_debt_details,
          'ins0:BadDebtDate': @bad_debt_credit_amount ? DateFormatting.to_xml_date_format(Date.today) : nil, # rubocop:disable Rails/Date
          'ins0:BadDebtDeclaration': debt_declaration_text }
      end

      # This method is used specifically for print items
      def debt_items
        items = []
        if bad_debt_present == 'Y'
          items.push({ code: :bad_debt_details, action_name: :pdf_label },
                     { code: :bad_debt_credit_amount, action_name: :pdf_label, format: :money },
                     { code: :bad_debt_declaration, action_name: :pdf_label })
        else
          items.push({ code: :bad_debt_present, action_name: :pdf_label })
        end
        items
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [{ code: :bad_debt,
           page_break: false,
           divider: true,
           display_title: true,
           type: :list,
           key: :title,
           key_scope: %i[returns sat bad_debt],
           list_items: debt_items }]
      end
    end
  end
end
