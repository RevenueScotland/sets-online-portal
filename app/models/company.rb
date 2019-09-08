# frozen_string_literal: true

# Model for company records
class Company # rubocop:disable Metrics/ClassLength
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Translation
  include CommonValidation
  include PrintData

  # Company number validation regex, either 8 numbers, or SC and 6 numbers
  COMPANY_NUMBER_REGEX = /\A\d{8}|[A-Z]{2}\d{6}\z/i.freeze

  # Attributes for this class, in list so can re-use as permitted params list in the controller. Note: attributes
  # names need to be unique between company and account, as that the "magic" account does on delegating validation
  # and assign_attributes works.
  def self.attribute_list
    %i[company_number company_name address_line1 address_line2 county country locality postcode org_email_address
       org_telephone main_rep_name]
  end

  attribute_list.each { |attr| attr_accessor attr }

  validates :company_number, presence: true, length: { minimum: 8, maximum: 8 },
                             on: %i[search registered_organisation company_number]
  validate  :company_number_valid?, on: %i[search registered_organisation company_number]
  validates :company_name, presence: true, on: %i[registered_organisation other_organisation company_name]
  validates :org_telephone, presence: true, on: %i[org_telephone]
  validate  :org_phone_format_valid?, on: %i[create update org_telephone update_basic]
  validate  :org_email_address_valid?, on: %i[create update org_email_address update_basic]
  validates :address_line1, presence: true, on: %i[registered_organisation address_line1]
  validates :locality, presence: true, on: %i[registered_organisation locality]
  validates :postcode, presence: true, on: %i[registered_organisation postcode]
  validates :main_rep_name, presence: true, on: %i[main_rep_name]
  validate  :company_selected?, on: :company_selected

  # Layout to print the data in this model
  # This defines the sections that are to be printed and the content and layout of those sections
  def print_layout # rubocop:disable Metrics/MethodLength
    [{ code: :company_details, # section code
       divider: false, # should we have a section divider
       display_title: true, # Is the title to be displayed
       type: :list, # type list = the list of attributes to follow
       list_items: [{ code: :company_number },
                    { code: :company_name },
                    { code: :address_line1 },
                    { code: :address_line2, nolabel: true },
                    { code: :locality },
                    { code: :county },
                    { code: :postcode },
                    { code: :country }] }]
  end

  # Override setter so that the optional letters in the company number are always upper case.
  def company_number=(value)
    @company_number = value&.upcase
  end

  # Validation contexts for companies to check that an company has been "selected"
  # @return [Hash] validation contexts for selecting an company
  def self.selected_validation_contexts
    %i[company_number company_selected]
  end

  # Performs an company search
  def search
    return nil unless valid?(:search)

    success, company = call_company_service
    errors.add(:company_number, (I18n.t '.no_company_search_results')) if success && company.nil?
    success && !company.nil? ? company : nil
  end

  # @return [String] The formatted full address
  def full_address
    [address_line1, address_line2, locality, county, postcode].reject(&:blank?).join(', ')
  end

  # @return [String] line 1, county and postcode only
  def short_address
    [address_line1, county, postcode].reject(&:blank?).join(', ')
  end

  # @return [Boolean] if company_number and company_name are both empty or nil
  def empty?
    !company_number? && !company_name?
  end

  # @return [Boolean] returns true if the company number is not empty
  def company_number?
    !company_number.to_s.empty?
  end

  # @return [Boolean] returns true if the company name is not empty
  def company_name?
    !company_name.to_s.empty?
  end

  # Returns a translation attribute where a given attribute may have more than one name based on e.g. a type
  # it also allows for a different attribute name for the error region for e.g. long labels
  # @param attribute [Symbol] the name of the attribute to translate
  # @param extra [Object] in this case the account type being processed passed from the page
  # @param _error_attribute [Boolean] is the translation being called for the error region
  # @return [Symbol] the name of the translation attribute
  def translation_attribute(attribute, extra = nil, _error_attribute = false)
    return :other_org_name if attribute == :company_name && !extra.nil? && AccountType.other_organisation?(extra)

    attribute
  end

  # @return [Address] returns the company address as an address object
  def company_address
    return nil if address_line1.nil?

    address = Address.new
    address.assign_attributes(address_line1: address_line1, address_line2: address_line2, town: locality,
                              county: county, country: country, postcode: postcode)
    address
  end

  # Sets the company address from an address object
  # @param address [Address] The address to sets the company address
  def from_address!(address)
    return nil_address if address.nil?

    assign_from_address! address
  end

  # converts hash returned from back-office to company object
  def self.convert_hash_to_company(input_hash)
    output = {}
    output[:company_name] = input_hash[:org_name]
    output[:company_number] = input_hash.delete(:com_regno)

    company = Company.new(output)

    # sets the company address from an address object
    company.from_address!(input_hash.delete(:address))

    company
  end

  private

  # set the company address to blank
  def nil_address
    self.address_line1 = nil
    self.address_line2 = nil
    self.town = nil
    self.county = nil
    self.country = nil
    self.postcode = nil
  end

  # set the company address to the address object
  # @param address [Address] The address to sets the company address
  def assign_from_address!(address)
    self.address_line1 = address.address_line1
    self.address_line2 = address.address_line2
    self.locality = address.town
    self.county = address.county
    self.country = address.country || 'GB'
    self.postcode = address.postcode
  end

  # call the companies house RESET service and return both the success of the call and the
  # company for the company name, if any.
  # @return [boolean,Object] success/failure flag and the company summary information
  def call_company_service
    ch_api = CompaniesHouseApi.new
    response = ch_api.company company_number
    parse_response response
  end

  # parse the response from companies house, and convert to a company_summary if possible
  # @return [boolean,Object] success/failure flag and the company summary information
  # if the company is found at companies house, the flag will be true and the company summary populated
  # if the company is not found, the flag will be true, but the company summary will be nil
  # in all other cases, the flag will be false.
  def parse_response(response)
    return [false, nil] if response.nil? || response.parsed_response.nil? || response.response.nil?
    return [true, nil] if response.response.is_a?(Net::HTTPNotFound)

    Rails.logger.debug { "Companies house response #{response}" }

    company = Company.new
    company = parse_companies_house_response company, response.parsed_response
    [true, company]
  end

  # parse the response from companies house, and convert to a company_summary
  # @return [Object] the converted response from companies house
  def parse_companies_house_response(company, response)
    company.company_name = response['company_name']
    company.company_number = response['company_number']
    parse_registered_office_address company, response['registered_office_address']
  end

  # parse the registered office address from within the companies house response to
  # populate the address details within the company summary
  # @return [Object] the converted response from companies house
  def parse_registered_office_address(company, address)
    return company if address.nil?

    company.address_line1 = [address['po_box'], address['address_line_1']].compact.join(', ')
    company.address_line2, company.locality = ensure_we_have_locality(address['address_line_2'], address['locality'])
    company.county = address['region']
    company.postcode = address['postal_code']
    company.country = 'GB'
    company
  end

  # switch address line 2 to locality if we don't have locality in response
  def ensure_we_have_locality(address_line2, locality)
    return [nil, address_line2] if locality.nil?

    [address_line2, locality]
  end

  # Validation to check that the company has been selected - it's the same as checking the
  # presence of number, name, and address_line1, but with a nicer error message
  # and attached to the base object
  def company_selected?
    return unless company_number.to_s.empty? || company_name.to_s.empty? || address_line1.to_s.empty?

    errors.add(:base, :company_not_chosen)
  end

  # Check if organisation telephone number is valid
  def org_phone_format_valid?
    phone_number_format_valid? :org_telephone
  end

  # Check if organisation email address is valid
  def org_email_address_valid?
    email_address_valid? :org_email_address
  end

  # Check if company number is valid based on @see COMPANY_NUMBER_REGEX.
  def company_number_valid?
    return if company_number&.match?(COMPANY_NUMBER_REGEX)

    errors.add(:company_number, :is_invalid)
  end
end
