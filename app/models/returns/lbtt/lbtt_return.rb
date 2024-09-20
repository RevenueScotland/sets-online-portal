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
      def self.attribute_list # rubocop:disable Metrics/MethodLength
        %i[orig_return_reference flbt_type buyers sellers agent landlords tenants new_tenants properties property_type
           non_residential_reason non_residential_reason_text
           previous_option_ind relevant_date contract_date lease_start_date lease_end_date business_ind declaration
           effective_date sale_include_option annual_rent lease_premium premium_paid linked_ind transaction_declaration
           linked_consideration linked_lease_premium link_transactions yearly_rents rent_for_all_years relief_claims ads
           total_consideration total_vat remaining_chargeable contingents_event_ind deferral_agreed_ind recalc_required
           non_chargeable deferral_reference relevant_rent bank_name account_number branch_code account_holder_name
           fpay_method authority_ind lease_declaration parties payment_date filing_date current_flbt_type exchange_ind
           repayment_ind repayment_amount_claimed repayment_declaration repayment_agent_declaration account_type
           ads change_reason orig_effective_date non_notifiable_submit_ind non_notifiable_explanation prepopulated
           pre_population_declaration orig_landlord_name taxpayer_email_id show_trans_declaration
           edit_calc_reason uk_ind calculation_edited initial_submitted_date]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      # linked_consideration, linked_lease_premium have setters
      strip_attributes :total_consideration, :total_vat, :non_chargeable, :remaining_chargeable,
                       :annual_rent, :relevant_rent, :repayment_amount_claimed, :account_number

      # Holds items that are internal and not set by the user
      # LBTT tax calculations object to manage and store tax calculation results.
      # Not including in the attribute_list so it can't be posted to, ie not user editable from this object
      attr_accessor :tax

      validates :flbt_type, presence: true, on: :flbt_type
      validates :orig_return_reference, presence: true, reference_number: true, on: :orig_return_reference
      validates :orig_effective_date, custom_date: true, presence: true, compare_date: true, on: :orig_effective_date
      validates :orig_landlord_name, presence: true, length: { maximum: 200 }, on: :orig_landlord_name
      validates :taxpayer_email_id, presence: true, length: { maximum: 100 }, on: :taxpayer_email_id
      validate  :validate_return_reference, on: :orig_return_reference

      # Validation of the pre population declaration
      validates :pre_population_declaration, acceptance: { accept: ['Y'] }, on: :pre_population_declaration,
                                             if: :show_pre_pop_declaration?

      # Transaction validation
      validates :property_type, presence: true, on: :property_type
      validates :non_residential_reason, presence: true, on: :non_residential_reason
      validates :non_residential_reason_text, presence: true, length: { maximum: 160 },
                                              on: :non_residential_reason,
                                              if: proc { |w| w.non_residential_reason == 'OTHER' }
      validates :effective_date, :relevant_date, custom_date: true, presence: true, compare_date: true,
                                                 on: :effective_date
      # Contract date is optional
      validates :contract_date, custom_date: true, compare_date: true, on: :effective_date
      validates :lease_start_date, :lease_end_date, custom_date: true, presence: true, compare_date: true,
                                                    on: :effective_date, unless: :convey?
      validates :lease_start_date, compare_date: { end_date_attr: :lease_end_date }, on: :lease_start_date
      validates :lease_end_date, compare_date: { equal_date_attr: :relevant_date }, on: :lease_end_date,
                                 if: :terminate?
      validates :relevant_date, compare_date: { triennial_date_attr: :effective_date }, on: :relevant_date,
                                if: :lease_review?
      validates :previous_option_ind, :exchange_ind,
                :uk_ind, presence: true, on: :previous_option_ind,
                         unless: :any_lease_review?
      validates :business_ind, presence: true, on: :business_ind, if: :convey?
      validate  :sale_include_option_is_choosen, on: :business_ind, if: :convey?
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
      validates :remaining_chargeable, numericality: { less_than: 1_000_000_000_000_000_000,
                                                       allow_blank: true },
                                       two_dp_pattern: true, presence: true,
                                       on: :remaining_chargeable,
                                       if: :convey?
      validate :validate_remaining_chargeable, on: :remaining_chargeable, if: :convey?

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
      validates :relief_claims, relief_type_unique: true, on: :relief_claims

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
                                two_dp_pattern: true, presence: true, on: :premium_paid, if: :premium_paid?,
                                unless: :convey?
      validates :edit_calc_reason, presence: true, length: { maximum: 4000 }, on: :edit_calc_reason,
                                   if: :calculation_edited
      validates :change_reason, presence: true, length: { maximum: 4000 }, on: :change_reason, if: :amendment?
      # claim repayment validation
      validates :repayment_ind, presence: true, on: :repayment_ind, if: :show_repayment?
      validates :repayment_amount_claimed, numericality: { greater_than_or_equal_to: 0,
                                                           less_than: 1_000_000_000_000_000_000,
                                                           allow_blank: true },
                                           two_dp_pattern: true, presence: true, on: :repayment_amount_claimed,
                                           if: :repayment_ind?
      validates :account_holder_name, presence: true, length: { maximum: 152 }, on: :account_holder_name,
                                      if: :repayment_ind?
      validates :bank_name, presence: true, length: { maximum: 255 }, on: :account_holder_name,
                            if: :repayment_ind?
      validates :account_number, presence: true, account_number: true, on: :account_holder_name,
                                 if: :repayment_ind?
      validates :branch_code, presence: true, bank_sort_code: true, on: :account_holder_name,
                              if: :repayment_ind?
      validates :repayment_declaration, acceptance: { accept: ['Y'] }, on: :repayment_declaration,
                                        if: :repayment_ind?
      validates :repayment_agent_declaration, acceptance: { accept: ['Y'] }, on: :repayment_declaration,
                                              if: proc { |s| s.account_type == 'AGENT' } && :repayment_ind?

      # declaration validation
      validates :fpay_method, presence: true, on: :fpay_method
      validates :authority_ind, presence: true, on: :authority_ind
      validates :non_notifiable_submit_ind, presence: true, on: :non_notifiable_submit_ind
      validates :non_notifiable_explanation, presence: true, length: { maximum: 4000 }, on: :non_notifiable_explanation
      validates :declaration, acceptance: { accept: ['Y'] }, on: :fpay_method
      validates :lease_declaration, acceptance: { accept: ['Y'] }, on: :fpay_method,
                                    if: :lease?
      validates :transaction_declaration, acceptance: { accept: ['Y'] }, on: :fpay_method

      # calls back office and returns hash which is used to validate the return reference and effective date
      def validate_return_reference
        return if errors.any? # don't check validation unless model already valid

        call_ok?(:validate_return_reference, request_validate_element) do |response|
          if not_filed_lease(response)
            errors.add(:orig_return_reference, :return_not_filed_lease)
          elsif response[:status] == 'Y'
            errors.add(:orig_return_reference, :return_disregarded)
          else
            pre_populate_return(response)
          end
        end
      end

      # Returns true if the data has been pre populated and claims are present on the return
      # @return [boolean] should we show the reliefs region
      def show_pre_pop_reliefs?
        pre_populated? && @tax.total_reliefs > '0'
      end

      # Gets the return pdf ready to be downloaded.
      # calls wsdl to send data given by client to back-office
      # current user is the user information in case of Authenticated user.
      # return_data hash which contains return number and version
      # pdf_type [String] for the type of pdf Return/Receipt
      def back_office_pdf_data(current_user, return_data, pdf_type)
        pdf_response = ''
        success = call_ok?(:view_return_pdf, request_pdf_elements(current_user, return_data, pdf_type)) do |body|
          break if body.blank?

          pdf_response = body
        end

        [success, pdf_response]
      end

      # @return a hash suitable for use in download pdf request to the back office
      # in case of unauthenticated user, current_user will be blank
      def request_pdf_elements(current_user, return_data, pdf_type)
        if current_user.blank?
          { Authenticated: 'no', TareReference: return_data[:tare_reference], ReturnVersion: return_data[:version],
            RequestType: pdf_type }
        else
          { Authenticated: 'yes', ParRefno: current_user.party_refno, Username: current_user.username,
            TareReference: return_data[:tare_reference], ReturnVersion: return_data[:version], RequestType: pdf_type }
        end
      end

      # Returns true if the return type is not a lease review or if a
      # pre populated lease review with reliefs for the pdf section
      def show_pre_pop_reliefs_pdf?
        show_pre_pop_reliefs? || !any_lease_review?
      end

      def show_trans_declaration?
        (show_trans_declaration == 'Y' && (convey? || lease?)) || any_lease_review?
      end

      # Returns true if the return data has been pre populated
      # @return [boolean] pre populated return
      def pre_populated?
        @prepopulated == 'Y'
      end

      # Return the property type attribute, but if this is one of the lease reviews set to non residential
      # as we don't ask the question
      # @return [String] The current value of the property type
      def property_type
        return '3' if any_lease_review? && @effective_date.present?

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

      # @return [Array] The array of MD reliefs, we are only expecting one
      def md_relief
        md_relief = []
        md_relief = @relief_claims.select(&:md_relief?) if
                              @relief_claims.present?
        md_relief
      end

      # Updates the ads_due flag on any linked reliefs and returns the mutated instance
      # @return [Array] The array of non ads relief claims with the latest ads due flag
      def synchronising_ads_due_on_reliefs!
        # Get adds up front as it is expensive
        ads_value = show_ads?
        if @relief_claims.present?
          @relief_claims.each do |r|
            r.lbtt_return_ads_due = ads_value
            r.lbtt_return_flbt_type = flbt_type
          end
        end
        self
      end

      # setter for the linked consideration
      # This sets the linked consideration from the passed value and also makes sure that the original copy is set
      def linked_consideration=(value)
        # Strips out leading spaces as this is a numeric field
        @linked_consideration = value.try(:strip) || value
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
        # Strips out leading spaces as this is a numeric field
        @linked_lease_premium = value.try(:strip) || value
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
          form_type: comp_key('RETURN_STATUS', 'SYS', 'RSTU'),
          non_residential_reason: comp_key('NON RES REASON', 'LBTT', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes but which won't be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { authority_ind: YESNO_COMP_KEY, pre_population_declaration: YESNO_COMP_KEY,
          previous_option_ind: YESNO_COMP_KEY, repayment_ind: YESNO_COMP_KEY,
          exchange_ind: YESNO_COMP_KEY, uk_ind: YESNO_COMP_KEY,
          linked_ind: YESNO_COMP_KEY, business_ind: YESNO_COMP_KEY,
          contingents_event_ind: YESNO_COMP_KEY, deferral_agreed_ind: YESNO_COMP_KEY,
          rent_for_all_years: YESNO_COMP_KEY, premium_paid: YESNO_COMP_KEY,
          declaration: YESNO_COMP_KEY, lease_declaration: YESNO_COMP_KEY,
          repayment_declaration: YESNO_COMP_KEY, repayment_agent_declaration: YESNO_COMP_KEY,
          non_notifiable_submit_ind: YESNO_COMP_KEY, transaction_declaration: YESNO_COMP_KEY }
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
                        { code: :receipt_date, placeholder: '<%RECEIPT_DATE%>' },
                        { code: :version, placeholder: '<%VERSION%>' },
                        { code: :change_reason, when: :amendment?, is: [true] },
                        { code: :form_type, lookup: true },
                        { code: :flbt_type, lookup: true },
                        { code: :orig_return_reference, when: :any_lease_review?, is: [true] },
                        { code: :pre_population_declaration, lookup: true,
                          when: :show_pre_pop_declaration?, is: [true] }] },
         { code: :agent,
           when: :user_account_type,
           is_not: ['PUBLIC'],
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
         { code: :about_the_transaction, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions property_type], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :property_type, lookup: true, when: :any_lease_review?, is_not: [true] },
                        { code: :non_residential_reason, lookup: true,
                          when: :non_residential_reason_needed?, is: [true] },
                        { code: :non_residential_reason_text,
                          when: :non_residential_reason_other?, is: [true] },
                        { code: :effective_date, format: :date },
                        { code: :relevant_date, format: :date },
                        { code: :contract_date, format: :date },
                        { code: :lease_start_date, format: :date, when: :convey?, is: [false] },
                        { code: :lease_end_date, format: :date, when: :convey?, is: [false] },
                        { code: :previous_option_ind, lookup: true, when: :any_lease_review?, is_not: [true] },
                        { code: :exchange_ind, lookup: true, when: :any_lease_review?, is_not: [true] },
                        { code: :uk_ind, lookup: true, when: :any_lease_review?, is_not: [true] }] },
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
         unless convey?
           { code: :non_notifiable, # section code
             key: :title, # key for the title translation
             key_scope: %i[returns lbtt_transactions non_notifiable], # scope for the title translation
             divider: false, # should we have a section divider
             display_title: true, # Is the title to be displayed
             when: :non_notifiable_submit_ind?,
             is: [true],
             type: :list, # type list = the list of attributes to follow
             list_items: [{ code: :non_notifiable_submit_ind, lookup: true,
                            when: :non_notifiable_submit_ind?, is: [true] },
                          { code: :non_notifiable_explanation, when: :non_notifiable_submit_ind?, is: [true] }] }
         end,
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
         if convey?
           { code: :non_notifiable, # section code
             key: :title, # key for the title translation
             key_scope: %i[returns lbtt_transactions non_notifiable], # scope for the title translation
             divider: false, # should we have a section divider
             display_title: true, # Is the title to be displayed
             when: :non_notifiable_submit_ind?,
             is: [true],
             type: :list, # type list = the list of attributes to follow
             list_items: [{ code: :non_notifiable_submit_ind, lookup: true,
                            when: :non_notifiable_submit_ind?, is: [true] },
                          { code: :non_notifiable_explanation, when: :non_notifiable_submit_ind?, is: [true] }] }
         end,
         if show_ads?
           { code: :ads, # section code
             type: :object } # key for the title translation
         end,
         { code: :relief_claims, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_reliefs reliefs_calculation], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :show_pre_pop_reliefs_pdf?,
           is: [true],
           type: :object }, #         unless @version.blank?
         { code: :tax, # section code
           type: :object }, # key for the title translation
         # if the repayment ind is nil/blank they never got asked the question i.e. not an amend
         # we can't use the version as that is set to 1 by the time this is called
         if form_type != 'D' && calculation_edited == 'Y'
           { code: :edit_calculation_reason, # section code
             key: :title, # key for the title translation
             key_scope: %i[returns lbtt_submit edit_calculation_reason], # scope for the title translation
             divider: true, # should we have a section divider
             display_title: true, # Is the title to be displayed
             type: :list, # type list = the list of attributes to follow
             list_items: [{ code: :edit_calc_reason, action_name: :print }] }
         end,
         if repayment_ind.present?
           { code: :repayment, # section code
             key: :title, # key for the title translation
             key_scope: %i[returns lbtt_submit repayment_claim], # scope for the title translation
             divider: true, # should we have a section divider
             display_title: true, # Is the title to be displayed
             type: :list, # type list = the list of attributes to follow
             list_items: [{ code: :repayment_ind, lookup: true },
                          { code: :repayment_amount_claimed, format: :money, when: :repayment_ind, is: ['Y'] },
                          { code: :account_holder_name, when: :repayment_ind, is: ['Y'] },
                          { code: :account_number, when: :repayment_ind, is: ['Y'] },
                          { code: :branch_code, when: :repayment_ind, is: ['Y'] },
                          { code: :bank_name, when: :repayment_ind, is: ['Y'] },
                          { code: :repayment_declaration, lookup: true,
                            when: :repayment_ind, is: ['Y'] },
                          { code: :repayment_agent_declaration, lookup: true,
                            when: :repayment_ind, is: ['Y'] }] }
         end,
         { code: :declaration, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_submit declaration], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :fpay_method, lookup: true }] },
         { code: :declaration, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_submit declaration], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :authority_ind, lookup: true, when: :account_type, is: ['AGENT'] },
                        { code: :declaration, lookup: true },
                        { code: :lease_declaration, lookup: true, when: :lease?, is: [true] },
                        { code: :transaction_declaration, lookup: true, when: :show_trans_declaration?, is: [true] }] }]
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
        @relevant_rent = nil unless premium_paid?
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

      # is this a lease return, see also tax.rb
      def lease?
        @flbt_type == 'LEASERET'
      end

      # is this a assignation return
      def assignation?
        @flbt_type == 'ASSIGN'
      end

      # is this any lease review type, see also tax.rb
      def any_lease_review?
        %w[LEASEREV ASSIGN TERMINATE].include?(@flbt_type)
      end

      # gets the account type from the current user
      def user_account_type
        User.account_type(current_user)
      end

      # is this any lease review type, with the logged in user type agent or taxpayer
      def show_pre_pop_declaration?
        any_lease_review? && %w[AGENT TAXPAYER].include?(user_account_type)
      end

      # is this any lease review type, see also tax.rb
      def lease_review?
        @flbt_type == 'LEASEREV'
      end

      # is this a termination type
      def terminate?
        @flbt_type == 'TERMINATE'
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
      def sale_include_option_is_choosen
        return unless business_ind?

        errors.add(:sale_include_option, :one_must_be_chosen) if sale_include_option.compact_blank.empty?
      end

      # Validation for transaction's remaining chargeable amount
      def validate_remaining_chargeable
        return if errors.any?

        return if total_remaining_chargeable.to_f.abs == @remaining_chargeable.to_f.abs

        errors.add(:remaining_chargeable, :must_be_calculated)
      end

      # Calculates the value for remaining chargeable field
      def total_remaining_chargeable
        if @linked_consideration.present?
          ((@total_consideration.to_f + @linked_consideration.to_f) - @non_chargeable.to_f).round(2)
        else
          (@total_consideration.to_f - @non_chargeable.to_f).round(2)
        end
      end

      # condition to check repayment_ind is set to Yes
      def repayment_ind?
        @repayment_ind == 'Y'
      end

      # condition to check non_notifiable_submit_ind is set to Yes
      def non_notifiable_submit_ind?
        @non_notifiable_submit_ind == 'Y'
      end

      # Condition to check if non-residential reason is needed
      # this is only applicable for convey and property is non-residential
      def non_residential_reason_needed?
        convey? && @property_type == '3'
      end

      # condition to check if the non-residential reason is other
      def non_residential_reason_other?
        non_residential_reason_needed? && @non_residential_reason == 'OTHER'
      end

      # check any calculated values are changed
      def calculated_values_changed
        return @calculation_edited = 'Y' if @tax.npv_value_changed? || @tax.calculations_are_changed?

        @calculation_edited = 'N'
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

      # Returns Array of addresses which are previously used for the Return.
      def list_of_used_addresses(party_id, party_type)
        address_list = []
        all_parties.each_value do |party|
          # Populating Addresses which are related to the same Party type and except from current Party.
          next unless party.party_type == party_type && party.party_id != party_id

          address_list << party.address
          address_list << party.contact_address
          address_list << party.org_contact_address
        end

        address_list.compact.uniq(&:full_address)
      end

      # The ADS section should only be shown if the user has specified that ADS applies to a property
      # @see LbttPropertiesController
      # @return [Boolean] whether or not to show the ADS section
      def show_ads?
        return false if @properties.blank?

        @properties.values.detect { |property| property.ads_due_ind == 'Y' }.present?
      end

      # Checks if any buyer party is non individual
      def non_individual_buyer?
        return false if @buyers.blank?

        @buyers.values.detect { |buyer| buyer.type != 'PRIVATE' }.present?
      end

      # For a repayment then for lbtt the return needs to be an amendment
      # OR one of the three lease review types
      # @see LbttPropertiesController
      # @return [Boolean] whether or not to show repayment details
      def show_repayment?
        return true if amendment? && !any_lease_review?

        false
      end

      # @return [Party] arbitrary "first" (they're stored by UUID) buyer or tenant depending on the return type
      def primary_party
        parties = if convey?
                    buyers&.values
                  else
                    tenants&.values
                  end
        parties&.sort_by!(&:full_name)&.first
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
          Lbtt::LbttReturn.new_from_fl(data).synchronising_ads_due_on_reliefs!
        end
      end

      # Takes the hash from the back office response and transform to make it compatible with our models
      # ie this method is like the opposite of @see #request_save.
      def self.convert_back_office_hash(lbtt) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
        # separate output object so that back office changes won't break FL record loading
        output = {}
        output[:form_type] = lbtt[:form_type]
        output[:tare_reference] = lbtt[:tare_reference]
        output[:tare_refno] = lbtt[:tare_refno]
        output[:version] = lbtt[:version]
        output[:initial_submitted_date] = lbtt[:initial_submitted_date]

        output.merge!(lbtt[:lbtt_return_details])

        hash_parties = convert_parties(output)
        output[:buyers] = split_by_party_type(hash_parties, 'BUYER')
        output[:sellers] = split_by_party_type(hash_parties, 'SELLER')
        output[:tenants] = split_by_party_type(hash_parties, 'TENANT')
        output[:landlords] = split_by_party_type(hash_parties, 'LANDLORD')
        output[:new_tenants] = split_by_party_type(hash_parties, 'NEWTENANT')
        output[:agent] = split_by_party_type(hash_parties, 'AGENT')
        output[:link_transactions] = convert_to_link_transactions(output) if output[:linked_transactions].present?
        output[:yearly_rents] = convert_to_yearly_rents(output) if output[:rent].present?

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
        output[:relief_claims] = convert_to_relief_claims(output[:reliefs]) if output[:reliefs].present?

        # prepopulation ind
        output[:prepopulated] = lbtt[:prepopulated] == 'yes' ? 'Y' : 'N'

        # if a lease review delete recalc flag as warning is now not shown for lease reviews
        if %w[LEASEREV ASSIGN TERMINATE].include?(lbtt[:lbtt_return_details][:flbt_type])
          output.delete(:recalc_required)
        end

        # convert back office yes/no to Y/N
        yes_nos_to_yns(output, %i[previous_option_ind exchange_ind uk_ind contingents_event_ind recalc_required])
        # derive yes no for transaction pages radio button based on the data now that we've finished moving it around
        # Use annual rent or total consideration as a marker they have entered the transaction wizard
        derive_transactions_yes_nos_in(output)

        # must be called after the above to make sure that linked ind is populated
        output[:tax] = Tax.convert_tax_calculations(output)

        # don't want to load the repayment details, throw this lot away
        # also the ads due ind as we get this at the property level
        # don't load the non notifiable explantation as we don't show it anywhere
        delete = %i[repayment_bank_name repay_account_holder repay_bank_account_no repay_bank_sort_code repayment_ind
                    repayment_agent_auth_ind repayment_amount_claimed ads_due_ind change_reason
                    non_notifiable_explanation]

        # clean up leftover indexes that we've converted/renamed/moved but not used the delete method to do so
        # ie this is not a list of data we're throwing away
        delete += %i[parties party include_in_sale linked_transactions reliefs rent ads_address agent_reference]
        delete.each { |key| output.delete(key) }
        output
      end

      # Set the derived yes or nos for the transaction wizard
      private_class_method def self.derive_transactions_yes_nos_in(lbtt)
        # Note the below in the reverse order they are asked as we
        # start from the end of the wizard and work back to find out how far through they were
        # Conveyance only
        lbtt[:deferral_agreed_ind] = derive_yes_no(value: lbtt[:deferral_reference],
                                                   default_n: lbtt[:total_consideration].present?)
        # lease only
        lbtt[:premium_paid] = derive_yes_no(value: lbtt[:lease_premium], default_n: lbtt[:net_present_value])

        # below are common to lease and conveyance
        derive_common_yes_nos_in(lbtt)

        # special case for rent for all years
        derive_rent_for_all_years(lbtt)
      end

      # Set the derived yes or nos for the transaction wizard that are common to lease and conveyance
      # note must still be in the correct order with the other indicators
      private_class_method def self.derive_common_yes_nos_in(lbtt)
        # Note the below in the order they are asked
        business_ind = derive_yes_no(value: lbtt[:sale_include_option],
                                     default_n: lbtt[:deferral_agreed_ind].present? ||
                                                lbtt[:annual_rent].present?)
        lbtt[:linked_ind] = derive_yes_no(value: lbtt[:link_transactions],
                                          default_n: business_ind.present?)
        lbtt[:business_ind] = business_ind
      end

      # Rename the rent for all years flag and derive Y/N
      private_class_method def self.derive_rent_for_all_years(lbtt)
        lbtt[:rent_for_all_years] = lbtt.delete(:same_rent_each_year_ind)
        yes_nos_to_yns(lbtt, %i[rent_for_all_years])
      end

      # Returns a translation attribute where a given attribute may have more than one name based on e.g. a type
      # it also allows for a different attribute name for the error region for e.g. long labels
      # @param attribute [Symbol] the name of the attribute to translate
      # @param _translation_options [Object] in this case the party type being processed passed from the page
      # @return [Symbol] the name of the translation attribute
      def translation_attribute(attribute, _translation_options = nil)
        #  Depending on the property type, this changes the attribute to match the specific attribute
        #  that has the translation text that we want for when it's 'Residential to be displayed.
        return :total_consideration_residential if attribute == :total_consideration && @property_type == '1'
        return :"#{attribute}_#{flbt_type}" if %i[effective_date relevant_date annual_rent]
                                               .include?(attribute)
        return attribute unless %i[authority_ind repayment_agent_declaration lease_declaration declaration
                                   repayment_declaration transaction_declaration
                                   pre_population_declaration].include?(attribute)

        translation_attribute_declarations(attribute)
      end

      # Convert the parties data received from back-office to our model specific format
      private_class_method def self.convert_parties(lbtt_return)
        return {} if lbtt_return[:parties].nil?

        output = {}
        ServiceClient.iterate_element(lbtt_return[:parties]) do |raw_hash|
          party = Party.convert_back_office_hash(raw_hash, lbtt_return[:flbt_type], lbtt_return[:agent_reference])
          output[party.party_id] = party
        end
        output
      end

      # Convert the incoming parties data into specific type for example into buyers, sellers depending on type
      # @param parties [Hash] an hash of parties objects indexed on the key
      # @param party_type [String] The party type to look for
      private_class_method def self.split_by_party_type(parties, party_type)
        return {} if parties.nil?

        output = {}
        parties.each_value do |party|
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

      # Convert the relief_claim data into relief object
      # @return [Hash] reliefs with indexes :relief_claims.
      private_class_method def self.convert_to_relief_claims(reliefs_data)
        return nil if reliefs_data.nil? || reliefs_data[:relief].nil?

        output = []
        ServiceClient.iterate_element(reliefs_data) do |raw_hash|
          output << ReliefClaim.convert_back_office_hash(raw_hash)
        end
        output
      end

      # Check to run before attempting a minimal Lbtt::Tax calculation request (ie anything the back office
      # can't do without should be validated for so we don't bother trying until we have it.)
      def ready_for_tax_calc?
        @effective_date.present? && @flbt_type.present? && property_type.present? && amounts_for_tax_calc?
      end

      # Convert the linked_transactions data into link_transactions objects
      private_class_method def self.convert_to_link_transactions(lbtt)
        return if lbtt[:linked_transactions].nil?

        output = []
        ServiceClient.iterate_element(lbtt[:linked_transactions]) do |raw_hash|
          output << LinkTransactions.convert_back_office_hash(raw_hash, lbtt[:flbt_type])
        end

        output
      end

      # Convert the yearly_rents data into yearly_rents objects
      private_class_method def self.convert_to_yearly_rents(lbtt)
        return if lbtt[:rent].nil?

        output = []
        ServiceClient.iterate_element(lbtt[:rent]) do |raw_hash|
          output << YearlyRent.convert_back_office_hash(raw_hash)
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

      private

      # @return a hash suitable for use in validateReturnReference request to the back office
      def request_validate_element
        output = { 'ins0:TareReference': @orig_return_reference }
        output['ins0:IncludeDisregardedReturns'] = true
        # TODO: Update the backoffice API so that we can pass in the return type @flbt_type rather than hardcoding
        output['ins0:LeaseReviewType'] = 'LEASEREV'
        output['ins0:PrepopulateDetails'] = true
        unauthenticated_request_element(output) if current_user.blank?
        authenticated_request_element(output) if current_user.present?

        output
      end

      # Adds authenticated details to the hash used in validateReturnReference request to the back office
      # @param output [Hash] that contains the reference, type and pre population and disregard ind to get data
      # returns output [Hash] the hash with the authenticated details
      def authenticated_request_element(output)
        output['ins0:Username'] = current_user.username
        output['ins0:ParRefNo'] = current_user.party_refno
        output['ins0:UnAuthenticated'] = false
        output
      end

      # Adds unauthenticated details to the hash used in validateReturnReference request to the back office
      # @param output [Hash] that contains the reference, type and pre population and disregard ind to get data
      # returns output [Hash] the hash with the unauthenticated details
      def unauthenticated_request_element(output)
        output['ins0:UnAuthenticated'] = true
        output['ins0:TaxPayersEmail'] = @taxpayer_email_id
        output['ins0:LandlordName'] = @orig_landlord_name
        output
      end

      # pre populates the model from the response
      # @param response [Hash] that contains the return details from the back office
      def pre_populate_return(response)
        pre_populate_data = self.class.convert_back_office_hash(response[:lbtt_tax_return])
        pre_populate_strip_attributes(pre_populate_data)
        assign_attributes(pre_populate_data)
        @prepopulated = 'Y'
        @recalc_required = 'N'
      end

      # Removes the attributes from the response that we don't want to pre populate
      # @param pre_populate_data [Hash] that contains the return details from the back office
      # returns pre_populate_data [Hash] that contains the return details from the back office
      def pre_populate_strip_attributes(pre_populate_data)
        delete = %i[form_type tare_reference tare_refno version flbt_type par_refno agent buyers sellers new_tenants]
        delete += %i[relevant_date] if assignation? || terminate?
        delete.each { |key| pre_populate_data.delete(key) }
        pre_populate_data
      end

      # check the correct amounts are present for the tax calc
      # note we don't check all the amounts but if these are present which should have the others as well
      def amounts_for_tax_calc?
        # Note we use the remaining chargeable method not the actual attribute as values are defaulted
        (convey? && @total_consideration.present? && remaining_chargeable.present?) ||
          (!convey? && @premium_paid.present?)
      end

      # check that the validate return response is for the suitable lease
      def not_filed_lease(response)
        response.blank? || response[:flbt_type] != 'LEASERET' ||
          response[:effective_date].to_date != orig_effective_date.to_date
      end

      # Called by @see Returns::AbstractReturn#save
      # If tare_refno exists then we are doing an update, otherwise creating a new one
      # We can't use version as that gets set by the portal on save so changes a create into update
      def save_operation
        operation = if @tare_refno.blank?
                      :lbtt_tax_return
                    else
                      :lbtt_update
                    end

        Rails.logger.debug do
          "Tare Refno is #{@tare_refno} Version number is #{@version}, using the #{operation} operation"
        end
        operation
      end

      # Called by @see Returns::AbstractReturn#save
      # @param _requested_by [Object] details for the current user
      # @param form_type [string] D(raft) or L(atest)
      # @return a hash suitable for use in a save request to the back office
      def request_save(_requested_by, form_type:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        clean_up_yes_nos
        output = {
          'ins0:FlbtType': @flbt_type, 'ins0:PropertyType': property_type
        }
        output['ins0:ChangeReason'] = @change_reason if amendment?
        output['ins0:NonResidentialReason'] = @non_residential_reason if non_residential_reason_needed?
        output['ins0:NonResidentialReasonText'] = @non_residential_reason_text if non_residential_reason_needed?
        output['ins0:OrigReturnReference'] = @orig_return_reference if any_lease_review?
        # TODO: RSTP-1321 Update LBTTCalculationScheme to CalculationScheme
        output['ins0:LBTTCalculationScheme'] = @tax.calculation_scheme
        output.merge!('ins0:EffectiveDate': DateFormatting.to_xml_date_format(@effective_date),
                      'ins0:RelevantDate': DateFormatting.to_xml_date_format(@relevant_date),
                      'ins0:ContractDate': DateFormatting.to_xml_date_format(@contract_date))
        unless convey?
          output['ins0:LeaseStartDate'] = DateFormatting.to_xml_date_format(@lease_start_date)
          output['ins0:LeaseEndDate'] = DateFormatting.to_xml_date_format(@lease_end_date)
        end

        output['ins0:NonNotifiableExplanation'] = @non_notifiable_explanation if non_notifiable_submit_ind?
        output['ins0:EditCalcReason'] = @edit_calc_reason if @calculation_edited == 'Y' && @edit_calc_reason.present?

        output.merge!('ins0:PreviousOptionInd': convert_to_backoffice_yes_no_value(@previous_option_ind),
                      'ins0:ExchangeInd': convert_to_backoffice_yes_no_value(@exchange_ind),
                      'ins0:UKInd': convert_to_backoffice_yes_no_value(@uk_ind))
        xml_element_if_present(output, 'ins0:AgentReference', @agent.agent_reference) unless @agent.nil?
        parties_hash = all_parties.values
        parties_hash.push(@agent) unless @agent.nil?
        output['ins0:Parties'] = { 'ins0:Party': parties_hash.map { |p| p.request_save(authority_ind) } }

        if @linked_ind == 'Y'
          linked_array = []
          linked_array << @link_transactions.map(&:request_save)

          # flatten and compact to ensure we create the right format output for the request without any empty entries
          if linked_array.present?
            output['ins0:LinkedTransactions'] = { 'ins0:LinkedTransaction': linked_array.flatten&.compact }
          end
        end

        if convey?
          # set to 0 if there are no linked transactions
          output['ins0:LinkedConsideration'] = linked_consideration
        else
          output['ins0:LinkedLeasePremium'] = linked_lease_premium
          output['ins0:AnnualRent'] = @annual_rent
          output['ins0:SameRentEachYearInd'] = convert_to_backoffice_yes_no_value(@rent_for_all_years)
          if @rent_for_all_years == 'N' && @yearly_rents.present?
            output['ins0:Rent'] = { 'ins0:YearlyRents': @yearly_rents.map(&:request_save) }
            output['ins0:Rent'] = output['ins0:Rent'].compact
          end
          output['ins0:LeasePremium'] = @lease_premium
          output['ins0:RelevantRent'] = @relevant_rent
          output.delete('ins0:ConsiderationAmount')
        end

        output['ins0:Properties'] = { 'ins0:Property': @properties.values.map(&:request_save) } unless @properties.nil?

        output['ins0:BusinessInd'] = convert_to_backoffice_yes_no_value(@business_ind)
        if business_ind == 'Y'
          output['ins0:IncludeInSale'] = {
            'ins0:StockInd': @sale_include_option.include?('STOCK') ? 'yes' : 'no',
            'ins0:GoodwillInd': @sale_include_option.include?('GOODWILL') ? 'yes' : 'no',
            'ins0:MoveablesInd': @sale_include_option.include?('MOVEABLES') ? 'yes' : 'no',
            'ins0:OtherInd': @sale_include_option.include?('OTHER') ? 'yes' : 'no'
          }
        end

        if convey?
          output['ins0:TotalConsideration'] = @total_consideration
          output['ins0:TotalVat'] = total_vat
          output['ins0:NonChargeable'] = non_chargeable
          output['ins0:RemainingChargeable'] = remaining_chargeable
        end

        if @relief_claims.present?
          xml_element_if_present(output, 'ins0:Reliefs',
                                 { 'ins0:Relief': @relief_claims.map(&:request_save) })
        end
        @tax.request_save(output, !convey?)
        output['ins0:AdsDueInd'] = (show_ads? ? 'yes' : 'no')
        output['ins0:ContingentsEventInd'] = convert_to_backoffice_yes_no_value(@contingents_event_ind)
        if @contingents_event_ind == 'Y'
          xml_element_if_present(output, 'ins0:DeferralReference', @deferral_reference)
          output['ins0:DeferralReference'] = @deferral_reference if @deferral_reference.present?
          output['ins0:DeferralAgreedInd'] = convert_to_backoffice_yes_no_value(@deferral_agreed_ind)
        end

        # Make sure previous payment method is saved to back office for a draft so we don't lose track of it
        xml_element_if_present(output, 'ins0:FPAYMethod', (form_type == 'D' ? @previous_fpay_method : @fpay_method))

        # repayments
        if @repayment_ind == 'Y'

          claim_reason_code = @ads.ads_sold_main_yes_no == 'Y' ? 'ADS' : 'OTHER'

          output.merge!('ins0:ClaimType': 'PRE12MONTH',
                        'ins0:ClaimReasonCode': claim_reason_code,
                        'ins0:RepaymentInd': 'yes',
                        'ins0:RepayAccountHolder': @account_holder_name,
                        'ins0:RepayBankAccountNo': @account_number,
                        'ins0:RepayBankSortCode': @branch_code,
                        'ins0:RepaymentBankName': @bank_name,
                        'ins0:RepayAmountClaimed': @repayment_amount_claimed,
                        'ins0:RepaymentAgentAuthInd': @repayment_declaration == 'Y' ? 'yes' : 'no')
        # They haven't yet claimed a repayment but have said they sold the property
        elsif @repayment_ind.nil? && @ads.ads_sold_main_yes_no == 'Y'
          output.merge!('ins0:ClaimType': 'PRE12MONTH',
                        'ins0:ClaimReasonCode': 'ADS',
                        'ins0:RepayAmountClaimed': @ads.ads_repay_amount_claimed)
        elsif @repayment_ind == 'N'
          output['ins0:RepaymentInd'] = 'no'
        end

        # include ADS fields only if the user is currently shown the ADS wizard option (ie it could have been hidden
        # since ADS data was added)
        @ads.request_save(output) if show_ads?

        # put the top tag in place and add the print data
        # The print data needs to be in this routine as it has specific information based on the return type
        { 'ins0:LBTTReturnDetails': output,
          'ins0:PrintData': print_data(:print_layout),
          'ins0:PrintDataReceipt': print_data(:print_layout_receipt),
          'ins0:Prepopulated': (@prepopulated == 'Y' ? 'yes' : 'no') }
      end

      # Dynamically returns the translation key based on the flbt_type or user_account_type
      # @param attribute [Symbol] the name of the attribute to translate
      # @return [Symbol] "attribute_" + extra information to make the translation key
      def translation_attribute_declarations(attribute)
        suffix = if %i[authority_ind repayment_agent_declaration].include?(attribute)
                   flbt_type
                 elsif %i[lease_declaration transaction_declaration pre_population_declaration].include?(attribute)
                   user_account_type
                 elsif %i[declaration repayment_declaration].include?(attribute)
                   "#{flbt_type}_#{user_account_type}"
                 end

        :"#{attribute}_#{suffix}"
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
          list_items: [{ code: :flbt_type, action_name: :declaration_submitted, lookup: true },
                       { code: :effective_date, format: :date }] }
      end

      # print data for Agent object
      def print_layout_receipt_agent
        { code: :agent,
          when: :user_account_type,
          is_not: ['PUBLIC'],
          display_title: false,
          type: :object }
      end

      # Hash to translate back office logical data item into an attribute
      def back_office_attributes
        { ORIG_RETURN_REFERENCE: { attribute: :orig_return_reference } }
      end
    end
  end
end
