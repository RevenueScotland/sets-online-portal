# frozen_string_literal: true

module Returns
  module Sat
    # Sat return sites contain credit claim specific information. There can be multiple claims per site
    class CreditClaim < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
      # Attributes for this class, in list so can re-use
      def self.attribute_list
        %i[tlb_refno attribute_type aggregate_type tax_credit_type tax_period_ind related_tare_refno tax_tonnage
           tax_rate credit_amount current_return related_return credit_claims]
      end

      # Attributes used when exporting or importing waste as a CSV file
      # @see post_csv_import for processing of other attributes
      def self.csv_attribute_list
        %i[aggregate_type tax_credit_type tax_period_ind current_return related_return tax_tonnage tax_rate]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      strip_attributes :tax_tonnage, :tax_rate

      # Not including in the attribute_list so it can't be posted on every sat form, ie to prevent data injection.
      # uuid represents the credit claim entry in a site (ie just for keeping track of it during editing).
      # site_name, rate_date and period_start are also denormalised mainly so it can be displayed
      # on the page during edits
      attr_accessor :uuid, :rate_date, :site_name, :period_start, :period_end, :current_user, :return_periods

      # tax_credit_details validations
      validates :aggregate_type, presence: true, on: :aggregate_type
      validates :tax_credit_type, presence: true, on: :tax_credit_type
      validates :tax_period_ind, presence: true, on: :tax_period_ind

      # tax_credit_tonnage validations
      validates :related_return, presence: true, on: :related_return
      validates :tax_tonnage, presence: true, on: :tax_tonnage

      # tax_credit_details validations, blank or 2dp decimals >= 0
      validates :tax_tonnage, numericality: { greater_than_or_equal_to: 0,
                                              less_than: 1_000_000_000_000_000_000,
                                              allow_blank: true },
                              two_dp_pattern: true, on: :tax_tonnage

      # Override constructor to set initial values to zero and provide a UUID
      def initialize(attributes = {})
        super

        # unless already set, provide a UUID
        @uuid = SecureRandom.uuid if @uuid.nil?
        # calling method to get the aggregate types and rates
        aggregate_type_rates
        return_previous_periods_list
      end

      # Overrides the param value passed into the id of the path when the instance of the object is used
      # as the parameter value of a path.
      def to_param
        @uuid
      end

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { tax_credit_type: comp_key('TAXCREDITREASON', 'SAT', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes but which won't be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { tax_period_ind: YESNO_COMP_KEY }
      end

      # gets the aggregate types and formats it for use in a lov
      # @return [array] The aggregate type list indexed
      def aggregate_types_list
        return @aggregate_types_lov if @aggregate_types_lov

        @aggregate_types_lov = []
        @aggregate_type_rates.map do |obj|
          @aggregate_types_lov.push(ReferenceData::ReferenceValue.new(code: obj[:code],
                                                                      value: obj[:description]))
        end
        @aggregate_types_lov
      end

      # gets the previous return periods and formats it for use in a lov
      # @return [array] Previous return list indexed
      # if there are no previous return submitted then created a blank entry
      def list_all_previous_return_periods # rubocop:disable Metrics/MethodLength
        return @previous_periods_lov if @previous_periods_lov

        @previous_periods_lov = []

        if @return_periods.empty?
          # blank entry created if there are no previous return
          @previous_periods_lov.push(ReferenceData::ReferenceValue.new(code: ' ',
                                                                       value: ' '))
        else
          @return_periods.each do |i, obj|
            @previous_periods_lov.push(ReferenceData::ReferenceValue.new(code: i,
                                                                         value: obj.previous_return_period_display))
          end
        end

        @previous_periods_lov
      end

      # converts the selected period index back to a user readable value
      # @return [array] The dates in a user readable value
      def return_period_display
        # Need to format the date to show dd/mm/yy else the date will show as yyyy-mm-dd
        start_date = DateFormatting.to_display_date_format(@period_start)
        end_date = DateFormatting.to_display_date_format(@period_end)

        "#{start_date} to #{end_date}"
      end

      # Returns the aggregate type selected
      # @return [String] the selected aggregate type
      def aggregate_type_display
        ReferenceData::ReferenceValue.lookup('AGGREGATE TYPE', 'SAT', 'RSTU')[@aggregate_type].value
      end

      # Returns the tax credit type selected
      # @return [String] the selected tax credit type
      def tax_credit_type_display
        lookup_ref_data_value :tax_credit_type
      end

      # Getter for standard credit amount to return decimal value
      # @return [Integer] credit amount value upto 2 decimal
      def credit_amount
        NumberFormatting.to_money_format(from_pence(to_pence(@tax_tonnage.to_d) * tax_rate.to_d))
      end

      # returns the dates in suitable format to display
      def period_relates_to_display
        return @current_return if @tax_period_ind == 'Y'

        @return_periods[@related_return].return_period_date_format
      end

      # Getter for standard rate to return value for selected aggregate type
      # @return [Integer] the current rate
      def tax_rate
        @aggregate_type_rates&.each do |obj|
          @tax_rate = obj[:rate] if obj[:code] == @aggregate_type
        end

        @tax_rate
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_credit_calc
        { 'ins1:AggregateType': @aggregate_type, 'ins1:Tonnage': @tax_tonnage,
          'ins1:Rate': tax_rate }
      end

      # returns the reference for previous return selected
      def return_relates_to_display
        return if @tax_period_ind == 'Y'

        @return_periods[@related_return].tare_reference
      end

      # returns the tare refno for selected previous return
      def relates_to_pdf
        @tax_period_ind == 'N' ? @return_periods[@related_return].tare_refno : nil
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        { 'ins0:TlbRefno': @tlb_refno, 'ins0:AttributeType': 'TACR',
          'ins0:AggregateType': @aggregate_type, 'ins0:TaxCreditType': @tax_credit_type,
          'ins0:RelatedTareRefno': @tax_period_ind == 'N' ? @return_periods[@related_return].tare_refno : nil,
          'ins0:SrpbRefno': @tax_period_ind == 'N' ? @return_periods[@related_return].srpb_refno : nil,
          'ins0:Tonnage': @tax_tonnage, 'ins0:Rate': tax_rate, 'ins0:CreditAmount': credit_amount }
      end

      # Create a new instance based on a back office style hash (@see SlftReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(raw_hash, attribute_hash) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        output = {}

        # Assigning other required attributes
        %i[rate_date site_name period_start period_end].each do |key|
          output[key] = attribute_hash.delete(key)
        end

        output[:tlb_refno] = raw_hash[:tlb_refno]
        output[:attribute_type] = raw_hash[:attribute_type]
        output[:aggregate_type] = raw_hash[:aggregate_type]
        output[:tax_credit_type] = raw_hash[:tax_credit_type]
        output[:related_tare_refno] = raw_hash[:related_tare_refno]
        output[:credit_amount] = raw_hash[:credit_amount]
        output[:tax_tonnage] = raw_hash[:tonnage]
        output[:tax_rate] = raw_hash[:rate]
        # Assign related reference data if present
        output[:tax_period_ind] = raw_hash[:related_tare_refno].nil? ? 'Y' : 'N'
        output[:related_return] = raw_hash[:srpb_refno] if raw_hash[:srpb_refno].present?

        # Create new instance
        CreditClaim.new_from_fl(output)
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :credit_claims,
           divider: false,
           display_title: true,
           type: :table,
           key: :credit_claims_title,
           key_scope: %i[returns sat credit_claims],
           row_cells: [{ list_items: [{ code: :aggregate_type, action_name: :pdf_label }] },
                       { list_items: [{ code: :tax_credit_type_display }] },
                       { list_items: [{ code: :relates_to_pdf, action_name: :pdf_label, when: :tax_period_ind,
                                        is: ['N'] }] },
                       { list_items: [{ code: :return_period_display, action_name: :pdf_label, when: :tax_period_ind,
                                        is: ['N'] }] },
                       { list_items: [{ code: :tax_tonnage }] },
                       { list_items: [{ code: :tax_rate }] },
                       { list_items: [{ code: :credit_amount }] }] }]
      end

      # Format tax_tonnage for display purpose
      def tax_tonnage_display
        format_tonnage_value(@tax_tonnage)
      end

      private

      # @return [Hash] elements used to specify what data we want to send to the back office
      def additional_parameters
        { Service: 'SAT', RateEffectiveDate: @rate_date }
      end

      # calls the back office to get the aggregate types data
      # @return [array] The bo data indexed
      def aggregate_type_rates
        @aggregate_type_rates = []

        call_ok?(:get_aggregate_type_rates, additional_parameters) do |body|
          ServiceClient.iterate_element(body[:aggregate_types]) do |types|
            @aggregate_type_rates.push(types)
          end
        end
        @aggregate_type_rates
      end

      # calls the ReturnPeriod model to get the data from the back office
      # @return [array] The bo data indexed
      def return_previous_periods_list
        return @return_periods if @return_periods

        requesting_user = current_user || Thread.current[:usr]
        @return_periods = {}
        PreviousReturnPeriods.all(requesting_user, @period_start).each do |prev_period| # rubocop:disable Rails/FindEach
          @return_periods[prev_period.srpb_refno] = prev_period
        end
      rescue StandardError => e
        Rails.logger.warn("No periods found on the back office for this enrolment reference #{e.message}")
        @return_periods
      end
    end
  end
end
