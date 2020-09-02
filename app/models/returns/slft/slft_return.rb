# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise SLfT return models
  module Slft
    # Model for the SLfT return
    class SlftReturn < AbstractReturn # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
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

      # Holds items that are internal and not set by the user
      # current user is used for getting the sites do not expose this in the attribute list!
      # deleted sites is used for holding sites that get deleted if they are no longer needed
      # these are temporary and are not saved or really used except for displaying to the user
      attr_accessor :current_user, :deleted_sites

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { year: comp_key('YEAR', 'SYS', 'RSTU'), fape_period: comp_key('PERIOD', 'SYS', 'RSTU'),
          fpay_method: comp_key('PAYMENT TYPE', 'SLFT', 'RSTU'), form_type: comp_key('RETURN_STATUS', 'SYS', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes but which won't be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { non_disposal_add_ind: YESNO_COMP_KEY,
          non_disposal_delete_ind: YESNO_COMP_KEY,
          slcf_yes_no: YESNO_COMP_KEY, bad_debt_yes_no: YESNO_COMP_KEY,
          removal_credit_yes_no: YESNO_COMP_KEY, repayment_yes_no: YESNO_COMP_KEY,
          declaration: YESNO_COMP_KEY, rrep_bank_auth_ind: YESNO_COMP_KEY }
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
      validates :year, :fape_period, presence: true, on: :year
      validates :non_disposal_add_ind, presence: true, on: :non_disposal_add_ind
      validates :non_disposal_add_text, presence: true, length: { maximum: 4000 }, on: :non_disposal_add_ind,
                                        if: :non_disposal_add_text_needed?
      validates :non_disposal_delete_ind, presence: true, on: :non_disposal_delete_ind
      validates :non_disposal_delete_text, presence: true, length: { maximum: 4000 }, on: :non_disposal_delete_ind,
                                           if: :non_disposal_delete_text_needed?

      # credit claimed validation
      validates :slcf_yes_no, presence: true, on: :slcf_yes_no
      validates :slcf_contribution, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                    allow_blank: true }, presence: true,
                                    two_dp_pattern: true, on: :slcf_yes_no, if: :slcf_details_needed?
      validates :slcf_credit_claimed, numericality: { greater_than: 0, less_than_or_equal_to: :credit_claimed_limit,
                                                      allow_blank: true }, presence: true,
                                      two_dp_pattern: true, on: :slcf_yes_no, if: :slcf_details_needed?
      validates :bad_debt_yes_no, presence: true, on: :bad_debt_yes_no
      validates :bad_debt_credit, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                  allow_blank: true }, presence: true,
                                  two_dp_pattern: true, on: :bad_debt_yes_no, if: :bad_debt_credit_details_needed?
      validates :removal_credit_yes_no, presence: true, on: :removal_credit_yes_no
      validates :removal_credit, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                 allow_blank: true }, presence: true,
                                 two_dp_pattern: true, on: :removal_credit_yes_no, if: :removal_credit_details_needed?

      # repayment validation
      validates :repayment_yes_no, presence: true, on: :repayment_yes_no
      validates :amount_claimed, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                 allow_blank: true }, presence: true,
                                 two_dp_pattern: true, on: :repayment_yes_no, if: :repayment_details_needed?
      validates :account_holder, :bank_name, presence: true, length: { maximum: 255 }, on: :account_holder
      validates :bank_account_no, numericality: { only_integer: true, allow_blank: true }, presence: true,
                                  length: { is: 8 }, on: :account_holder
      validates :bank_sort_code, presence: true, bank_sort_code: true, on: :account_holder

      # repayment declaration
      validates :rrep_bank_auth_ind, acceptance: { accept: ['Y'] }, on: :rrep_bank_auth_ind

      # declaration validation
      validates :fpay_method, presence: true, on: :fpay_method
      validates :declaration, acceptance: { accept: ['Y'] }, on: :fpay_method

      # save draft and calculate (submit) buttons validation

      validate :draft_validation, on: %i[draft]

      # Custom initializer that sets up the sites for this return, relies on the current user being set as part of
      # the initialisation
      def initialize(attributes = {})
        super
        setup_sites
      end

      # Custom setter that refreshes the sites when the year is changed
      # note we only do this on the year not the period (even though it is keyed on the period and year)
      # to make sure that we don't refresh twice when both are changed
      def year=(value)
        @year = value
        setup_sites
      end

      # Find a SLFT return by it's reference number and version
      # @param param_id [Hash] The reference number, tare_refno, srv_code and version of the SLFT return to get data.
      # @param requested_by [User] is usually the current_user, who is requesting the data and containing the account id
      def self.find(param_id, requested_by)
        Slft::SlftReturn.abstract_find(:slft_tax_return_details, param_id, requested_by,
                                       :slft_tax_return) do |data|
          Slft::SlftReturn.new_from_fl(data.merge!(current_user: requested_by))
        end
      end

      # The credit limit percentage values that are found from the back office's system parameter, we get them from
      # the back office so that if they have changed their values then we will still be in sync.
      # To prevent it from doing the lookup all the time, we will be setting the global variable to
      # the value of the lookup.
      # @return [Hash] contains the two percentage limit values (in string) for both the env_contrib_cut_off
      #   and liability_cut_off. These percentage limit values are used with the :slcf_credit_claimed attribute.
      def self.slcf_credit_claimed_limits
        if @slcf_credit_claimed_limits.nil?
          reference_hash = ReferenceData::SystemParameter.lookup('COMMON', 'SLFT', 'RSTU', true)

          # If the reference_hash with the key 'ENV_CONTRIB_CUT_OFF' is nil then we'll use the default value that we
          # know, which is the value 90.
          env_contrib_cut_off = reference_hash['ENV_CONTRIB_CUT_OFF']&.value || '90'
          # Similarly with the key 'LIABILITY_CUT_OFF' of reference_hash, the value we know here is 5.6 so that will
          # be the default if we don't find anything from the reference_hash.
          liability_cut_off = reference_hash['LIABILITY_CUT_OFF']&.value || '5.6'
          @slcf_credit_claimed_limits =
            { env_contrib_cut_off: env_contrib_cut_off, liability_cut_off: liability_cut_off }
        end
        @slcf_credit_claimed_limits
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [print_layout_transaction,
         { code: :sites,
           type: :object }, # this is an object so get the section from the objects
         print_layout_credit_claimed,
         print_layout_calculation,
         print_layout_repayment,
         print_layout_declaration]
      end

      # Print data for the receipt
      def print_layout_receipt
        [{ code: :about_transaction, key: :transaction_subtitle, key_scope: %i[returns slft summary],
           divider: true, display_title: true, type: :list,
           list_items: [{ code: :tare_reference, placeholder: '<%TARE_REFERENCE%>' }] }]
      end

      # custom getter to only return the value if visibility rules say it is needed
      def non_disposal_add_text
        @non_disposal_add_text if non_disposal_add_text_needed?
      end

      # custom getter to only return the value if visibility rules say it is needed
      def non_disposal_delete_text
        @non_disposal_delete_text if non_disposal_delete_text_needed?
      end

      # custom getter to only return the value if visibility rules say it is needed
      # In order to handle save and restore to the back office we need to
      # return 0 if the related flag is set to 'N' as opposed to nil
      # @param return_zero [Boolean] return zero if the flag is 'N'
      # @return the value
      def slcf_contribution(return_zero = false)
        return 0 if return_zero && slcf_yes_no == 'N'

        @slcf_contribution if slcf_details_needed?
      end

      # custom getter to only return the value if visibility rules say it is needed
      # In order to handle save and restore to the back office we need to
      # return 0 if the related flag is set to 'N' as opposed to nil
      # @param return_zero [Boolean] return zero if the flag is 'N'
      # @return the value
      def slcf_credit_claimed(return_zero = false)
        return 0 if return_zero && slcf_yes_no == 'N'

        @slcf_credit_claimed if slcf_details_needed?
      end

      # custom getter to only return the value if visibility rules say it is needed
      # In order to handle save and restore to the back office we need to
      # return 0 if the related flag is set to 'N' as opposed to nil
      # @param return_zero [Boolean] return zero if the flag is 'N'
      # @return the value
      def bad_debt_credit(return_zero = false)
        return 0 if return_zero && bad_debt_yes_no == 'N'

        @bad_debt_credit if bad_debt_credit_details_needed?
      end

      # custom getter to only return the value if visibility rules say it is needed
      # In order to handle save and restore to the back office we need to
      # return 0 if the related flag is set to 'N' as opposed to nil
      # @param return_zero [Boolean] return zero if the flag is 'N'
      # @return the value
      def removal_credit(return_zero = false)
        return 0 if return_zero && removal_credit_yes_no == 'N'

        @removal_credit if removal_credit_details_needed?
      end

      # Calculates the limit to the credit claimed based on the contribution
      def credit_claimed_limit
        # Need to convert back to a float for comparison in validation
        percentage = SlftReturn.slcf_credit_claimed_limits[:env_contrib_cut_off].to_f / 100.0

        from_pence((to_pence(slcf_contribution) * percentage)).to_f
      end

      # performs the validation when the user presses save draft
      def draft_validation
        errors.add(:base, :missing_about_the_transaction, link_id: 'add_return_period') if @year.blank?
      end

      # Describe the return
      def to_s
        "tare_reference: #{tare_reference} year: #{year} quarter: #{fape_period}"
      end

      # Export all the sites wastes details as separate CSV files into the supplied parent folder
      # @param parent_folder [String] the folder to put the CSV files into
      def export_site_wastes(parent_folder)
        return if @sites.nil? || @sites.empty?

        @sites.each do |_, site|
          site.export_waste_csv_data tare_reference, parent_folder
        end
      end

      # @!method self.convert_back_office_hash(body)
      # Takes the hash from the back office response and fiddles with it to make it compatible with our models
      # ie so we can pass it to @see FLApplicationRecord#new_from_fl. @see #save.
      # ie this method is like the opposite of @see #request_save.
      # @param body [Hash] the hash from the @see ServiceClient.call_ok? method
      # @return [Hash] the section of the body hash that describes the return converted for use in creating a new model
      def self.convert_back_office_hash(slft)
        output = {}
        # copy some items over to the output
        %i[form_type tare_reference tare_refno version].each { |key| output[key] = slft[key] }

        # move the whole return to the outout
        output.merge!(slft[:slft_return_details])

        # move some items to the root
        %i[nda credit_claim tax_payable].each { |key| move_to_root(output, key) }

        derive_yes_nos_in(output)

        output[:sites] = convert_sites(output)

        # don't want to load the repayment details, throw this lot away
        # also clear any FPAYMethod data as user must re-enter that
        %i[amount_claimed account_holder bank_account_no bank_sort_code bank_name
           rrep_bank_auth_ind fpay_method].each { |key| output.delete(key) }

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
      # @return [Symbol] the name of the translation attribute
      def translation_attribute(attribute, _extra = nil)
        return attribute unless %i[declaration].include?(attribute)

        :SLFT_declaration
      end

      # Returns the extra options to be passed into when doing the translating, so that the values can be passed on
      # to the hint or label.
      # see https://guides.rubyonrails.org/i18n.html#passing-variables-to-translations
      # @return [Hash] the extra options for the translation.
      def translation_variables(attribute, _translation_options = nil)
        if attribute == :slcf_credit_claimed
          percentage_hash = SlftReturn.slcf_credit_claimed_limits
          return { env_contrib_cut_off: percentage_hash[:env_contrib_cut_off],
                   liability_cut_off: percentage_hash[:liability_cut_off] }
        end

        {}
      end

      # Note: As used in print data these need to be public
      # Do we need the non disposal area added text
      def non_disposal_add_text_needed?
        @non_disposal_add_ind == 'Y'
      end

      # Do we need the non disposal area deleted text
      def non_disposal_delete_text_needed?
        @non_disposal_delete_ind == 'Y'
      end

      # Do we need credit details for the SLCF contribution
      def slcf_details_needed?
        @slcf_yes_no == 'Y'
      end

      # Do we need details of the bad debt credit
      def bad_debt_credit_details_needed?
        @bad_debt_yes_no == 'Y'
      end

      # Do we need details of the removal credit
      def removal_credit_details_needed?
        @removal_credit_yes_no == 'Y'
      end

      def repayment_details_needed?
        @repayment_yes_no == 'Y'
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

      private

      # Gets the list of sites for the current user, year and period
      # note that the current user must be set on the model
      # reconciles these sites with the currently defined sites and adds or removes as needed
      def setup_sites
        return unless @last_year != @year || @last_fape_period != @fape_period
        # Don't bother if we won't get any sites
        return if @current_user.blank? || @year.blank? || @fape_period.blank?

        initialise_sites

        sites = {}
        Slft::Site.find(@current_user, @year, @fape_period).each { |site| sites[site.lasi_refno] = site }

        delete_removed_sites(sites)
        add_or_update_sites(sites)

        @last_year = @year
        @last_fape_period = @fape_period

        # if sites.keys list is empty then back office/cache provided invalid data
        Rails.logger.debug("Loading downloaded SLfT sites data #{@sites.keys}")
      end

      # initialises the sites and deleted sites to move the deleted sites back to sites
      def initialise_sites
        @sites ||= {}
        @deleted_sites ||= {}
        @sites.merge!(@deleted_sites)
        @deleted_sites = {} # clear the deleted sites
      end

      # deletes any sites on teh old list if they are not on the new list
      # raised an error for any removed
      # @param sites [Hash] the hash of the new sites
      def delete_removed_sites(sites)
        @sites.delete_if do |k, v|
          if sites.key?(k)
            false # do not delete
          else
            @deleted_sites[k] = v unless v.total_tonnage.zero? # move to deleted sites
            true
          end
        end
      end

      # adds or updates any sites from the new list
      # in practice we take the new list and merge in the old list copying the wastes
      # @param sites [Hash] the hash of the new sites
      def add_or_update_sites(sites)
        return if sites.nil?

        # Merges the old and new sites list copy wastes from the old to the new if they are duplicated
        @sites.merge!(sites) do |_k, o, n|
          o.site_name = n.site_name
          o
        end
      end

      # Called by @see Returns::AbstractReturn#save
      # If tare_refno exists then must be doing an update, otherwise creating a new one
      # We can't use version as that gets set by the portal on save so changes a create into update
      def save_operation
        operation = if @tare_refno.blank?
                      :slft_tax_return
                    else
                      :slft_update
                    end

        Rails.logger.debug(
          "Tare Refno is #{@tare_refno} Version number is #{@version}, using the #{operation} operation"
        )
        operation
      end

      # Called by @see Returns::AbstractReturn#save
      # @param _requested_by [Object] details for the current user
      # @return a hash suitable for use in a save request to the back office
      def request_save(_requested_by) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # NB the order is thought to be important to the back office
        # have to have '' around symbols as they need to contain ':' characters for output to be correct
        output = { SLFTReturnDetails: {
          'ins1:Year': year, 'ins1:FapePeriod': fape_period, # Fape stands for FL Accounting Period
          'ins1:NDA': save_nda_hash,
          'ins1:Sites': { 'ins1:Site': sites.values.map(&:request_save) }, # calls @see Site#request_save
          'ins1:CreditClaim': save_credit_claimed_hash
        } }

        output[:SLFTReturnDetails]['ins1:TaxPayable'] = save_tax_payable_hash unless @tax_payable.nil?

        # add optional repayment details
        output[:ClaimDetails] = save_repayment_hash if repayment_yes_no == 'Y'

        output[:PrintData] = print_data(:print_layout)

        output[:PrintDataReceipt] = print_data(:print_layout_receipt)

        output
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_calc
        {
          'ins1:SLFTReturnDetails': {
            'ins1:Year': year, 'ins1:AccountPeriod': fape_period,
            'ins1:Sites': {
              'ins1:Site': sites.values.map(&:request_calc) # calls @see Site#request_hash
            },
            'ins1:CreditClaim': calc_credit_claimed_hash
          }
        }
      end

      # returns the credit claimed details required for a calc
      def calc_credit_claimed_hash
        {
          'ins1:CreditClaimed': slcf_credit_claimed,
          'ins1:BadDebtClaimedAmount': bad_debt_credit,
          'ins1:PermanentRemovalClaimedAmount': removal_credit
        }
      end

      # returns the NDA details
      def save_nda_hash
        {
          'ins1:NonDisposalAddText': non_disposal_add_text,
          'ins1:NonDisposalDeleteText': non_disposal_delete_text
        }
      end

      # returns the credit claimed details required for a save draft or submit
      def save_credit_claimed_hash
        { # note we specifically return 0 for an N so we can restore on load
          # know the difference between they weren't asked (nil) and they answered no (0)
          'ins1:SLCFContribution': slcf_contribution(true),
          'ins1:SLCFCreditClaimed': slcf_credit_claimed(true),
          'ins1:BadDebtCredit': bad_debt_credit(true),
          'ins1:RemovalCredit': removal_credit(true)
        }
      end

      # returns the bundle tax payable hash for sending to the back office
      def save_tax_payable_hash
        {
          'ins1:TotalTaxDue': total_tax_due,
          'ins1:TotalCredit': total_credit,
          'ins1:TaxPayable': tax_payable,
          'ins1:Declaration': declaration,
          'ins1:FPAYMethod': fpay_method
        }
      end

      # Repayment details, SLfT only has 1 FrerReason so it's hard coded here
      # also hard coding ClaimType
      def save_repayment_hash
        {
          'ins1:ClaimType': 'PRE12MONTH',
          'ins1:FrerReason': 'CLAIM',
          'ins1:AmountClaimed': amount_claimed,
          'ins1:AccountHolder': account_holder,
          'ins1:BankAccountNo': bank_account_no,
          'ins1:BankSortCode': bank_sort_code,
          'ins1:BankName': bank_name
        }
      end

      # Print data for the transaction
      def print_layout_transaction
        { code: :about_transaction, key: :transaction_subtitle, key_scope: %i[returns slft summary],
          divider: true, display_title: true, type: :list,
          list_items: [{ code: :tare_reference, placeholder: '<%TARE_REFERENCE%>' },
                       { code: :version, placeholder: '<%VERSION%>' },
                       { code: :form_type, lookup: true }, { code: :year, lookup: true },
                       { code: :fape_period, lookup: true },
                       { code: :non_disposal_add_ind, lookup: true },
                       { code: :non_disposal_add_text, when: :non_disposal_add_text_needed?, is: [true] },
                       { code: :non_disposal_delete_ind, lookup: true },
                       { code: :non_disposal_delete_text, when: :non_disposal_delete_text_needed?, is: [true] }] }
      end

      # print data for credit claimed region
      def print_layout_credit_claimed
        { code: :credits_claimed, key: :credits_subtitle, key_scope: %i[returns slft summary], # region code and key
          page_break: true, divider: false, display_title: true, type: :list,
          list_items: [{ code: :slcf_yes_no, lookup: true },
                       { code: :slcf_contribution, format: :money, when: :slcf_details_needed?, is: [true] },
                       { code: :slcf_credit_claimed, format: :money, when: :slcf_details_needed?, is: [true] },
                       { code: :bad_debt_yes_no, lookup: true },
                       { code: :bad_debt_credit, format: :money, when: :bad_debt_credit_details_needed?, is: [true] },
                       { code: :removal_credit_yes_no, lookup: true },
                       { code: :removal_credit, format: :money, when: :removal_credit_details_needed?, is: [true] }] }
      end

      # print layout for the calculation details
      def print_layout_calculation
        { code: :calculation, key: :title, key_scope: %i[returns slft declaration_calculation],
          divider: false, display_title: true, type: :list,
          list_items: [{ code: :total_tax_due, format: :money },
                       { code: :total_credit, format: :money },
                       { code: :tax_payable, format: :money }] }
      end

      # Print data for the repayment
      # if the repayment yes no nil/blank they never got asked the question i.e. not an amend
      # we can't use the version as that is set to 1 by the time this is called
      def print_layout_repayment
        return if @repayment_yes_no.blank?

        { code: :repayment, key: :title, key_scope: %i[returns slft declaration_repayment], # region details
          divider: false, display_title: true, type: :list,
          list_items: print_layout_repayment_fields }
      end

      # Print fields data for the repayment
      def print_layout_repayment_fields
        [
          { code: :repayment_yes_no, lookup: true },
          { code: :amount_claimed, format: :money, when: :repayment_details_needed?, is: [true] },
          { code: :account_holder, when: :repayment_details_needed?, is: [true] },
          { code: :bank_sort_code, when: :repayment_details_needed?, is: [true] },
          { code: :bank_account_no, when: :repayment_details_needed?, is: [true] },
          { code: :bank_name, when: :repayment_details_needed?, is: [true] },
          { code: :rrep_bank_auth_ind, lookup: true, when: :repayment_details_needed?, is: [true] }
        ]
      end

      # Layout for the declaration region
      def print_layout_declaration
        { code: :declaration, key: :title, key_scope: %i[returns slft declaration],
          divider: false, display_title: true, type: :list,
          list_items: [{ code: :fpay_method, lookup: true },
                       { code: :declaration, lookup: true }] }
      end
    end
  end
end
