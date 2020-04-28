# frozen_string_literal: true

# Models an All ClaimPayment object
module Claim
  # model for claim payment to check validation
  class ClaimPayment < FLApplicationRecord # rubocop:disable Metrics/ClassLength
    include AccountPersistence
    include PrintData

    # Not included in the list allowed from forms so it can't be posted and changed, ie to prevent data injection.
    attr_accessor :srv_code, :version, :current_user, :ads_included, :ads_amount,
                  :flbt_type, :submitted_date, :filing_date, :number_of_buyers

    # Attributes for this class, in list so can re-use as permitted params list in the controller
    def self.attribute_list
      %i[repayment_ref_no eligibility_checkers tare_reference case_reference
         reason claim_desc address date_of_sale
         evidence_files full_repayment_of_ads claiming_amount taxpayers
         account_holder_name account_number branch_code bank_name
         authenticated_declaration_1 authenticated_declaration_2 unauthenticated_declarations]
    end

    attribute_list.each { |attr| attr_accessor attr }

    validates :reason, presence: true, on: :reason
    validates :claim_desc, presence: true, on: :claim_desc, if: :claim_desc_required?
    validates :date_of_sale, presence: true, custom_date: true, on: :date_of_sale
    validates :full_repayment_of_ads, presence: true, on: :full_repayment_of_ads
    validates :claiming_amount, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                allow_blank: true }, presence: true,
                                two_dp_pattern: true, on: :claiming_amount, if: :claim_amount_required?
    validates :account_holder_name, :bank_name, presence: true, length: { maximum: 255 }, on: :account_holder_name
    validates :account_number, numericality: { only_integer: true, allow_blank: true }, presence: true,
                               length: { is: 8 }, on: :account_holder_name
    validates :branch_code, presence: true, bank_sort_code: true, on: :account_holder_name
    # Note validation context @see ClaimPaymentsController#authenticated_declaration_2
    validates :authenticated_declaration_1, :authenticated_declaration_2, acceptance: { accept: ['true'] },
                                                                          on: :declaration, unless: :claim_public?
    validates :tare_reference, presence: true, reference_number: true, on: :return_reference

    validate :validate_return_reference, on: :tare_reference
    validate :validate_amount, on: :claiming_amount, if: :ads_included
    validate :validate_unauthenticated_declaration, on: :declaration, if: :claim_public?
    validate :validate_evidence_files, on: :evidence_files
    validate :validate_eligibility_checker, on: :eligibility_checker

    # Layout to print the data in this model
    # This defines the sections that are to be printed and the content and layout of those sections
    def print_layout
      [print_layout_header,
       print_layout_ads_date_of_sale, print_layout_ads_main_address,
       print_layout_non_ads_claiming_amount, print_layout_ads_claiming_amount,
       { code: :taxpayers,
         type: :object },
       print_layout_bank_details,
       print_layout_authenticated_declarations,
       print_layout_unauthenticated_declarations]
    end

    # Define the ref data codes associated with the attributes not to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def cached_ref_data_codes
      # identifies which type of return it is and loads the radio button descriptions
      # eg:  CLAIMREASONS.LBTT.RSTU
      { reason: comp_key('CLAIMREASONS', @srv_code, 'RSTU'),
        eligibility_checker: comp_key('ELIGIBILITY_LIST', 'SYS', 'RSTU') }
    end

    # Define the ref data codes associated with the attributes not to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def uncached_ref_data_codes
      { full_repayment_of_ads: comp_key('YESNO', 'SYS', 'RSTU') }
    end

    # Returns the array of reasons valid for this claim
    # This is the full list for a conveyance or the list without ADS
    def reason_list
      if @ads_included
        list_ref_data(:reason)
      else
        list_ref_data(:reason).delete_if { |r| r.code =~ /ADS.*/ }
      end
    end

    # Validates that the reason chosen is valid
    def validate_amount
      errors.add(:claiming_amount, :ads_amount) if claim_amount_required? && ads_amount.to_i < claiming_amount.to_i
    end

    # Validates that the reason chosen is valid
    def validate_unauthenticated_declaration
      errors.add(:unauthenticated_declarations, :accepted) unless unauthenticated_declarations.all?(&:checked)
    end

    # Validates that the evidence files are attached for ADS claim
    def validate_evidence_files
      errors.add(:evidence_files, :evidence_files_missing_categories) if @evidence_files.size < 2 && @reason == 'ADS'
    end

    # Validates that the reason chosen is valid
    def validate_eligibility_checker
      # there are 4 eligibility checkers which are mandatory to select
      # @eligibility_checkers array contains selected option this arrays 0th element is always nil
      errors.add(:eligibility_checkers, :accepted) unless @eligibility_checkers.length == 5
    end

    # Is the claim description required, which is when the reason is other
    def claim_desc_required?
      @reason == 'OTHER'
    end

    # This routine is being used to determine claim is for UNAUTHENTICATED user or not.
    # If there is a current_user that means that this claim is authenticated, so it is not a public type of claim.
    def claim_public?
      @current_user.nil?
    end

    # Is the claim amount required, which is when the full_repayment_of_ads is 'N'
    def claim_amount_required?
      @full_repayment_of_ads == 'N' || @srv_code == 'SLFT'
    end

    # Builds and returns the ads declarations if not already populated
    # This works because the declarations are cleared on entry to the page
    # otherwise it needs to handle the scenario where the names may change
    # @return [Array] the list of declarations to check
    def unauthenticated_declarations
      return if @srv_code == 'SLFT'
      return @unauthenticated_declarations unless @unauthenticated_declarations.nil?

      @unauthenticated_declarations = []
      taxpayers.each_with_index do |t, i|
        value = I18n.t('.claim.claim_payments.final_declaration.UNAUTHENTICATED_claim_declaration', name: t.full_name)
        @unauthenticated_declarations << AdsDeclaration.new(index: i, text: value, checked: false)
      end
      @unauthenticated_declarations
    end

    # Sets the declarations that have been checked
    # The value passed from the page is the actual indexes that have been set
    # @param value [Array] The indexes of the set declarations
    def unauthenticated_declarations=(value)
      # Make sure we have unauthenticated_declarations set up as
      # the initial set up is not necessarily saved in the cache
      unauthenticated_declarations

      return if value.nil?

      value.each do |d|
        @unauthenticated_declarations[d.to_i].checked = true unless d.blank?
      end
    end

    # calls back office and returns hash which is used to validate postcode on Main_residence_address
    def validate_return_reference
      return if errors.any?

      # if we don't have the service then the return reference can't exist or we weren't called correctly from the
      # dashboard page
      return errors.add(:tare_reference, :return_does_not_exist) if @srv_code.blank?

      # Check RS no. belongs to a conveyancing return with ADS
      return errors.add(:tare_reference, :not_ads_return_reference) if @ads_included == false || @flbt_type != 'CONVEY'
    end

    # Custom setter to get the information on the back office when the reference is set
    def tare_reference=(value)
      @tare_reference = value
      # We only call validate reference for LBTT or if we don't have a service set from the dashboard page
      if @srv_code.nil? || @srv_code == 'LBTT'
        # Get the other info from the back office for LBTT
        if valid?(:return_reference)
          call_ok?(:validate_return_reference, request_validate_element(@current_user)) do |response|
            response.blank? ? clear_back_office_data : assign_back_office_data(response)
          end
        end
      end
      @number_of_buyers = 1 if @number_of_buyers.nil?
      taxpayers_object(@number_of_buyers)
    end

    # initialize taxpayers array and create an party objects for multiple buyers or taxpayers
    def taxpayers_object(number_of_buyers)
      @taxpayers = Array.new(number_of_buyers) { Returns::Lbtt::Party.new(party_type: 'CLAIMANT') }
    end

    # store individual document to back office
    def add_additional_document(additional_document)
      doc_refno = ''
      success = call_ok?(:add_document, request_add_additional_document_elements(additional_document)) do |response|
        break if response.blank?

        doc_refno = response[:doc_refno]
      end
      [success, doc_refno]
    end

    # saving data came from back office in response of validate_return_reference service
    def clear_back_office_data
      @flbt_type = nil
      @srv_code = nil
      @version = nil
      @submitted_date = nil
      @filing_date = nil
      @reason = nil
      @ads_included = nil
      @ads_amount = nil
      @number_of_buyers = nil
    end

    # saving data came from back office in response of validate_return_reference service
    def assign_back_office_data(response)
      @flbt_type = response[:flbt_type]
      @srv_code = response[:service_code]
      @version = response[:tare_version]
      @submitted_date = response[:submitted_date]
      @filing_date = response[:filing_date]
      @reason = 'ADS' if pre_claim? || (response[:ads_included] == 'Y')
      @number_of_buyers = response[:no_of_buyers].to_i
      assign_ads_back_office_data(response)
    end

    # saving data came from back office in response of validate_return_reference service of ads
    def assign_ads_back_office_data(response)
      @ads_included = (response[:ads_included] == 'Y')
      @ads_amount = response[:ads_amount]
      @full_repayment_of_ads = 'N' if @reason != 'ADS'
    end

    # Is this claim within 12 months of the filed date
    def pre_claim?
      return false if filing_date.blank?

      filing_days_old = (Date.today - filing_date).to_i.days

      # If the filing date is 365 days old or older then true (used for showing the claim)
      (filing_days_old <= Rails.configuration.x.returns.amendable_days)
    end

    # Is date_of_sale More than 12 months of the filed date
    def post_date_of_sale?
      return false if date_of_sale.blank? || filing_date.blank?

      date_of_sale_days_old = (Date.parse(date_of_sale) - filing_date).to_i.days
      # If the date_of_sale is 365 days old or older then true (used for evidence page)
      (date_of_sale_days_old > Rails.configuration.x.returns.amendable_days)
    end

    # @return a hash suitable for use in a add additional_document to the back office
    def request_add_additional_document_elements(additional_document)
      add_attachment_request = request_user_instance
      add_attachment_request.merge!(request_document_create(additional_document))
    end

    # @return a hash suitable for use in all message request
    def request_user_instance
      if claim_public?
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

    # delete additional document from back-office
    # @param doc_refno [String] additional document reference number to be delete from back-office
    # @return [Boolean] true if additional document delete successfully from back-office else false
    def delete_additional_document(doc_refno)
      success = call_ok?(:delete_document, request_delete_additional_document_elements(doc_refno))
      success
    end

    # @return a hash suitable for use in a delete additional document to the back office
    def request_delete_additional_document_elements(doc_refno)
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
        # This submitted_date is used only for display purpose of confirmation page
        # and is not being submitted to the back office
        @submitted_date = Date.today
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
      if claim_public?
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
      output[:RepayAmountClaimed] = @ads_amount if @full_repayment_of_ads == 'Y'
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
    def request_save(current_user)
      output = {}
      output.merge!(request_save_elements)
      # address- LBTT for ADS main Address
      output.merge!(save_ads_elements) if @reason == 'ADS'

      output.merge!(print_data_element(current_user))

      output[:TaxPayer] = taxpayer_details(@taxpayers[0])

      output.merge!(additional_taxpayers_elements)

      output.merge!(save_evidence_files_elements) unless evidence_files.nil?

      output
    end

    # @return [Hash] elements used to specify the print data element that we want to save in the back office
    #   for this return.
    def print_data_element(current_user)
      { PrintData: print_data(:print_layout, account_type: User.account_type(current_user),
                                             translation_prefix: translation_prefix,
                                             translation_pdf_prefix: translation_prefix(:pdf_party_title)) }
    end

    # @return [Hash] elements used to specify what data we want to send to the back office
    def additional_taxpayers_elements
      additional_taxpayer_arr = taxpayers.drop(1)
      output = { AdditionalTaxPayers: { 'ins1:AdditionalTaxPayer':
        additional_taxpayer_arr.map { |taxpayer| taxpayer_details(taxpayer) } } }

      output
    end

    # @return [Hash] elements used to specify what data we want to send to the back office
    def save_ads_elements
      output = { ADSSoldAddress: @address.format_to_back_office_address,
                 ADSSoldDate: DateFormatting.to_xml_date_format(@date_of_sale) }

      output
    end

    # @return [Hash] elements used to specify what data we want to send to the back office
    def save_evidence_files_elements
      output = { Documents: { 'ins1:Document':
          evidence_files.map { |evidence_file| request_document_create(evidence_file) } } }
      output
    end

    # @return [hash] of additional tax payer address details
    # if taxpayers[x] address is same as taxpayers[0] it returns same address as first taxpayers
    def taxpayer_address(taxpayer)
      current_taxpayer = taxpayer.same_address == 'N' ? taxpayer : taxpayers[0]
      { 'ins1:ContactAddress': current_taxpayer.address.format_to_back_office_address }
    end

    # @return [hash] of taxpayer
    def taxpayer_details(taxpayer)
      output = { 'ins1:TaxPayerType':
         (@reason == 'ADS' || taxpayer.org_name.blank? ? 'Individual' : 'Organisation') }
      output.merge!(taxpayer_address(taxpayer))
      output.merge!('ins1:ContactTelNo': taxpayer.telephone,
                    'ins1:ContactEmailAddress': taxpayer.email_address)
      output.merge!(taxpayer_more_data(taxpayer))
      output if @srv_code == 'LBTT'
    end

    # taxpayer_more_data decides if individual party or organizational party
    def taxpayer_more_data(taxpayer)
      return { 'ins1:Individual': taxpayer_individual_details(taxpayer) } if taxpayer.org_name.blank?

      { 'ins1:OrganisationContact': taxpayer_org_details(taxpayer) }
    end

    # taxpayer details if individual party
    def taxpayer_individual_details(taxpayer)
      { 'ins1:ForeName': taxpayer.firstname, 'ins1:Surname': taxpayer.surname }
    end

    # taxpayer details if organization party
    def taxpayer_org_details(taxpayer)
      { 'ins1:CompanyName': taxpayer.org_name, 'ins1:ContactName': taxpayer.firstname + ' ' + taxpayer.surname }
    end

    # The prefix used as part of the translation key.
    # @param context [Symbol] put :party_title as the context when being used in the view section
    #   as the title part of claim party pages title section.
    #   and put :pdf_party_title as the context when being used in the pdf title part of claim party pages title section
    # @return [String] as a prefix for translation key on basis of claim is AUTHENTICATED or not.
    def translation_prefix(context = :any)
      prefix = claim_public? ? 'UNAUTHENTICATED' : 'AUTHENTICATED'

      # If we only have 1 buyer, then the key used should be for a single buyer only.
      return prefix + '_SINGLE' if @number_of_buyers == 1 && context == :party_title
      return prefix + '_PDF' if context == :pdf_party_title

      prefix
    end

    # Dynamically returns the translation key based on the translation_options provided by the page if it exists
    # or else the flbt_type.
    # @param attribute [Symbol] the name of the attribute to translate
    # @param translation_options [Object] in this case the party type being processed passed from the page
    # @return [Symbol] "attribute_" + extra information to make the translation key
    def translation_attribute(attribute, translation_options = nil)
      return amount_date_translation_attribute(attribute) if %i[claiming_amount date_of_sale
                                                                full_repayment_of_ads].include?(attribute)

      return "#{attribute}_#{translation_options}".to_sym if %i[authenticated_declaration_1
                                                                authenticated_declaration_2].include?(attribute)

      attribute
    end

    # @return [Symbol] attribute extra information to make the translation key
    def amount_date_translation_attribute(attribute)
      attribute = :claiming_amount_non_ads if @reason != 'ADS' && !claim_public? && attribute == :claiming_amount

      "#{translation_prefix}_#{attribute}".to_sym
    end

    # layout for the header of the print data
    def print_layout_header
      { code: :claim_reason, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments claim_reason], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: print_layout_header_list_items }
    end

    # fields for the header
    def print_layout_header_list_items
      [{ code: :tare_reference },
       { code: :case_reference, placeholder: '<%CASE_REFERENCE%>' },
       { code: :version },
       { code: :reason, lookup: true, when: :pre_claim?, is: [false] },
       { code: :claim_desc, when: :reason, is: ['OTHER'] }]
    end

    # layout for the ads date of sale
    def print_layout_ads_date_of_sale
      return unless @reason == 'ADS'

      { code: :date_of_sale, # section code
        key_value: :translation_prefix,
        key: '#key_value#_title',
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
        key_value: :translation_prefix,
        key: '#key_value#_title',
        key_scope: %i[claim claim_payments main_residence_address], # scope for the title translation
        divider: false, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :object }
    end

    # layout for the claim amount
    def print_layout_non_ads_claiming_amount
      return unless @reason == 'ADS'

      { code: :claiming_amount, # section code
        key: :claiming_amount_title, # key for the title translation
        key_scope: %i[claim claim_payments claiming_amount], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :full_repayment_of_ads, lookup: true },
                     { code: :claiming_amount, format: :money }] }
    end

    # layout for the claim amount
    def print_layout_ads_claiming_amount
      return unless @reason != 'ADS'

      { code: :claiming_amount, # section code
        key: :non_ads_claiming_amount_title, # key for the title translation
        key_scope: %i[claim claim_payments claiming_amount], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :claiming_amount, format: :money }] }
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

    # layout for the authenticated declarations
    def print_layout_authenticated_declarations
      return nil if claim_public?

      { code: :declarations, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments final_declaration], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :list, # type list = the list of attributes to follow
        list_items: [{ code: :authenticated_declaration_1, boolean_lookup: true, translation_extra: :account_type },
                     { code: :authenticated_declaration_2, boolean_lookup: true, translation_extra: :account_type }] }
    end

    # layout for the unauthenticated (ads) declarations
    def print_layout_unauthenticated_declarations
      return nil unless claim_public?

      { code: :unauthenticated_declarations, # section code
        key: :title, # key for the title translation
        key_scope: %i[claim claim_payments final_declaration], # scope for the title translation
        divider: true, # should we have a section divider
        display_title: true, # Is the title to be displayed
        type: :object }
    end
  end
end
