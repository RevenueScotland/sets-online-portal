# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Methods for calculating taxes and holding the results
    # Split out from and used by LbttReturn which was getting too big.
    # Uses lbtt. at various points to access the LBTT model object (ie must be set up by the controller).
    class Tax < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
      include CommonValidation

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      # NB flbt_type is passed in by the form for validation as we don't have access to it otherwise
      def self.attribute_list
        %i[calculated ads_due total_reliefs npv npv_tax_due amount_already_paid
           linked_npv total_ads_reliefs ads_repay_amount_claimed premium_tax_due]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # Not including in the attribute_list so it can't be changed by the user
      attr_accessor :orig_calculated, :orig_ads_due, :orig_total_reliefs, :orig_npv,
                    :orig_npv_tax_due, :orig_premium_tax_due, :orig_total_due, :orig_total_ads_reliefs,
                    :orig_linked_npv, # this isn't used but we create orig_ values automatically so keeping it for that
                    :flbt_type, :ads_sold_main_yes_no, :linked_ind # HACK: values copied from LbttReturn for validation

      # calc_already_paid page has amount_already paid which is only shown if type is not CONVEY or LEASERET
      # and amount_already_paid is also on the calculation page in a section only for LEASEREV, ASSIGN or TERMINATE
      # So basically it's only for LEASEREV, ASSIGN or TERMINATE unless we add a new type
      validates :amount_already_paid, presence: true, numericality: { greater_than_or_equal_to: 0,
                                                                      less_than: 1_000_000_000_000_000_000 },
                                      format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                      on: :amount_already_paid, if: :leaserev_assign_terminate?

      # calculation page - the rules on that page are defined here so that whole model validation also works correctly
      validates :calculated, presence: true, numericality: true,
                             format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: :calculated, if: :convey?

      validates :ads_due, presence: true, numericality: true, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                          on: %i[calculated ads_due], if: :convey?
      validates :total_reliefs, presence: true,
                                numericality: { greater_than_or_equal_to: 0,
                                                less_than_or_equal_to: proc { |s| s.calculated.to_f } },
                                format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: :calculated,
                                if: :convey?
      validates :total_ads_reliefs, presence: true,
                                    numericality: { greater_than_or_equal_to: 0,
                                                    less_than_or_equal_to: proc { |s| s.ads_due.to_f } },
                                    format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: :calculated,
                                    if: :convey?

      validates :npv_tax_due, presence: true, numericality: true,
                              format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: :npv_tax_due,
                              unless: :convey?
      validates :premium_tax_due, presence: true, numericality: true,
                                  format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: :npv_tax_due,
                                  unless: :convey?
      validates :total_reliefs, presence: true,
                                numericality: {
                                  greater_than_or_equal_to: 0,
                                  less_than_or_equal_to: proc { |s| s.calculated_for_lease.to_f }
                                },
                                format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                on: :npv_tax_due, if: :leaseret?

      # ads_repay_details
      validates :ads_repay_amount_claimed, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000 },
                                           format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                                           on: :ads_repay_amount_claimed, if: :ads_repayment?

      # npv page
      validates :npv, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000 },
                      format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true, on: :npv,
                      unless: :convey?
      validates :linked_npv, numericality: { greater_than_or_equal_to: 0,
                                             less_than: 1_000_000_000_000_000_000 }, presence: true,
                             format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, on: :linked_npv,
                             if: :linked_ind_and_not_convey?

      # The total liability before any reliefs are added
      def due_before_reliefs
        from_pence(to_pence(@calculated) + to_pence(@ads_due))
      end

      # The original total liability before any reliefs are added
      def orig_due_before_reliefs
        # use round to avoid funny trailing decimals
        from_pence(to_pence(@orig_calculated) + to_pence(@orig_ads_due))
      end

      # The tax due based from liability either conveyance or lease less any reliefs
      def tax_due
        from_pence_advantageous_round(
          (to_pence(@calculated) + to_pence(@ads_due) + to_pence(@npv_tax_due) + to_pence(premium_tax_due)) -
          (to_pence(@total_reliefs) + to_pence(total_ads_reliefs))
        )
      end

      # The tax due based from liability either conveyance or lease less any reliefs
      def orig_tax_due
        from_pence_advantageous_round(
          (to_pence(@orig_calculated) + to_pence(@orig_ads_due) + to_pence(@orig_npv_tax_due) +
           to_pence(@orig_premium_tax_due)) -
          (to_pence(@orig_total_reliefs) + to_pence(@orig_total_ads_reliefs))
        )
      end

      # The tax due for return is tax_due minus amount_already_paid.  It's always rounded to the lower whole number
      # if it's a positive figure.  If it's negative then it's always rounded to the higher whole number.
      def tax_due_for_return
        from_pence_advantageous_round(to_pence(tax_due) - to_pence(@amount_already_paid))
      end

      # This derives the total calculated amount for a lease i.e. the npv and premium tax due
      def calculated_for_lease
        from_pence(to_pence(@npv_tax_due) + to_pence(@premium_tax_due))
      end

      # Validation method to check model flbt_type
      def convey?
        @flbt_type == 'CONVEY'
      end

      # Validation method to check model flbt_type
      def leaseret?
        @flbt_type == 'LEASERET'
      end

      # Validation method to check model flbt_type
      def convey_or_leaseret?
        %w[CONVEY LEASERET].include? @flbt_type
      end

      # Validation method to check model flbt_type
      def leaserev_assign_terminate?
        %w[LEASEREV ASSIGN TERMINATE].include? @flbt_type
      end

      def linked_ind_and_not_convey?
        return false if convey?

        @linked_ind == 'Y'
      end

      # Validation method to check if ADS repayment is applicable.
      # HACK: Copied from @see LbttAdsController#ads_repay_reason_next_steps because Tax can't access LbttReturn when
      # doing model-based validation
      def ads_repayment?
        @ads_sold_main_yes_no == 'Y'
      end

      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :calculation,
           key: :edit_calculation, # key for the title translation
           key_scope: %i[returns lbtt summary], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list,
           list_items: [{ code: :calculated, format: :money, when: :flbt_type, is: ['CONVEY'] },
                        { code: :ads_due, format: :money, when: :flbt_type, is: ['CONVEY'] },
                        { code: :ads_repay_amount_claimed, format: :money, when: :flbt_type, is: ['CONVEY'] },
                        { code: :due_before_reliefs, format: :money, when: :flbt_type, is: ['CONVEY'] },
                        { code: :total_ads_reliefs, format: :money, when: :flbt_type, is: ['CONVEY'] },
                        { code: :npv, format: :money, when: :flbt_type, is_not: ['CONVEY'] },
                        { code: :linked_npv, format: :money, when: :flbt_type, is_not: ['CONVEY'] },
                        { code: :npv_tax_due, format: :money, when: :flbt_type, is_not: ['CONVEY'] },
                        { code: :premium_tax_due, format: :money, when: :flbt_type, is_not: ['CONVEY'] },
                        { code: :total_reliefs, format: :money },
                        { code: :tax_due, format: :money },
                        { code: :amount_already_paid, format: :money,
                          when: :flbt_type, is: %w[LEASEREV ASSIGN TERMINATE] },
                        { code: :tax_due_for_return, format: :money,
                          when: :flbt_type, is: %w[LEASEREV ASSIGN TERMINATE] }] }]
      end

      # Returns a translation attribute where a given attribute may have more than one name based on e.g. a type
      # it also allows for a different attribute name for the error region for e.g. long labels
      # @param attribute [Symbol] the name of the attribute to translate
      # @param translation_options [Object] extra information passed from the page
      # @param _error_attribute [Boolean] is the translation being called for the error region
      # @return [Symbol] the name of the translation attribute
      def translation_attribute(attribute, translation_options = nil, _error_attribute = false)
        return :ads_due_repay_original if attribute == :ads_due && translation_options == :original

        attribute
      end

      # A brief summary of the tax calculations
      def to_s
        "Tax calculated #{@calculated} Tax due #{tax_due} Orig tax due #{orig_tax_due}"
      end

      # Method to ensure the Tax sub-object is created and up to date with the values it needs copying into it.
      # Ideally the Tax model would have a reference to the LbttReturn model but for now, we're copying the required
      # values instead.
      # @param lbtt_return [LbttReturn] the parent model in which to create/refresh the tax model
      # @param force_clear [Boolean] force creation of a new model
      # @param values [Hash] any initial values for the model
      def self.setup_tax(lbtt_return, force_clear = false, values = {})
        # ensure these values are copied from lbtt (unless overridden in initial_values) to assist validation
        values[:flbt_type] ||= lbtt_return.flbt_type
        values[:ads_sold_main_yes_no] ||= lbtt_return.ads_sold_main_yes_no
        values[:linked_ind] ||= lbtt_return.linked_ind

        if force_clear
          lbtt_return.tax = Lbtt::Tax.new(values)
          return
        end

        # ensure the Tax model exists and the important values are updated from values
        lbtt_return.tax ||= Lbtt::Tax.new
        %i[flbt_type ads_sold_main_yes_no linked_ind].each { |attr| lbtt_return.tax.send("#{attr}=", values[attr]) }
      end

      # Summary data about the calculation data in this return.
      # @see calculation.html.erb which this summary effectively duplicates.
      # If there is no calculation data then .blank? will be true.
      # @return [Hash] of [ attribute => data ]
      def calculation_summary(lbtt)
        output = {}
        prefix = 'activemodel.attributes.returns/lbtt/tax'

        if lbtt.flbt_type == 'CONVEY'
          calculation_summary_convey(prefix, output, lbtt)
        else
          calculation_summary_non_convey(prefix, output, lbtt)
        end

        # format to show pound sign, 2dp for pence and 0 if the value is empty
        output.transform_values { |v| '&#163;'.html_safe + NumberFormatting.to_money_format(v).to_s }
      end

      # split from #calculation_summary
      def calculation_summary_convey(prefix, output, lbtt)
        show_ads = lbtt.show_ads?
        output["#{prefix}.calculated"] = @calculated
        output["#{prefix}.ads_due"] = @ads_due if show_ads
        # if ads is not due then due before reliefs and calculated is the same value so only show the calculated
        output["#{prefix}.due_before_reliefs"] = due_before_reliefs if show_ads
        output["#{prefix}.total_reliefs"] = @total_reliefs
        output["#{prefix}.total_ads_reliefs"] = @total_ads_reliefs if show_ads
        output["#{prefix}.tax_due"] = tax_due
      end

      # split from #calculation_summary
      def calculation_summary_non_convey(prefix, output, lbtt)
        output["#{prefix}.npv_tax_due"] = @npv_tax_due
        output["#{prefix}.premium_tax_due"] = @premium_tax_due

        if %w[LEASEREV ASSIGN TERMINATE].include? lbtt.flbt_type
          output["#{prefix}.tax_due"] = tax_due
          output["#{prefix}.amount_already_paid"] = @amount_already_paid
          output["#{prefix}.tax_due_for_return"] = tax_due_for_return
        else
          output["#{prefix}.total_reliefs"] = @total_reliefs
          output["#{prefix}.tax_due"] = tax_due
        end
      end

      # For loading an LBTT record's Tax part.
      # Moves all the tax calculations data into a new Tax object at output[:tax] based on the attribute
      # list in this class.  Assumes each attribute has a corresponding orig_<attribute name> and checks for that
      # (ie we don't hard code them all).
      # Note that matched attributes are removed from the hash to stop them being matched into the main lbtt_return
      # except for flbt
      # @param output [Hash] the hash from the back office being converted to native format.
      def self.convert_tax_calculations(output) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        new_hash = {}
        # put tax entries (including orig_ versions) into it
        # note it is possible to get attribute or original or both
        Lbtt::Tax.attribute_list.each do |attr|
          output_attr = (attr == :npv ? :net_present_value : attr)
          if output.key?(output_attr)
            new_hash[attr] = (output_attr == :flbt_type ? output[output_attr] : output.delete(output_attr))
          end

          orig_output_attr = "orig_#{output_attr}".to_sym
          new_hash["orig_#{attr}".to_sym] = output.delete(orig_output_attr) if output.key?(orig_output_attr)
        end
        # Set the ads repayment amount from the repayment amount claimed
        new_hash[:ads_repay_amount_claimed] = output[:repayment_amount_claimed] unless output[:ads_sold_date].blank?

        # delete the fields from the back office that are derived locally in the tax model
        %i[due_before_reliefs orig_due_before_reliefs
           tax_due orig_tax_due tax_due_for_return].each { |attr| output.delete(attr) }

        # setup tax object
        Lbtt::Tax.new(new_hash)
      end

      # Calculate the linked totals based on the linked transactions field if the user has said there are linked
      # transactions.
      # NB this may overwrite any previous totals but we do not save the model here.
      def calculate_linked_totals(lbtt)
        return unless lbtt.linked_ind == 'Y'

        Rails.logger.debug('Calculating sum of linked NPV')
        @linked_npv = sum_from_values(lbtt.link_transactions, :npv_inc)
      end

      # Populates and returns the totals calculations by calling the back office (overwrites any user-edited data).
      # Also populates the "orig_" versions of each field so we keep a record of the non-editable version.
      # Calls a #request_calc method to produce the request.
      # @param requested_by [User] the user saving the return (ie current_user)
      # @param lbtt [LbttReturn] the LbttReturn object this tax object is associated with
      # @param update_orig_fields [Boolean] whether or not to update the orig_<attribute> field equivalents or not
      #        ie whether we want to keep the data the back office sent regardless of what the user changes
      #        (if we've already saved it and are updating the calculations then we wouldn't want to overwrite it.)
      def calculate_tax(requested_by, lbtt, update_orig_fields = false)
        # when called by a public user requested_by will be nil
        additional_parameters = if requested_by
                                  { Username: requested_by.username, PartyRef: requested_by.party_refno }
                                else
                                  { Authenticated: 'No' }
                                end

        call_ok?(:lbtt_calc, additional_parameters.merge!(request_calc(lbtt))) do |body|
          assign_attributes(convert_back_office_hash(body, update_orig_fields))
          set_lbtt_values(body, lbtt)
        end
      end

      private

      # Method to convert back office Tax calculations hash into a suitable format for loading into a Tax object.
      # @param update_orig_fields [Boolean] see #calculate_tax
      def convert_back_office_hash(body, update_orig_fields)
        output = {}

        if body.key? :conv_tax_payable
          conveyance_tax_response(body, output)
        else
          lease_tax_response(body, output)
        end

        # duplicate the entries to save the original values
        output.keys.each { |key| output["orig_#{key}"] = output[key]&.dup } if update_orig_fields

        output
      end

      # Extract back office tax response details for a conveyance type response
      # @param body Back office response data
      def conveyance_tax_response(body, merge)
        conv_tax_payable = body[:conv_tax_payable]
        merge['calculated'] = conv_tax_payable[:lbtt_calculated]
        merge['ads_due'] = conv_tax_payable[:ads_payable]
        merge['total_reliefs'] = conv_tax_payable[:total_reliefs_claimed]
        merge['total_ads_reliefs'] = conv_tax_payable[:total_ads_reliefs_claimed]
      end

      # Extract back office tax response details for a non-conveyance type response
      # @param body Back office response data
      def lease_tax_response(body, merge)
        lease_tax_payable = body[:lease_tax_payable]
        merge['npv'] = lease_tax_payable[:npv]
        merge['npv_tax_due'] = lease_tax_payable[:tax_liabilityon_npv]
        merge['premium_tax_due'] = lease_tax_payable[:tax_liabilityon_premium]
        merge['total_reliefs'] = lease_tax_payable[:total_reliefs_claimed]
        merge['linked_npv'] = lease_tax_payable[:total_linked_npv]
      end

      # Set relevant fields in the LBTT model.
      def set_lbtt_values(body, lbtt)
        # update calculated conv field not in tax model
        lbtt.linked_consideration = body[:conv_tax_payable][:total_linked_transactions] if body.key? :conv_tax_payable

        # updates calculated lease field not in tax model
        lbtt.linked_lease_premium = body[:lease_tax_payable][:total_linked_premium] if body.key? :lease_tax_payable
      end

      # @return a hash suitable for use in a calc request to the back office.
      # @param lbtt [LbttReturn] contains details related to the calculate request
      def request_calc(lbtt)
        output = {
          'ins1:EffectiveDate': DateFormatting.to_xml_date_format(lbtt.effective_date),
          'ins1:ContractDate': DateFormatting.to_xml_date_format(lbtt.contract_date)
        }

        # decide what data to send based on the type
        if lbtt.flbt_type == 'CONVEY'
          request_calc_convey(output, lbtt)
        else
          request_calc_lease(output, lbtt)
        end

        # put the top tag in place
        { 'ins1:LBTTReturnDetails': output }
      end

      # Conveyance part of the calc request
      # For some fields, if the indicator is yes then we take the value the user may have updated, otherwise we send 0.
      # @param output [Hash] the output datastructure which forms the request
      # @param lbtt [LbttReturn] the LBTT model
      def request_calc_convey(output, lbtt) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        Rails.logger.info('Sending conveyance type calculation request')

        # put basic request together
        conv_details = output['ins1:ConvDetails'] = {
          'ins1:PropertyType': lbtt.convert_property_type,
          'ins1:TransactionDetails' => {}
        }

        # pointer to child hash
        tr_details = conv_details['ins1:TransactionDetails']

        # set to zero if ADS section is not shown
        show_ads = lbtt.show_ads?
        tr_details['ins1:ADSAmountLiable'] = show_ads ? lbtt.ads_amount_liable : 0

        tr_details['ins1:SumofLinkedTrans'] = lbtt.linked_ind == 'Y' ? lbtt.linked_consideration : 0

        # non-ADS reliefs
        non_ads_ind = lbtt.non_ads_reliefclaim_option_ind
        sum_reliefs = non_ads_ind == 'Y' ? sum_from_values(lbtt.non_ads_relief_claims, :relief_amount) : 0
        tr_details['ins1:SumofReliefs'] = sum_reliefs

        # ADS reliefs (set to zero if ADS section is not shown)
        ads_ind = lbtt.ads_reliefclaim_option_ind
        ads_ind = 'N' unless show_ads
        sum_ads = ads_ind == 'Y' ? sum_from_values(lbtt.ads_relief_claims, :relief_amount) : 0
        tr_details['ins1:SumofADSReliefs'] = sum_ads

        tr_details['ins1:TotalConsideration'] = lbtt.total_consideration
        tr_details['ins1:NonChargeableConsideration'] = lbtt.non_chargeable
        tr_details['ins1:TotalConsiderationRemaining'] = lbtt.remaining_chargeable
      end

      # Lease part of the calc request
      # @param output [Hash] the output datastructure which forms the request
      # @param lbtt [LbttReturn] the LBTT model
      def request_calc_lease(output, lbtt) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/LineLength
        Rails.logger.info('Sending lease type calculation request')

        # put basic request together
        lease_details = output['ins1:LeaseDetails'] = {
          'ins1:PropertyType': lbtt.convert_property_type,
          'ins1:LeaseStartDate': DateFormatting.to_xml_date_format(lbtt.lease_start_date),
          'ins1:LeaseEndDate': DateFormatting.to_xml_date_format(lbtt.lease_end_date)
        }

        # Pass annual rent if all the rent values are declared to be the same, else pass the individual years' data
        if lbtt.rent_for_all_years == 'Y'
          lease_details['ins1:AnnualRent'] = lbtt.annual_rent
        else
          lease_details['ins1:RentalYears'] = { 'ins1:Years': lbtt.yearly_rents.map(&:request_save_for_calc) }
        end

        # child part of the request
        tr_details = lease_details['ins1:TransactionDetails'] = {}

        # if the indicator is yes the derive this from the value the user was shown/edited, otherwise send 0
        if lbtt.linked_ind == 'Y'
          tr_details['ins1:SumofLinkedNPV'] = lbtt.tax.linked_npv
          tr_details['ins1:SumofLinkedPremium'] = lbtt.linked_lease_premium
        else
          tr_details['ins1:SumofLinkedNPV'] = tr_details['ins1:SumofLinkedPremium'] = 0
        end

        op_in = lbtt.non_ads_reliefclaim_option_ind
        tr_details['ins1:SumofReliefs'] = op_in ? sum_from_values(lbtt.non_ads_relief_claims, :relief_amount) : 0

        tr_details['ins1:Premium'] = lbtt.premium_paid == 'Y' ? or_zero(lbtt.lease_premium) : 0

        tr_details['ins1:RelevantRentalFigure'] = lbtt.relevant_rent

        # NPV value the user has seen/agreed/updated
        tr_details['ins1:OverriddenNPV'] = lbtt.tax.npv if lbtt.tax.npv.present?
      end
    end
  end
end
