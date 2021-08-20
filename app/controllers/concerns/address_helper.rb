# frozen_string_literal: true

# Address helpers for this application
# Included by controllers to help manage address search/lookup forms.
module AddressHelper
  extend ActiveSupport::Concern

  # Returns the validation contexts for address validation based on whether the address read only flag is set or not
  # @return [Array] validation contexts
  def address_validation_contexts
    # Checking if address_read_only is true or EMPTY
    if ActiveModel::Type::Boolean.new.cast(params[:address_read_only]) || params[:address_read_only].empty?
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
  # @param address_detail[Object] parameter use to view exiting address details on address view
  # @param search_postcode[String] the postcode used in the search
  # @param default_country[String] the default country to be used for the address
  def initialize_address_variables(address_detail = nil, search_postcode = nil, default_country = nil)
    @address_summary = AddressSummary.new
    @address_summary.postcode = search_postcode
    @address_read_only = true
    @show_manual_address = true if address_detail.present?
    @address_detail = address_detail || Address.new(default_country: default_country)

    move_postcode_search_errors(address_detail) unless params[:show_manual_address] == 'true'
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
    params[:search] || params[:select] || params[:manual_address] || params[:change_postcode]
  end

  # Performs an address search based on the search parameters and displays the results (if any)
  def address_search
    # A search here is an initial search based on postcode, whereas a find is
    # a detailed search based on the address identifier
    if params[:search]
      do_address_identifier_search
    elsif params[:manual_address]
      set_for_manual_address
    elsif params[:change_postcode]
      @address_summary.postcode = ''
    elsif params[:search_results]
      # user has selected address from the drop down list, get the full details for them
      find_address_details
    end
  end

  # re-populate address summary and address details data from request param
  def populate_address_data
    @address_summary = AddressSummary.new(search_params)
    @address_detail = Address.new(address_params) unless params[:address].nil?
  end

  # Performs an address search based on the search parameters
  # and displays the results (if any)
  def do_address_identifier_search
    @address_summary = AddressSummary.new(search_params)
    @search_results = @address_summary.search
    # We need to carry the default country set up forward as the address currently
    @address_detail = Address.new(default_country: params[:address][:default_country])
  end

  # Given an address identifier get the detail of that address
  # that matches the identifier
  def find_address_details
    @address_summary = AddressSummary.new
    # Carry forward the default country otherwise it gets lost
    @address_detail = Address.find(find_params[:search_results], params[:address][:default_country])
    if @address_detail.nil?
      @address_summary.errors.add(:postcode, (I18n.t '.no_address_find_results'))
    else
      @address_summary.postcode = @address_detail.postcode
      @show_manual_address = true
    end
    @address_read_only = true
    [@address_detail, @address_summary, @address_read_only, @show_manual_address]
  end

  # Sets the address search up for a manual search
  def set_for_manual_address
    @show_manual_address = true
    @address_read_only = false
    # clear the identifier as this address is no longer from the search
    @address_detail.address_identifier = nil
  end

  # controls the permitted parameters to this controller to perform
  # a search
  def search_params
    params.require(:address_summary).permit(:postcode)
  end

  # controls the permitted parameters for address
  def address_params
    params.require(:address).permit(Address.attribute_list)
  end

  # controls the permitted parameters to this controller to perform
  # a find
  def find_params
    params.permit(:search_results)
  end
end
