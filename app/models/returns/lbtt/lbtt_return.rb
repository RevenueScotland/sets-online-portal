# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for the LBTT return
    class LbttReturn < AbstractReturn # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData

      validates_with LbttReturnValidator, on: :submit

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[orig_return_reference flbt_type buyers sellers agent landlords tenants new_tenants properties property_type
           effective_date relevant_date contract_date lease_start_date lease_end_date business_ind exchange_ind
           previous_option_ind uk_ind sale_include_option non_ads_relief_claims non_ads_reliefclaim_option_ind
           lease_premium premium_paid linked_ind linked_consideration linked_lease_premium link_transactions
           annual_rent yearly_rents rent_for_all_years total_consideration total_vat remaining_chargeable
           contingents_event_ind deferral_agreed_ind non_chargeable deferral_reference relevant_rent
           bank_name account_number branch_code account_holder_name fpay_method
           authority_ind declaration lease_declaration parties payment_date filing_date current_flbt_type
           repayment_ind repayment_amount_claimed repayment_declaration repayment_agent_declaration account_type
           ads]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # The attribute is_public is used to determine if the return was made as a public, in other words, a
      # user who is not logged in. This needs to be populated on a new instance of a lbtt_return object.
      # LBTT tax calculations object to manage and store tax calculation results.
      # Not including in the attribute_list so it can't be posted to, ie not user editable from this object
      attr_accessor :tax, :is_public

      validates :flbt_type, presence: true, on: :flbt_type
      validates :orig_return_reference, presence: true, reference_number: true, on: :orig_return_reference

      # Transaction validation
      validates :property_type, presence: true, on: :property_type
      validates :effective_date, :relevant_date, custom_date: true, presence: true, compare_date: true,
                                                 on: :effective_date
      # Contract date is optional
      validates :contract_date, custom_date: true, compare_date: true, on: :effective_date
      validates :lease_start_date, :lease_end_date, custom_date: true, presence: true, compare_date: true,
                                                    on: :effective_date, unless: :convey?
      validates :lease_start_date, compare_date: { end_date_attr: :lease_end_date }, on: :lease_start_date
      validates :previous_option_ind, :exchange_ind,
                :uk_ind, presence: true, on: :previous_option_ind,
                         unless: :lease_review?
      validates :business_ind, presence: true, on: :business_ind, if: :convey?
      validate  :sale_include_option_valid?, on: :business_ind, if: :convey?
      validates :contingents_event_ind, presence: true, on: :contingents_event_ind,
                                        if: :convey?
      validates :deferral_agreed_ind, presence: true, on: :contingents_event_ind,
                                      if: :contingent_events?
      validates :deferral_reference, presence: true, length: { maximum: 50 }, on: :contingents_event_ind,
                                     if: :deferral_reference_required?
      # Conveyance calculations
      validates :total_consideration, presence: true, two_dp_pattern: true,
                                      numericality: { greater_than: 0,
                                                      less_than: 1_000_000_000_000_000_000,
                                                      allow_blank: true },
                                      on: :total_consideration, if: :convey?
      validates :total_vat, :non_chargeable, numericality: {
        greater_than_or_equal_to: 0, less_than_or_equal_to: proc { |s| s.total_consideration.to_f }, allow_blank: true
      }, two_dp_pattern: true, presence: true, on: :remaining_chargeable, if: :convey?
      validates :remaining_chargeable, numericality: { greater_than_or_equal_to: 0,
                                                       less_than: 1_000_000_000_000_000_000,
                                                       allow_blank: true },
                                       two_dp_pattern: true, presence: true,
                                       on: :remaining_chargeable,
                                       if: :convey?

      validates :linked_consideration, numericality: { greater_than_or_equal_to: 0,
                                                       less_than: 1_000_000_000_000_000_000,
                                                       allow_blank: true },
                                       two_dp_pattern: true, presence: true,
                                       on: :linked_consideration,
                                       if: :linked_consideration_needed?
      # linked transactions validation
      validates :linked_ind, presence: true, on: :linked_ind

      # yearly rent validation
      validates :rent_for_all_years, presence: true, on: :rent_for_all_years,
                                     unless: :convey?

      # reliefs validation
      validates :non_ads_reliefclaim_option_ind, presence: true, on: :non_ads_reliefclaim_option_ind,
                                                 unless: :lease_review?
      validates :non_ads_relief_claims, relief_type_unique: true, on: :non_ads_reliefclaim_option_ind

      # other than conveyance type calculations
      validates :annual_rent, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000,
                                              allow_blank: true },
                              two_dp_pattern: true, presence: true, on: :annual_rent,
                              unless: :convey?
      validates :premium_paid, presence: true, on: :premium_paid, unless: :convey?
      validates :lease_premium, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000,
                                                allow_blank: true },
                                two_dp_pattern: true, presence: true, on: :premium_paid, if: :premium_paid?
      validates :linked_lease_premium, numericality: { greater_than_or_equal_to: 0,
                                                       less_than: 1_000_000_000_000_000_000,
                                                       allow_blank: true },
                                       two_dp_pattern: true, presence: true, on: :linked_lease_premium,
                                       if: :linked_lease_premium_needed?
      validates :relevant_rent, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000,
                                                allow_blank: true },
                                two_dp_pattern: true, presence: true, on: :relevant_rent,
                                unless: :convey?
      # claim repayment validation
      validates :repayment_ind, presence: true, on: :repayment_ind
      validates :repayment_amount_claimed, numericality: { greater_than_or_equal_to: 0,
                                                           less_than: 1_000_000_000_000_000_000,
                                                           allow_blank: true },
                                           two_dp_pattern: true, presence: true, on: :repayment_amount_claimed
      validates :account_holder_name, :bank_name, presence: true, length: { maximum: 255 }, on: :account_holder_name
      validates :account_number, presence: true,
                                 numericality: { only_integer: true, allow_blank: true }, length: { is: 8 },
                                 on: :account_holder_name
      validates :branch_code, presence: true, bank_sort_code: true, on: :account_holder_name
      validates :repayment_declaration, acceptance: { accept: ['Y'] }, on: :repayment_declaration
      validates :repayment_agent_declaration, acceptance: { accept: ['Y'] }, on: :repayment_declaration,
                                              if: proc { |s| s.account_type == 'AGENT' }

      # declaration validation
      validates :fpay_method, presence: true, on: :fpay_method
      validates :authority_ind, presence: true, on: :authority_ind
      validates :declaration, acceptance: { accept: ['Y'] }, on: :fpay_method
      validates :lease_declaration, acceptance: { accept: ['Y'] }, on: :fpay_method,
                                    if: :lease?

      # Return the property type attribute, but if this is one of the lease reviews set to non residential
      # as we don't ask the question
      # @return [String] The current value of the property type
      def property_type
        return '3' if lease_review? && !@effective_date.blank?

        @property_type
      end

      # @return [Integer] the value of the @total_vat attribute or 0, depending on the @property_type value.
      def total_vat
        # The @property_type == '1' means it is 'Residential' and it defaults to 0 because in the page
        # the field that uses this attribute becomes hidden.
        return 0 if @property_type == '1'

        # When the @property_type is nil or equivalent to 'Non-residential' then we output the attribute's value
        @total_vat
      end

      # @return [Integer] the value of the @non_chargeable attribute or 0, depending on the @business_ind value.
      # @see business_ind? to learn more about what the @business_ind consists of and it's meaning.
      def non_chargeable
        # Defaults to 0 because in the page the field that uses this attribute becomes hidden.
        return 0 if @business_ind == 'N'

        # When the @business_ind is nil or equivalent to 'Y' then we output the attribute's value
        @non_chargeable
      end

      # @return [Integer] the value of the @remaining_chargeable or @total_consideration attribute,
      # depending on the @property_type, @business_ind, @linked_ind values.
      # @see business_ind?, linked_transaction_validation to learn more about what
      # the @business_ind, @property_type, @linked_ind consists of and their meaning.
      def remaining_chargeable
        # Defaults to the value entered in @total_consideration field because in the page the field
        # that uses this attribute becomes hidden.
        if @property_type == '1' && @business_ind == 'N' && @linked_ind == 'N'
          @total_consideration
        else
          # When the @property_type, @business_ind, @linked_ind are nil or equivalent to
          # '3' or 'Y' or 'Y' respectively then we output the attribute's value.
          @remaining_chargeable
        end
      end

      # setter for the linked consideration
      # This sets the linked consideration from the passed value and also makes sure that the original copy is set
      def linked_consideration=(value)
        @linked_consideration = value
        return unless (@orig_linked_consideration || 0).zero?

        @orig_linked_consideration = sum_from_values(@link_transactions, :consideration_amount)
      end

      # getter for the linked consideration
      # This sets the linked consideration from the link transactions but only if it has changed from the last time
      # This means we only override a value set by the user if they change the values on the source link transactions
      # we can't do this when the link transactions are set as it gets too complicated
      def linked_consideration
        return if @linked_ind == 'N' || !convey?

        current_linked_consideration = sum_from_values(@link_transactions, :consideration_amount)
        # set the linked consideration to the current summed value unless this hasn't changed since the last check
        @linked_consideration = current_linked_consideration unless
          @orig_linked_consideration == current_linked_consideration

        @orig_linked_consideration = current_linked_consideration # store the derived value for the next time
        @linked_consideration
      end

      # setter for the linked lease premium
      # This sets the linked consideration from the passed value and also makes sure that the original copy is set
      def linked_lease_premium=(value)
        @linked_lease_premium = value
        return unless (@orig_linked_lease_premium || 0).zero?

        @orig_linked_lease_premium = sum_from_values(@link_transactions, :premium_inc)
      end

      # getter for the linked lease premium
      # the logic for this is the same @see linked_consideration
      def linked_lease_premium
        return if @linked_ind == 'N' || convey?

        current_linked_lease_premium = sum_from_values(@link_transactions, :premium_inc)
        # set the linked consideration to the current summed value unless this hasn't changed since the last check
        @linked_lease_premium = current_linked_lease_premium unless
           @orig_linked_lease_premium == current_linked_lease_premium

        @orig_linked_lease_premium = current_linked_lease_premium # store the derived value for the next time
        @linked_lease_premium
      end

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { fpay_method: comp_key('PAYMENT TYPE', 'LBTT', 'RSTU'), flbt_type: comp_key('RETURN TYPE', 'LBTT', 'RSTU'),
          property_type: comp_key('PROPERTYTYPE', 'SYS', 'RSTU'),
          sale_include_option: comp_key('SALEOFBUSINESS', 'LBTT', 'RSTU'),
          form_type: comp_key('RETURN_STATUS', 'SYS', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes but which won't be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { authority_ind: YESNO_COMP_KEY, non_ads_reliefclaim_option_ind: YESNO_COMP_KEY,
          previous_option_ind: YESNO_COMP_KEY, repayment_ind: YESNO_COMP_KEY,
          exchange_ind: YESNO_COMP_KEY, uk_ind: YESNO_COMP_KEY,
          linked_ind: YESNO_COMP_KEY, business_ind: YESNO_COMP_KEY,
          contingents_event_ind: YESNO_COMP_KEY, deferral_agreed_ind: YESNO_COMP_KEY,
          rent_for_all_years: YESNO_COMP_KEY, premium_paid: YESNO_COMP_KEY,
          declaration: YESNO_COMP_KEY, lease_declaration: YESNO_COMP_KEY,
          repayment_declaration: YESNO_COMP_KEY, repayment_agent_declaration: YESNO_COMP_KEY }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :return_type, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt return_type], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :tare_reference, placeholder: '<%TARE_REFERENCE%>' },
                        { code: :version, placeholder: '<%VERSION%>' },
                        { code: :form_type, lookup: true },
                        { code: :flbt_type, lookup: true },
                        { code: :orig_return_reference, when: :lease_review?, is: [true] }] },
         { code: :agent,
           when: :is_public,
           is_not: [true],
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_agent agent_details], # scope for the title translation
           type: :object },
         { code: :buyers,
           type: :object },
         { code: :tenants,
           type: :object },
         { code: :sellers,
           type: :object },
         { code: :landlords,
           type: :object },
         { code: :new_tenants,
           type: :object },
         { code: :properties,
           type: :object },
         { code: :ads,
           type: :object },
         { code: :about_the_transaction, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions property_type], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :property_type, lookup: true, when: :lease_review?, is_not: [true] },
                        { code: :effective_date, format: :date },
                        { code: :relevant_date, format: :date },
                        { code: :contract_date, format: :date },
                        { code: :lease_start_date, format: :date, when: :convey?, is: [false] },
                        { code: :lease_end_date, format: :date, when: :convey?, is: [false] },
                        { code: :previous_option_ind, lookup: true, when: :lease_review?, is_not: [true] },
                        { code: :exchange_ind, lookup: true, when: :lease_review?, is_not: [true] },
                        { code: :uk_ind, lookup: true, when: :lease_review?, is_not: [true] }] },
         { code: :linked_transactions_ind, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions linked_transactions], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :linked_ind, lookup: true }] },
         { code: :link_transactions, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           when: :linked_ind,
           is: ['Y'],
           type: :object },
         { code: :sale_of_business, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions sale_of_business], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :convey?,
           is: [true],
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :business_ind, lookup: true },
                        { code: :sale_include_option, lookup: true }] },
         { code: :non_ads_relief_claim_ind, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions reliefs_on_transaction], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :lease_review?,
           is: [false],
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :non_ads_reliefclaim_option_ind, lookup: true }] },
         { code: :non_ads_relief_claims, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           when: :non_ads_reliefclaim_option_ind,
           is: ['Y'],
           type: :object }, #         unless @version.blank?
         { code: :lease_values, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions lease_values], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :convey?,
           is: [false],
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :annual_rent, format: :money },
                        { code: :rent_for_all_years, lookup: true }] },
         { code: :yearly_rents, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           when: :rent_for_all_years,
           is: ['N'],
           type: :object },
         { code: :premium_paid, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions premium_paid], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           when: :convey?,
           is: [false],
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :premium_paid, lookup: true },
                        { code: :lease_premium, format: :money },
                        { code: :linked_lease_premium, format: :money },
                        { code: :relevant_rent, format: :money }] },
         { code: :about_the_calculation, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions about_the_calculation], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :convey?,
           is: [true],
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :contingents_event_ind, lookup: true },
                        { code: :deferral_agreed_ind, lookup: true, when: :contingents_event_ind, is: ['Y'] },
                        { code: :deferral_reference, when: :deferral_reference_required?, is: [true] }] },
         { code: :conveyance_values, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions conveyance_values], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :convey?,
           is: [true],
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :total_consideration, format: :money },
                        { code: :total_vat, format: :money },
                        { code: :linked_consideration, format: :money },
                        { code: :non_chargeable, format: :money },
                        { code: :remaining_chargeable, format: :money }] },
         { code: :tax, # section code
           type: :object }, # key for the title translation
         # if the repayment ind is nil/blank they never got asked the question i.e. not an amend
         # we can't use the version as that is set to 1 by the time this is called
         unless repayment_ind.blank?
           { code: :repayment, # section code
             key: :title, # key for the title translation
             key_scope: %i[returns lbtt_claim repayment_claim], # scope for the title translation
             divider: false, # should we have a section divider
             display_title: true, # Is the title to be displayed
             type: :list, # type list = the list of attributes to follow
             list_items: [{ code: :repayment_ind, lookup: true },
                          { code: :repayment_amount_claimed, format: :money, when: :repayment_ind, is: ['Y'] },
                          { code: :account_holder_name, when: :repayment_ind, is: ['Y'] },
                          { code: :account_number, when: :repayment_ind, is: ['Y'] },
                          { code: :branch_code, when: :repayment_ind, is: ['Y'] },
                          { code: :bank_name, when: :repayment_ind, is: ['Y'] },
                          { code: :repayment_declaration, lookup: true, translation_extra: :account_type,
                            when: :repayment_ind, is: ['Y'] },
                          { code: :repayment_agent_declaration, lookup: true,
                            when: :repayment_ind, is: ['Y'] }] }
         end,
         { code: :declaration, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt declaration], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :fpay_method, lookup: true }] },
         { code: :declaration, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt declaration], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :authority_ind, lookup: true, when: :account_type, is: ['AGENT'] },
                        { code: :declaration, lookup: true, translation_extra: :account_type },
                        { code: :lease_declaration, lookup: true, when: :lease?, is: [true],
                          translation_extra: :account_type }] }]
      end

      # Layout to print the receipt data in this model
      def print_layout_receipt
        [print_layout_receipt_tare_reference,
         { code: :primary_property,
           type: :object },
         { code: :primary_party,
           type: :object },
         print_layout_receipt_return_type,
         print_layout_receipt_agent]
      end

      # Enforce business data rules for yes/no fields by clearing the text if no is selected.
      def clean_up_yes_nos
        @deferral_reference = nil unless deferral_reference_required?
        @deferral_agreed_ind = nil unless contingent_events?
        @lease_premium = nil unless premium_paid?
      end

      # transaction validation method
      def business_ind?
        @business_ind == 'Y'
      end

      # transaction validation method
      def contingent_events?
        @contingents_event_ind == 'Y'
      end

      # validate the deferral_reference
      def deferral_reference_required?
        @deferral_agreed_ind == 'Y' && @contingents_event_ind == 'Y'
      end

      # transaction validation method
      def premium_paid?
        @premium_paid == 'Y'
      end

      # Is this a conveyance, see also tax.rb
      def convey?
        @flbt_type == 'CONVEY'
      end

      # is this a lease return, , see also tax.rb
      def lease?
        @flbt_type == 'LEASERET'
      end

      # is this a lease review type, see also tax.rb
      def lease_review?
        %w[LEASEREV ASSIGN TERMINATE].include?(@flbt_type)
      end

      # Is a linked consideration amount needed
      def linked_consideration_needed?
        @linked_ind == 'Y' && convey?
      end

      # condition to check linked lease premium
      def linked_lease_premium_needed?
        @linked_ind == 'Y' && !convey?
      end

      # Validation for transaction sale include options, user must have selected at least one non-blank option
      def sale_include_option_valid?
        return unless business_ind?

        errors.add(:sale_include_option, :one_must_be_chosen) if sale_include_option.reject(&:empty?).empty?
      end

      # Combine list of parties together
      def all_parties
        output = {}
        output = output.merge(@buyers) unless @buyers.nil?
        output = output.merge(@sellers) unless @sellers.nil?
        output = output.merge(@landlords) unless @landlords.nil?
        output = output.merge(@tenants) unless @tenants.nil?
        output = output.merge(@new_tenants) unless @new_tenants.nil?
        output
      end

      # Returns a hash of all the NINOs entered previously along with their party_id and full_name.
      # The entries are stored in hash as key => NINO and values as party_id and full_name
      # Data is stored as a hash to get the details of the existing party based on the key i.e. nino
      # which is stored as a key in the hash.(used for validation of duplicate nino)
      def list_of_used_ninos(nino)
        nino_hash = {}
        all_parties.each do |party|
          party_details = []
          # party is an array containing two indexes [0] & [1],At party[0] we get only the party_id but we
          # get the complete details of the party at the 1st index ie. full_name, party_id,etc.
          party_details[0] = party[1].party_id
          party_details[1] = party[1].full_name
          # Using data at 1st index of party as party details are stored in it and not the 0th index.
          nino_hash.store(party[1].nino, party_details) unless nino == party[1].nino
        end
        nino_hash
      end

      # The ADS section should only be shown if the user has specified that ADS applies to a property
      # @see LbttPropertiesController
      # @return [Boolean] whether or not to show the ADS section
      def show_ads?
        return false if @properties.blank?

        @properties.values.detect { |property| property.ads_due_ind == 'Y' }.present?
      end

      # The relief claim should only show if user has entered ADS and transaction details
      # and we have calculated the amounts, which we can determine by checking the override amount
      def show_relief_calc?
        !relief_claims.blank? && relief_claims[0].relief_override_amount.present?
      end

      # For a repayment then for lbtt the return needs to be an amendment
      # OR one of the three lease review types
      # @see LbttPropertiesController
      # @return [Boolean] whether or not to show repayment details
      def show_repayment?
        return true if lease_review?
        return true if amendment?

        false
      end

      # @return [Party] arbitrary "first" (they're stored by UUID) buyer or tenant depending on the return type
      def primary_party
        return buyers&.values&.first if convey?

        tenants&.values&.first
      end

      # @return [Property] arbitrary "first" (they're stored by UUID property)
      def primary_property
        properties&.values&.first
      end

      # Find a LBTT return by it's reference number and version
      # @param param_id [Hash] The reference number, tare_refno, srv_code and version of the LBTT return to get data.
      # @param requested_by [User] is usually the current_user, who is requesting the data and containing the account id
      def self.find(param_id, requested_by)
        Lbtt::LbttReturn.abstract_find(:lbtt_tax_return_details, param_id, requested_by,
                                       :lbtt_tax_return) do |data|
          Lbtt::LbttReturn.new_from_fl(data)
        end
      end

      # Takes the hash from the back office response and transform to make it compatible with our models
      # ie this method is like the opposite of @see #request_save.
      private_class_method def self.convert_back_office_hash(lbtt) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
        # separate output object so that back office changes won't break FL record loading
        output = {}
        output[:form_type] = lbtt[:form_type]
        output[:tare_reference] = lbtt[:tare_reference]
        output[:tare_refno] = lbtt[:tare_refno]
        output[:version] = lbtt[:version]
        output.merge!(lbtt[:lbtt_return_details])

        raw_hash_parties = convert_parties(output)
        output[:buyers] = convert_to_party_type(raw_hash_parties, 'BUYER')
        output[:sellers] = convert_to_party_type(raw_hash_parties, 'SELLER')
        output[:tenants] = convert_to_party_type(raw_hash_parties, 'TENANT')
        output[:landlords] = convert_to_party_type(raw_hash_parties, 'LANDLORD')
        output[:new_tenants] = convert_to_party_type(raw_hash_parties, 'NEWTENANT')
        output[:agent] = convert_to_party_type(raw_hash_parties, 'AGENT')

        output[:link_transactions] = convert_to_link_transactions(output) unless output[:linked_transactions].blank?
        output[:yearly_rents] = convert_to_yearly_rents(output) unless output[:rent].blank?

        output[:properties] = convert_properties(output)

        output[:ads] = Ads.convert_back_office_hash(output)

        if output.key?(:include_in_sale)
          output[:sale_include_option] = []
          output[:sale_include_option] << 'GOODWILL' if output[:include_in_sale][:goodwill_ind] == 'yes'
          output[:sale_include_option] << 'STOCK' if output[:include_in_sale][:stock_ind] == 'yes'
          output[:sale_include_option] << 'MOVEABLES' if output[:include_in_sale][:moveables_ind] == 'yes'
          output[:sale_include_option] << 'OTHER' if output[:include_in_sale][:other_ind] == 'yes'
          output.delete(:include_in_sale)
        end

        # tax and reliefs
        output.merge!(convert_to_relief_claims(output[:reliefs])) unless output[:reliefs].blank?

        # convert back office yes/no to Y/N
        yes_nos_to_yns(output, %i[previous_option_ind exchange_ind uk_ind contingents_event_ind])

        # derive yes no for transaction pages radio button based on the data now that we've finished moving it around
        # Use relevant rent or total consideration as a marker they have entered the transaction wizard
        unless output[:relevant_rent].blank? && output[:total_consideration].blank?
          derive_transactions_yes_nos_in(output)
        end

        # must be called after the above to make sure that linked ind is populated
        output[:tax] = Tax.convert_tax_calculations(output)

        # don't want to load the repayment details, throw this lot away
        # also the ads due ind as we get this at the property level
        delete = %i[repayment_bank_name repay_account_holder repay_bank_account_no repay_bank_sort_code repayment_ind
                    repayment_agent_auth_ind repayment_amount_claimed ads_due_ind]

        # clean up leftover indexes that we've converted/renamed/moved but not used the delete method to do so
        # ie this is not a list of data we're throwing away
        delete += %i[parties party include_in_sale linked_transactions reliefs rent ads_address agent_reference]
        delete.each { |key| output.delete(key) }
        output
      end

      # handle transaction pages yes_no type which are depend on some other attribute value, so here we are setting them
      private_class_method def self.derive_transactions_yes_nos_in(lbtt)
        to_derive = {
          non_ads_reliefclaim_option_ind: :non_ads_relief_claims,
          business_ind: :sale_include_option,
          linked_ind: :link_transactions,
          premium_paid: :lease_premium,
          deferral_agreed_ind: :deferral_reference
        }
        derive_yes_nos(lbtt, to_derive, true)

        # custom ones
        lbtt[:rent_for_all_years] = (lbtt.delete(:same_rent_each_year_ind) == 'yes' ? 'Y' : 'N')
      end

      # Returns a translation attribute where a given attribute may have more than one name based on e.g. a type
      # it also allows for a different attribute name for the error region for e.g. long labels
      # @param attribute [Symbol] the name of the attribute to translate
      # @param translation_options [Object] in this case the party type being processed passed from the page
      # @return [Symbol] the name of the translation attribute
      def translation_attribute(attribute, translation_options = nil)
        #  Depending on the property type, this changes the attribute to match the specific attribute
        #  that has the translation text that we want for when it's 'Residential to be displayed.
        return :total_consideration_residential if attribute == :total_consideration && @property_type == '1'
        return (attribute.to_s + '_' + flbt_type).to_sym if %i[effective_date relevant_date annual_rent]
                                                            .include?(attribute)
        return attribute unless %i[authority_ind repayment_agent_declaration lease_declaration
                                   declaration repayment_declaration].include?(attribute)

        translation_attribute_declarations(attribute, translation_options)
      end

      # Convert the parties data received from back-office to our model specific format
      private_class_method def self.convert_parties(lbtt_return)
        parties = lbtt_return[:parties][:party] unless lbtt_return[:parties].nil?
        return {} if parties.nil?

        # wrap party in an array if it's not already (ie when there's only 1 party)
        parties = [parties] unless parties.is_a? Array

        output = {}
        parties.each do |raw_hash|
          party = Party.convert_back_office_hash(raw_hash, lbtt_return[:flbt_type], lbtt_return[:agent_reference])
          output[party.party_id] = party
        end
        output
      end

      # Convert the incoming parties data into specific type for example into buyers, sellers depending on type
      private_class_method def self.convert_to_party_type(parties, party_type)
        return {} if parties.nil?

        output = {}
        ServiceClient.iterate_element(parties) do |party|
          return party if party.party_type == party_type && party_type == 'AGENT'

          output[party.party_id] = party if party.party_type == party_type
        end
        output
      end

      # Convert the incoming property data into property objects
      private_class_method def self.convert_properties(lbtt)
        return if lbtt[:properties].nil?

        output = {}

        ServiceClient.iterate_element(lbtt[:properties]) do |raw_hash|
          property = Property.convert_back_office_hash(raw_hash, lbtt[:flbt_type])
          output[property.property_id] = property
        end
        output
      end

      # Convert the relief_claim data into non ads relief object see ads model for ads_relief_claims
      # @return [Hash] reliefs with indexes :non_ads_relief_claims.
      private_class_method def self.convert_to_relief_claims(reliefs_data)
        return nil if reliefs_data.nil? || reliefs_data[:relief].nil?

        # convert to array if it isn't already
        reliefs_data[:relief] = [reliefs_data[:relief]] unless reliefs_data[:relief].is_a? Array

        output = { non_ads_relief_claims: [] }
        reliefs_data[:relief].each do |raw_hash|
          convert_and_organise_relief(raw_hash, output)
        end
        # delete empty parts of the reliefs hash.
        output.delete(:non_ads_relief_claims) if output[:non_ads_relief_claims].empty?
        output
      end

      # Separated out of #convert_to_relief_claims.
      # @param raw_hash [Hash] data loaded from the back office about a relief
      private_class_method def self.convert_and_organise_relief(raw_hash, output)
        relief = ReliefClaim.convert_back_office_hash(raw_hash)
        output[:non_ads_relief_claims] << relief unless /ADS.*/.match?(relief.relief_type)
      end

      # Check to run before attempting a minimal Lbtt::Tax calculation request (ie anything the back office
      # can't do without should be validated for so we don't bother trying until we have it.)
      def ready_for_tax_calc?
        @effective_date.present? && @flbt_type.present? && property_type.present? && amounts_for_tax_calc?
      end

      # Convert the linked_transactions data into link_transactions objects
      private_class_method def self.convert_to_link_transactions(lbtt)
        linked_transactions =  lbtt[:linked_transactions][:linked_transaction] unless lbtt[:linked_transactions].nil?
        return nil if linked_transactions.nil?

        # convert to array if it isn't already
        linked_transactions = [linked_transactions] unless linked_transactions.is_a? Array

        output = []

        linked_transactions.each do |raw_hash|
          output << LinkTransactions.convert_back_office_hash(raw_hash)
        end

        output
      end

      # Convert the yearly_rents data into yearly_rents objects
      private_class_method def self.convert_to_yearly_rents(lbtt)
        yearly_rents = lbtt[:rent][:yearly_rents] unless lbtt[:rent].nil?
        return nil if yearly_rents.nil?

        yearly_rents = [yearly_rents] unless yearly_rents.is_a? Array

        output = []
        yearly_rents.each_with_index do |raw_hash, i|
          output[i] = YearlyRent.convert_back_office_hash(raw_hash)
        end
        output
      end

      # create sorted list of return types available to a public user
      def public_flbt_type_list
        if @public_return_types.nil?
          @public_return_types = lookup_ref_data(:flbt_type)
          @public_return_types.delete('LEASERET')
          @public_return_types.delete('CONVEY')
        end
        @public_return_types.values.sort_by(&:sort_key)
      end

      # Custom setter for relief claim that splits into the two lists for ads and non ads
      # @param value [Array] and array of relief claims
      def relief_claims=(value)
        return if value.nil?

        # Note that the select returns a blank array so we check for and set to nil for these
        ads_relief_claims = value.select(&:ads?)
        @ads.ads_relief_claims = (ads_relief_claims.empty? ? nil : ads_relief_claims)

        non_ads_relief_claims = value.reject(&:ads?)
        @non_ads_relief_claims = (non_ads_relief_claims.empty? ? nil : non_ads_relief_claims)
      end

      # Add the ADS and non-ADS reliefs together
      # not that we have to check the flags are set otherwise we need to ignore any data in the arrays
      def relief_claims
        non_ads_relief_claims = (@non_ads_reliefclaim_option_ind == 'Y' ? @non_ads_relief_claims : [])
        ads_relief_claims = (@ads.ads_reliefclaim_option_ind == 'Y' ? @ads.ads_relief_claims : [])
        (non_ads_relief_claims || []) + (ads_relief_claims || [])
      end

      private

      # check the correct amounts are present for the tax calc
      # note we don't check all the amounts but if these are present which should have the others as well
      def amounts_for_tax_calc?
        ((convey? && @total_consideration.present?) || (!convey? && @relevant_rent.present?))
      end

      # Called by @see Returns::AbstractReturn#save
      # If tare_refno exists then must be doing an update, otherwise creating a new one
      # We can't use version as that gets set by the portal on save so changes a create into update
      def save_operation
        operation = if @tare_refno.blank?
                      :lbtt_tax_return
                    else
                      :lbtt_update
                    end

        Rails.logger.debug(
          "Tare Refno is #{@tare_refno} Version number is #{@version}, using the #{operation} operation"
        )
        operation
      end

      # Called by @see Returns::AbstractReturn#save
      # @param requested_by [Object] details for the current user
      # @return a hash suitable for use in a save request to the back office
      def request_save(requested_by) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        output = {
          'ins1:FlbtType': @flbt_type, 'ins1:PropertyType': property_type
        }
        output['ins1:OrigReturnReference'] = @orig_return_reference if lease_review?
        output.merge!('ins1:EffectiveDate': DateFormatting.to_xml_date_format(@effective_date),
                      'ins1:RelevantDate': DateFormatting.to_xml_date_format(@relevant_date),
                      'ins1:ContractDate': DateFormatting.to_xml_date_format(@contract_date))
        unless convey?
          output[:'ins1:LeaseStartDate'] = DateFormatting.to_xml_date_format(@lease_start_date)
          output[:'ins1:LeaseEndDate'] = DateFormatting.to_xml_date_format(@lease_end_date)
        end
        output.merge!('ins1:PreviousOptionInd': convert_to_backoffice_yes_no_value(@previous_option_ind),
                      'ins1:ExchangeInd': convert_to_backoffice_yes_no_value(@exchange_ind),
                      'ins1:UKInd': convert_to_backoffice_yes_no_value(@uk_ind))
        xml_element_if_present(output, 'ins1:AgentReference', @agent.agent_reference) unless @agent.nil?
        parties_hash = all_parties.values
        parties_hash = parties_hash.push(@agent) unless @agent.nil?
        output['ins1:Parties'] = { 'ins1:Party': parties_hash.map { |p| p.request_save(authority_ind) } }

        if @linked_ind == 'Y'
          linked_array = []
          linked_array << @link_transactions.map(&:request_save)

          # flatten and compact to ensure we create the right format output for the request without any empty entries
          unless linked_array.blank?
            output['ins1:LinkedTransactions'] = { 'ins1:LinkedTransaction': linked_array.flatten&.compact }
          end
        end

        if convey?
          # set to 0 if there are no linked transactions
          output['ins1:LinkedConsideration'] = linked_consideration
        else
          output['ins1:LinkedLeasePremium'] = linked_lease_premium
          output['ins1:AnnualRent'] = @annual_rent
          output['ins1:SameRentEachYearInd'] = convert_to_backoffice_yes_no_value(@rent_for_all_years)
          if @rent_for_all_years == 'N' && @yearly_rents.present?
            output['ins1:Rent'] = { 'ins1:YearlyRents': @yearly_rents.map(&:request_save) }
            output['ins1:Rent'] = output['ins1:Rent'].compact
          end
          output['ins1:LeasePremium'] = @lease_premium
          output['ins1:RelevantRent'] = @relevant_rent
          output.delete('ins1:ConsiderationAmount')
        end

        output['ins1:Properties'] = { 'ins1:Property': @properties.values.map(&:request_save) } unless @properties.nil?

        output['ins1:BusinessInd'] = convert_to_backoffice_yes_no_value(@business_ind)
        if business_ind == 'Y'
          output['ins1:IncludeInSale'] = {
            'ins1:StockInd': @sale_include_option.include?('STOCK') ? 'yes' : 'no',
            'ins1:GoodwillInd': @sale_include_option.include?('GOODWILL') ? 'yes' : 'no',
            'ins1:MoveablesInd': @sale_include_option.include?('MOVEABLES') ? 'yes' : 'no',
            'ins1:OtherInd': @sale_include_option.include?('OTHER') ? 'yes' : 'no'
          }
        end

        if convey?
          output['ins1:TotalConsideration'] = @total_consideration
          output['ins1:TotalVat'] = total_vat
          output['ins1:NonChargeable'] = non_chargeable
          output['ins1:RemainingChargeable'] = remaining_chargeable
        end

        # merge ADS and non-ADS reliefs into one and use that unless it's blank
        reliefs = merge_reliefs

        xml_element_if_present(output, 'ins1:Reliefs', reliefs)
        @tax.request_save(output, !convey?)
        output['ins1:AdsDueInd'] = (show_ads? ? 'yes' : 'no')
        output['ins1:ContingentsEventInd'] = convert_to_backoffice_yes_no_value(@contingents_event_ind)
        if @contingents_event_ind == 'Y'
          xml_element_if_present(output, 'ins1:DeferralReference', @deferral_reference)
          output['ins1:DeferralReference'] = @deferral_reference unless @deferral_reference.blank?
          output['ins1:DeferralAgreedInd'] = convert_to_backoffice_yes_no_value(@deferral_agreed_ind)
        end

        xml_element_if_present(output, 'ins1:FPAYMethod', @fpay_method)

        # repayments
        if @repayment_ind == 'Y'

          claim_reason_code = @ads.ads_sold_main_yes_no == 'Y' ? 'ADS' : 'OTHER'

          output.merge!('ins1:ClaimType': 'PRE12MONTH',
                        'ins1:ClaimReasonCode': claim_reason_code,
                        'ins1:RepaymentInd': 'yes',
                        'ins1:RepayAccountHolder': @account_holder_name,
                        'ins1:RepayBankAccountNo': @account_number,
                        'ins1:RepayBankSortCode': @branch_code,
                        'ins1:RepaymentBankName': @bank_name,
                        'ins1:RepayAmountClaimed': @repayment_amount_claimed,
                        'ins1:RepaymentAgentAuthInd': @repayment_declaration == 'Y' ? 'yes' : 'no')
        # They haven't yet claimed a repayment but have said they sold the property
        elsif @repayment_ind.nil? && @ads.ads_sold_main_yes_no == 'Y'
          output.merge!('ins1:ClaimType': 'PRE12MONTH',
                        'ins1:ClaimReasonCode': 'ADS',
                        'ins1:RepayAmountClaimed': @ads.ads_repay_amount_claimed)
        elsif @repayment_ind == 'N'
          output['ins1:RepaymentInd'] = 'no'
        end

        # is the ADS section currently available to the user
        show_ads = show_ads?

        # include ADS fields only if the user is currently shown the ADS wizard option (ie it could have been hidden
        # since ADS data was added)
        @ads.request_save(output) if show_ads

        # put the top tag in place and add the print data
        # The print data needs to be in this routine as it has specific information based on the return type
        { 'ins1:LBTTReturnDetails': output,
          'ins1:PrintData': print_data(:print_layout, account_type: User.account_type(requested_by),
                                                      flbt_type: @flbt_type),
          'ins1:PrintDataReceipt': print_data(:print_layout_receipt, receipt: :receipt) }
      end

      # Add the ADS and non-ADS reliefs together for submission if their respective indicators are 'Y'.
      def merge_reliefs
        output = []
        output << @non_ads_relief_claims.map(&:request_save) if @non_ads_reliefclaim_option_ind == 'Y'
        output << @ads.ads_relief_claims.map(&:request_save) if @ads.ads_reliefclaim_option_ind == 'Y'

        # flatten and compact to ensure we create the right format output for the request without any empty entries
        { 'ins1:Relief': output.flatten&.compact }
      end

      # Dynamically returns the translation key based on the translation_options provided by the page if it exists
      # or else the flbt_type.
      # @param attribute [Symbol] the name of the attribute to translate
      # @param translation_options [Object] in this case the party type being processed passed from the page
      # @return [Symbol] "attribute_" + extra information to make the translation key
      def translation_attribute_declarations(attribute, translation_options = nil)
        suffix = if %i[authority_ind repayment_agent_declaration].include?(attribute)
                   flbt_type
                 elsif %i[lease_declaration].include?(attribute) && !translation_options.nil?
                   translation_options
                 elsif %i[declaration repayment_declaration].include?(attribute)
                   "#{flbt_type}_#{translation_options}"
                 end

        (attribute.to_s + '_' + suffix).to_sym
      end

      # print data for return reference
      def print_layout_receipt_tare_reference
        { code: :return_type, # section code
          divider: true, # should we have a section divider
          display_title: false, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :tare_reference, placeholder: '<%TARE_REFERENCE%>' }] }
      end

      # print data for flbt type and effective date
      def print_layout_receipt_return_type
        { code: :return_type, # section code
          divider: true, # should we have a section divider
          display_title: false, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :flbt_type, key_scope: %i[returns lbtt return_type], lookup: true },
                       { code: :effective_date, format: :date }] }
      end

      # print data for Agent object
      def print_layout_receipt_agent
        { code: :agent,
          when: :is_public,
          is_not: [true],
          display_title: false,
          type: :object }
      end
    end
  end
end
