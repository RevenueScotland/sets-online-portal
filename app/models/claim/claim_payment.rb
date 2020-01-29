# frozen_string_literal: true

# Models an All ClaimPayment object
module Claim
  # model for claim payment to check validation
  class ClaimPayment < FLApplicationRecord # rubocop:disable Metrics/ClassLength
    include AccountPersistence
    include PrintData

    # Not included in the list allowed from forms so it can't be posted and changed, ie to prevent data injection.
    attr_accessor :srv_code, :version, :is_public, :current_user, :open_ads_repayment,
                  :ads_address_postcode, :flbt_type, :submitted_date, :filing_date

    # Attributes for this class, in list so can re-use as permitted params list in the controller
    def self.attribute_list
      %i[reason claim_desc date_of_sale further_claim_info org_name claiming_amount slft_claim_amount email_address
         surname firstname nino telephone address account_holder_name account_number branch_code bank_name
         taxpayer confirmation_of_payment tax_address s_tax_address account_type additional_tax_payer
         s_email_address s_firstname s_surname s_telephone s_nino s_org_name upload_evidence more_uploads
         payment_date case_reference repayment_ref_no attachment
         view_claim_pdf postcode upload_attachment document tare_reference claimant_info agent_address
         agent_email_address agent_firstname agent_surname agent_telephone agent_dx_number agent_org_name
         is_pre_claim declaration_public declaration second_taxpayer_info]
    end

    attribute_list.each { |attr| attr_accessor attr }

    validates :reason, presence: true, on: :reason
    validates :claim_desc, presence: true, on: :claim_desc, if: :claim_desc_required?
    validates :date_of_sale, presence: true, custom_date: true, on: :date_of_sale
    validates :further_claim_info, presence: true, on: :further_claim_info
    validates :claiming_amount, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                allow_blank: true }, presence: true,
                                two_dp_pattern: true, on: :claiming_amount
    validates :firstname, :surname, presence: true, on: :firstname
    validates :telephone, presence: true, phone_number: true, on: :telephone
    validates :email_address, presence: true, email_address: true, on: :email_address

    validates :nino, nino: true, on: :nino
    validates :account_holder_name, :bank_name, presence: true, length: { maximum: 255 }, on: :account_holder_name
    validates :account_number, numericality: { only_integer: true, allow_blank: true }, presence: true,
                               length: { is: 8 }, on: :account_holder_name
    validates :branch_code, presence: true, bank_sort_code: true, on: :account_holder_name
    # Note validation context @see ClaimPaymentsController#declaration
    validates :declaration_public, :declaration, acceptance: { accept: ['true'] }, on: :declaration
    validates :s_firstname, :s_surname, presence: true, on: :s_firstname
    validates :s_telephone, presence: true, phone_number: true, on: :s_telephone
    validates :s_email_address, presence: true, email_address: true, on: :s_email_address
    validates :s_nino, nino: true, on: :s_nino
    validates :more_uploads, presence: true, on: :more_uploads
    validates :tare_reference, presence: true, reference_number: true, on: :tare_reference
    validates :agent_firstname, :agent_surname, presence: true, on: :agent_firstname
    validates :agent_telephone, presence: true, phone_number: true, on: :agent_telephone
    validates :agent_email_address, presence: true, email_address: true, on: :agent_email_address
    validates :agent_dx_number, length: { maximum: 200 }, on: :agent_dx_number

    validate :validate_postcode_matches, on: :postcode_matches
    validate :validate_return_reference, on: :tare_reference
    validate :validate_reason, on: :reason

    # Layout to print the data in this model
    # This defines the sections that are to be printed and the content and layout of those sections
    def print_layout
      [print_layout_header,
       print_layout_ads_date_of_sale, print_layout_ads_main_address, print_layout_ads_further_claim_info,
       print_layout_claiming_amount,
       print_layout_claimant_info,
       print_layout_agent_details, print_layout_agent_address,
       print_layout_taxpayer_details, print_layout_taxpayer_address, print_layout_additional_tax_payer,
       print_layout_additional_taxpayer_details, print_layout_additional_taxpayer_address,
       print_layout_bank_details,
       print_layout_taxpayer_declarations]
    end

    # Define the ref data codes associated with the attributes not to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def cached_ref_data_codes
      # identifies which type of return it is and loads the radio button descriptions
      # eg:  CLAIMREASONS.LBTT.RSTU
      { reason: comp_key('CLAIMREASONS', @srv_code, 'RSTU') }
    end

    # Define the ref data codes associated with the attributes not to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def uncached_ref_data_codes
      { further_claim_info: comp_key('YESNO', 'SYS', 'RSTU'), additional_tax_payer: comp_key('YESNO', 'SYS', 'RSTU'),
        more_uploads: comp_key('YESNO', 'SYS', 'RSTU'), claimant_info: comp_key('YESNO', 'SYS', 'RSTU') }
    end

    # Returns the array of reasons valid for this claim
    # This is the full list for a conveyance or the list without ADS
    def reason_list
      if flbt_type == 'CONVEY'
        list_ref_data(:reason)
      else
        list_ref_data(:reason).delete_if { |r| r.code =~ /ADS.*/ }
      end
    end

    # Validates that the reason chosen is valid
    def validate_reason
      errors.add(:reason, :open_ads_repayment) if open_ads_repayment && @reason =~ /ADS.*/
    end

    # Is the claim description required, which is when the reason is other
    def claim_desc_required?
      return true if @reason == 'OTHER'

      false
    end

    # validate the postcode from property and Ads from claim are same or not
    def validate_postcode_matches
      errors.add(:base, :unmatched_postcode, link_id: :change_postcode) unless
       ads_address_postcode.blank? || address.postcode == ads_address_postcode
    end

    # calls back office and returns hash which is used to validate postcode on Main_residence_address
    def validate_return_reference
      # if we don't have the service then the return reference can't exist or we weren't called correctly from the
      # dashboard page
      errors.add(:tare_reference, :return_does_not_exist) if @srv_code.blank?
      # for pre claims validate that it is a conveyance return
      errors.add(:tare_reference, :pre_claim_not_conveyance) if @flbt_type != 'CONVEY' && pre_claim?
      # for pre claims validate that ADS is allowed based on open ads repayment
      errors.add(:tare_reference, :open_ads_repayment) if open_ads_repayment && pre_claim?
    end

    # Custom setter to get the information on the back office when the reference is set
    def tare_reference=(value)
      @tare_reference = value
      # We only call validate reference for LBTT or if we don't have a service set from the dashboard page
      return unless @srv_code.nil? || @srv_code == 'LBTT'

      # Get the other info from the back office for LBTT
      call_ok?(:validate_return_reference, request_validate_element(@current_user)) do |response|
        if response.blank?
          clear_back_office_data
        else
          assign_back_office_data(response)
        end
      end
    end

    # store individual document to back office
    def add_claim_attachment(document)
      doc_refno = ''
      success = call_ok?(:add_document, request_add_attachment(document)) do |response|
        break if response.blank?

        doc_refno = response[:doc_refno]
      end
      [success, doc_refno]
    end

    # saving data came from back office in response of validate_return_reference service
    def clear_back_office_data
      @flbt_type = nil
      @ads_address_postcode = nil
      @srv_code = nil
      @version = nil
      @submitted_date = nil
      @filing_date = nil
      @open_ads_repayment = nil
      @reason = nil
    end

    # saving data came from back office in response of validate_return_reference service
    def assign_back_office_data(response)
      @flbt_type = response[:flbt_type]
      @ads_address_postcode = response[:ads_address_postcode]
      @srv_code = response[:service_code]
      @version = response[:tare_version]
      @submitted_date = response[:submitted_date]
      @filing_date = response[:filing_date]
      @open_ads_repayment = (response[:open_ads_repayment_indicator] == 'Y')
      @reason = 'ADS' if pre_claim?
    end

    # Is this claim within 12 months of the filed date
    def pre_claim?
      return false if filing_date.blank?

      filing_days_old = (Date.today - filing_date).to_i.days
      # If the filing date is 365 days old or older then true (used for showing the claim)
      (filing_days_old <= Rails.configuration.x.returns.amendable_days)
    end

    # @return a hash suitable for use in a add attachment to the back office
    def request_add_attachment(document)
      add_attachment_request = request_user_instance
      add_attachment_request.merge!(request_document_create(document))
    end

    # @return a hash suitable for use in all message request
    def request_user_instance
      if @current_user.blank?
        { 'ins1:Authenticated': 'no', 'ins1:ObjectRefno': @case_reference, 'ins1:ObjectType': 'CASE',
          'ins1:DocumentType': 'CLAIMDOC' }
      else
        { 'ins1:ParRefNo': @current_user.party_refno, 'ins1:Username': @current_user.username,
          'ins1:Authenticated': 'yes', 'ins1:ObjectRefno': @case_reference, 'ins1:ObjectType': 'CASE',
          'ins1:DocumentType': 'CLAIMDOC' }
      end
    end

    # @return a hash suitable for use in store document request to the back office
    def request_document_create(document)
      { 'ins1:FileName': document.original_filename,
        'ins1:FileType': document.content_type,
        'ins1:Description': document.description,
        'ins1:BinaryData': Base64.encode64(document.file_data) }
    end

    # @return a hash suitable for use in validateReturnReference request to the back office
    def request_validate_element(current_user)
      if current_user.blank?
        { 'ins1:UnAuthenticated': true, TareReference: @tare_reference, IncludeDrafts: false }
      else
        { Username: current_user.username, ParRefNo:  current_user.party_refno,
          'ins1:UnAuthenticated': false, TareReference: @tare_reference, IncludeDrafts: false }
      end
    end

    # delete document from backoffice
    # @param doc_refno [String] document reference number to be delete from backoffice
    # @return [Boolean] true if document delete successfully from backoffice else false
    def delete_attachment(doc_refno)
      success = call_ok?(:delete_document, request_delete_attachment(doc_refno))
      success
    end

    # @return a hash suitable for use in a delete attachment to the back office
    def request_delete_attachment(doc_refno)
      request_user_instance.merge!('ins1:DocRefNo': doc_refno.to_i)
    end

    # Checks whether a save can be done by checking the validations
    def save(current_user)
      return false unless valid?

      save_claim(current_user)
    end

    # Do the save processing for claim payment
    # calls wsdl to send data given by client to back-office
    def save_claim(current_user)
      success = call_ok?(:claim_repayment_details, request_elements(current_user)) do |body|
        @case_reference = body[:claim_repayment][:case_reference]
        @repayment_ref_no = body[:claim_repayment][:repayment_ref_no]
      end
      success
    end

    # Do the save processing for claim payment
    # calls wsdl to send data given by client to back-office
    def view_claim_pdf
      claim_pdf_response = ''
      success = call_ok?(:view_claim_pdf, request_pdf_elements) do |body|
        break if body.blank?

        claim_pdf_response = body
      end

      [success, claim_pdf_response]
    end

    # @return a hash suitable for use in download pdf request to the back office
    def request_pdf_elements
      if @current_user.blank?
        { Authenticated: 'no', 'ins1:RepaymentRefNo': @repayment_ref_no }
      else
        { ParRefNo: @current_user.party_refno, Username: @current_user.username, Authenticated: 'yes',
          'ins1:RepaymentRefNo': @repayment_ref_no }
      end
    end

    # @return [Hash] elements used to specify what data we want to get from the back office
    def request_elements(current_user)
      if current_user.blank?
        { 'ins1:Authenticated': 'no' }.merge!(request_save(current_user))
      else
        { 'ins1:ParRefNo': current_user.party_refno,
          Username: current_user.username }.merge!(request_save(current_user))
      end
    end

    # @return [Hash] elements used to specify what data we want to send to the back office
    def request_save_elements
      output = { ClaimType: pre_claim? ? 'PRE' : 'POST',
                 TareReference: @tare_reference,
                 Version: @version,
                 ServiceCode: @srv_code,
                 ClaimReasonCode: @reason,
                 RepayAmountClaimed: @claiming_amount }
      output[:OtherClaimReasonDescription] = @claim_desc if @reason == 'OTHER'
      output.merge!(request_save_bank_details)

      output
    end

    # @return [Hash] elements used to specify what data we want to send to the back office
    def request_save_bank_details
      output = { RepayAccountHolder: @account_holder_name,
                 RepayBankAccountNo: @account_number,
                 RepayBankSortCode: @branch_code,
                 RepayBankName: @bank_name }
      output
    end

    # @return [Hash] elements used to specify what data we want to send to the back office
    def request_save_ads_element
      output = { ADSSoldDate: DateFormatting.to_xml_date_format(@date_of_sale) }
      output[:ADSFamilyInd] = convert_to_backoffice_yes_no_value(@further_claim_info)

      output
    end

    # @return [Hash] elements used to specify what data we want to send to the back office
    def request_save(current_user)
      output = {}

      output.merge!(request_save_elements)

      # address- LBTT for ADS main Address
      if @reason == 'ADS'
        output[:ADSSoldAddress] = @address.format_to_back_office_address
        output.merge!(request_save_ads_element)
      end

      output[:PrintData] = print_data(:print_layout, account_type: User.account_type(current_user))
      output[:Document] = request_document_create(@upload_attachment) unless @upload_attachment.blank?

      output.merge!(party_details)

      output
    end

    # returns hash which contains party details eg. taxpayer/agent/second Taxpayer
    def party_details
      output = { 'Agent': agent_details,
                 'TaxPayer': taxpayer_details,
                 'SecondTaxPayer': second_taxpayer_details }
      output
    end

    # @return [hash] of tax payer
    def taxpayer_details
      output = { 'ins1:TaxPayerType': (@org_name.blank? ? 'Individual' : 'Organisation'),
                 'ins1:FlptType': 'BUYER' }
      output['ins1:ContactAddress'] = @tax_address.format_to_back_office_address unless @tax_address.blank?
      output.merge!('ins1:ContactTelNo': @telephone,
                    'ins1:ContactEmailAddress': @email_address,
                    'ins1:ParPerNiNo': @nino)
      output.merge!(taxpayer_more_details)
      output if @srv_code == 'LBTT'
    end

    # taxpayer_more_details decides if individual party or organizational party
    def taxpayer_more_details
      return { 'ins1:Individual': taxpayer_individual_details } if @org_name.blank?

      { 'ins1:OrganisationContact': taxpayer_org_details }
    end

    # taxpayer details if individual party
    def taxpayer_individual_details
      { 'ins1:ForeName': @firstname, 'ins1:Surname': @surname }
    end

    # taxpayer details if organization party
    def taxpayer_org_details
      { 'ins1:CompanyName': @org_name, 'ins1:ContactName': @firstname + '' + @surname }
    end

    # @return [hash] of second tax payer if additional taxpayer added if field
    def second_taxpayer_details
      output = { 'ins1:TaxPayerType': (@s_org_name.blank? ? 'Individual' : 'Organisation'),
                 'ins1:FlptType': 'BUYER' }
      output['ins1:ContactAddress'] = @s_tax_address.format_to_back_office_address unless @s_tax_address.blank?
      output.merge!('ins1:ContactTelNo': @s_telephone,
                    'ins1:ContactEmailAddress': @s_email_address,
                    'ins1:ParPerNiNo': @s_nino)
      output.merge!(second_taxpayer_more_details)
      output if @additional_tax_payer == 'Y'
    end

    # second_taxpayer_more_details decides if individual party or organizational party
    def second_taxpayer_more_details
      return { 'ins1:Individual': second_taxpayer_individual_details } if @s_org_name.blank?

      { 'ins1:OrganisationContact': second_taxpayer_org_details }
    end

    # second taxpayer details if individual party
    def second_taxpayer_individual_details
      { 'ins1:ForeName': @s_firstname, 'ins1:Surname': @s_surname }
    end

    # second taxpayer details if organization party
    def second_taxpayer_org_details
      { 'ins1:CompanyName': @s_org_name, 'ins1:ContactName': @s_firstname + '' + @s_surname }
    end

    # @return [hash] of agent for unauthorized user if agent if field
    def agent_details
      output = { 'ins1:AgentType': (@agent_org_name.blank? ? 'Individual' : 'Organisation'),
                 'ins1:FlptType': 'BUYER' }
      output['ins1:ContactAddress'] = @agent_address.format_to_back_office_address unless @agent_address.blank?
      output.merge!('ins1:ContactTelNo': @agent_telephone,
                    'ins1:ContactEmailAddress': @agent_email_address,
                    'ins1:DXNumber': @agent_dx_number)
      output.merge!(agent_more_details)
      output if @is_public == true && @claimant_info == 'N'
    end

    # agent_more_details decides if individual party or organizational party
    def agent_more_details
      return { 'ins1:Individual': agent_individual_details } if @agent_org_name.blank?

      { 'ins1:OrganisationContact': agent_org_details }
    end

    # second taxpayer details if individual party
    def agent_individual_details
      { 'ins1:ForeName': @agent_firstname, 'ins1:Surname': @agent_surname }
    end

    # second taxpayer details if organization party
    def agent_org_details
      { 'ins1:CompanyName': @agent_org_name, 'ins1:ContactName': @agent_firstname + '' + @agent_surname }
    end

    # Dynamically returns the translation key based on the translation_options provided by the page if it exists
    # or else the flbt_type.
    # @param attribute [Symbol] the name of the attribute to translate
    # @param translation_options [Object] in this case the party type being processed passed from the page
    # @return [Symbol] "attribute_" + extra information to make the translation key
    def translation_attribute(attribute, translation_options = nil)
      return attribute unless %i[declaration_public declaration].include?(attribute)

      suffix = if translation_options == 'PUBLIC'
                 public_suffix
               elsif !translation_options.nil?
                 translation_options
               end
      return attribute if suffix.nil?

      "#{attribute}_#{suffix}".to_sym
    end

    # public_suffix will return the account type party type being processed passed is nil
    def public_suffix
      suffix = if @claimant_info == 'Y'
                 'TAXPAYER'
               elsif @claimant_info == 'N'
                 'AGENT'
               end
      suffix
    end

    # layout for the header of the print data
    def print_layout_header
      { code: :claim_reason, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments claim_reason], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :tare_reference },
                     { code: :version },
                     { code: :reason, lookup: true, when: :pre_claim?, is: [false] },
                     { code: :claim_desc, when: :reason, is: ['OTHER'] }] }
    end

    # layout for the ads date of sale
    def print_layout_ads_date_of_sale
      return unless @reason == 'ADS'

      { code: :date_of_sale, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments date_of_sale], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :date_of_sale, format: :date }] }
    end

    # layout for the ads main address
    def print_layout_ads_main_address
      return unless @reason == 'ADS'

      { code: :address, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments main_residence_address], # scope for the title translation
        divider: false, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :object }
    end

    # layout for the ads further claim info page
    def print_layout_ads_further_claim_info
      return unless @reason == 'ADS'

      { code: :further_claim_info, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments further_claim_info], # scope for the title translation
        divider: false, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :further_claim_info, lookup: true }] }
    end

    # layout for the claim amount
    def print_layout_claiming_amount
      { code: :claiming_amount, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments claiming_amount], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :claiming_amount, format: :money }] }
    end

    # layout for the claimant type question
    def print_layout_claimant_info
      return unless is_public

      { code: :claimant_info, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments claimant_info], # scope for the title translation
        divider: false, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :claimant_info, lookup: true }] }
    end

    # layout for the agent details
    def print_layout_agent_details
      return unless @claimant_info == 'N'

      { code: :agent_details, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments agent_info], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: print_layout_agent_details_fields }
    end

    # agent details fields
    def print_layout_agent_details_fields
      [{ code: :agent_org_name },
       { code: :agent_firstname },
       { code: :agent_surname },
       { code: :agent_telephone },
       { code: :agent_email_address },
       { code: :agent_dx_number }]
    end

    # layout for the agent address
    def print_layout_agent_address
      return unless @claimant_info == 'N'

      { code: :agent_address, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments agent_address], # scope for the title translation
        divider: false, # should we have a section divider
        display_title: false, # Is the title to be displayed
        type: :object }
    end

    # layout for the taxpayer details
    def print_layout_taxpayer_details
      return unless @srv_code == 'LBTT'

      { code: :taxpayer_details, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments taxpayer_details], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: print_layout_taxpayer_details_fields }
    end

    # fields for the taxpayer details
    def print_layout_taxpayer_details_fields
      [{ code: :org_name, when: :reason, is_not: ['ADS'] },
       { code: :firstname },
       { code: :surname },
       { code: :telephone },
       { code: :email_address },
       { code: :nino }]
    end

    # layout for the taxpayer address
    def print_layout_taxpayer_address
      return unless @srv_code == 'LBTT'

      { code: :tax_address, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments taxpayer_address], # scope for the title translation
        divider: false, # should we have a section divider
        display_title: false, # Is the title to be displayed
        type: :object }
    end

    # layout for the is there an additional tax payer question
    def print_layout_additional_tax_payer
      return unless @srv_code == 'LBTT'

      { code: :additional_tax_payer, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments additional_tax_payer], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :additional_tax_payer, lookup: true }] }
    end

    # layout for the additional tax payer details
    def print_layout_additional_taxpayer_details
      return unless @additional_tax_payer == 'Y'

      { code: :taxpayer_details, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments second_taxpayer_info], # scope for the title translation
        divider: false, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: print_layout_additional_taxpayer_details_fields }
    end

    # fields for the additional tax payer details
    def print_layout_additional_taxpayer_details_fields
      [{ code: :s_org_name, when: :reason, is_not: ['ADS'] },
       { code: :s_firstname },
       { code: :s_surname },
       { code: :s_telephone },
       { code: :s_email_address },
       { code: :s_nino }]
    end

    # layout for the additional tax payer address
    def print_layout_additional_taxpayer_address
      return unless @additional_tax_payer == 'Y'

      { code: :s_tax_address, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments second_tax_payer], # scope for the title translation
        divider: false, # should we have a section divider
        display_title: false, # Is the title to be displayed
        type: :object }
    end

    # layout for the bank details
    def print_layout_bank_details
      { code: :bank_details, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments claim_payment_bank_details], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :account_holder_name },
                     { code: :account_number },
                     { code: :branch_code },
                     { code: :bank_name }] }
    end

    # layout for the declarations
    def print_layout_taxpayer_declarations
      { code: :taxpayer_declaration, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments taxpayer_declaration], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        when: :is_public,
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :declaration_public, boolean_lookup: true, translation_extra: :account_type },
                     { code: :declaration, boolean_lookup: true, translation_extra: :account_type }] }
    end
  end
end
