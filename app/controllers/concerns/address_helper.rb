# frozen_string_literal: true

# Address helpers for this application
# Included by controllers to help manage address search/lookup forms.
module AddressHelper # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # Returns the validation contexts for address validation based on whether the address read only flag is set or not
  # @return [Array] validation contexts
  def address_validation_contexts
    default_page_statuses

    # Checking if address_read_only is true or EMPTY
    if @address_read_only
      %i[address_selected]
    else
      %i[save]
    end
  end

  # Gets the postcode for the search if it's available from the parameters
  def search_postcode
    params[:address_summary][:postcode] unless params[:address_summary].nil?
  end

  private

  # Initialize address required variables for the address view to use.
  # If error are present on address_detail and we are not showing the manual address
  # then move to the address summary as that is shown, functionally this would be
  # the 'you haven't chosen and address' message
  # @param address_detail[Object] parameter use to view existing address details on address view
  # @param search_postcode[String] the postcode used in the search
  # @param default_country[String] the default country to be used for the address
  # @param address_list[Array] List of addresses that can be selected
  def initialize_address_variables(address_detail: nil, search_postcode: nil,
                                   default_country: nil, address_list: nil)
    @address_summary = AddressSummary.new
    @address_summary.postcode = search_postcode
    # NOTE: use .nil? not ||= as ||= is based on value equating to false, which a boolean does
    @address_read_only = true if @address_read_only.nil?
    @show_manual_address = address_detail.present? if @show_manual_address.nil?
    @address_detail = address_detail || Address.new(default_country: default_country)
    @address_list = address_list

    move_postcode_search_errors(address_detail) unless @show_manual_address
  end

  # If search_postcode is present and errors exist in address_detail, they will be moved to the @address_summary
  # object as that's the one which shows the postcode search box.
  # Called by #initialize_address_variables only.
  def move_postcode_search_errors(address_detail)
    return if address_detail.nil?

    @address_summary.errors.merge!(address_detail.errors)
    address_detail.errors.clear
  end

  # Is the form submit for an address search?
  def address_search?
    # do any of the parameters start with pick_address
    pick_address = params.each_key.find { |key| key.start_with? 'pick_address_' }.present?
    params[:search] || params[:select] || params[:manual_address] || params[:change_postcode] || pick_address
  end

  # Performs an address search based on the search parameters and displays the results (if any)
  def address_search
    default_page_statuses

    populate_address_list_from_params

    # Pick the action based on the parameters
    # Search here is an initial search based on postcode
    return do_address_identifier_search if params[:search]
    # User has selected to do enter a manual address, or edit a searched address
    return set_for_manual_address if params[:manual_address]
    # User has selected to change the postcode from a previous search
    return set_for_postcode_search if params[:change_postcode]
    # user has selected address from the drop down list, get the full details for them
    return find_address_details if params[:search_results].present?

    # User (may) have clicked on the list of previously used addresses
    pick_address_from_list
  end

  # re-populate address summary and address details data from request param
  def populate_address_data
    @address_summary = AddressSummary.new(search_params)
    @address_detail = Address.new(address_params)
  end

  # Picks the address from the address list
  def pick_address_from_list
    params.each_key do |key|
      next unless key.start_with? 'pick_address'

      index = key.to_s.delete_prefix('pick_address_').to_i

      @show_manual_address = true
      @address_read_only = true
      @address_summary = AddressSummary.new
      @address_detail = @address_list[index]
      break
    end
  end

  # Performs an address search based on the search parameters
  # and displays the results (if any)
  def do_address_identifier_search
    @address_summary = AddressSummary.new(search_params)
    @search_results = @address_summary.search
    @show_manual_address = false
    # We need to carry the default country set up forward as the address currently
    @address_detail = Address.new(default_country: params[:address][:default_country])
  end

  # Sets the address search up for a manual search
  def set_for_manual_address
    @show_manual_address = true
    @address_read_only = false
    # clear the identifier as this address is no longer from the search
    @address_detail.address_identifier = nil
  end

  # Sets the address search up for a postcode search
  def set_for_postcode_search
    @show_manual_address = false
    @address_read_only = false
    @address_summary.postcode = ''
    @address_detail = Address.new(default_country: params[:address][:default_country])
  end

  # Given an address identifier get the detail of that address
  # that matches the identifier
  def find_address_details
    @address_summary = AddressSummary.new
    # Carry forward the default country otherwise it gets lost
    @address_detail = Address.find(find_params[:search_results], params[:address][:default_country])
    if @address_detail.nil?
      @address_summary.errors.add(:postcode, :no_address_find_results)
    else
      @address_summary.postcode = @address_detail.postcode
      @show_manual_address = true
    end
    @address_read_only = true
    [@address_detail, @address_summary, @address_read_only, @show_manual_address]
  end

  # populates the address list from the posted parameters
  def populate_address_list_from_params
    @address_list = []
    params.each do |key, value|
      next unless key.start_with? 'address_list_'

      address = Address.new.from_json(value)
      @address_list << address
    end
  end

  # Sets the current page status based on the values posted by the page.
  # These will be altered by later processing.
  def default_page_statuses
    @address_read_only = ActiveModel::Type::Boolean.new.cast(params[:address_read_only])
    @show_manual_address = ActiveModel::Type::Boolean.new.cast(params[:show_manual_address])
  end

  # controls the permitted parameters to this controller to perform
  # a search
  def search_params
    params.require(:address_summary).permit(:postcode) unless params[:address_summary].nil?
  end

  # controls the permitted parameters for address
  def address_params
    params.require(:address).permit(Address.attribute_list) unless params[:address].nil?
  end

  # controls the permitted parameters to this controller to perform
  # a find
  def find_params
    params.permit(:search_results)
  end
end
