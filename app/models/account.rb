# frozen_string_literal: true

# Holds details about an account.
# Includes @see AccountBasedCaching so the account data will be cached based on the account ID which is
# the party_refno of the current_user.  However, use Account.find to get the account since that
# automatically turns the skinny current_user into account.current_user a fat/fully populated user
# object. (Ie Users.all is called which also includes AccountBasedCaching).
# AccountBasedCaching allows us to keep the Account class to include just account specific information,
# rather than it including all the other classes that are linked to an account (eg for the account users
# see the User class).
class Account < FLApplicationRecord # rubocop:disable Metrics/ClassLength
  include AccountBasedCaching
  include AccountPersistence
  include AccountValidation

  # Attributes for this class, in list so can re-use as permitted params list in the controller
  def self.attribute_list
    %i[current_user forename surname terms_and_conditions registration_token contact_number address email_address
       email_address_confirmation taxes company account_type reg_company_contact_address_yes_no party_account_type
       nino email_data_ind dd_instruction_available enrolment_ref tp_business_name tp_busi_postcode tp_busi_email_addr]
  end

  attribute_list.each { |attr| attr_accessor attr }

  validates :taxes, presence: true, on: %i[create taxes]
  validates :email_data_ind, presence: true, on: %i[create email_data_ind]
  validate  :names_are_valid, on: %i[update update_basic]
  validates :email_address, presence: true, email_address: true, on: %i[create update email_address update_basic]
  validates :email_address, confirmation: true, on: %i[create update email_address update_basic]
  validate  :company_valid?, on: :update
  validate  :basic_company_details_valid?, on: :update_basic
  validates :reg_company_contact_address_yes_no, presence: true, on: :reg_company_contact_address_yes_no
  validates :party_account_type, presence: true, on: :party_account_type
  validates :nino, presence: true, nino: true, on: %i[nino update_basic],
                   unless: proc { |p| AccountType.registered_organisation?(p.account_type) }
  validates :contact_number, presence: true, phone_number: true, on: %i[contact_number update_basic]
  validates :enrolment_ref, presence: true, enrolment_reference: true, on: :enrolment_ref

  validates :tp_business_name, presence: true, on: :tp_business_name
  validates :tp_busi_postcode, presence: true, on: :tp_busi_postcode
  validates :tp_busi_email_addr, presence: true, on: :tp_busi_email_addr
  validates :terms_and_conditions, acceptance: { accept: 'Y' }, on: %i[create terms_and_conditions]
  # Custom validation context for activating account
  validates :registration_token, length: { maximum: 100 }, presence: true, on: :process_activate_account
  validates :tp_busi_email_addr, email_address: true, if: proc { |p| p.tp_busi_email_addr.present? }

  # Define the ref data codes associated with the attributes to be cached in this model
  # @return [Hash] <attribute> => <ref data composite key>
  def cached_ref_data_codes
    { taxes: comp_key('PORTALSERVICES', 'SYS', 'RSTU'), party_account_type: comp_key('PARTY_ACT_TYPES', 'SYS', 'RSTU') }
  end

  # Define the ref data codes associated with the attributes not to be cached in this model
  # @return [Hash] <attribute> => <ref data composite key>
  def uncached_ref_data_codes
    { terms_and_conditions: YESNO_COMP_KEY,
      reg_company_contact_address_yes_no: YESNO_COMP_KEY,
      email_data_ind: YESNO_COMP_KEY }
  end

  # initialises a new instance with the hash passed, uses Active model to do this
  # @param attributes [Hash] a hash of objects that uses Active model
  def initialize(attributes = {})
    super(filter_attributes(attributes, Account.attribute_list))
    self.current_user = User.new(filter_attributes(attributes, User.attribute_list)) if current_user.nil?
    return if account_type.present?

    self.account_type = AccountType.new(filter_attributes(attributes, AccountType.attribute_list))
  end

  # Allows you to set all the attributes by passing in a hash of attributes with keys matching the attribute names
  # (which again matches the column names).
  # @param attributes [Hash] a hash of objects that uses Active model
  def assign_attributes(attributes)
    super(filter_attributes(attributes, Account.attribute_list))
    assign_attributes_for(attributes, User, :current_user)
    assign_attributes_for(attributes, Company, :company)
    assign_attributes_for(attributes, AccountType, :account_type)
  end

  # Gets the account data for the user and then fills that user's details into the current_user field
  # (aka turning a skinny user into a fat user).
  # @param requested_by [User] is usually the current_user, who is requesting the data and containing the account id
  # @return the account instance for requested_by
  def self.find(requested_by)
    account = Account.all(requested_by)
    raise Error::AppError.new('Account.find', 'Only 1 account expected') if account.is_a?(Array)

    account.current_user = User.all(requested_by)[requested_by.username]
    account
  end

  # Gets account data from the back office for the given user.
  # @example Do not call this method directly, use the @see AccountBasedCaching#all method eg use :
  #   "account = Account.all(current_user)"
  # as then you'll access cached data rather than hitting the back office each time.
  # @param [User] requested_by is usually the current_user, who is requesting the data and containing the account id
  # @note return list of users for the account
  private_class_method def self.back_office_data(requested_by)
    account = Account.new
    call_ok?(:get_party_details, account.account_details_element_list(requested_by)) do |body|
      account = assign_from_back_office(account, body)
    end
    account
  end

  # @!method self.assign_from_back_office(account, body)
  # Assign data from the back office into the account object
  # @param account [Account] the account object to assign the data into
  # @param body [Hash] the data from the back office
  # @return [Account] the account object with the data assigned from the back office
  private_class_method def self.assign_from_back_office(account, body)
    account.forename = body[:forename]
    account.surname = body[:surname]
    account.dd_instruction_available = ActiveModel::Type::Boolean.new.cast(body[:curr_dd_instruction_avail])
    account.party_account_type = body[:party_account_type]
    account.taxes = extract_services(body[:user_services])
    assign_sub_objects_from_back_office(account, body)
  end

  # @!method self.assign_sub_objects_from_back_office(account, body)
  # Assign data from the back office into the account's sub-objects
  # @param account [Account] the account object to assign the data into
  # @param body [Hash] the data from the back office
  # @return [Account] the account object with the data assigned from the back office
  private_class_method def self.assign_sub_objects_from_back_office(account, body)
    account.account_address(body[:address]) unless body[:address].nil?
    account.account_company(body)
    account.account_type = AccountType.from_account(account)
    account.email_address_confirmation = account.email_address = body[:email_address]
    account.nino = body[:party_nino]
    account.contact_number = body[:phone_number]
    account
  end

  # @!method self.extract_services(services)
  # Return a simple array of services based on the parameter
  # @param services [Array/Array of Array/string] array, or array of array, or single value of services
  # @return [Array] array of services
  private_class_method def self.extract_services(services)
    return [] if services.nil?

    services = services.values
    return [] if services.nil?
    return [services] unless services.is_a?(Array)
    return [] if services.empty?
    return services.uniq unless services[0].is_a?(Array)

    services[0].uniq
  end

  # returns account name as company name or forename+surname if company name doesn't exist
  # @note returns the account name
  def account_name
    return company.company_name unless company.nil? || company.company_name.nil?

    [forename, surname].join(' ')
  end

  # returns enrolment type for registering new account
  def enrolment_type
    return nil if taxes != 'SAT'

    'SAT registration'
  end

  # element list to retrieve user account details
  def account_details_element_list(requested_by)
    { PartyRef: requested_by.party_refno, 'ins1:Requestor': requested_by.username }
  end

  # set user account address details
  def account_address(address_details)
    self.address = Address.new(
      address_line1: address_details[:address_line1], address_line2: address_details[:address_line2],
      address_line3: address_details[:address_line3], address_line4: address_details[:address_line4],
      town: address_details[:address_town_or_city], county: address_details[:address_county_or_region],
      postcode: address_details[:address_postcode_or_zip], country: address_details[:address_country_code]
    )
  end

  # set user account company details
  def account_company(response)
    address = response[:registered_address]
    self.company = Company.new(company_number: response[:registration_number],
                               company_name: response[:company_name])
    company_address(company, address) unless address.nil?
  end

  # @return [Array] list of portal taxes for registration
  def portal_services
    services ||= list_ref_data(:taxes)

    sat_service ||= ReferenceData::SystemParameter.lookup(
      'COMMON', 'SAT', 'RSTU', safe_lookup: true
    )['PWS_ACCT_REG_ALLOWED']&.value

    services.delete_if { |srv| srv.code == 'SAT' } if sat_service == 'N'

    services
  end

  # @return [Array] list of party types for registration
  def party_types
    party_types ||= list_ref_data(:party_account_type)

    party_types.delete_if { |type| type.code == 'UKTAXREP' } unless taxes == 'SAT'

    party_types
  end

  # Remove any spaces from the provided nino value
  def nino=(value)
    @nino = value&.delete(' ')
  end

  # Surrogate getter to return the company address at the account level
  # used by the @see registration_controller
  def org_address
    company&.company_address
  end

  # Surrogate setter to return the company address at the account level
  # used by the @see registration_controller
  def org_address=(address)
    company.from_address!(address)
  end

  # Returns a translation attribute where a given attribute
  # may have more than one name based on e.g. a type discriminator
  # @param attribute [Symbol] the name of the attribute to translate
  # @param extra [Object] additional information for the translation process
  # @return [Symbol] the name of the translation attribute
  def translation_attribute(attribute, extra = nil)
    return :"#{attribute}_#{taxes}" if %i[party_account_type].include?(attribute)
    return :ORG_nino if attribute == :nino && AccountType.other_organisation?(account_type)
    return @company.translation_attribute(attribute, extra) unless @company.nil?

    attribute
  end

  # Check if the account has the supplied service/tax
  # @param service [String/Symbol] the service to check for
  # @return [Boolean] returns true if the account has the service otherwise false
  def service?(service)
    taxes.include?(service.to_s.upcase)
  end

  # check if the account has services allocated to it
  # @return [Boolean] returns true if account does not have any service otherwise false
  def no_services?
    # taxes is a array which contains services if allocated by back-office
    taxes.empty?
  end

  # This method returns the registration notes for the new user registration
  def registration_notes
    return '' if taxes != 'SAT'

    acct_type = list_ref_data(:party_account_type).select { |x| x.code == party_account_type }.map(&:value).join(', ')
    I18n.t('activemodel.attributes.account.registration_notes', enrolment_ref: enrolment_ref,
                                                                account_type: acct_type,
                                                                taxpayer_name: tp_business_name,
                                                                taxpayer_postcode: tp_busi_postcode,
                                                                taxpayer_email: tp_busi_email_addr).html_safe
  end

  private

  # Maps an address hash map to a company structure
  def company_address(company, address)
    company.address_line1 = address[:address_line1]
    company.address_line2 = address[:address_line2]
    company.locality = address[:address_town_or_city]
    company.county = address[:address_county_or_region]
    company.country = address[:address_country_code]
    company.postcode = address[:address_postcode_or_zip]
  end

  # Assigns attributes to sub objects of this class
  # @param attributes [Hash] hash of attributes that may be applicable to sub objects
  # @param model [Class] the class of the sub object
  # @param attribute [symbol] the name of the class variable to assign the attributes to
  def assign_attributes_for(attributes, model, attribute)
    filtered_attributes = filter_attributes(attributes, model.send(:attribute_list))
    return if filtered_attributes.nil? && filtered_attributes.empty?

    send(:"#{attribute}=", model.to_s.constantize.new) if send(attribute).nil?
    send(attribute).assign_attributes(filtered_attributes)
  end

  # filter attributes so that it only contains attributes that are applicable to this model
  # @param attributes [Hash] a hash of objects that use Active model
  # @param to_filter [Array] a list of attributes to include in the return
  def filter_attributes(attributes, to_filter)
    return nil if attributes.nil? || to_filter.nil?

    attributes.select { |key, _| to_filter.include? key.to_sym }
  end
end
