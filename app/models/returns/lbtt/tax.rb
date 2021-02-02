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

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      # NB flbt_type is passed in by the form for validation as we don't have access to it otherwise
      def self.attribute_list
        %i[calculated ads_due total_reliefs npv npv_tax_due amount_already_paid
           linked_npv total_ads_reliefs premium_tax_due]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # Not including in the attribute_list so it can't be changed by the user
      attr_accessor :orig_calculated, :orig_ads_due, :orig_total_reliefs, :orig_npv,
                    :orig_npv_tax_due, :orig_premium_tax_due, :orig_total_due, :orig_total_ads_reliefs,
                    :orig_linked_npv, # this isn't used but we create orig_ values automatically so keeping it for that
                    # HACK: values copied from LbttReturn for validation and printing
                    :flbt_type, :linked_ind

      # calc_already_paid page has amount_already paid which is only shown if type is not CONVEY or LEASERET
      # and amount_already_paid is also on the calculation page in a section only for LEASEREV, ASSIGN or TERMINATE
      # So basically it's only for LEASEREV, ASSIGN or TERMINATE unless we add a new type
      validates :amount_already_paid, numericality: { greater_than_or_equal_to: 0,
                                                      less_than: 1_000_000_000_000_000_000,
                                                      allow_blank: true }, presence: true,
                                      two_dp_pattern: true, on: :amount_already_paid, if: :lease_review?

      # calculation page - the rules on that page are defined here so that whole model validation also works correctly
      validates :calculated, numericality: { greater_than_or_equal_to: 0,
                                             less_than: 1_000_000_000_000_000_000,
                                             allow_blank: true }, presence: true,
                             two_dp_pattern: true, on: :calculated, if: :convey?

      validates :ads_due, numericality: { greater_than_or_equal_to: 0,
                                          less_than: 1_000_000_000_000_000_000,
                                          allow_blank: true }, presence: true,
                          two_dp_pattern: true, on: %i[calculated ads_due], if: :convey?
      validates :total_reliefs, numericality: { greater_than_or_equal_to: 0,
                                                less_than_or_equal_to: :calculated,
                                                allow_blank: true }, presence: true,
                                two_dp_pattern: true, on: :total_reliefs, if: :convey?
      validates :total_ads_reliefs, numericality: { greater_than_or_equal_to: 0,
                                                    less_than_or_equal_to: :ads_due,
                                                    allow_blank: true }, presence: true,
                                    two_dp_pattern: true, on: :total_reliefs, if: :convey?

      validates :npv_tax_due, :premium_tax_due, numericality: { greater_than_or_equal_to: 0,
                                                                less_than: 1_000_000_000_000_000_000,
                                                                allow_blank: true }, presence: true,
                                                two_dp_pattern: true, on: :npv_tax_due, unless: :convey?

      validates :total_reliefs, numericality: { greater_than_or_equal_to: 0,
                                                less_than_or_equal_to: :calculated_for_lease,
                                                allow_blank: true }, presence: true,
                                two_dp_pattern: true, on: :total_reliefs, if: :lease?

      # npv page
      validates :npv, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000,
                                      allow_blank: true }, presence: true,
                      two_dp_pattern: true,  on: :npv, unless: :convey?
      validates :linked_npv, numericality: { greater_than_or_equal_to: 0,
                                             less_than: 1_000_000_000_000_000_000, allow_blank: true }, presence: true,
                             two_dp_pattern: true, on: :linked_npv, if: :linked_ind_and_not_convey?

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
      def lease?
        @flbt_type == 'LEASERET'
      end

      # Validation method to check model flbt_type
      def lease_review?
        %w[LEASEREV ASSIGN TERMINATE].include?(@flbt_type)
      end

      def linked_ind_and_not_convey?
        return false if convey?

        @linked_ind == 'Y'
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
      # @return [Symbol] the name of the translation attribute
      def translation_attribute(attribute, translation_options = nil)
        return :ads_due_repay_original if attribute == :ads_due && translation_options == :original

        attribute
      end

      # A brief summary of the tax calculations
      def to_s
        "Tax calculated #{@calculated} Tax due #{tax_due} Orig tax due #{orig_tax_due}"
      end

      # Method to ensure the Tax sub-object is created and up to date with the values it needs from the LbttReturn
      # model.
      # @param lbtt_return [LbttReturn] the parent model in which to create/refresh the tax model
      # @param force_clear [Boolean] force creation of a new model
      def self.setup_tax(lbtt_return, force_clear: false)
        lbtt_return.tax = Lbtt::Tax.new if force_clear

        # ensure the Tax model exists and the important values are updated from values
        lbtt_return.tax ||= Lbtt::Tax.new
        %i[flbt_type linked_ind].each do |attr|
          lbtt_return.tax.send("#{attr}=", lbtt_return.send(attr))
        end
        lbtt_return.tax.update_npv_linked_from_lbtt(lbtt_return)
      end

      # For loading an LBTT record's Tax part.
      # Moves all the tax calculations data into a new Tax object at output[:tax] based on the attribute
      # list in this class.  Assumes each attribute has a corresponding orig_<attribute name> and checks for that
      # (ie we don't hard code them all).
      # @note that matched attributes are removed from the hash to stop them being matched into the main lbtt_return
      # except for flbt_type which may be needed by other sub-objects
      # @param bo_hash [Hash] the hash from the back office being converted to native format.
      def self.convert_tax_calculations(bo_hash)
        new_hash = {}

        copy_entries_from_lbtt_hash(new_hash, bo_hash)

        # delete the fields from the back office that are derived locally in the tax model
        %i[due_before_reliefs orig_due_before_reliefs
           tax_due orig_tax_due tax_due_for_return].each { |attr| bo_hash.delete(attr) }

        # populate values from main lbtt model, needed for validation
        new_hash[:flbt_type] = bo_hash[:flbt_type]
        new_hash[:linked_ind] = bo_hash[:linked_ind]

        # setup tax object
        Lbtt::Tax.new(new_hash)
      end

      # Copy tax entries (defined in attribute_list) plus orig_<attribute> versions of them, from
      # the back office hash into the new_hash.  Deletes entries in bo_hash as we go.
      # Called by/extracted from @see Tax::convert_tax_calculations
      private_class_method def self.copy_entries_from_lbtt_hash(new_hash, bo_hash)
        Lbtt::Tax.attribute_list.each do |attr|
          bo_hash_attr = (attr == :npv ? :net_present_value : attr)
          new_hash[attr] = bo_hash.delete(bo_hash_attr) if bo_hash.key?(bo_hash_attr)

          orig_bo_hash_attr = "orig_#{bo_hash_attr}".to_sym
          new_hash["orig_#{attr}".to_sym] = bo_hash.delete(orig_bo_hash_attr) if bo_hash.key?(orig_bo_hash_attr)
        end
      end

      # Populates and returns the totals calculations by calling the back office (overwrites any user-edited data).
      # Also populates the "orig_" versions of each field so we keep a record of the non-editable version.
      # Calls a #request_calc method to produce the request.
      # @param requested_by [User] the user saving the return (ie current_user)
      # @param lbtt [LbttReturn] the LbttReturn object this tax object is associated with
      # @param type [Symbol] is this doing the :npv or :main or :relief_type calculation
      #        if this is npv then we only update the npv value and ignore the other values returned
      #        if this is relief_type calculation then we pass in the overridden relief type amounts
      # @return [Boolean] true if the calculation was successful
      def calculate_tax(requested_by, lbtt, type = :main)
        # when called by a public user requested_by will be nil
        additional_parameters = if requested_by
                                  { Username: requested_by.username, PartyRef: requested_by.party_refno }
                                else
                                  { Authenticated: 'No' }
                                end

        call_ok?(:lbtt_calc, additional_parameters.merge!(request_calc(lbtt, type))) do |body|
          convert_calc_relief_claim_back_office_hash(body, lbtt)
          assign_attributes(convert_back_office_hash(body, type))
        end
      end

      # override npv value get value as per business
      def linked_npv
        @linked_npv if @linked_ind == 'Y'
      end

      # Overwrite the local linked NPV from lbtt model but only if it has changed
      # since the last time @see lbtt_return for similar logic
      def update_npv_linked_from_lbtt(lbtt_return)
        return if @linked_ind == 'N' || @flbt_type == 'CONVEY'

        current_linked_npv = sum_from_values(lbtt_return.link_transactions, :npv_inc)
        # set the linked consideration to the current summed value unless this hasn't changed since the last check
        @linked_npv = current_linked_npv unless @orig_linked_npv == current_linked_npv
        @orig_linked_npv = current_linked_npv # store the derived value for the next time
      end

      # request save specific to tax
      # @param output [Hash] the hash from the back office for an tax property
      # @param type_not_conveyance [Boolean] holding flag if return type is conveyance or not
      # @return a hash suitable for use in a save request to the back office
      def request_save(output, type_not_conveyance)
        type_not_conveyance_request(output, type_not_conveyance)
        output['ins1:Calculated'] = @calculated
        output['ins1:AdsDue'] = @ads_due
        output['ins1:DueBeforeReliefs'] = due_before_reliefs
        output['ins1:TotalReliefs'] = @total_reliefs
        output['ins1:TotalADSReliefs'] = @total_ads_reliefs
        output['ins1:TaxDue'] = tax_due
        original_tax_value_request(output)
        request_flbt_type(output)
      end

      private

      # request save specific to flbt type
      # @return a hash suitable for use in a save request to the back office
      def request_flbt_type(output)
        return unless %w[LEASEREV ASSIGN TERMINATE].include? @flbt_type

        output['ins1:AmountAlreadyPaid'] = @amount_already_paid
        output['ins1:TaxDueForReturn'] = tax_due_for_return
      end

      # request save for not conveyance
      # @param output [Hash] the hash from the back office for an tax property
      # @param type_not_conveyance [Boolean] holding flag if return type is conveyance or not
      # @return a hash suitable for use in a save request to the back office
      def type_not_conveyance_request(output, type_not_conveyance)
        return unless type_not_conveyance

        # sends 0 for linked npv if there are no linked transactions
        output['ins1:LinkedNPV'] = @linked_npv
        output['ins1:NetPresentValue'] = @npv
        output['ins1:PremiumTaxDue'] = @premium_tax_due
        output['ins1:NpvTaxDue'] = @npv_tax_due
        output['ins1:OrigNpvTaxDue'] = @orig_npv_tax_due
      end

      # request save specific to tax original value
      # @param output [Hash] the hash from the back office for an tax property
      # @return a hash suitable for use in a save request to the back office
      def original_tax_value_request(output)
        output['ins1:OrigCalculated'] = @orig_calculated
        output['ins1:OrigAdsDue'] = @orig_ads_due
        output['ins1:OrigDueBeforeReliefs'] = orig_due_before_reliefs
        output['ins1:OrigTotalReliefs'] = @orig_total_reliefs
        output['ins1:OrigTaxDue'] = orig_tax_due
        output['ins1:OrigNetPresentValue'] = @orig_npv
        output['ins1:OrigTotalADSReliefs'] = @orig_total_ads_reliefs
        output['ins1:OrigPremiumTaxDue'] = @orig_premium_tax_due
      end

      # Extract relief details from the tax response to create the relief items
      # and assigned to the lbtt_return which will split into ads and non ads reliefs
      def convert_calc_relief_claim_back_office_hash(body, lbtt)
        reliefs_hash = if body.key?(:conv_tax_payable)
                         body[:conv_tax_payable][:reliefs]
                       else
                         body[:lease_tax_payable][:reliefs]
                       end
        reliefs = []
        ServiceClient.iterate_element(reliefs_hash) do |relief|
          reliefs << ReliefClaim.new_from_fl(relief)
        end
        lbtt.relief_claims = reliefs
      end

      # Method to convert back office Tax calculations hash into a suitable format for loading into a Tax object.
      # Note that reliefs have already been converted
      # @see convert_calc_relief_claim_back_office_hash
      # @param calc_type [Symbol] @see calculate_tax
      def convert_back_office_hash(body, calc_type)
        output = {}

        if body.key? :conv_tax_payable
          conveyance_tax_response(body, output, calc_type)
        else
          lease_tax_response(body, output, calc_type)
        end

        # duplicate the entries to save the original values
        orig_hash = output.transform_keys { |key| "orig_#{key}" }
        output.merge!(orig_hash)
      end

      # Extract back office tax response details for a conveyance type response
      # @param body [Hash] Back office response data
      # @param merge [Hash] The current hash being built for this object
      # @param calc_type [Symbol] @see calculate_tax
      # @return [Hash] the current hash for this object
      def conveyance_tax_response(body, merge, calc_type)
        conv_tax_payable = body[:conv_tax_payable]

        merge['total_reliefs'] = conv_tax_payable[:total_reliefs_claimed]
        merge['total_ads_reliefs'] = conv_tax_payable[:total_ads_reliefs_claimed]

        # if this is a relief type calculation don't update the calculated values as they may have been overridden
        # we could be more rigorous and check if the original values have changed but that doesn't work if they want
        # to step through and force a recalculation
        return if calc_type == :relief_type

        merge['calculated'] = conv_tax_payable[:lbtt_calculated]
        merge['ads_due'] = conv_tax_payable[:ads_payable]
      end

      # Extract back office tax response details for a non-conveyance type response
      # @param body [Hash] Back office response data
      # @param merge [Hash] The current hash being built for this object
      # @param calc_type [Symbol] @see calculate_tax
      # @return [Hash] the current hash for this object
      def lease_tax_response(body, merge, calc_type)
        lease_tax_payable = body[:lease_tax_payable]
        # store the npv returned if this is the npv calc
        # otherwise leave in place
        if calc_type == :npv
          current_npv = lease_tax_payable[:npv]
          # if the calculated npv hasn't changed since the last calculation
          # then do not overwrite the npv or the other calculated values as these may be based on
          # an overridden npv we didn't pass in
          return if current_npv == @orig_npv

          merge['npv'] = current_npv
        end

        merge['total_reliefs'] = lease_tax_payable[:total_reliefs_claimed]

        # if this is a relief type calculation don't update the calculated values as they may have been overridden
        # see comment on conveyance
        return if calc_type == :relief_type

        merge['npv_tax_due'] = lease_tax_payable[:tax_liabilityon_npv]
        merge['premium_tax_due'] = lease_tax_payable[:tax_liabilityon_premium]
      end

      # @return a hash suitable for use in a calc request to the back office.
      # @param lbtt [LbttReturn] contains details related to the calculate request
      # @param calc_type [Symbol] is this doing the :npv or :main calculation
      def request_calc(lbtt, calc_type)
        output = {
          'ins1:EffectiveDate': DateFormatting.to_xml_date_format(lbtt.effective_date),
          'ins1:ContractDate': DateFormatting.to_xml_date_format(lbtt.contract_date)
        }

        # decide what data to send based on the type
        if lbtt.flbt_type == 'CONVEY'
          request_calc_convey(output, lbtt, calc_type)
        else
          request_calc_lease(output, lbtt, calc_type)
        end

        # put the top tag in place
        { 'ins1:LBTTReturnDetails': output }
      end

      # Conveyance part of the calc request
      # @param output [Hash] the output data structure which forms the request
      # @param lbtt [LbttReturn] the LBTT model
      # @param calc_type [Symbol] is this doing the :npv or :main or :relief_type calculation
      def request_calc_convey(output, lbtt, calc_type)
        Rails.logger.info('Sending conveyance type calculation request')

        output['ins1:ConvDetails'] = {
          'ins1:PropertyType': lbtt.lookup_ref_data_value(:property_type),
          'ins1:Reliefs': request_reliefs(lbtt, calc_type),
          'ins1:TransactionDetails' => request_calc_convey_tr_details(lbtt)
        }
      end

      # Transaction details part of a conveyance calc request
      # @note: see @lbtt_return for some of the derivations
      # @param lbtt [LbttReturn] the LBTT model
      # @return [Hash] the TransactionDetails hash
      def request_calc_convey_tr_details(lbtt)
        {
          # set to zero if ADS section is not shown
          'ins1:ADSAmountLiable': lbtt.show_ads? ? lbtt.ads.ads_amount_liable : nil,
          'ins1:SumofLinkedTrans': lbtt.linked_consideration,
          'ins1:TotalConsideration': lbtt.total_consideration,
          'ins1:NonChargeableConsideration': lbtt.non_chargeable,
          'ins1:TotalConsiderationRemaining': lbtt.remaining_chargeable
        }
      end

      # Lease part of the calc request
      # @param output [Hash] the output data structure which forms the request
      # @param lbtt [LbttReturn] the LBTT model
      # @param calc_type [Symbol] is this doing the :npv or :main or :relief_type calculation
      def request_calc_lease(output, lbtt, calc_type)
        Rails.logger.info("Sending lease type calculation request for #{calc_type}")

        # put basic request together
        lease_details = output['ins1:LeaseDetails'] = {
          'ins1:PropertyType': lbtt.lookup_ref_data_value(:property_type, lbtt.property_type || '3'),
          'ins1:Reliefs': request_reliefs(lbtt, calc_type),
          'ins1:LeaseStartDate': DateFormatting.to_xml_date_format(lbtt.lease_start_date),
          'ins1:LeaseEndDate': DateFormatting.to_xml_date_format(lbtt.lease_end_date)
        }.merge!(request_calc_lease_rent(lbtt))

        # child part of the request
        lease_details['ins1:TransactionDetails'] = request_calc_lease_tr_details(lbtt, calc_type)
      end

      # reliefs part request
      def request_reliefs(lbtt, calc_type)
        return if lbtt.relief_claims.blank?

        output = []
        output << if calc_type == :relief_type
                    lbtt.relief_claims.map(&:request_for_relief_type_calc)
                  else
                    lbtt.relief_claims.map(&:request_for_main_calc)
                  end

        # flatten and compact to ensure we create the right format output for the request without any empty entries
        { 'ins1:Relief': output.flatten&.compact }
      end

      # Rent part of the lease part of the calc request
      # @param lbtt [LbttReturn] the LBTT model
      # @return [Hash] the rent hash hash
      def request_calc_lease_rent(lbtt)
        # Pass annual rent if all the rent values are declared to be the same, else pass the individual years' data
        if lbtt.rent_for_all_years == 'Y'
          { 'ins1:AnnualRent': lbtt.annual_rent }
        else
          { 'ins1:RentalYears': { 'ins1:Years': lbtt.yearly_rents.map(&:request_save_for_calc) } }
        end
      end

      # transaction details of the lease part of the calc request
      # @note: see @lbtt_return for some of the derivations
      # @param lbtt [LbttReturn] the LBTT model
      # @param calc_type [Symbol] is this doing the :npv or :main calculation
      # @return [Hash] the TransactionDetails hash
      def request_calc_lease_tr_details(lbtt, calc_type)
        {
          'ins1:SumofLinkedNPV': lbtt.tax.linked_npv,
          'ins1:SumofLinkedPremium': lbtt.linked_lease_premium,
          'ins1:Premium': or_zero(lbtt.lease_premium),
          'ins1:RelevantRentalFigure': lbtt.relevant_rent
          # Merge NPV value the user has seen/agreed/updated but not if calculating npv
        }.merge!(calc_type == :npv ? {} : { 'ins1:OverriddenNPV': lbtt.tax.npv })
      end
    end
  end
end
