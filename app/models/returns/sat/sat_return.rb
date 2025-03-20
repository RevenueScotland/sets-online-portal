# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise SAT return models
  module Sat
    # Model for the SAT return
    class SatReturn < AbstractReturn # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
      include CsvHelper
      include Sat::SiteCsvImporting

      validates_with SatReturnValidator, on: :calc_return
      validates_with SatReturnValidator, on: :submit

      # Attributes for this class, in list so can re-use as permitted params list in the controller.
      def self.attribute_list
        %i[trs_refno period_start period_end sat_period sites fpay_method total_tax_due total_credit tax_payable
           tax_payable_raw declaration submitted_date effective_date enrm_name change_reason net_tax_payable
           enrm_par_ref bad_debt repayment_ind claiming_amount account_holder_name account_number branch_code
           bank_name claim_declaration csv_taxable_data]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # Not including in the attribute_list so it can't be posted on every sat form, ie to prevent data injection
      # Holds items that are internal and not set by the user
      attr_accessor :selected_return_period, :portal_object_type

      # validations
      validates :sat_period, presence: true, on: :sat_period

      # submit page
      validates :fpay_method, presence: true, on: :fpay_method
      validates :declaration, acceptance: { accept: ['Y'] }, on: :fpay_method
      validates :claim_declaration, acceptance: { accept: ['Y'] }, on: :claim_declaration, if: :claim_repayment?

      validates :change_reason, presence: true, length: { maximum: 500 }, on: :change_reason, if: :amendment?

      validates :repayment_ind, presence: true, on: :repayment_ind, if: :show_repayment?
      validates :claiming_amount, numericality: { greater_than_or_equal_to: 0,
                                                  less_than: 1_000_000_000_000_000_000,
                                                  allow_blank: true },
                                  two_dp_pattern: true, presence: true, on: :claiming_amount, if: :claim_repayment?
      validates :account_holder_name, presence: true, on: :account_holder_name, if: :claim_repayment?
      validates :account_number, presence: true, on: :account_number, account_number: true, if: :claim_repayment?
      validates :branch_code, presence: true, on: :branch_code, bank_sort_code: true, if: :claim_repayment?
      validates :bank_name, presence: true, on: :bank_name, if: :claim_repayment?

      # Checks to see if an amendment and if the user has an active direct debit instruction
      # and if they did not pay via direct debit then show the warning
      # returns true else false
      def show_amend_dd_warning?
        return false unless amendment? && enrolment_has_dd_instruction? && fpay_method != 'DDEBIT'

        true
      end

      # For a repayment then for SAT the return the tax payable needs to be below 0
      def show_repayment?
        return true if @tax_payable_raw.negative?

        false
      end

      # If repayment was selected then the claim repayment amount should also be provided
      def claim_repayment?
        return true if repayment_ind == 'Y'

        false
      end

      # Total taxable tonnage for the sites shown on the summary page
      def net_taxable_tonnage
        total = 0
        sites.each_value do |site|
          total += site.taxable_tonnage
        end
        format_tonnage_value(total.to_s)
      end

      # Total exempt tonnage for the sites shown on the summary page
      def net_exempt_tonnage
        total = 0
        sites.each_value do |site|
          total += site.exempt_tonnage
        end
        format_tonnage_value(total.to_s)
      end

      # Total tax due for the sites shown on the summary page
      def net_tax_due
        total = 0
        sites.each_value do |site|
          total += site.total_tax_due
        end
        total
      end

      # Total tax credits for the sites shown on the summary page
      def net_tax_credits
        total = 0
        sites.each_value do |site|
          total += site.tax_credits
        end
        total
      end

      # Total tax payable for the sites shown on the summary page
      def net_tax_payable
        total = 0
        sites.each_value do |site|
          total += site.tax_payable
        end
        total
      end

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { fpay_method: comp_key('PAYMENT TYPE', 'SAT', 'RSTU'),
          form_type: comp_key('RETURN_STATUS', 'SYS', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes not to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { declaration: YESNO_COMP_KEY, repayment_ind: YESNO_COMP_KEY, claim_declaration: YESNO_COMP_KEY }
      end

      # Custom initializer that sets up the sites for this return, relies on the current user being set as part of
      # the initialisation
      def initialize(attributes = {})
        super
        user_periods(current_user)
      end

      # Override setter so that the when the user changes the period it will load the latest site list.
      # @param value [Object] the index key of the selected date period
      # @return [Object] The back office (sites) data for the selected period
      def sat_period=(value)
        @sat_period = value
        @selected_return_period = @user_periods[value]
      end

      # Find a SAT return by it's reference number and version
      # @param param_id [Hash] The reference number, tare_refno, srv_code and version of the SAT return to get data.
      # @param requested_by [User] is usually the current_user, who is requesting the data and containing the account id
      def self.find(param_id, requested_by)
        Sat::SatReturn.abstract_find(:sat_return_details, param_id, requested_by,
                                     :sat_return) do |data|
          Sat::SatReturn.new_from_fl(data.merge!(current_user: requested_by))
        end
      end

      # converts the selected period index back to a user readable value
      # @return [array] The dates in a user readable value
      def current_return_period
        # Need to format the date to show dd/mm/yy else the date will show as yyyy-mm-dd
        start_date = DateFormatting.to_display_date_format(@selected_return_period.period_start)
        end_date = DateFormatting.to_display_date_format(@selected_return_period.period_end)

        "#{start_date} #{I18n.t('.returns.sat.summary.to')} #{end_date}"
      end

      # formats the sites with the period breakdown to use on the summary page
      def sites
        @selected_return_period.sites
      end

      # performs the validation when the user presses save draft
      def draft_validation
        errors.add(:base, :missing_about_the_transaction, link_id: 'return_period') if @sat_period.blank?
      end

      # gets the return periods and formats it for use in a lov
      # @return [array] The period list indexed
      def user_periods_list
        periods_lov = []
        @user_periods.each_value do |obj|
          start_date = DateFormatting.to_display_date_format(obj.period_start)
          end_date = DateFormatting.to_display_date_format(obj.period_end)
          formatted_date = "#{start_date} #{I18n.t('.returns.sat.summary.to')} #{end_date}"

          periods_lov.push(ReferenceData::ReferenceValue.new(code: obj.trs_refno,
                                                             value: formatted_date))
        end
        periods_lov
      end

      # addition portal object parameters to be passed for calling back office
      # @param requested_by [Hash] the hash from the @see AbstractReturn.abstract_find method
      private_class_method def self.portal_object_request_params(requested_by)
        { 'ins0:EnrmRefno': requested_by.portal_object_reference,
          'ins0:EnrmRegistrationRef': requested_by.portal_object_display_reference }
      end

      # @!method self.convert_back_office_hash(body)
      # Takes the hash from the back office response and fiddles with it to make it compatible with our models
      # ie so we can pass it to @see FLApplicationRecord#new_from_fl. @see #save.
      # ie this method is like the opposite of @see #request_save.
      # @param body [Hash] the hash from the @see ServiceClient.call_ok? method
      # @return [Hash] the section of the body hash that describes the return converted for use in creating a new model
      def self.convert_back_office_hash(sat) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        output = {}
        # copy some items over to the output
        %i[form_type tare_reference tare_refno version fpay_method enrm_par_ref].each { |key| output[key] = sat[key] }

        sat_return = sat[:sat_return_details]

        # strip out attributes we don't want yet
        delete = %i[submitted_date change_reason bad_debt]
        delete.each { |key| sat_return.delete(key) }

        output[:trs_refno] = sat_return.delete(:return_schedule_refno)
        output[:period_start] = sat_return.delete(:return_period_start_date)
        output[:period_end] = sat_return.delete(:return_period_end_date)
        output[:fpay_method] = sat[:tax_payable][:fpay_method] if sat[:tax_payable] && sat[:tax_payable][:fpay_method]
        # move the whole return to the output
        output.merge!(sat_return)

        output[:sites] = convert_taxable_sites(output.delete(:taxable_locations))
        output[:selected_return_period] = convert_return_periods(output)
        output[:bad_debt] = convert_bad_debt_data(sat[:bad_debt])

        output
      end

      # @!method self.convert_bad_debt_data(sat)
      # Convert the bad debt data (raw hash) into bad debt object
      # @return [Hash] Bad debt object
      def self.convert_bad_debt_data(body)
        return ::Returns::Sat::BadDebt.new(bad_debt_present: 'N') if body.nil?

        debt_params = {}
        # Check if bad debt was submitted previously
        # We don't save debt_present field in BO hence using declaration flag
        # RSTS-4342 : Using a backward compatible array of Debt declaration
        valid_bd_decl = [I18n.t('activemodel.attributes.returns/sat/bad_debt.bad_debt_declaration'), 'Y']
        if valid_bd_decl.include? body[:bad_debt_declaration]
          %i[bad_debt_credit_amount bad_debt_details].each { |obj| debt_params[obj] = body[obj] }
          debt_params[:bad_debt_present] = 'Y'
        else
          debt_params[:bad_debt_present] = 'N'
        end
        ::Returns::Sat::BadDebt.new(debt_params)
      end

      # Overwrites the existing site taxable data
      # The data set to the csv_taxable_data is set to respective sites
      # The existing site data is reset before writing the data
      def save_csv_file_data
        # reset existing site data
        sites.each_value do |st|
          st.taxable_aggregates = {}
          st.exempt_aggregates = {}
          st.credit_claims = {}
        end
        # Save taxable data
        csv_taxable_data.each do |record|
          send(:"save_#{record[:type]}_data", record[:site], record[:record])
        end
      end

      # @!method self.convert_taxable_sites(sat)
      # Convert the sites data (raw hash) into Sites objects
      # @param body [Hash] the back office data
      # @return [Hash] Sites objects indexed by the site id
      private_class_method def self.convert_taxable_sites(body)
        output = {}
        ServiceClient.iterate_element(body) do |site_hash|
          site = Sites.convert_back_office_hash(site_hash)

          # site ref must be an integer
          output[SecureRandom.uuid] = site
        end

        output
      end

      # @!method self.convert_return_periods(sat)
      # Convert the return period data (raw hash) into return period objects
      # @return [Hash] Return period objects indexed by the trs refno or an empty hash
      def self.convert_return_periods(body)
        output = {}

        %i[trs_refno period_start period_end sites].each do |key|
          output[key] = body[key]
        end

        ReturnPeriod.new_from_fl(output)
      end

      # @return a hash suitable for use in a calc request to the back office
      def request_calc
        {
          'ins1:SATReturnDetails': {
            'ins1:TaxableLocations': {
              'ins1:TaxableLocation': sites.values.map(&:request_site_calc)
            },
            'ins1:BadDebtCreditAmount': bad_debt&.bad_debt_credit_amount
          }
        }
      end

      # Populates and returns the totals calculations by calling the back office call below.
      # @param body is the data returned from the back office
      def assign_calc_tax_params(body)
        @total_tax_due = NumberFormatting.to_money_format(body[:tax_payable][:tax_due])
        @total_credit = NumberFormatting.to_money_format(body[:tax_payable][:total_credits])
        @tax_payable_raw = body[:tax_payable][:net_tax_payable].to_i
        @tax_payable = NumberFormatting.to_money_format(body[:tax_payable][:net_tax_payable])
      end

      # Populates and returns the totals calculations by calling the back office.
      # Calls a #request_calc method to produce the request.
      # @param requested_by [User] the user saving the return (ie current_user)
      def calculate_tax(requested_by)
        additional_parameters = { ParRefno: requested_by.party_refno, Username: requested_by.username,
                                  EnrmRefno: requested_by.portal_object_reference }
        call_ok?(:sat_calc, additional_parameters.merge!(request_calc)) do |body|
          assign_calc_tax_params(body)
        end
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

      # @return a hash suitable for use in download pdf request to the back office.
      # In case of unauthenticated user, current_user will be blank
      def request_pdf_elements(current_user, return_data, pdf_type)
        if current_user.blank?
          { Authenticated: 'no', TareReference: return_data[:tare_reference], ReturnVersion: return_data[:version],
            RequestType: pdf_type }
        else
          { Authenticated: 'yes', ParRefno: current_user.party_refno, Username: current_user.username,
            TareReference: return_data[:tare_reference], ReturnVersion: return_data[:version], RequestType: pdf_type }
        end
      end

      # Does the enrolment have a dd instruction
      # See controller_helper.account_has_dd_instruction? does the same but for an enrolment party
      # and not the logged in user
      # @return [String] returns true if the enrolment has the service otherwise false
      def enrolment_has_dd_instruction?
        return false if @enrm_par_ref.nil?
        # if already present then don't call the bo again
        return @dd_instruction_available unless @dd_instruction_available.nil?

        message = { PartyRef: @enrm_par_ref, 'ins1:Requestor': @current_user.username }
        call_ok?(:get_party_details, message) do |body|
          @dd_instruction_available = body[:curr_dd_instruction_avail]
        end
        @dd_instruction_available
      end

      private

      # calls the ReturnPeriod model to get the data from the back office
      # @param user [Object] The logged in user
      # @return [array] The bo data indexed
      def user_periods(user)
        # returns the data if the data exists this stops the code from doing another call
        # to the BO when data was pulled back
        return @user_periods unless @user_periods.nil?

        @user_periods = {}
        ReturnPeriod.all(user)&.each do |user_period|
          @user_periods[user_period.trs_refno] = user_period
          @enrm_par_ref = user_period.enrm_par_ref
        end
      end

      # Called by @see Returns::AbstractReturn#save
      # If tare_refno exists then must be doing an update, otherwise creating a new one
      # We can't use version as that gets set by the portal on save so changes a create into update
      def save_operation
        operation = :sat_tax_return

        Rails.logger.debug do
          "Tare Refno is #{@tare_refno} Version number is #{@version}, using the #{operation} operation"
        end
        operation
      end

      # Custom getter for the enrolment reference for the pdf data
      def enrolment_reference
        @current_user.portal_object_display_reference
      end

      # Custom getter for the enrolment reference for the pdf data
      def enrm_name
        @enrm_name ||= @current_user.portal_object_display_name
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :enrolment_details,
           key: :title,
           key_scope: %i[returns sat enrolment_details],
           divider: true,
           display_title: true,
           type: :list,
           list_items: [{ code: :enrolment_reference },
                        { code: :enrm_name }] },
         { code: :return_type,
           key: :title,
           key_scope: %i[returns sat return_type],
           divider: true,
           display_title: true,
           type: :list,
           list_items: [{ code: :tare_reference, placeholder: '<%TARE_REFERENCE%>' },
                        { code: :version, placeholder: '<%VERSION%>' },
                        { code: :current_return_period },
                        { code: :form_type, lookup: true },
                        { code: :submitted_date, placeholder: '<%RECEIPT_DATE%>' }] },
         { code: :sites,
           type: :object },
         { code: :bad_debt,
           type: :object },
         { code: :tax_liability,
           key: :title,
           key_scope: %i[returns sat tax_liability],
           divider: true,
           display_title: true,
           type: :list,
           list_items: [{ code: :net_taxable_tonnage },
                        { code: :net_exempt_tonnage },
                        { code: :total_tax_due, format: :money },
                        { code: :total_credit, format: :money },
                        { code: :tax_payable, format: :money }] },
         { code: :repayment_request,
           key: :title,
           key_scope: %i[returns sat repayment_request],
           divider: true,
           display_title: true,
           when: :claim_repayment?,
           is: [true],
           type: :list,
           list_items: [{ code: :repayment_ind, lookup: true },
                        { code: :claiming_amount, format: :money },
                        { code: :account_holder_name },
                        { code: :account_number },
                        { code: :branch_code },
                        { code: :bank_name },
                        { code: :claim_declaration, lookup: true }] },
         { code: :declaration_calculation,
           key: :title,
           key_scope: %i[returns sat declaration_calculation],
           divider: true,
           display_title: true,
           type: :list,
           list_items: [{ code: :change_reason, when: :amendment?, is: [true] },
                        { code: :fpay_method, lookup: true }] },
         { code: :declaration_submitted,
           key: :title,
           key_scope: %i[returns sat declaration_submitted],
           divider: true,
           display_title: true,
           type: :list,
           list_items: [{ code: :declaration, lookup: true }] }]
      end

      # Print data for the receipt
      def print_layout_receipt
        [{ code: :about_transaction, key: :transaction_subtitle, key_scope: %i[returns sat summary],
           divider: true, display_title: true, type: :list,
           list_items: [{ code: :tare_reference, placeholder: '<%TARE_REFERENCE%>' }] }]
      end

      # Called by @see Returns::AbstractReturn#save
      # @param _requested_by [Object] details for the current user
      # @return a hash suitable for use in a save request to the back office
      def request_save(_requested_by, form_type:) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        # NB the order is thought to be important to the back office
        # have to have '' around symbols as they need to contain ':' characters for output to be correct
        output = { SATReturnDetails: {
          'ins0:EffectiveDate': @effective_date,
          'ins0:SubmittedDate': @submitted_date, 'ins0:ReleventDate': @relevent_date,
          'ins0:ReturnPeriodStartDate': @selected_return_period.period_start,
          'ins0:ReturnPeriodEndDate': @selected_return_period.period_end,
          'ins0:ReturnScheduleRefno': @selected_return_period.trs_refno,
          'ins0:TaxableLocations': { 'ins0:TaxableLocation': sites.values.map(&:request_save) }
        } }

        output[:SATReturnDetails]['ins0:ChangeReason'] = @change_reason if amendment?

        output[:SATReturnDetails]['ins0:TaxPayable'] = save_tax_payable_hash(form_type) unless @tax_payable.nil?

        output[:SATReturnDetails]['ins0:BadDebt'] = bad_debt&.request_save

        output[:SATReturnDetails]['ins0:Repayment'] = save_repayment_hash if claim_repayment?

        # add optional repayment details
        output[:SATReturnDetails]['ins0:AmountAlreadyPaid'] = @amount_paid_ind

        # add optional repayment details
        output[:SATReturnDetails]['ins0:AmountBalance'] = @amount_balance

        # add print data (for PDF)
        output[:'ins0:PrintData'] = print_data(:print_layout)

        # add print data receipt
        output[:'ins0:PrintDataReceipt'] = print_data(:print_layout_receipt)

        output
      end

      # returns the bundle repayments hash for sending to the back office
      def save_repayment_hash
        {
          'ins0:RepaymentInd': repayment_ind,
          'ins0:RepayAccountHolder': account_holder_name,
          'ins0:RepayBankAccountNo': account_number,
          'ins0:RepayBankSortCode': branch_code,
          'ins0:RepaymentBankName': bank_name,
          'ins0:RepayAmountClaimed': claiming_amount
        }
      end

      # returns the bundle tax payable hash for sending to the back office
      # @param form_type [string] D(raft) or L(atest)
      def save_tax_payable_hash(form_type)
        {
          'ins0:NetExemptTonnage': net_exempt_tonnage,
          'ins0:TotalTaxDue': total_tax_due,
          'ins0:TotalCredit': total_credit,
          'ins0:NetTaxPayable': tax_payable,
          # Make sure previous payment method is saved to back office for a draft so we don't lose track of it
          'ins0:FPAYMethod': (form_type == 'D' ? previous_fpay_method : fpay_method)
        }
      end
    end
  end
end
