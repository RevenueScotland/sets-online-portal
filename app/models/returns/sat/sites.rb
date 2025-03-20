# frozen_string_literal: true

module Returns
  module Sat
    # Sat returns contain site specific information.  There can be multiple sites per period
    class Sites < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
      # Attributes for this class, in list so can re-use
      def self.attribute_list
        %i[period_bdown_start period_bdown_end rate_date site_ref site_party_ref site_party_name site_name
           taxable_tonnage exempt_tonnage tax_due tax_credits tax_payable taxable_aggregates exempt_aggregates
           credit_claims tld_nil_submit]
      end

      # Enable validating the tld_nil_submit field based on accessor
      attr_accessor :validate_nil_submit

      attribute_list.each { |attr| attr_accessor attr }
      validates :tld_nil_submit, presence: true, if: :validate_nil_submit

      # converts the selected period index back to a user readable value
      # @return [array] The dates in a user readable value
      def selected_return_period
        # Need to format the date to show dd/mm/yy else the date will show as yyyy-mm-dd
        start_date = DateFormatting.to_display_date_format(@period_bdown_start)
        end_date = DateFormatting.to_display_date_format(@period_bdown_end)

        "#{start_date} to #{end_date}"
      end

      # sum of all the tax_due based on the taxable aggregate entries
      def total_tax_due
        sum_from_values(taxable_aggregates, :tax_due)
      end

      # Sum of all the exploited_tonnage based on the taxable aggregate entries
      def net_exploited_tonnage
        sum_from_values(taxable_aggregates, :exploited_tonnage)
      end

      # Sum of all the taxable_tonnage based on the taxable aggregate entries
      def net_taxable_tonnage
        sum_from_values(taxable_aggregates, :taxable_tonnage)
      end

      # Sum of all the taxable tonnage (for the site) shown on the summary screen
      def taxable_tonnage
        net_taxable_tonnage
      end

      # Sum of all the exempt tonnage (for the site) shown on the summary screen
      def exempt_tonnage
        net_exempt_tonnage
      end

      # Sum of all the tax due (for the site) shown on the summary screen
      def tax_due
        total_tax_due
      end

      # Sum of all the tax credits (for the site) shown on the summary screen
      def tax_credits
        total_credit_amount
      end

      # The tax payable (for the site) shown on the summary screen
      def tax_payable
        from_pence(to_pence(total_tax_due - tax_credits)).to_d
      end

      # sum of all the exempt_tonnage based on the exempt aggregate entries
      def net_exempt_tonnage
        sum_from_values(exempt_aggregates, :exempt_tonnage)
      end

      # Sum of all the credit_amount based on the tax credit entries
      def total_credit_amount
        sum_from_values(credit_claims, :credit_amount)
      end

      # @return a hash suitable for use for each of the sites in a calc request to the back office
      def request_site_calc
        {
          'ins1:PeriodBDownStart': @period_bdown_start,
          'ins1:TaxableAggregates': request_tax_calc,
          'ins1:CreditClaims': request_credit_calc
        }
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_tax_calc
        return if taxable_aggregates.blank?

        {
          'ins1:TaxableAggregate': taxable_aggregates.values.map(&:request_tax_calc)
        }
      end

      # Define the ref data codes associated with the attributes not to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        {
          nil_submission: YESNO_COMP_KEY
        }
      end

      # This method is used for displaying Nil Submission in the return summary page table
      def tld_value
        return nil if tld_nil_submit != 'Y'

        tld_nil_submit.to_s
      end

      # Return value for Aggregate activity radio button
      def tld_display_value
        return nil if tld_nil_submit.nil?

        tld_nil_submit == 'Y' ? 'N' : 'Y'
      end

      # Nil Submission should be either 'Yes' or Nil in the B.O
      def tld_xml_value
        return nil if tld_nil_submit != 'Y'

        'Y'
      end

      # Checks to see that the user has entered data for a site
      # they only need to fill out one of the three sections or can fill out all three
      # @return true if no data has been entered
      def missing_sat_details_data?
        invert_detail_present?(taxable_aggregates) && invert_detail_present?(exempt_aggregates) &&
          invert_detail_present?(credit_claims)
      end

      # This method is used to invert the present? method e.g., !detail.present?
      # @return true if key is not present?
      def invert_detail_present?(key)
        return false if key.present?

        true
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_credit_calc
        return if credit_claims.blank?

        {
          'ins1:CreditClaim': credit_claims.values.map(&:request_credit_calc)
        }
      end

      # This method returns the print items for site based on Nil Submission
      def print_items
        common_items = %w[site_name selected_return_period tld_nil_submit]
        tonnage_fields = %w[net_taxable_tonnage net_exempt_tonnage total_tax_due total_credit_amount
                            tax_payable]
        if tld_nil_submit == 'Y'
          common_items
        else
          (common_items + tonnage_fields).reject do |x|
            x == 'tld_nil_submit'
          end
        end
      end

      # This method returns a hash for list_items in print_layout
      def site_list_items
        money_fields = %w[total_tax_due total_credit_amount tax_payable]
        field_list = []
        print_items.each do |t|
          list_item = { code: t.to_sym, action_name: :pdf_label }
          list_item[:format] = :money if money_fields.include? t
          field_list.push(list_item) unless field_list.include? list_item
        end
        field_list
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :sites,
           page_break: false,
           divider: true,
           display_title: true,
           type: :list,
           name: { code: :site_party_name },
           key_scope: %i[returns sat sites],
           list_items: site_list_items,
           footer: ' ' },
         { code: :taxable_aggregates,
           type: :table,
           display_title: true,
           key: :title,
           key_scope: %i[returns sat taxable_aggregates] },
         { code: :exempt_aggregates,
           type: :table,
           display_title: true,
           key: :title,
           key_scope: %i[returns sat exempt_aggregate] },
         { code: :credit_claims,
           type: :table,
           display_title: true,
           key: :title,
           key_scope: %i[returns sat credit_claim] }]
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        # doesn't include '@total_tonnage as that's always derived
        output = { 'ins0:TaxlPartyRef': @site_party_ref, 'ins0:TaxlPartyName': @site_party_name,
                   'ins0:TaxlRefno': @site_ref, 'ins0:TaxlName': @site_name,
                   'ins0:PeriodBDownStart': @period_bdown_start, 'ins0:PeriodBDownEnd': @period_bdown_end,
                   'ins0:TotalTaxableTonnage': net_taxable_tonnage, 'ins0:TotalExemptTonnage': net_exempt_tonnage,
                   'ins0:TotalTaxDue': total_tax_due, 'ins0:TotalTaxCredits': total_credit_amount,
                   'ins0:TotalTaxPayable': tax_payable, 'ins0:TldNilSubmit': tld_xml_value }

        output['ins0:TaxableAggregates'] =
          taxable_aggregates.blank? ? nil : { 'ins0:TaxableAggregate': taxable_aggregates.values.map(&:request_save) }

        output['ins0:ExemptAggregates'] =
          exempt_aggregates.blank? ? nil : { 'ins0:ExemptAggregate': exempt_aggregates.values.map(&:request_save) }

        output['ins0:CreditClaims'] =
          credit_claims.blank? ? nil : { 'ins0:CreditClaim': credit_claims.values.map(&:request_save) }

        output
      end

      # Create a new instance based on a back office style hash (@see SlftReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(raw_hash) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        output = {}

        output[:site_party_ref] = raw_hash[:taxl_party_ref]
        output[:site_party_name] = raw_hash[:taxl_party_name]
        output[:site_ref] = raw_hash[:taxl_refno]
        output[:site_name] = raw_hash[:taxl_name]
        output[:period_bdown_start] = raw_hash[:period_b_down_start]
        output[:period_bdown_end] = raw_hash[:period_b_down_end]
        output[:rate_date] = raw_hash[:period_b_down_start]
        output[:taxable_tonnage] = raw_hash[:total_taxable_tonnage]
        output[:exempt_tonnage] = raw_hash[:total_exempt_tonnage]
        output[:tax_due] = raw_hash[:total_tax_due]
        output[:tax_credits] = raw_hash[:total_tax_credits]
        output[:tax_payable] = raw_hash[:total_tax_payable]
        output[:tld_nil_submit] = raw_hash[:tld_nil_submit]

        output[:taxable_aggregates] = convert_taxable_aggregates(raw_hash)

        output[:exempt_aggregates] = convert_exempt_aggregates(raw_hash)

        output[:credit_claims] = convert_credit_claims(raw_hash)

        # Create new instance
        Sites.new_from_fl(output)
      end

      # @!method self.convert_taxable_aggregates(taxable_aggregates)
      # Convert the taxable aggregates data (raw hash) into aggregates objects
      # @param raw_hash [Hash] the back office data
      # @return [Hash] taxable aggregates indexed by uuid
      private_class_method def self.convert_taxable_aggregates(raw_hash)
        output = {}
        ServiceClient.iterate_element(raw_hash.delete(:taxable_aggregates)) do |aggregate_hash|
          # passing the rate date and site name as we don't have in BO hash for taxable aggregate
          aggregate_hash[:rate_date] = raw_hash[:period_b_down_start]
          aggregate_hash[:site_name] = raw_hash[:taxl_name]

          aggregate = TaxableAggregate.new_from_fl(aggregate_hash)

          # taxable aggregate ref must be an integer
          output[aggregate.uuid] = aggregate
        end

        output
      end

      # @!method self.convert_exempt_aggregates(exempt_aggregates)
      # Convert the exempt aggregates data (raw hash) into exempt objects
      # @param raw_hash [Hash] the back office data
      # @return [Hash] exempt aggregates indexed by uuid
      private_class_method def self.convert_exempt_aggregates(raw_hash)
        output = {}
        ServiceClient.iterate_element(raw_hash.delete(:exempt_aggregates)) do |exempt_hash|
          # passing the rate date as we don't have in BO hash for exempt aggregate
          exempt_hash[:rate_date] = raw_hash[:period_b_down_start]
          exempt_hash[:site_name] = raw_hash[:taxl_name]

          exempt_agg = ExemptAggregate.new_from_fl(exempt_hash)

          # exempt aggregate ref must be an integer
          output[exempt_agg.uuid] = exempt_agg
        end

        output
      end

      # @!method self.convert_credit_claims(credit_claims)
      # Convert the credit claims data (raw hash) into claim objects
      # @param raw_hash [Hash] the back office data
      # @return [Hash] credit claims indexed by uuid
      private_class_method def self.convert_credit_claims(raw_hash)
        output = {}
        ServiceClient.iterate_element(raw_hash.delete(:credit_claims)) do |claim_hash|
          # passing the rate date as we don't have in BO hash for credit claim
          claim = CreditClaim.convert_back_office_hash(claim_hash, assign_attribute_hash(raw_hash))

          # credit claim ref must be an integer
          output[claim.uuid] = claim
        end

        output
      end

      # @!method self.assign_attribute_hash(credit_claims)
      # Creates a output hash to assign the attributes for credit claims objects
      # @param raw_hash [Hash] the back office data
      private_class_method def self.assign_attribute_hash(raw_hash)
        output = {}

        output[:rate_date] = raw_hash[:period_b_down_start]
        output[:site_name] = raw_hash[:taxl_name]
        output[:period_start] = raw_hash[:period_b_down_start]
        output[:period_end] = raw_hash[:period_b_down_end]

        output
      end
    end
  end
end
