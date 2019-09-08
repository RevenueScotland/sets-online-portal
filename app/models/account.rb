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
  include CommonValidation
  include AccountPersistence
  include AccountValidation

  # Attributes for this class, in list so can re-use as permitted params list in the controller
  def self.attribute_list
    %i[current_user forename surname terms_and_conditions registration_token contact_number address email_address
       email_address_confirmation taxes company account_type reg_company_contact_address_yes_no party_account_type
       nino email_data_ind dd_instruction_available]
  end

  attribute_list.each { |attr| attr_accessor attr }

  validates :terms_and_conditions, presence: true, on: %i[create terms_and_conditions]
  validates :email_data_ind, presence: true, on: %i[create email_data_ind]
  validate  :valid_email_address?, on: %i[create update email_address update_basic]
  validates :email_address, confirmation: true, on: %i[create update email_address update_basic]
  validate  :taxes_valid?, on: %i[create taxes]
  validate  :names_valid?, on: %i[update update_basic]
  validate  :company_valid?, on: :update
  validate  :basic_company_details_valid?, on: :update_basic
  validates :reg_company_contact_address_yes_no, presence: true, on: :reg_company_contact_address_yes_no
  validates :party_account_type, presence: true, on: :party_account_type
  validate  :nino_valid?, on: %i[nino update_basic]
  validates :contact_number, presence: true, on: %i[contact_number update_basic]
  validate  :contact_number_format_valid?, on: %i[create update contact_number update_basic]

  # Custom validation context for activating account
  validates :registration_token, presence: true, on: :process_activate_account

  # Define the ref data codes associated with the attributes to be cached in this model
  # @return [Hash] <attribute> => <ref data composite key>
  def cached_ref_data_codes
    { taxes: 'PORTALSERVICES.SYS.RSTU', party_account_type: 'PARTY_ACT_TYPES.SYS.RSTU' }
  end

  # Define the ref data codes associated with the attributes not to be cached in this model
  # @return [Hash] <attribute> => <ref data composite key>
  def uncached_ref_data_codes
    { terms_and_conditions: 'YESNO.SYS.RSTU', reg_company_contact_address_yes_no: 'YESNO.SYS.RSTU',
      email_data_ind: 'YESNO.SYS.RSTU' }
  end

  # Check if contact telephone number is valid
  def contact_number_format_valid?
    phone_number_format_valid? :contact_number
  end

  # override getter for terms and conditions to ensure it returns a boolean type
  # @return [Boolean] terms_and_conditions value
  def terms_and_conditions
    return false if @terms_and_conditions.to_s.empty?

    ActiveModel::Type::Boolean.new.cast(@terms_and_conditions)
  end

  # initialises a new instance with the hash passed, uses Active model to do this
  # @param attributes [Hash] a hash of objects that uses Active model
  def initialize(attributes = {})
    super filter_attributes(attributes, Account.attribute_list)
    self.current_user = User.new(filter_attributes(attributes, User.attribute_list)) if current_user.nil?
    return unless account_type.nil? || account_type.empty?

    self.account_type = AccountType.new(filter_attributes(attributes, AccountType.attribute_list))
  end

  # Allows you to set all the attributes by passing in a hash of attributes with keys matching the attribute names
  # (which again matches the column names).
  # @param attributes [Hash] a hash of objects that uses Active model
  def assign_attributes(attributes)
    super filter_attributes(attributes, Account.attribute_list)
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
    account.contact_number = body[:phone_number]
    account.email_address_confirmation = body[:email_address] = account.email_address = body[:email_address]
    account.dd_instruction_available = ActiveModel::Type::Boolean.new.cast(body[:curr_dd_instruction_avail])
    account.party_account_type = body[:party_account_type]
    account.taxes = extract_services(body[:user_services])
    assign_sub_objects_from_back_office account, body
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
    account.nino = body[:party_nino]
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
      postcode: address_details[:address_postcode_or_zip]
    )
  end

  # set user account company details
  def account_company(response)
    address = response[:registered_address]
    self.company = Company.new(company_number: response[:registration_number],
                               company_name: response[:company_name])
    company_address(address) unless address.nil?
  end

  # Returns a translation attribute where a given attribute
  # may have more than one name based on e.g. a type discriminator
  # @param attribute [Symbol] the name of the attribute to translate
  # @param extra [Object] additional information for the translation process
  # @param _error_attribute [Boolean] is this being called to render the error attribute name
  # @return [Symbol] the name of the translation attribute
  def translation_attribute(attribute, extra = nil, _error_attribute = false)
    return :org_nino if attribute == :nino && AccountType.other_organisation?(account_type)
    return @company.translation_attribute(attribute, extra) unless @company.nil?

    attribute
  end

  # Check if the account has the supplied service/tax
  # @param service [String/Symbol] the service to check for
  # @return [Boolean] returns true if the account has the service otherwise false
  def service?(service)
    taxes.include?(service.to_s.upcase)
  end

  private

  # Maps an address hash map to a company structure
  def company_address(address)
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

    send("#{attribute}=", model.to_s.constantize.new) if send(attribute).nil?
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
