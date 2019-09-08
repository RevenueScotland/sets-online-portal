# frozen_string_literal: true

# Address helpers for this application
# Included by controllers to help manage address search/lookup forms.
module AddressHelper
  extend ActiveSupport::Concern

  # Returns the validation context for address validation based on whether the address read only flag is set or not
  # @return [Array] validation context
  def address_validation_context
    # Checking if address_read_only is true or EMPTY then selected_validation_contexts
    if ActiveModel::Type::Boolean.new.cast(params[:address_read_only]) || params[:address_read_only].empty?
      Address.selected_validation_contexts
    else
      Address.save_validation_contexts
    end
  end

  # Gets the postcode for the search if it's available from the parameters
  def search_postcode
    params[:address_summary][:postcode] unless params[:address_summary].nil?
  end

  private

  # Initialize address required variables for the address view to use.
  # If search_postcode is present and errors exist in address_detail, they will be moved to the @address_summary
  # object as that's the one which shows the postcode search box (@see #move_postcode_search_errors).
  # @param address_detail[Object] parameter use to view exiting address details on address view
  # @param search_postcode[String] the postcode used in the search
  def initialize_address_variables(address_detail = nil, search_postcode = nil)
    @address_summary = AddressSummary.new
    @address_summary.postcode = search_postcode
    @address_read_only = true
    @show_manual_address = true unless address_detail.blank?
    # Address has it's own blank? method which doesn't include the errors so don't use that here (using .nil? instead)
    @address_detail = address_detail.nil? ? Address.new : address_detail

    move_postcode_search_errors(address_detail, search_postcode)
  end

  # @HACK: If search_postcode is present and errors exist in address_detail, they will be moved to the @address_summary
  # object as that's the one which shows the postcode search box.
  # Called by #initialize_address_variables only.
  def move_postcode_search_errors(address_detail, search_postcode)
    return if search_postcode.nil? || address_detail.nil? || address_detail&.errors.blank?

    @address_summary.errors.merge!(address_detail.errors)
    address_detail.errors.clear
  end

  # Performs an address search based on the search parameters and displays the results (if any)
  def address_search
    return unless params[:search] || params[:search_results] || params[:manual_address]

    # # An search here is an initial search based on postcode, whereas a find is
    # a detailed search based on the address identifier
    if params[:search]
      do_address_identifier_search
    elsif params[:manual_address]
      @show_manual_address = true
      @address_read_only = false
    else
      # user has selected address from the drop down list, get the full details for them
      find_address_details
    end
  end

  # validate address details and put any address detail errors into parent
  def validate_address_detail
    return true if @address_detail.nil?

    @address_detail.valid?
  end

  # re-populate address summary and address details data from request param
  def populate_address_data
    @address_summary = AddressSummary.new(search_params)
    @address_detail = Address.new(address_params) unless params[:address].nil?
  end

  # Is the form submit for an address search?
  def address_search?
    params[:search] || params[:select] || params[:manual_address]
  end

  # Performs an address search based on the search parameters
  # and displays the results (if any)
  def do_address_identifier_search
    @address_summary = AddressSummary.new(search_params)
    @search_results = @address_summary.search
    @address_detail = Address.new
  end

  # Given an address identifier get the detail of that address
  # that matches the identifier
  def find_address_details
    @address_summary = AddressSummary.new
    @address_detail = Address.find(find_params[:search_results])
    if @address_detail.nil?
      @address_summary.errors.add(:postcode, (I18n.t '.no_address_find_results'))
    else
      @address_summary.postcode = @address_detail.postcode
      @show_manual_address = true
    end
    @address_read_only = true
    [@address_detail, @address_summary, @address_read_only, @show_manual_address]
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
