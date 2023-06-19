# frozen_string_literal: true

# Model for address records
class Address < FLApplicationRecord
  include ActiveModel::Serializers::JSON
  include PrintData
  validates_with ScotlandPostcodeValidator, on: :scotland_postcode_selected

  # Attributes for this class, in list so can re-use as permitted params list in the controller
  def self.attribute_list
    %i[address_identifier address_line1 address_line2 address_line3 address_line4 town county postcode country
       local_ed_auth_code local_auth_code udprn umprn delivery_point_suffix default_country]
  end

  # sets the attributes for serialising as JSON on the page
  def attributes
    Address.attribute_list.index_with { |_attr| nil }
  end

  attribute_list.each { |attr| attr_accessor attr }

  # validates :address_line1, presence: true, on: :save
  validates :address_line1, presence: true, length: { maximum: 255 }, on: :save
  validates :address_line2, :address_line3, :address_line4, length: { maximum: 255 }, on: :save
  validates :town, presence: true, length: { maximum: 100 }, on: :save
  validates :county, length: { maximum: 50 }, on: :save
  validates :postcode,
            format: /\A([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})\z/i,
            on: :save, if: proc { |p| p.postcode.present? }
  validate :address_selected?, on: :address_selected
  validates :country, presence: true, on: :save

  # Layout to print the data in this model
  # This defines the sections that are to be printed and the content and layout of those sections
  def print_layout # rubocop:disable Metrics/MethodLength
    [{ code: :address, # section code
       divider: false, # should we have a section divider
       display_title: true, # Is the title to be displayed
       type: :list, # type list = the list of attributes to follow
       list_items: [{ code: :address_line1 },
                    { code: :address_line2, label: false, when: :address_line2, is_not: :nil? },
                    { code: :address_line3, label: false, when: :address_line3, is_not: :nil? },
                    { code: :address_line4, label: false, when: :address_line4, is_not: :nil? },
                    { code: :town },
                    { code: :county },
                    { code: :postcode }] }]
  end

  # Performs a get address detail query
  # @param address_identifier the identifier of the address to be searched for
  # @param default_country [String] the default country to carry forward
  # @return [Object] the details of the address
  def self.find(address_identifier, default_country)
    address_detail = {}
    success = call_ok?(:address_detail, Address: { 'ins1:AddressIdentifier' => address_identifier }) do |body|
      body[:address][:country] = convert_search_country_code(body[:address][:country])
      body[:address][:default_country] = default_country
      address_detail = new(body[:address])
    end
    address_detail if success
  end

  # Define the ref data codes associated with the attributes to be cached in this model
  # @return [Hash] <attribute> => <ref data composite key>
  def cached_ref_data_codes
    { country: comp_key('COUNTRIES', 'SYS', 'RSTU') }
  end

  # Overrides the default getter. Sets default country to the default country if one was set on initialisation or to GB
  def country
    @country || @default_country || 'GB'
  end

  # Overrides the default setter to trim the value as seems to come back with spaces
  def address_identifier=(value)
    @address_identifier = value&.strip
  end

  # @return [String] The formatted full address
  def full_address
    [address_line1, address_line2, address_line3, address_line4, town, county, postcode].compact_blank.join(', ')
  end

  # @return [String] line 1, town and postcode only
  def short_address
    [address_line1, town, postcode].compact_blank.join(', ')
  end

  # Specify own blank? method
  # @return true if address_line1 and town and postcode are all blank
  def blank?
    @address_line1.blank? && @town.blank? && @postcode.blank?
  end

  # Help with debugging
  def to_s
    short_address
  end

  # Converts address hash suitable for use in a save_request method in the returns models(eg @see Property#request_save)
  # for sending to the back office
  def format_to_back_office_address(prefix = 'ns1')
    output = { "#{prefix}:AddressLine1": address_line1 }
    xml_element_if_present(output, "#{prefix}:AddressLine2", address_line2)
    xml_element_if_present(output, "#{prefix}:AddressLine3", address_line3)
    xml_element_if_present(output, "#{prefix}:AddressLine4", address_line4)
    format_town_county_postcode(output, prefix)
    output
  end

  # converts back-office address hash into address object
  def self.convert_hash_to_address(address_hash)
    # map back-office fields with attributes in Address model
    address_hash[:town] = address_hash.delete(:address_town_or_city)
    if address_hash[:address_county_or_region].present?
      address_hash[:county] = address_hash.delete(:address_county_or_region)
    end
    address_hash[:postcode] = address_hash.delete(:address_postcode_or_zip)
    address_hash[:country] = address_hash.delete(:address_country_code)

    # remove unnecessary values from address hash
    address_hash[:address_identifier] = address_hash.delete(:qas_moniker)

    # setup address object
    Address.new(address_hash)
  end

  # Convert the code returned by the address search into a recognised country code
  private_class_method def self.convert_search_country_code(country_code)
    return 'SCO' if country_code == 'S92000003'
    return 'EN' if country_code == 'E92000001'
    return 'NIR' if country_code == 'N92000002'
    return 'WA' if country_code == 'W92000004'

    country_code
  end

  private

  # Convert address fields town, county and postcode in back-office format
  def format_town_county_postcode(output, prefix)
    output["#{prefix}:AddressTownOrCity"] = town
    xml_element_if_present(output, "#{prefix}:AddressCountyOrRegion", county)
    xml_element_if_present(output, "#{prefix}:AddressPostcodeOrZip", postcode)
    xml_element_if_present(output, "#{prefix}:AddressCountryCode", country)
    xml_element_if_present(output, "#{prefix}:QASMoniker", address_identifier)
  end

  # Validation to check that the address has been selected - it's the same as checking the
  # presence of address_line1, town, postcode but with a nicer error message.
  def address_selected?
    return unless address_line1.to_s.empty? || town.to_s.empty?

    errors.add(:postcode, :address_not_chosen)
  end
end
