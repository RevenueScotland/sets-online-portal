# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for the LBTT return
    class LbttReturn < AbstractReturn # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
      include CommonValidation
      validates_with LbttReturnValidator, on: :submit

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list # rubocop:disable Metrics/MethodLength
        %i[orig_return_reference flbt_type buyers sellers agent landlords tenants new_tenants properties property_type
           effective_date relevant_date contract_date business_ind exchange_ind previous_option_ind uk_ind
           sale_include_option ads_amount_liable ads_sell_residence_ind non_ads_relief_claims ads_relief_claims
           non_ads_reliefclaim_option_ind ads_reliefclaim_option_ind lease_premium premium_paid
           ads_sold_main_yes_no ads_sold_date ads_sold_address linked_consideration linked_lease_premium
           linked_ind link_transactions annual_rent yearly_rents rent_for_all_years total_consideration total_vat
           remaining_chargeable contingents_event_ind deferral_agreed_ind ads_consideration non_chargeable
           deferral_reference ads_main_address ads_consideration_yes_no relevant_rent bank_name
           lease_start_date lease_end_date account_number branch_code account_holder_name fpay_method
           authority_ind declaration lease_declaration parties payment_date filing_date current_flbt_type
           repayment_ind repayment_amount_claimed repayment_declaration repayment_agent_declaration account_type]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # The attribute is_public is used to determine if the return was made as a public, in other words, a
      # user who is not logged in. This needs to be populated on a new instance of a lbtt_return object.
      # LBTT tax calculations object to manage and store tax calculation results.
      # Not including in the attribute_list so it can't be posted to, ie not user editable from this object
      attr_accessor :tax, :is_public

      validates :flbt_type, presence: true, on: :flbt_type
      validates :orig_return_reference, presence: true, on: :orig_return_reference
      validate  :orig_return_reference_valid?, on: :orig_return_reference

      # Transaction validation
      validates :property_type, presence: true, on: :property_type
      validates :effective_date, presence: true, on: :effective_date
      validates :relevant_date, presence: true, on: :effective_date
      validates :contract_date, presence: true, on: :effective_date
      validate :valid_transaction_date_format?, on: :effective_date
      validates :lease_start_date, presence: true, on: :effective_date, if: :lbtt_return_type_not_conveyance?
      validates :lease_end_date, presence: true, on: :effective_date, if: :lbtt_return_type_not_conveyance?
      validate :valid_start_end_date_format?, on: :effective_date
      validate :end_date_after_start_date, on: :effective_date
      validate :validate_transaction_dates, on: :effective_date
      validates :previous_option_ind, presence: true, on: :previous_option_ind,
                                      unless: proc { |p| %w[LEASEREV ASSIGN TERMINATE].include? p.flbt_type }
      validates :exchange_ind, presence: true, on: :previous_option_ind,
                               unless: proc { |p| %w[LEASEREV ASSIGN TERMINATE].include? p.flbt_type }
      validates :uk_ind, presence: true, on: :previous_option_ind,
                         unless: proc { |p| %w[LEASEREV ASSIGN TERMINATE].include? p.flbt_type }
      validates :business_ind, presence: true, on: :business_ind, unless: :lbtt_return_type_not_conveyance?
      validate  :sale_include_option_valid?, on: :business_ind, unless: :lbtt_return_type_not_conveyance?
      validates :contingents_event_ind, presence: true, on: :contingents_event_ind,
                                        unless: :lbtt_return_type_not_conveyance?
      validates :deferral_agreed_ind, presence: true, on: :contingents_event_ind,
                                      if: :contingent_events_ind_yes_no_y?
      validates :deferral_reference, presence: true, length: { maximum: 50 }, on: :contingents_event_ind,
                                     if: :deferral_agreed_ind_yes_no_y?
      validates :total_consideration, presence: true, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                      numericality: { greater_than: 0,
                                                      less_than: 1_000_000_000_000_000_000 },
                                      on: :total_consideration, unless: :lbtt_return_type_not_conveyance?
      validates :total_vat, numericality: { greater_than_or_equal_to: 0,
                                            less_than: proc { |s| s.total_consideration.to_f } },
                            format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                            on: :total_consideration, unless: :lbtt_return_type_not_conveyance?
      validates :linked_consideration, numericality: { greater_than_or_equal_to: 0,
                                                       less_than: 1_000_000_000_000_000_000 },
                                       format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                                       on: :linked_consideration, unless: :lbtt_return_type_not_conveyance?

      # linked transactions validation
      validates :linked_ind, presence: true, on: :linked_ind
      validate :linked_transaction_validation, on: :linked_ind

      # yearly rent validation
      validates :rent_for_all_years, presence: true, on: :rent_for_all_years,
                                     if: :lbtt_return_type_not_conveyance?
      validate :yearly_rent_validation, on: :rent_for_all_years,
                                        if: :lbtt_return_type_not_conveyance?

      # reliefs validation
      validates :non_ads_reliefclaim_option_ind, presence: true, on: :non_ads_reliefclaim_option_ind,
                                                 unless: proc { |p| %w[LEASEREV ASSIGN TERMINATE].include? p.flbt_type }
      validate :non_ads_relief_code_validation, on: :non_ads_reliefclaim_option_ind
      validate :non_ads_relief_validation, on: :non_ads_reliefclaim_option_ind
      validates :ads_reliefclaim_option_ind, presence: true, on: :ads_reliefclaim_option_ind
      validate :ads_relief_validation, on: :ads_reliefclaim_option_ind
      validate :ads_relief_code_validation, on: :ads_reliefclaim_option_ind

      validates :non_chargeable, numericality: { greater_than_or_equal_to: 0,
                                                 less_than: proc { |s| s.total_consideration.to_f } },
                                 format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                                 on: :total_consideration, unless: :lbtt_return_type_not_conveyance?
      validates :remaining_chargeable, numericality: { greater_than_or_equal_to: 0,
                                                       less_than: 1_000_000_000_000_000_000 }, presence: true,
                                       format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                       on: :total_consideration, unless: :lbtt_return_type_not_conveyance?

      validates :annual_rent, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000 },
                              format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true, on: :annual_rent,
                              if: :lbtt_return_type_not_conveyance?
      validates :premium_paid, presence: true, on: :premium_paid, if: :lbtt_return_type_not_conveyance?
      validates :lease_premium, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000 },
                                format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                                on: :premium_paid, if: :premium_paid_yes_no_y?
      validates :linked_lease_premium, numericality: { greater_than_or_equal_to: 0,
                                                       less_than: 1_000_000_000_000_000_000 },
                                       format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                       presence: true, on: :linked_lease_premium,
                                       if: :lbtt_return_type_not_conveyance?
      validates :relevant_rent, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000 },
                                format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                                on: :relevant_rent, if: :lbtt_return_type_not_conveyance?

      # claim repayment validation
      validates :repayment_ind, presence: true, on: :repayment_ind
      validates :repayment_amount_claimed, numericality: { greater_than_or_equal_to: 0,
                                                           less_than: 1_000_000_000_000_000_000 },
                                           format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                                           on: :repayment_amount_claimed
      validates :account_holder_name, presence: true, length: { maximum: 255 }, on: :account_holder_name
      validates :account_number, presence: true,
                                 numericality: { only_integer: true }, length: { is: 8 },
                                 on: :account_holder_name
      validate :repay_bank_sort_code_valid?, on: :account_holder_name
      validates :bank_name, presence: true, length: { maximum: 255 }, on: :account_holder_name
      validates :repayment_declaration, acceptance: { accept: ['true'] }, on: :repayment_declaration
      validates :repayment_agent_declaration, acceptance: { accept: ['true'] }, on: :repayment_declaration,
                                              if: proc { |s| s.account_type == 'AGENT' }

      # ADS claim repayment validation
      validates :ads_sold_main_yes_no, presence: true, on: :ads_sold_main_yes_no
      validates :ads_sold_date, presence: true, on: :ads_sold_date,
                                if: proc { |s| s.ads_sold_main_yes_no == 'Y' }
      validate :valid_ads_date_format?, on: :ads_sold_date

      # ADS validation
      validates :ads_consideration_yes_no, presence: true, on: :ads_consideration_yes_no
      validates :ads_sell_residence_ind, presence: true, on: :ads_sell_residence_ind
      validates :ads_amount_liable, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000 },
                                    format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                                    on: :ads_amount_liable
      validates :ads_consideration, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000 },
                                    format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true,
                                    on: :ads_amount_liable, if: :ads_consideration_yes_no_yes?

      # save draft and calculate (submit) buttons validation
      validates :effective_date, presence: { message: :missing_about_the_transaction }, on: %i[submit]
      validate :save_validation, on: %i[submit]

      # declaration validation
      validates :fpay_method, presence: true, on: :fpay_method
      validates :authority_ind, presence: true, on: :authority_ind
      validates :declaration, acceptance: { accept: ['true'] }, on: :fpay_method
      validates :lease_declaration, acceptance: { accept: ['true'] }, on: :fpay_method,
                                    if: proc { |p| p.flbt_type == 'LEASERET' }

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { fpay_method: 'PAYMENT TYPE.LBTT.RSTU', flbt_type: 'RETURN TYPE.LBTT.RSTU',
          property_type: 'PROPERTYTYPE.SYS.RSTU', sale_include_option: 'SALEOFBUSINESS.LBTT.RSTU',
          form_type: 'RETURN_STATUS.SYS.RSTU' }
      end

      # Define the ref data codes associated with the attributes but which won't becached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { authority_ind: 'YESNO.SYS.RSTU', non_ads_reliefclaim_option_ind: 'YESNO.SYS.RSTU',
          ads_reliefclaim_option_ind: 'YESNO.SYS.RSTU', ads_consideration_yes_no: 'YESNO.SYS.RSTU',
          ads_sell_residence_ind: 'YESNO.SYS.RSTU', previous_option_ind: 'YESNO.SYS.RSTU',
          exchange_ind: 'YESNO.SYS.RSTU', uk_ind: 'YESNO.SYS.RSTU', linked_ind: 'YESNO.SYS.RSTU',
          business_ind: 'YESNO.SYS.RSTU', contingents_event_ind: 'YESNO.SYS.RSTU',
          deferral_agreed_ind: 'YESNO.SYS.RSTU', rent_for_all_years: 'YESNO.SYS.RSTU', premium_paid: 'YESNO.SYS.RSTU',
          ads_sold_main_yes_no: 'YESNO.SYS.RSTU', repayment_ind: 'YESNO.SYS.RSTU' }
      end

      # @return cached human readable version of the flbt_type attribute
      # TODO: CR RSTP-580 wouldn't need this if display_regions could do lookups
      def cached_human_readable_flbt_type
        lookup_ref_data_value(:flbt_type)
      end

      # @return effective date appropriately formatted
      # TODO: CR RSTP-580 wouldn't need this if display_regions could do arbitrary method calls on attributes
      #                   (though that may be going too far - should be discussed)
      def human_readable_effective_date
        DateFormatting.to_display_date_format(effective_date)
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
                        { code: :orig_return_reference, when: :flbt_type, is_not: %w[CONVEY LEASERET] }] },
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
         { code: :ads_repayment, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_ads], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           when: :ads_sold_main_yes_no,
           is: %w[Y N],
           list_items: [{ code: :ads_sold_main_yes_no, lookup: true },
                        { code: :ads_sold_date, format: :date, when: :ads_sold_main_yes_no, is: ['Y'] }] },
         { code: :ads_sold_address, # section code
           key: :ads_sold_address, # key for the title translation
           key_scope: %i[returns lbtt_ads ads_repay_address], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :ads_sold_main_yes_no,
           is: ['Y'],
           type: :object },
         { code: :ads_consideration, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_ads], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           when: :flbt_type,
           is: ['CONVEY'],
           list_items: [{ code: :ads_consideration_yes_no, lookup: true },
                        { code: :ads_amount_liable, format: :money },
                        { code: :ads_consideration, format: :money, when: :ads_consideration_yes_no, is: ['Y'] },
                        { code: :ads_sell_residence_ind, lookup: true }] },
         { code: :ads_main_address, # section code
           key: :address, # key for the title translation
           key_scope: %i[returns lbtt_ads ads_intending_sell], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :flbt_type,
           is: ['CONVEY'],
           type: :object },
         { code: :ads_relief_claim_ind, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_ads ads_reliefs], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           when: :flbt_type,
           is: ['CONVEY'],
           list_items: [{ code: :ads_reliefclaim_option_ind, lookup: true }] },
         { code: :ads_relief_claims, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           when: :ads_reliefclaim_option_ind,
           is: ['Y'],
           type: :object },
         { code: :about_the_transaction, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions property_type], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :property_type, lookup: true },
                        { code: :effective_date, format: :date },
                        { code: :relevant_date, format: :date },
                        { code: :contract_date, format: :date },
                        { code: :lease_start_date, format: :date, when: :flbt_type, is_not: 'CONVEY' },
                        { code: :lease_end_date, format: :date, when: :flbt_type, is_not: 'CONVEY' },
                        { code: :previous_option_ind, lookup: true, when: :flbt_type, is: %w[CONVEY LEASERET] },
                        { code: :exchange_ind, lookup: true, when: :flbt_type, is: %w[CONVEY LEASERET] },
                        { code: :uk_ind, lookup: true, when: :flbt_type, is: %w[CONVEY LEASERET] }] },
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
           when: :flbt_type,
           is: ['CONVEY'],
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :business_ind, lookup: true },
                        { code: :sale_include_option, lookup: true }] },
         { code: :non_ads_relief_claim_ind, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions reliefs_on_transaction], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :flbt_type,
           is: %w[CONVEY LEASERET],
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
           when: :flbt_type,
           is_not: ['CONVEY'],
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
           when: :flbt_type,
           is_not: ['CONVEY'],
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
           when: :flbt_type,
           is: ['CONVEY'],
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :contingents_event_ind, lookup: true },
                        { code: :deferral_agreed_ind, lookup: true, when: :contingents_event_ind, is: ['Y'] },
                        { code: :deferral_reference, when: :deferral_agreed_ind, is: ['Y'] }] },
         { code: :conveyance_values, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions conveyance_values], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :flbt_type,
           is: ['CONVEY'],
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
                          { code: :repayment_declaration, boolean_lookup: true, translation_extra: :account_type,
                            when: :repayment_ind, is: ['Y'] },
                          { code: :repayment_agent_declaration, boolean_lookup: true,
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
                        { code: :declaration, boolean_lookup: true, translation_extra: :account_type },
                        { code: :lease_declaration, boolean_lookup: true, when: :flbt_type, is: ['LEASERET'],
                          translation_extra: :account_type }] }]
      end

      # Validation on yearly rent to have all record with valid rent values
      def yearly_rent_validation
        return unless @rent_for_all_years == 'N'

        empty_counter = 0

        (0..yearly_rents.size - 1).each do |i|
          empty_counter = check_yearly_rents_validation_status(yearly_rents, i, empty_counter)
        end

        return unless empty_counter == yearly_rents.size

        # clear each row empty message
        errors.clear
        # add error if all entries are empty
        errors.add(:base, :missing_rental_year_entries)
      end

      # Separated from #linked_transaction_validation to add errors to this model when there's a validation problem
      # and increment empty_counter if it's empty
      # @param yearly_rents [Array] the list to check
      # @param empty_counter [Integer] count of how many link_transactions are empty
      # @param row_counter [Integer] which index in array
      # @return empty_counter
      def check_yearly_rents_validation_status(yearly_rents, row_counter, empty_counter)
        case yearly_rents[row_counter].validation_yearly_rents
        when :bad
          # amount fails validation
          errors.add(:base, :bad_rental_year_entry, row: row_counter + 1)
        when :missing
          # type or amount missing
          errors.add(:base, :invalid_rental_year_entry, row: row_counter + 1)
          # not present
          empty_counter += 1
        end

        # return the empty_counter
        empty_counter
      end

      # Validation on linked transaction to have at least one record with valid amount values
      def linked_transaction_validation
        return unless @linked_ind == 'Y'

        empty_counter = 0

        (0..link_transactions.size - 1).each do |i|
          empty_counter = check_link_transaction_validation_status(link_transactions, i, empty_counter, @flbt_type)
        end

        # add error if all entries are empty
        errors.add(:base, :one_row_required) if empty_counter == link_transactions.size
      end

      # Separated from #linked_transaction_validation to add errors to this model when there's a validation problem
      # and increment empty_counter if it's empty
      # @param link_transactions [Array] the list to check
      # @param empty_counter [Integer] count of how many link_transactions are empty
      # @param row_counter [Integer] which index in array
      # @param context [@flbt_type] the validation context (LBTT type)
      # @return empty_counter
      def check_link_transaction_validation_status(link_transactions, row_counter, empty_counter, context)
        case link_transactions[row_counter].validation_status(context)
        when :bad
          # amount fails validation
          errors.add(:base, :bad_transaction_entry, row: row_counter + 1)
        when :missing
          # type or amount missing
          errors.add(:base, :invalid_transaction_entry, row: row_counter + 1)
        when :empty
          # type and amount not present (which could be fine)
          empty_counter += 1
        end

        # return the empty_counter
        empty_counter
      end

      # Validation on non-ADS relief claim to have at least one record and values for any options selected
      def non_ads_relief_validation
        return unless @non_ads_reliefclaim_option_ind == 'Y'

        reliefs_validation(@non_ads_relief_claims)
      end

      # Validation on non-ADS relief claim to have only one relief type per return
      def non_ads_relief_code_validation
        return unless @non_ads_reliefclaim_option_ind == 'Y'

        reliefs_code_validation(@non_ads_relief_claims)
      end

      # Add validation message if duplicate entries of relief_type exists
      def reliefs_code_validation(reliefs)
        list = reliefs.collect(&:relief_type).reject(&:empty?)
        errors.add(:base, :duplicate_relief_code) unless list.detect { |e| list.count(e) > 1 }.nil?
      end

      # Validation on ADS relief claim to have at least one record and values for any options selected
      def ads_relief_validation
        return unless @ads_reliefclaim_option_ind == 'Y'

        reliefs_validation(@ads_relief_claims)
      end

      # Validation on ADS relief claim to have only one relief type per return
      def ads_relief_code_validation
        return unless @ads_reliefclaim_option_ind == 'Y'

        reliefs_code_validation(@ads_relief_claims)
      end

      # Check there's relief entries and that they're valid (empty is valid as long as it's not all of them!)
      # Adds to the model's errors if there's a validation problem.
      def reliefs_validation(reliefs)
        empty_counter = 0

        (0..reliefs.size - 1).each do |i|
          empty_counter = check_relief_validation_status(reliefs, i, empty_counter)
        end

        # add error if all entries are empty
        errors.add(:base, :one_row_required) if empty_counter == reliefs.size
      end

      # Separated from #reliefs_validation to add errors to this model when there's a relief validation problem
      # and increment empty_counter if it's empty
      # @param reliefs [Array] the ReliefClaim to check
      # @param empty_counter [Integer] count of how many reliefs are empty
      # @param row_counter [Integer] which index in array
      # @return empty_counter
      def check_relief_validation_status(reliefs, row_counter, empty_counter)
        case reliefs[row_counter].validation_status
        when :bad
          # amount fails validation
          errors.add(:base, :bad_relief_entry, row: row_counter + 1)
        when :missing
          # type or amount missing
          errors.add(:base, :invalid_relief_entry, row: row_counter + 1)
        when :empty
          # type and amount not present (which could be fine)
          empty_counter += 1
        end

        # return the empty_counter
        empty_counter
      end

      # Enforce business data rules for yes/no fields by clearing the text if no is selected.
      def clean_up_yes_nos
        @deferral_reference = nil unless deferral_agreed_ind_yes_no_y?
        @deferral_agreed_ind = nil unless contingent_events_ind_yes_no_y?
        @lease_premium = nil unless premium_paid_yes_no_y?
        @ads_consideration = nil unless ads_consideration_yes_no_yes?
        @ads_main_address = nil unless ads_sell_residence_ind == 'Y'
      end

      # Check if the return is valid for saving to the back office - adds errors any found.
      def save_validation
        errors.add(:base, :missing_properties_entries) if @properties.blank?
        errors.add(:base, :missing_agent_details) if @is_public == false && @agent.blank?
        buyer_or_seller_validation if @flbt_type == 'CONVEY'
        landlord_or_tenant_validation if %w[LEASERET LEASEREV ASSIGN TERMINATE].include? @flbt_type
      end

      # validation to check buyer and seller details - adds errors if any found.
      def buyer_or_seller_validation
        errors.add(:base, :missing_buyer_entries) if buyers.blank?
        errors.add(:base, :missing_seller_entries) if sellers.blank?
        ads_validation unless @properties.blank?
      end

      # validation to check landlord and tenant details - adds error if any found.
      def landlord_or_tenant_validation
        errors.add(:base, :missing_landlord_entries) if @flbt_type == 'LEASERET' && landlords.blank?
        errors.add(:base, :missing_tenant_entries) if tenants.blank?
        errors.add(:base, :missing_new_tenant_entries) if @flbt_type == 'ASSIGN' && new_tenants.blank?
      end

      # validation on ads wizard if ADS indicator is Yes on any of the properties entered in About the property flow
      def ads_validation
        errors.add(:base, :missing_ads) if show_ads? && @ads_consideration_yes_no.blank?
      end

      # transaction validation method
      def business_ind_yes_no_y?
        @business_ind == 'Y'
      end

      # transaction date validation method
      # Check lease end date should be after lease start date
      def end_date_after_start_date
        return unless date_parsable?(lease_end_date) && date_parsable?(lease_start_date)
        return unless Date.parse(lease_end_date) < Date.parse(lease_start_date)

        errors.add(:lease_start_date, :before_date_error)
        errors.add(:lease_end_date, :after_date_error)
      end

      # Transaction date validation method to see if date is in correct format
      # Checks if each of the three dates are in the valid date format
      # @see CommonValidation::date_format_valid?
      def valid_transaction_date_format?
        date_format_valid? :effective_date
        date_format_valid? :relevant_date
        date_format_valid? :contract_date
      end

      # Checks if each of the two dates are in the valid date format
      # @see CommonValidation::date_format_valid?
      def valid_start_end_date_format?
        date_format_valid? :lease_start_date unless lease_start_date.blank?
        date_format_valid? :lease_end_date unless lease_end_date.blank?
      end

      # Checks validation on dates should be after date mentioned in configuration parameter
      # Transaction date validation method
      def validate_transaction_dates
        validate_date_before_mentioned_date(effective_date, 'effective_date')
        validate_date_before_mentioned_date(relevant_date, 'relevant_date')
        validate_date_before_mentioned_date(contract_date, 'contract_date')
      end

      # Check date should not be before date mentioned in configuration parameter
      def validate_date_before_mentioned_date(date, attribute)
        return unless date.present? && (Date.parse(date) < Date.parse(Rails.configuration.x.earliest_start_date))

        errors.add(attribute, :past_date_error, start_date: Rails.configuration.x.earliest_start_date)
      end

      # ADS validation method
      def ads_consideration_yes_no_yes?
        @ads_consideration_yes_no == 'Y'
      end

      # ADS claim repayment date validation
      def valid_ads_date_format?
        date_format_valid? :ads_sold_date unless ads_sold_date.blank?
      end

      # transaction validation method
      def contingent_events_ind_yes_no_y?
        @contingents_event_ind == 'Y'
      end

      # transaction validation method
      def deferral_agreed_ind_yes_no_y?
        @deferral_agreed_ind == 'Y'
      end

      # transaction validation method
      def premium_paid_yes_no_y?
        @premium_paid == 'Y'
      end

      # transaction validation method
      def lbtt_return_type_not_conveyance?
        @flbt_type != 'CONVEY'
      end

      # Validation for transaction sale include options, user must have selected at least one non-blank option
      def sale_include_option_valid?
        return unless business_ind_yes_no_y?

        errors.add(:sale_include_option, :one_must_be_chosen) if sale_include_option.reject(&:empty?).empty?
      end

      # Validation for original reference.
      def orig_return_reference_valid?
        return if valid_reference?(@orig_return_reference)

        errors.add(:orig_return_reference, :format_is_invalid)
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

      # Summary data about the transaction data in this return.
      # If there is no summary data then .blank? will be true.
      # @param return_prefix [String] added to the start of keys to help finding the translation
      # @param tax_prefix [String] added to the start of keys to help finding the translation
      # @return [Hash] of [ attribute => data ]
      def transaction_summary(return_prefix, tax_prefix) # rubocop:disable Metrics/MethodLength
        output = {}
        output["#{return_prefix}.property_type"] = property_type_value(@property_type) unless @property_type.blank?
        unless @effective_date.blank?
          output["#{return_prefix}.effective_date"] = @effective_date.to_date.strftime('%d %B %Y')
        end
        unless @relevant_date.blank?
          output["#{return_prefix}.relevant_date"] = @relevant_date.to_date.strftime('%d %B %Y')
        end
        output = if @flbt_type == 'CONVEY'
                   transaction_summary_convey(output, return_prefix)
                 else
                   transaction_summary_lease(output, return_prefix, tax_prefix)
                 end

        output
      end

      # The ADS section should only be shown if the user has specified that ADS applies to a property
      # @see LbttPropertiesController
      # @return [Boolean] whether or not to show the ADS section
      def show_ads?
        return false if @properties.blank?

        @properties.values.detect { |property| property.ads_due_ind == 'Y' }.present?
      end

      # For a repayment then for lbtt the return needs to be an amendment
      # OR one of the three lease review types
      # @see LbttPropertiesController
      # @return [Boolean] whether or not to show repayment details
      def show_repayment?
        return true if %w[LEASEREV ASSIGN TERMINATE].include? flbt_type
        return true if amendment?

        false
      end

      # Summary data about the ADS data in this return.
      # If there is no summary data then .blank? will be true.
      # @param prefix [String] added to the start of keys to help finding the translation
      # @return [Hash] of [ attribute => data ]
      def ads_summary(prefix) # rubocop:disable Metrics/MethodLength
        output = {}
        unless @ads_sell_residence_ind.blank?
          output["#{prefix}.ads_sell_residence_ind"] = lookup_ref_data_value(:ads_sell_residence_ind)
        end
        output["#{prefix}.ads_main_address"] = @ads_main_address.short_address unless @ads_main_address.blank?
        unless @ads_consideration.blank?
          output["#{prefix}.ads_consideration"] = "£#{NumberFormatting.to_money_format(@ads_consideration)}"
        end
        unless @ads_amount_liable.blank?
          output["#{prefix}.ads_amount_liable"] = "£#{NumberFormatting.to_money_format(@ads_amount_liable)}"
        end
        return output if @ads_reliefclaim_option_ind.blank? # strange construct but keeps rubocop happy

        output["#{prefix}.ads_reliefclaim_option_ind"] = lookup_ref_data_value(:ads_reliefclaim_option_ind)
        output
      end

      # Property type based on its ref data code
      # @param code [String] property code
      # @return [String] property type description from cache
      def property_type_value(code)
        property_types = ReferenceData::ReferenceValue.list('PROPERTYTYPE', 'SYS', 'RSTU')
        property_types.select { |data| data.code == code }[0].value
      end

      # Retrieve local authority value based on lau_code
      # from list of local authorities reference array
      def property_authority_value(code)
        authorities = ReferenceData::ReferenceValue.lookup('LAU', 'SYS', 'RSTU')
        authorities[code].value
      end

      # TODO: CR RSTP-643 Currently returns the first of the UUID index hash values ie it's arbitrary
      # @return main party which is the first buyer or tenant depending on the return type
      def primary_party
        return buyers.values.first if @flbt_type == 'CONVEY'

        tenants.values.first if %w[LEASERET LEASEREV ASSIGN TERMINATE].include?(@flbt_type)
      end

      # TODO: CR RSTP-643 Currently returns the first of the UUID index hash values ie it's arbitrary
      def primary_property
        properties.values.first
      end

      # Takes the hash from the back office response and transform to make it compatible with our models
      # ie this method is like the opposite of @see #request_save.
      private_class_method def self.convert_back_office_hash(lbtt) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/LineLength
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

        if output.key?(:include_in_sale)
          output[:sale_include_option] = []
          output[:sale_include_option] << 'GOODWILL' if output[:include_in_sale][:goodwill_ind] == 'yes'
          output[:sale_include_option] << 'STOCK' if output[:include_in_sale][:stock_ind] == 'yes'
          output[:sale_include_option] << 'MOVEABLES' if output[:include_in_sale][:moveables_ind] == 'yes'
          output[:sale_include_option] << 'OTHER' if output[:include_in_sale][:other_ind] == 'yes'
          output.delete(:include_in_sale)
        end

        # tax and reliefs
        output.merge!(convert_to_relief_claims(output.delete(:reliefs))) unless output[:reliefs].blank?
        output[:tax] = Tax.convert_tax_calculations(output)

        unless output[:ads_address].blank?
          output[:ads_main_address] = Address.convert_hash_to_address(output[:ads_address])
        end

        unless output[:ads_sold_address].blank?
          output[:ads_sold_address] = Address.convert_hash_to_address(output[:ads_sold_address])
        end
        output[:ads_sold_main_yes_no] = 'Y' unless output[:ads_sold_date].blank?
        output[:ads_sold_date] = output[:ads_sold_date] unless output[:ads_sold_date].blank?

        # convert back office yes/no to Y/N
        yes_nos_to_yns(output, %i[previous_option_ind exchange_ind uk_ind contingents_event_ind ads_sell_residence_ind])

        # derive yes no based on the data now that we've finished moving it around
        derive_yes_nos_in(output)

        # derive values based on yes/no indicator and some other values
        derive_amount(output)

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

      # Calculating some values which are depend on some other values
      private_class_method def self.derive_amount(lbtt)
        return unless lbtt[:linked_ind] == 'Y'

        Rails.logger.debug('Calculating sum of linked consideration amount for linked transactions total')
        lbtt[:linked_consideration] = FLApplicationRecord.sum_of_values_from_list(lbtt[:link_transactions],
                                                                                  :consideration_amount)
        lbtt[:linked_lease_premium] = FLApplicationRecord.sum_of_values_from_list(lbtt[:link_transactions],
                                                                                  :premium_inc)
      end

      # Some atrributes yes_no type depending on some other attribute value, so here we are setting them
      private_class_method def self.derive_yes_nos_in(lbtt) # rubocop:disable Metrics/MethodLength
        to_derive = {
          ads_reliefclaim_option_ind: :ads_relief_claims,
          non_ads_reliefclaim_option_ind: :non_ads_relief_claims,
          business_ind: :sale_include_option,
          linked_ind: :link_transactions,
          premium_paid: :lease_premium,
          deferral_agreed_ind: :deferral_reference,
          ads_consideration_yes_no: :ads_consideration
        }
        derive_yes_nos(lbtt, to_derive, true)

        # custom ones
        lbtt[:rent_for_all_years] = (lbtt.delete(:same_rent_each_year_ind) == 'yes' ? 'Y' : 'N')
        lbtt[:ads_consideration_yes_no] = nil if lbtt[:ads_amount_liable].blank?
      end

      # Returns a translation attribute where a given attribute may have more than one name based on e.g. a type
      # it also allows for a different attribute name for the error region for e.g. long labels
      # @param attribute [Symbol] the name of the attribute to translate
      # @param translation_options [Object] in this case the party type being processed passed from the page
      # @param error_attribute [Boolean] is the translation being called for the error region
      # @return [Symbol] the name of the translation attribute
      def translation_attribute(attribute, translation_options = nil, error_attribute = false)
        return attribute unless %i[authority_ind declaration lease_declaration repayment_declaration
                                   repayment_agent_declaration annual_rent].include?(attribute)
        return (attribute.to_s + '_' + flbt_type).to_sym if attribute == :annual_rent
        return (attribute.to_s + '_error').to_sym if error_attribute

        translation_attribute_not_error(attribute, translation_options)
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

      # Convert the incomming parties data into specific type for example into buyers, sellers depending on type
      private_class_method def self.convert_to_party_type(parties, party_type)
        return {} if parties.nil?

        output = {}
        ServiceClient.iterate_element(parties) do |party|
          return party if party.party_type == party_type && party_type == 'AGENT'

          output[party.party_id] = party if party.party_type == party_type
        end
        output
      end

      # Convert the incomming property data into property objects
      private_class_method def self.convert_properties(lbtt)
        properties = lbtt[:properties][:property] unless lbtt[:properties].nil?
        return {} if properties.nil?

        properties = [properties] unless properties.is_a? Array
        output = {}

        properties.each do |raw_hash|
          property = Property.convert_back_office_hash(raw_hash)
          output[property.property_id] = property
        end
        output
      end

      # Convert the relief_claim data into relief objects separated into ADS and non-ADS reliefs.
      # @return [Hash] reliefs with indexes :non_ads_relief_claims and :ads_relief_claims.
      private_class_method def self.convert_to_relief_claims(reliefs_data)
        return nil if reliefs_data.nil? || reliefs_data[:relief].nil?

        # convert to array if it isn't already
        reliefs_data[:relief] = [reliefs_data[:relief]] unless reliefs_data[:relief].is_a? Array

        output = { non_ads_relief_claims: [], ads_relief_claims: [] }
        reliefs_data[:relief].each do |raw_hash|
          convert_and_organise_relief(raw_hash, output)
        end

        clean_empty_relief_lists(output)
      end

      # Separated out of #convert_to_relief_claims.
      # @param raw_hash [Hash] data loaded from the back office about a relief
      private_class_method def self.convert_and_organise_relief(raw_hash, output)
        relief = ReliefClaim.convert_back_office_hash(raw_hash)
        if /ADS.*/.match?(relief.relief_type)
          output[:ads_relief_claims] << relief
        else
          output[:non_ads_relief_claims] << relief
        end
      end

      # So that other code can just do a nil check rather than having to check for contents, delete
      # empty parts of the reliefs hash.  Called by #convert_to_relief_claims to tidy it's output.
      # @return [Hash] reliefs with populated indexes only
      private_class_method def self.clean_empty_relief_lists(output)
        output.delete(:non_ads_relief_claims) if output[:non_ads_relief_claims].empty?
        output.delete(:ads_relief_claims) if output[:ads_relief_claims].empty?

        output
      end

      # Validation to run before attempting a minimal Lbtt::Tax calculation request (ie anything the back office
      # can't do without should be validated for so we don't bother trying until we have it.)
      def valid_for_tax_calc?
        output = true
        output = false unless @effective_date.present?
        output = false unless @contract_date.present?
        output = false unless @flbt_type.present?
        output = false unless lbtt_property_type.present?
        Rails.logger.debug("  valid_for_tax_calc? is #{output}")

        output
      end

      # Converts property type to back-office required format
      # In lease review, assignation and termination page, we not select property type thorugh application
      # So, we need to set to non-residential.
      def convert_property_type
        lbtt_property_type == '3' ? 'Non-residential' : 'Residential'
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

      # Uses the payment code to and translates it to the description of the payment
      def payment_description
        lookup_ref_data_value(:fpay_method)
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

      # Calculate the linked totals based on the linked transactions field if the user has said there are linked
      # transactions.
      # NB this may overwrite any previous values for @linked_consideration and @linked_lease_premium
      # but we do not save the model here.
      def calculate_linked_totals
        return unless @linked_ind == 'Y'

        Rails.logger.debug('Calculating sum of linked consideration amount for linked transactions total')
        @linked_consideration = sum_from_values(@link_transactions, :consideration_amount)
        @linked_lease_premium = sum_from_values(@link_transactions, :premium_inc)
      end

      private

      # Called by @see Returns::AbstractReturn#save
      # If @version exists then must be doing an update so use the update webservice, else it's new so use the new one.
      # Raises an error if using the update operation but tare_refno is nil since that should not happen.
      def save_operation
        if @version.blank?
          operation = :lbtt_tax_return
          @version = '1'
        else
          operation = :lbtt_update
          raise Error::AppError.new('LBTT save', 'Missing existing ref no') if @tare_refno.nil?
        end

        Rails.logger.debug("Version number is #{@version}, using the #{operation} operation")
        operation
      end

      # Called by @see Returns::AbstractReturn#save
      # @param requested_by [Object] details for the current user
      # @return a hash suitable for use in a save request to the back office
      def request_save(requested_by) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/LineLength
        output = {
          'ins1:FlbtType': @flbt_type, 'ins1:PropertyType': lbtt_property_type
        }
        output['ins1:OrigReturnReference'] = @orig_return_reference if %w[LEASEREV ASSIGN TERMINATE].include? @flbt_type
        output.merge!('ins1:EffectiveDate': DateFormatting.to_xml_date_format(@effective_date),
                      'ins1:RelevantDate': DateFormatting.to_xml_date_format(@relevant_date),
                      'ins1:ContractDate': DateFormatting.to_xml_date_format(@contract_date))
        if lbtt_return_type_not_conveyance?
          output[:'ins1:LeaseStartDate'] = DateFormatting.to_xml_date_format(@lease_start_date)
          output[:'ins1:LeaseEndDate'] = DateFormatting.to_xml_date_format(@lease_end_date)
        end
        output.merge!('ins1:PreviousOptionInd': @previous_option_ind == 'Y' ? 'yes' : 'no',
                      'ins1:ExchangeInd': @exchange_ind == 'Y' ? 'yes' : 'no',
                      'ins1:UKInd': @uk_ind == 'Y' ? 'yes' : 'no')
        output['ins1:AgentReference'] = @agent.agent_reference unless @agent&.agent_reference.blank?
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

        if lbtt_return_type_not_conveyance?

          # sends 0 for linked npv if there are no linked transactions
          output['ins1:LinkedNPV'] = @linked_ind == 'Y' ? or_zero(@tax.linked_npv) : 0

          output['ins1:LinkedLeasePremium'] = @linked_ind == 'Y' ? or_zero(@linked_lease_premium) : 0
          output['ins1:AnnualRent'] = or_zero(@annual_rent)
          output['ins1:SameRentEachYearInd'] = @rent_for_all_years == 'Y' ? 'yes' : 'no'
          if @rent_for_all_years == 'N' && @yearly_rents.present?
            output['ins1:Rent'] = { 'ins1:YearlyRents': @yearly_rents.map(&:request_save) }
            output['ins1:Rent'] = output['ins1:Rent'].compact
          end
          output['ins1:LeasePremium'] = or_zero(@lease_premium)

          output['ins1:RelevantRent'] = or_zero(@relevant_rent)
          output['ins1:NetPresentValue'] = or_zero(@tax.npv)
          output['ins1:PremiumTaxDue'] = or_zero(@tax.premium_tax_due)
          output['ins1:NpvTaxDue'] = or_zero(@tax.npv_tax_due)
          output.delete('ins1:ConsiderationAmount')
        else
          # set to 0 if there are no linked transactions
          output['ins1:LinkedConsideration'] = @linked_ind == 'Y' ? or_zero(@linked_consideration) : 0
        end

        output['ins1:Properties'] = { 'ins1:Property': @properties.values.map(&:request_save) } unless @properties.nil?

        if business_ind == 'Y'
          output['ins1:IncludeInSale'] = {
            'ins1:StockInd': @sale_include_option.include?('STOCK') ? 'yes' : 'no',
            'ins1:GoodwillInd': @sale_include_option.include?('GOODWILL') ? 'yes' : 'no',
            'ins1:MoveablesInd': @sale_include_option.include?('MOVEABLES') ? 'yes' : 'no',
            'ins1:OtherInd': @sale_include_option.include?('OTHER') ? 'yes' : 'no'
          }
        end
        if @flbt_type == 'CONVEY'
          output['ins1:TotalConsideration'] = or_zero(@total_consideration)
          output['ins1:TotalVat'] = or_zero(@total_vat)
          output['ins1:NonChargeable'] = or_zero(@non_chargeable)
          output['ins1:RemainingChargeable'] = or_zero(@remaining_chargeable)
        end

        # merge ADS and non-ADS reliefs into one and use that unless it's blank
        reliefs = merge_reliefs
        output['ins1:Reliefs'] = reliefs unless reliefs.blank?

        output['ins1:Calculated'] = or_zero(@tax.calculated)
        output['ins1:AdsDue'] = or_zero(@tax.ads_due)
        output['ins1:AdsDueInd'] = (show_ads? ? 'yes' : 'no')
        output['ins1:DueBeforeReliefs'] = or_zero(@tax.due_before_reliefs)
        output['ins1:TotalReliefs'] = or_zero(@tax.total_reliefs)
        output['ins1:TotalADSReliefs'] = or_zero(@tax.total_ads_reliefs)
        output['ins1:TaxDue'] = or_zero(@tax.tax_due)

        output['ins1:OrigNpvTaxDue'] = or_zero(@tax.orig_npv_tax_due) if lbtt_return_type_not_conveyance?

        if %w[LEASEREV ASSIGN TERMINATE].include? @flbt_type
          output['ins1:AmountAlreadyPaid'] = or_zero(@tax.amount_already_paid)
          output['ins1:TaxDueForReturn'] = or_zero(@tax.tax_due_for_return)
        end

        output['ins1:OrigCalculated'] = or_zero(@tax.orig_calculated)
        output['ins1:OrigAdsDue'] = or_zero(@tax.orig_ads_due)
        output['ins1:OrigDueBeforeReliefs'] = or_zero(@tax.orig_due_before_reliefs)
        output['ins1:OrigTotalReliefs'] = or_zero(@tax.orig_total_reliefs)
        output['ins1:OrigTaxDue'] = or_zero(@tax.orig_tax_due)
        output['ins1:OrigNetPresentValue'] = or_zero(@tax.orig_npv)
        output['ins1:OrigTotalADSReliefs'] = or_zero(@tax.orig_total_ads_reliefs)
        output['ins1:OrigPremiumTaxDue'] = or_zero(@tax.orig_premium_tax_due)

        output['ins1:ContingentsEventInd'] = @contingents_event_ind == 'Y' ? 'yes' : 'no'
        if @contingents_event_ind == 'Y'
          output['ins1:DeferralReference'] = @deferral_reference unless @deferral_reference.blank?
          output['ins1:DeferralAgreedInd'] = @deferral_agreed_ind == 'Y' ? 'yes' : 'no'
        end

        output['ins1:FPAYMethod'] = @fpay_method unless @fpay_method.blank?

        # repayments
        if @repayment_ind == 'Y'

          claim_reason_code = @ads_sold_main_yes_no == 'Y' ? 'ADS' : 'OTHER'

          output.merge!('ins1:ClaimType': 'PRE12MONTH',
                        'ins1:ClaimReasonCode': claim_reason_code,
                        'ins1:RepaymentInd': 'yes',
                        'ins1:RepayAccountHolder': @account_holder_name,
                        'ins1:RepayBankAccountNo': @account_number,
                        'ins1:RepayBankSortCode': @branch_code,
                        'ins1:RepaymentBankName': @bank_name,
                        'ins1:RepayAmountClaimed': @repayment_amount_claimed,
                        'ins1:RepaymentAgentAuthInd': @repayment_declaration.blank? ? 'no' : 'yes')
        # They haven't yet claimed a repayment but have said they sold the property
        elsif @repayment_ind.nil? && @ads_sold_main_yes_no == 'Y'
          output.merge!('ins1:ClaimType': 'PRE12MONTH',
                        'ins1:ClaimReasonCode': 'ADS',
                        'ins1:RepayAmountClaimed': @tax.ads_repay_amount_claimed)
        elsif @repayment_ind == 'N'
          output['ins1:RepaymentInd'] = 'no'
        end

        # is the ADS section currently available to the user
        show_ads = show_ads?
        output['ins1:AdsSellResidenceInd'] = @ads_sell_residence_ind == 'Y' && show_ads ? 'yes' : 'no'

        # include ADS fields only if the user is currently shown the ADS wizard option (ie it could have been hidden
        # since ADS data was added)
        if show_ads
          output['ins1:AdsAddress'] = @ads_main_address.format_to_back_office_address unless @ads_main_address.blank?
          output['ins1:AdsConsideration'] = @ads_consideration unless @ads_consideration.blank?
          output['ins1:AdsAmountLiable'] = @ads_amount_liable unless @ads_amount_liable.blank?
          unless @ads_sold_address.blank?
            output['ins1:AdsSoldAddress'] = @ads_sold_address.format_to_back_office_address
          end
          output['ins1:AdsSoldDate'] = DateFormatting.to_xml_date_format(@ads_sold_date) unless @ads_sold_date.blank?
        end

        # put the top tag in place and add the print data
        # The print data needs to be in this routine as it has specific information based on the return type
        { 'ins1:LBTTReturnDetails': output,
          'ins1:PrintData': print_data(account_type: User.account_type(requested_by), flbt_type: @flbt_type) }
      end

      # Add the ADS and non-ADS reliefs together for submission if their respective indicators are 'Y'.
      # Hides the ADS reliefs if @see #show_ads? doesn't return true
      def merge_reliefs
        output = []
        output << @non_ads_relief_claims.map(&:request_save) if @non_ads_reliefclaim_option_ind == 'Y'
        output << @ads_relief_claims.map(&:request_save) if @ads_reliefclaim_option_ind == 'Y' && show_ads?

        # flatten and compact to ensure we create the right format output for the request without any empty entries
        { 'ins1:Relief': output.flatten&.compact }
      end

      # Set property type as non residential in case of lease review, assignation and termination
      # Property_type page is not present in these lease flow, so need to set manually
      def lbtt_property_type
        @property_type = '3' if %w[LEASEREV ASSIGN TERMINATE].include? @flbt_type
        @property_type
      end

      # Dynamically returns the translation key based on the translation_options provided by the page if it exists
      # or else the flbt_type.
      # @param attribute [Symbol] the name of the attribute to translate
      # @param translation_options [Object] in this case the party type being processed passed from the page
      # @return [Symbol] "attribute_" + extra information to make the translation key
      def translation_attribute_not_error(attribute, translation_options = nil)
        suffix = if %i[authority_ind repayment_agent_declaration].include?(attribute)
                   flbt_type
                 elsif %i[lease_declaration].include?(attribute) && !translation_options.nil?
                   translation_options
                 elsif %i[declaration repayment_declaration].include?(attribute)
                   "#{flbt_type}_#{translation_options}"
                 end

        (attribute.to_s + '_' + suffix).to_sym
      end

      # Summary data about the transaction data for conveyance return
      # @see transaction_summary
      # @param output [Hash] the hash being created
      # @param prefix [String] added to the start of keys to help finding the translation
      # @return [Hash] of [ attribute => data ]
      def transaction_summary_convey(output, prefix)
        output["#{prefix}.linked_ind"] = lookup_ref_data_value(:linked_ind) unless @linked_ind.blank?
        output["#{prefix}.business_ind"] = lookup_ref_data_value(:business_ind) unless @business_ind.blank?
        unless @non_ads_reliefclaim_option_ind.blank?
          output["#{prefix}.non_ads_reliefclaim_option_ind"] = lookup_ref_data_value(:non_ads_reliefclaim_option_ind)
        end
        unless @remaining_chargeable.blank?
          output["#{prefix}.remaining_chargeable"] = "£#{NumberFormatting.to_money_format(@remaining_chargeable)}"
        end
        output
      end

      # Summary data about the transaction data for lease return
      # @see transaction_summary
      # @param output [Hash] the hash being created
      # @param return_prefix [String] added to the start of keys to help finding the translation
      # @param tax_prefix [String] added to the start of keys to help finding the translation
      # @return [Hash] of [ attribute => data ]
      def transaction_summary_lease(output, return_prefix, tax_prefix)
        output = transaction_summary_lease_dates(output, return_prefix)
        output["#{return_prefix}.linked_ind"] = lookup_ref_data_value(:linked_ind) unless @linked_ind.blank?
        output = transaction_summary_rent_and_premium(output, return_prefix)
        output["#{tax_prefix}.npv"] = "£#{NumberFormatting.to_money_format(@tax&.npv)}" unless @tax&.npv.blank?

        # LEASEREV, ASSSIGN and TERMINATE don't have the relief claim option
        return output if %w[LEASEREV ASSIGN TERMINATE].include? @flbt_type

        unless @non_ads_reliefclaim_option_ind.blank?
          output["#{return_prefix}.non_ads_reliefclaim_option_ind"] =
            lookup_ref_data_value(:non_ads_reliefclaim_option_ind)
        end

        output
      end

      # Summary data about the lease premium
      # @see transaction_summary
      # @param output [Hash] the hash being created
      # @param prefix [String] added to the start of keys to help finding the translation
      # @return [Hash] of [ attribute => data ]
      def transaction_summary_rent_and_premium(output, prefix)
        unless @relevant_rent.blank?
          output["#{prefix}.relevant_rent"] = "£#{NumberFormatting.to_money_format(@relevant_rent)}"
        end
        output["#{prefix}.premium_paid"] = lookup_ref_data_value(:premium_paid) if @premium_paid == 'N'
        unless @lease_premium.blank?
          output["#{prefix}.lease_premium"] = "£#{NumberFormatting.to_money_format(@lease_premium)}"
        end
        output
      end

      # Summary data about the transaction data for lease return dates
      # @see transaction_summary
      # @param output [Hash] the hash being created
      # @param prefix [String] added to the start of keys to help finding the translation
      # @return [Hash] of [ attribute => data ]
      def transaction_summary_lease_dates(output, prefix)
        unless @lease_start_date.blank?
          output["#{prefix}.lease_start_date"] = @lease_start_date.to_date.strftime('%d %B %Y')
        end
        output["#{prefix}.lease_end_date"] = @lease_end_date.to_date.strftime('%d %B %Y') unless @lease_end_date.blank?
        output
      end
    end
  end
end
