# frozen_string_literal: true

# Models an All ClaimPayment object
module Claim
  # model for claim payment to check validation
  class ClaimPayment < FLApplicationRecord # rubocop:disable Metrics/ClassLength
    include AccountPersistence
    include CommonValidation
    include PrintData

    # Not included in the list allowed from forms so it can't be posted and changed, ie to prevent data injection.
    attr_accessor :srv_code, :version, :tare_reference

    # Attributes for this class, in list so can re-use as permitted params list in the controller
    def self.attribute_list
      %i[reason claim_desc date_of_sale further_claim_info org_name claiming_amount slft_claim_amount email_address
         surname firstname nino telephone address account_holder_name account_number branch_code bank_name
         taxpayer confirmation_of_payment agent_declaration agent_second_declaration
         tax_address taxpayer_type account_type]
    end

    attribute_list.each { |attr| attr_accessor attr }
    validates :reason, presence: true, on: :reason
    validates :date_of_sale, presence: true, on: :date_of_sale
    validate :date_valid?, on: :date_of_sale
    validates :further_claim_info, presence: true, on: :further_claim_info
    validates :claiming_amount, presence: true, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000 },
                                format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                on: :claiming_amount
    validates :firstname, presence: true, on: :firstname
    validates :surname, presence: true, on: :surname
    validates :telephone, presence: true, on: %i[telephone]
    validate  :phone_format_is_valid?, on: %i[telephone]
    validates :email_address, presence: true, on: %i[email_address]
    validate  :individual_email_address_valid?, on: %i[email_address]
    validates :nino, presence: true, on: :nino
    validate  :nino_valid?, on: %i[nino]
    validates :nino, presence: true, on: :nino
    validates :account_holder_name, presence: true, length: { maximum: 255 }, on: :account_holder_name
    validates :account_number, presence: true,
                               numericality: { only_integer: true }, length: { is: 8 },
                               on: :account_holder_name
    validate :repay_bank_sort_code_valid?, on: :account_holder_name
    validates :bank_name, presence: true, length: { maximum: 255 }, on: :account_holder_name
    validates :taxpayer, acceptance: { accept: ['true'] }, on: :taxpayer,
                         if: proc { |s| s.account_type != 'AGENT' }
    validates :agent_declaration, acceptance: { accept: ['true'] }, on: :agent_declaration,
                                  if: proc { |s| s.account_type == 'AGENT' }
    validates :agent_second_declaration, acceptance: { accept: ['true'] }, on: :agent_second_declaration,
                                         if: proc { |s| s.account_type == 'AGENT' }

    # Layout to print the data in this model
    # This defines the sections that are to be printed and the content and layout of those sections
    def print_layout # rubocop:disable Metrics/MethodLength
      [{ code: :claim_reason, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments payment_after_year], # scope for the title translation
         divider: true, # should we have a section divider
         display_title: true, # Is the title to be displayed
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :tare_reference },
                      { code: :version },
                      { code: :reason, lookup: true },
                      { code: :claim_desc, when: :reason, is: ['OTHER'] }] },
       { code: :date_of_sale, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments date_of_sale], # scope for the title translation
         divider: true, # should we have a section divider
         display_title: true, # Is the title to be displayed
         when: :reason,
         is: ['ADS'],
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :date_of_sale, format: :date }] },
       { code: :address, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments main_residence_address], # scope for the title translation
         divider: false, # should we have a section divider
         display_title: true, # Is the title to be displayed
         when: :reason,
         is: ['ADS'],
         type: :object },
       { code: :further_claim_info, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments further_claim_info], # scope for the title translation
         divider: false, # should we have a section divider
         display_title: true, # Is the title to be displayed
         when: :reason,
         is: ['ADS'],
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :further_claim_info, lookup: true }] },
       { code: :claiming_amount, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments claiming_amount], # scope for the title translation
         divider: true, # should we have a section divider
         display_title: true, # Is the title to be displayed
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :claiming_amount }] },
       { code: :taxpayer_details, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments confirm_individual_details], # scope for the title translation
         divider: false, # should we have a section divider
         display_title: true, # Is the title to be displayed
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :org_name, when: :reason, is_not: ['ADS'] },
                      { code: :firstname },
                      { code: :surname },
                      { code: :telephone },
                      { code: :email_address },
                      { code: :nino }] },
       { code: :tax_address, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments taxpayer_address], # scope for the title translation
         divider: false, # should we have a section divider
         display_title: false, # Is the title to be displayed
         type: :object },
       { code: :bank_details, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments claim_payment_bank_details], # scope for the title translation
         divider: false, # should we have a section divider
         display_title: true, # Is the title to be displayed
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :account_holder_name },
                      { code: :account_number },
                      { code: :branch_code },
                      { code: :bank_name }] },
       { code: :agent_declaration, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments agent_declaration], # scope for the title translation
         divider: false, # should we have a section divider
         display_title: true, # Is the title to be displayed
         when: :account_type,
         is: ['AGENT'],
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :agent_declaration, boolean_lookup: true },
                      { code: :agent_second_declaration, boolean_lookup: true }] },
       { code: :taxpayer_declaration, # section code
         key: :title, # key for the title translation
         key_scope: %i[claim claim_payments agent_declaration], # scope for the title translation
         divider: false, # should we have a section divider
         display_title: true, # Is the title to be displayed
         when: :account_type,
         is_not: ['AGENT'],
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :taxpayer, boolean_lookup: true }] }]
    end

    # Check if telephone number is valid
    def phone_format_is_valid?
      phone_number_format_valid? :telephone
    end

    # Check if email address is valid
    def individual_email_address_valid?
      email_address_valid? :email_address
    end

    # Check if NINO address is valid
    def nino_valid?
      national_insurance_number_valid? :nino
    end

    # Does the validation for date to see if the format is a valid date format
    def date_valid?
      date_format_valid? :date_of_sale
    end

    # Define the ref data codes associated with the attributes not to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def cached_ref_data_codes
      # identifies which type of return it is and loads the radio button descriptions
      # eg:  CLAIMREASONS.LBTT.RSTU
      Rails.logger.debug("Return_type code = #{@srv_code}")
      { reason: "CLAIMREASONS.#{@srv_code}.RSTU" }
    end

    # Define the ref data codes associated with the attributes not to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def uncached_ref_data_codes
      { further_claim_info: 'YESNO.SYS.RSTU' }
    end

    # Do the save processing for claim payment
    # calls wsdl to send data given by client to back-office
    def save_claim(requested_by)
      success = call_ok?(:claim_repayment_details, request_elements(requested_by))
      success
    end

    # @return [Hash] elements used to specify what data we want to get from the back office
    def request_elements(requested_by)
      { 'ins1:ParRefNo': requested_by.party_refno, Username: requested_by.username }.merge!(request_save(requested_by))
    end

    # @return [Hash] elements used to specify what data we want to send to the back office
    def request_save(requested_by) # rubocop:disable Metrics/MethodLength
      output = { ClaimType: 'POST',
                 TareReference: @tare_reference,
                 Version: @version,
                 ServiceCode: @srv_code,
                 ClaimReasonCode: @reason,
                 RepayAmountClaimed: @claiming_amount,
                 RepayAccountHolder: @account_holder_name,
                 RepayBankAccountNo: @account_number,
                 RepayBankSortCode: @branch_code,
                 RepayBankName: @bank_name }

      output[:OtherClaimReasonDescription] = @claim_desc if @reason == 'OTHER'

      # address- LBTT for ADS main Address
      if @reason == 'ADS'
        output[:ADSSoldAddress] = @address.format_to_back_office_address
        output[:ADSSoldDate] = DateFormatting.to_xml_date_format(@date_of_sale)
        output[:ADSFamilyInd] = @further_claim_info == 'Y' ? 'yes' : 'no'
      end
      output[:PrintData] = print_data(account_type: User.account_type(requested_by))
      output[:TaxPayer] = taxpayer_details if @srv_code == 'LBTT'
      output
    end

    def taxpayer_details # rubocop:disable Metrics/MethodLength
      output = { 'ins1:TaxPayerType': (@org_name.blank? ? 'Individual' : 'Organisation'),
                 'ins1:FlptType': 'BUYER' }
      output['ins1:ContactAddress'] = @tax_address.format_to_back_office_address unless @tax_address.blank?
      output.merge!('ins1:ContactTelNo': @telephone,
                    'ins1:ContactEmailAddress': @email_address,
                    'ins1:ParPerNiNo': @nino)
      if @org_name.blank?
        output['ins1:Individual'] = taxpayer_individual_details
      else
        output['ins1:OrganisationContact'] = taxpayer_org_details
      end
      output
    end

    # taxpayer details if individual party
    def taxpayer_individual_details
      { 'ins1:ForeName': @firstname, 'ins1:Surname': @surname }
    end

    # taxpayer details if organization party
    def taxpayer_org_details
      { 'ins1:CompanyName': @org_name, 'ins1:ContactName': @firstname + '' + @surname }
    end
  end
end
