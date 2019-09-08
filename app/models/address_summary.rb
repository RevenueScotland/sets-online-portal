# frozen_string_literal: true

# Model for address summary records used to store data return from  NASAddressSearch service
# These only contain the address identifier and summary address line
# Example : NASAddressSearch serice responce is
#           <AddressSearchResponse>
#               <AddressList>
#                 <Address>
#                   <AddressIdentifier>1111</AddressIdentifier>
#                   <FormattedAddress>Address summary</FormattedAddress>
#                </Address>
#              </AddressList>
#           </AddressSearchResponse>
class AddressSummary
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Translation
  include ServiceClient

  attr_accessor :postcode, :address_identifier, :formatted_address

  validates :postcode, presence: true, length: { minimum: 6, maximum: 8 }, on: %i[search]
  validates_format_of :postcode,
                      with: /\A([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})\z/i,
                      on: %i[search]

  # Performs an address search
  def search
    return nil unless valid?(:search)

    success, addresses = call_address_service
    errors.add(:postcode, (I18n.t '.no_address_search_results')) unless success && !addresses.empty?
    addresses if success && !addresses.empty?
  end

  # Sets up a new instance of the class when retrieved from the search
  # @param attributes [Hash] a hash of objects used for the new instance of class
  # @return [Object] a new instance of the class with the hash of objects passed as param values
  def self.new_from_search(attributes = {})
    object = new(attributes)
    object
  end

  private

  # call the address service and return both the success of the call and the addresses
  # for the postcode
  # @return [Array] this contains the success and the addresses
  def call_address_service
    addresses = []
    success = call_ok?(:address_search, make_request) do |body|
      ServiceClient.iterate_element(body[:address_list]) do |address|
        add_address(addresses, address) unless address.nil?
      end
    end
    [success, addresses]
  end

  # given the request it creates a hash that repesents the data that will be passed to the back office
  # address service
  # @return [Hash] data that will be passed to the back office address service
  def make_request
    { RequestParameters: {}, SearchParameters: { 'ins1:Postcode' => postcode.upcase },
      SelectionOptions: { 'ins1:MaximumNumberOfRows' => 200, 'ins1:IncludeNonGeographicAddresses' => false,
                          'ins1:IncludeBFPOAddresses' => false, 'ins1:IncludeMultiResidenceAddresses' => false,
                          'ins1:IncludeNIAddresses' => true } }
  end

  # Adds an address summary record to the search results
  # @param addresses [Array] an array of addresses to have new address pushed in
  # @param address [Object] the address to be searched for and added to the array
  def add_address(addresses, address)
    address[:postcode] = postcode
    addresses.push(AddressSummary.new_from_search(address))
  end
end
