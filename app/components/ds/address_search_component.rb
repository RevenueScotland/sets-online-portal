# frozen_string_literal: true

# Revenue Scotland Specific UI code
module DS
  # Renders a company search component works with the @see WizardCompanyHelper
  class AddressSearchComponent < ViewComponent::Base
    include DS::ComponentHelpers
    include DS::FieldsFor

    attr_reader :address_summary, :search_results, :address, :address_list, :show_address_detail,
                :readonly, :country_code_required, :nested

    # @param address_summary [AddressSummary] The address summary object used for the postcode search
    # @param search_results [Array<AddressSummary>] The list of results from the postcode search
    # @param address [Address] The address detail object that is the actual address
    # @param address_list [Array<Address> ] An array of addresses that the user can pick, normally
    #   already used addresses
    # @param show_address_detail [Boolean] Show the address detail
    # @param readonly [Boolean] The address detail is read only
    # @param country_code_required [Boolean] Is the country code required in the address
    def initialize(address_summary:, search_results:, address:, address_list: nil, show_address_detail: false,
                   readonly: true, country_code_required: true, nested: false)
      super()

      @address_summary = address_summary
      @search_results = search_results
      @address = address
      @address_list = address_list
      @show_address_detail = show_address_detail
      @readonly = readonly
      @country_code_required = country_code_required
      @nested = nested
    end

    # Utility function determines if the postcode search has been done and we show the search as a label
    def show_postcode_as_label
      @search_results.present? || (@show_address_detail && @readonly) ||
        (@show_address_detail && @address_summary.postcode.present?)
    end
  end
end
