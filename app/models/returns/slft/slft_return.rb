# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise SLfT return models
  module Slft
    # Model for the SLfT return
    class SlftReturn < AbstractReturn # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
      include CommonValidation
      validates_with SlftReturnValidator, on: :submit

      # Attributes for this class, in list so can re-use as permitted params list in the controller.
      # NB sites is a hash [lasi_refno => Slft::Site] (lasi_refno is a site ID number).
      def self.attribute_list
        %i[
          slcf_yes_no slcf_contribution slcf_credit_claimed
          bad_debt_credit bad_debt_yes_no removal_credit_yes_no removal_credit
          fape_period year non_disposal_add_ind non_disposal_add_text
          non_disposal_delete_ind non_disposal_delete_text sites
          declaration total_tax_due total_credit tax_payable fpay_method
          repayment_yes_no amount_claimed account_holder bank_account_no bank_sort_code bank_name
          rrep_bank_auth_ind payment_date filing_date
        ]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { year: 'YEAR.SYS.RSTU', fape_period: 'PERIOD.SYS.RSTU', fpay_method: 'PAYMENT TYPE.SLFT.RSTU',
          form_type: 'RETURN_STATUS.SYS.RSTU' }
      end

      # Define the ref data codes associated with the attributes but which won't becached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { non_disposal_add_ind: 'YESNO.SYS.RSTU', non_disposal_delete_ind:  'YESNO.SYS.RSTU',
          slcf_yes_no: 'YESNO.SYS.RSTU', bad_debt_yes_no: 'YESNO.SYS.RSTU', removal_credit_yes_no: 'YESNO.SYS.RSTU',
          repayment_yes_no: 'YESNO.SYS.RSTU' }
      end

      # Attribute list for return period wizard
      def self.return_period_attr_list
        %i[fape_period year non_disposal_add_ind non_disposal_add_text
           non_disposal_delete_ind non_disposal_delete_text]
      end

      # Attribute list for credit claim wizard
      def self.credit_claimed_attr_list
        %i[slcf_yes_no slcf_contribution slcf_credit_claimed bad_debt_credit bad_debt_yes_no removal_credit_yes_no
           removal_credit]
      end

      # about the transaction validation
      validates :year, presence: true, on: :year
      validates :fape_period, presence: true, on: :year
      validates :non_disposal_add_ind, presence: true, on: :non_disposal_add_ind
      validates :non_disposal_add_text, presence: true, length: { maximum: 4000 }, on: :non_disposal_add_ind,
                                        if: :non_disposal_add_ind_y?
      validates :non_disposal_delete_ind, presence: true, on: :non_disposal_delete_ind
      validates :non_disposal_delete_text, presence: true, length: { maximum: 4000 }, on: :non_disposal_delete_ind,
                                           if: :non_disposal_delete_ind_y?

      # credit claimed validation
      validates :slcf_yes_no, presence: true, on: :slcf_yes_no
      validates :slcf_contribution, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000 },
                                    on: :slcf_yes_no, if: :slcf_yes_no_y?
      validates :slcf_credit_claimed, numericality: { less_than: proc { |s| s.slcf_contribution.to_f } },
                                      on: :slcf_yes_no, if: :slcf_yes_no_y?
      validates :bad_debt_yes_no, presence: true, on: :bad_debt_yes_no
      validates :bad_debt_credit, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000 },
                                  on: :bad_debt_yes_no, if: :bad_debt_yes_no_y?
      validates :removal_credit_yes_no, presence: true, on: :removal_credit_yes_no
      validates :removal_credit, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000 },
                                 on: :removal_credit_yes_no, if: :removal_credit_yes_no_y?

      # repayment validation
      validates :repayment_yes_no, presence: true, on: :repayment_yes_no
      validates :amount_claimed, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000 },
                                 on: :repayment_yes_no, if: proc { |s| s.repayment_yes_no == 'Y' }
      validates :account_holder, presence: true, length: { maximum: 255 }, on: :account_holder
      validates :bank_account_no, presence: true,
                                  numericality: { only_integer: true },
                                  length: { is: 8 }, on: :account_holder
      validates :bank_sort_code, presence: true, on: %i[bank_sort_code]
      validate :repay_bank_sort_code_valid?, on: :account_holder
      validates :bank_name, presence: true, length: { maximum: 255 }, on: :account_holder

      # repayment declaration
      validates :rrep_bank_auth_ind, acceptance: { accept: ['true'] }, on: :rrep_bank_auth_ind

      # declaration validation
      validates :fpay_method, presence: true, on: :fpay_method
      validates :declaration, acceptance: { accept: ['true'] }, on: :fpay_method

      # save draft and calculate (submit) buttons validation
      validates :year, presence: { message: :missing_about_the_transaction }, on: %i[draft submit]
      validates :slcf_yes_no, presence: { message: :missing_credits_claimed }, on: :submit

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :about_transaction, # section code
           key: :transaction_subtitle, # key for the title translation
           key_scope: %i[returns slft summary], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :tare_reference, placeholder: '<%TARE_REFERENCE%>' },
                        { code: :version, placeholder: '<%VERSION%>' },
                        { code: :form_type, lookup: true },
                        { code: :year, lookup: true },
                        { code: :fape_period, lookup: true },
                        { code: :non_disposal_add_ind, lookup: true },
                        { code: :non_disposal_add_text, when: :non_disposal_add_ind, is: ['Y'] },
                        { code: :non_disposal_delete_ind, lookup: true },
                        { code: :non_disposal_delete_text, when: :non_disposal_delete_ind, is: ['Y'] }] },
         { code: :sites,
           type: :object }, # this is an object so get the section from the objects
         { code: :credits_claimed, # section code
           key: :credits_subtitle, # key for the title translation
           key_scope: %i[returns slft summary], # scope for the title translation
           page_break: true,
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :slcf_yes_no, lookup: true },
                        { code: :slcf_contribution, format: :money, when: :slcf_yes_no, is: ['Y'] },
                        { code: :slcf_credit_claimed, format: :money, when: :slcf_yes_no, is: ['Y'] },
                        { code: :bad_debt_yes_no, lookup: true },
                        { code: :bad_debt_credit, format: :money, when: :bad_debt_yes_no, is: ['Y'] },
                        { code: :removal_credit_yes_no, lookup: true },
                        { code: :removal_credit, format: :money, when: :removal_credit_yes_no, is: ['Y'] }] },
         { code: :calculation, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns slft declaration_calculation], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :total_tax_due, format: :money },
                        { code: :total_credit, format: :money },
                        { code: :tax_payable, format: :money }] },
         # if the repayment yes no nil/blank they never got asked the question i.e. not an amend
         # we can't use the version as that is set to 1 by the time this is called
         unless @repayment_yes_no.blank?
           { code: :repayment, # section code
             key: :title, # key for the title translation
             key_scope: %i[returns slft declaration_repayment], # scope for the title translation
             divider: false, # should we have a section divider
             display_title: true, # Is the title to be displayed
             type: :list, # type list = the list of attributes to follow
             list_items: [{ code: :repayment_yes_no, lookup: true },
                          { code: :amount_claimed, format: :money, when: :repayment_yes_no, is: ['Y'] },
                          { code: :account_holder, when: :repayment_yes_no, is: ['Y'] },
                          { code: :bank_sort_code, when: :repayment_yes_no, is: ['Y'] },
                          { code: :bank_account_no, when: :repayment_yes_no, is: ['Y'] },
                          { code: :bank_name, when: :repayment_yes_no, is: ['Y'] },
                          { code: :rrep_bank_auth_ind, boolean_lookup: true, when: :repayment_yes_no, is: ['Y'] }] }
         end,
         { code: :declaration, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns slft declaration], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :fpay_method, lookup: true }] },
         { code: :declaration, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns slft declaration], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :declaration, boolean_lookup: true }] }]
      end

      # about the transaction validation method
      def non_disposal_add_ind_y?
        @non_disposal_add_ind == 'Y'
      end

      # about the transaction validation method
      def non_disposal_delete_ind_y?
        @non_disposal_delete_ind == 'Y'
      end

      # credit claimed validation method
      def slcf_yes_no_y?
        @slcf_yes_no == 'Y'
      end

      # credit claimed validation method
      def bad_debt_yes_no_y?
        @bad_debt_yes_no == 'Y'
      end

      # credit claimed validation method
      def removal_credit_yes_no_y?
        @removal_credit_yes_no == 'Y'
      end

      # Validation for Sort code
      def repay_bank_sort_code_valid?
        repay_bank_sort_code_format_valid? :bank_sort_code
      end

      # Enforce business data rules for yes/no fields by clearing the text if no is selected.
      def clean_up_yes_nos
        @non_disposal_add_text = nil unless non_disposal_add_ind_y?
        @non_disposal_delete_text = nil unless non_disposal_delete_ind_y?
        @bad_debt_credit = nil unless bad_debt_yes_no_y?
        @removal_credit = nil unless removal_credit_yes_no_y?

        return if slcf_yes_no_y?

        @slcf_contribution = nil
        @slcf_credit_claimed = nil
      end

      # Cleans the money fields by ensuring they're 2dp if they are set.
      def clean_up_money
        if slcf_yes_no_y?
          @slcf_contribution = NumberFormatting.to_money_format(slcf_contribution)
          @slcf_credit_claimed = NumberFormatting.to_money_format(slcf_credit_claimed)
        end

        @bad_debt_credit = NumberFormatting.to_money_format(bad_debt_credit) if bad_debt_yes_no_y?
        @removal_credit = NumberFormatting.to_money_format(removal_credit) if removal_credit_yes_no_y?
      end

      # Summary data about the transaction data in this return.
      # If there is no summary data then .blank? will be true.
      # @param prefix [String] added to the start of keys to help finding the translation
      # @return [Hash] of [ attribute => data ]
      def transaction_summary(prefix)
        output = {}

        # NB the order of these is important to the output and the result must be .blank? if there's no data
        output["#{prefix}.year"] = lookup_ref_data_value(:year) unless @year.nil?

        output["#{prefix}.fape_period"] = lookup_ref_data_value(:fape_period) unless @fape_period.nil?

        output["#{prefix}.non_disposal_add_ind"] = lookup_ref_data_value(:non_disposal_add_ind) unless
          @non_disposal_add_ind.nil?

        output["#{prefix}.non_disposal_delete_ind"] = lookup_ref_data_value(:non_disposal_delete_ind) unless
          @non_disposal_delete_ind.nil?

        output
      end

      # Summary data about the credit data in this return
      # If there is no summary data then .blank? will be true.
      # @return [Hash] of [ attribute => data ]
      def credit_summary(prefix)
        output = {}
        output = credit_slcf_summary(output, prefix)
        output = credit_bad_debt_summary(output, prefix)
        credit_removal_summary(output, prefix)
      end

      # Describe the return
      def to_s
        "tare_reference: #{tare_reference} year: #{year} quarter: #{fape_period}"
      end

      # @!method self.convert_back_office_hash(body)
      # Takes the hash from the back office response and fiddles with it to make it compatible with our models
      # ie so we can pass it to @see FLApplicationRecord#new_from_fl. @see #save.
      # ie this method is like the opposite of @see #request_save.
      # @param body [Hash] the hash from the @see ServiceClient.call_ok? method
      # @return [Hash] the section of the body hash that describes the return converted for use in creating a new model
      def self.convert_back_office_hash(slft) # rubocop:disable Metrics/MethodLength
        # separate output object so that back office changes won't break FL record loading
        output = {}
        output[:form_type] = slft[:form_type]
        output[:tare_reference] = slft[:tare_reference]
        output[:tare_refno] = slft[:tare_refno]
        output[:version] = slft[:version]

        # arrange the output
        output.merge!(slft[:slft_return_details])

        move_to_root(output, :nda)
        move_to_root(output, :credit_claim)
        move_to_root(output, :tax_payable)

        derive_yes_nos_in(output)

        output[:sites] = convert_sites(output)

        # don't want to load the repayment details, throw this lot away
        # also clear any FPAYMethod data as user must re-enter that
        delete = %i[amount_claimed account_holder bank_account_no bank_sort_code bank_name
                    rrep_bank_auth_ind fpay_method]
        delete.each { |key| output.delete(key) }

        output
      end

      # Populates and returns the totals calculations by calling the back office.
      # Calls a #request_calc method to produce the request.
      # @param requested_by [User] the user saving the return (ie current_user)
      def calculate_tax(requested_by)
        additional_parameters = { PartyRef: requested_by.party_refno, Username: requested_by.username }

        call_ok?(:slft_calc, additional_parameters.merge!(request_calc)) do |body|
          @total_tax_due = body[:tax_payable][:tax_due]
          @total_credit = body[:tax_payable][:total_credits]
          @tax_payable = body[:tax_payable][:tax_liability]
        end
      end

      # Returns a translation attribute where a given attribute may have more than one name based on e.g. a type
      # it also allows for a different attribute name for the error region for e.g. long labels
      # @param attribute [Symbol] the name of the attribute to translate
      # @param _extra [Object] in this case the party type being processed passed from the page
      # @param error_attribute [Boolean] is the translation being called for the error region
      # @return [Symbol] the name of the translation attribute
      def translation_attribute(attribute, _extra = nil, error_attribute = false)
        return attribute unless %i[declaration].include?(attribute)
        return (attribute.to_s + '_error').to_sym if error_attribute

        attribute
      end

      # @!method self.convert_sites(slft)
      # Convert the sites data (raw hash) into Sites objects
      # @param slft [Hash] the back office data
      # @return [Hash] Sites objects indexed by the site id (aka lasi_refno) or an empty hash
      private_class_method def self.convert_sites(slft)
        output = {}
        ServiceClient.iterate_element(slft[:sites]) do |site_hash|
          site = Site.convert_back_office_hash(site_hash)

          # site ref must be an integer
          output[site.lasi_refno.to_i] = site
        end

        output
      end

      # The back office is supposed to store the yes no _ind attributes we derive them here.
      # Also we've added _yes_no attributes for the UI, derive them here too.
      private_class_method def self.derive_yes_nos_in(slft)
        to_derive = {
          non_disposal_add_ind: :non_disposal_add_text,
          non_disposal_delete_ind: :non_disposal_delete_text
        }

        # sort out the Yes No fields
        derive_yes_nos(slft, to_derive, false)

        # Custom as if amount is nil then flag is not set, otherwise yes or no based on value
        slft[:slcf_yes_no] = derive_yes_no_nil(slft[:slcf_contribution])
        slft[:bad_debt_yes_no] = derive_yes_no_nil(slft[:bad_debt_credit])
        slft[:removal_credit_yes_no] = derive_yes_no_nil(slft[:removal_credit])
      end

      # Uses the payment code to and translates it to the description of the payment
      def payment_description
        lookup_ref_data_value(:fpay_method)
      end

      private

      # Called by @see credit_summary
      # Summary data about the credit data (slcf) in this return
      # @param output [Hash] the hash being build
      # @param prefix [String] the prefix for the translations
      # @return [Hash] of [ attribute => data ]
      def credit_slcf_summary(output, prefix)
        output["#{prefix}.slcf_yes_no"] = lookup_ref_data_value(:slcf_yes_no) if @slcf_yes_no == 'N'
        output["#{prefix}.slcf_contribution"] = "£#{@slcf_contribution}" unless @slcf_contribution.nil?
        output["#{prefix}.slcf_credit_claimed"] = "£#{@slcf_credit_claimed}" unless @slcf_credit_claimed.nil?
        output
      end

      # Called by @see credit_summary
      # Summary data about the credit data (bad_debt) in this return
      # @param output [Hash] the hash being build
      # @param prefix [String] the prefix for the translations
      # @return [Hash] of [ attribute => data ]
      def credit_bad_debt_summary(output, prefix)
        output["#{prefix}.bad_debt_yes_no"] = lookup_ref_data_value(:bad_debt_yes_no) if @bad_debt_yes_no == 'N'
        output["#{prefix}.bad_debt_credit"] = "£#{@bad_debt_credit}" unless @bad_debt_credit.nil?
        output
      end

      # Called by @see credit_summary
      # Summary data about the credit data (removal) in this return
      # @param output [Hash] the hash being build
      # @param prefix [String] the prefix for the translations
      # @return [Hash] of [ attribute => data ]
      def credit_removal_summary(output, prefix)
        output["#{prefix}.removal_credit_yes_no"] = lookup_ref_data_value(:removal_credit_yes_no) if
                                                 @removal_credit_yes_no == 'N'
        output["#{prefix}.removal_credit"] = "£#{@removal_credit}" unless @removal_credit.nil?
        output
      end

      # Called by @see Returns::AbstractReturn#save
      # If @version exists then must be doing an update so use the update webservice, else it's new so use the new one.
      # Raises an error if using the update operation but tare_refno is nil since that should not happen.
      def save_operation
        if @version.blank?
          operation = :slft_tax_return
          @version = '1'
        else
          operation = :slft_update
          raise Error::AppError.new('SLfT save', 'Missing existing ref no') if @tare_refno.nil?
        end

        Rails.logger.debug("Version number is #{@version}, using the #{operation} operation")
        operation
      end

      # Sets bad debt and removal credit to zero if flag is N
      def clean_up_for_save
        @bad_debt_credit = 0 if @bad_debt_yes_no == 'N'
        @removal_credit = 0 if @removal_credit_yes_no == 'N'
        @slcf_contribution = 0 if @slcf_yes_no == 'N'
        @slcf_credit_claimed = 0 if @slcf_yes_no == 'N'
      end

      # Called by @see Returns::AbstractReturn#save
      # @param _requested_by [Object] details for the current user
      # @return a hash suitable for use in a save request to the back office
      def request_save(_requested_by) # rubocop:disable Metrics/MethodLength
        clean_up_for_save

        # NB the order is thought to be important to the back office
        output = {
          SLFTReturnDetails: {
            # have to have '' around symbols as they need to contain ':' characters for output to be correct
            'ins1:Year': @year, 'ins1:FapePeriod': @fape_period, # Fape stands for FL Accounting Period
            'ins1:NDA': {
              'ins1:NonDisposalAddText': @non_disposal_add_text,
              'ins1:NonDisposalDeleteText': @non_disposal_delete_text
            },
            'ins1:Sites': {
              'ins1:Site': sites.values.map(&:request_save) # calls @see Site#reqest_save
            },
            'ins1:CreditClaim': {
              'ins1:SLCFContribution': @slcf_contribution,
              'ins1:SLCFCreditClaimed': @slcf_credit_claimed,
              'ins1:BadDebtCredit': @bad_debt_credit,
              'ins1:RemovalCredit': @removal_credit
            }
          }
        }

        unless @tax_payable.nil?
          output[:SLFTReturnDetails]['ins1:TaxPayable'] = {
            'ins1:TotalTaxDue': @total_tax_due,
            'ins1:TotalCredit': @total_credit,
            'ins1:TaxPayable': @tax_payable,
            'ins1:Declaration': @declaration,
            'ins1:FPAYMethod': @fpay_method
          }
        end

        # add optional repayment details, SLfT only has 1 FrerReason so it's hard coded here
        # also hard coding ClaimType
        if @repayment_yes_no == 'Y'
          output[:ClaimDetails] = {
            'ins1:ClaimType': 'PRE12MONTH',
            'ins1:FrerReason': 'CLAIM',
            'ins1:AmountClaimed': @amount_claimed,
            'ins1:AccountHolder': @account_holder,
            'ins1:BankAccountNo': @bank_account_no,
            'ins1:BankSortCode': @bank_sort_code,
            'ins1:BankName': @bank_name
          }
        end

        output[:PrintData] = print_data

        output
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_calc # rubocop:disable Metrics/MethodLength
        clean_up_for_save
        {
          'ins1:SLFTReturnDetails': {
            'ins1:Year': @year, 'ins1:AccountPeriod': @fape_period,
            'ins1:Sites': {
              'ins1:Site': sites.values.map(&:request_calc) # calls @see Site#request_hash
            },
            'ins1:CreditClaim': {
              'ins1:CreditClaimed': @slcf_credit_claimed,
              'ins1:BadDebtClaimedAmount': @bad_debt_credit,
              'ins1:PermanentRemovalClaimedAmount': @removal_credit
            }
          }
        }
      end
    end
  end
end
