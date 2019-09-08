# frozen_string_literal: true

# Helper class to support functionality to LbttPartiesController
module LbttPartiesHelper # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # Load previously entered address
  def load_previous_address
    initialize_address_variables(@party.address)
  end

  # Load previously entered different contact address
  def load_alternate_address
    initialize_address_variables(@party.contact_address)
  end

  # Stores the company details within the account
  def store_company
    @party.company = Company.new(company_detail_params)
    unless @party.company.valid?(Company.selected_validation_contexts)
      @party.errors.merge!(@party.company.errors)
      initialize_company_variables(@party.company)
      return false
    end
    wizard_save(@party)
    true
  end

  # Loads the company details from the account
  def load_company
    initialize_company_variables(@party.company)
  end

  # stores address in the wizard cache
  def store_address
    @party.address = Address.new(address_params)
    address_valid = @party.address.valid?(address_validation_context)
    valid = non_address_party_fields_valid?(true) && address_valid
    initialize_address_variables(@party.address, search_postcode) unless valid
    wizard_save(@party) if valid
    valid
  end

  # Stores the value of radio button whether contact address is different or not
  # while searching address to display on the view
  def store_different_address_indicator
    return if filter_params.nil?

    @party.is_contact_address_different = filter_params['is_contact_address_different']
    wizard_save(@party) if contact_address_different_valid?
  end

  # Stores alternate address in case of individual party into the Lbtt wizard
  def store_alternate_address
    @party.is_contact_address_different = filter_params['is_contact_address_different']
    @party.contact_address = Address.new(address_params)

    unless address_valid?
      initialize_address_variables(@party.contact_address, search_postcode)
      return false
    end

    wizard_save(@party)
    true
  end

  # This method basically checks addeess is valid or not.
  # As this address submission is depend on parameter, so also checking value of that paramter and validation.
  # As logic is same while making changes also copy changes in  @see LbttAdsController#address_valid?
  def address_valid?
    return false unless contact_address_different_valid?
    return true if @party.is_contact_address_different == 'N'

    @party.contact_address.valid?(address_validation_context)
  end

  # Checks if the is_contact_address_different is valid
  def contact_address_different_valid?
    return true if params[:returns_lbtt_party].nil?

    @party.valid?(%i[is_contact_address_different])
  end

  # Load previously entered representative address
  def load_previous_representative_address
    initialize_address_variables(@party.org_contact_address, search_postcode)
  end

  # store the data on the page before doing an address search
  def address_pre_search
    @party.address = Address.new(address_params)
    non_address_party_fields_valid? false
  end

  # store the data on the page before doing an address search
  def representative_address_pre_search
    @party.org_contact_address = Address.new(address_params) unless params[:address].nil?
    non_address_party_fields_valid? false
  end

  # Store representative member address into the Lbtt wizard
  def store_representative_address
    @party.org_contact_address = Address.new(address_params)
    address_valid = @party.org_contact_address.valid?(address_validation_context)
    valid = non_address_party_fields_valid?(true) && address_valid
    initialize_address_variables(@party.org_contact_address, search_postcode) unless valid
    wizard_save(@party) if valid
    valid
  end

  # Check other fields validation if address is on same page with them
  def non_address_party_fields_valid?(validate)
    return true if filter_params.nil?

    # invoke validation on all parameters submitted
    @party.assign_attributes(filter_params)
    return unless validate

    validation_contexts = filter_params.keys.map(&:to_sym)
    @party.valid?(validation_contexts)
  end

  # Searches the LBTT wizard model for a party, optionally deletes it.
  # @param party_id [String] the party_id to look for
  # @param delete [Boolean] option to delete the party if found
  # @return [Party] found (or deleted)
  def look_for_party(party_id, delete = false)
    output = nil
    lbtt_return = wizard_load(Returns::LbttController)

    # search the different places we store party details (the party_id is a UUID so won't be duplicated)
    search = [lbtt_return.landlords, lbtt_return.tenants, lbtt_return.buyers, lbtt_return.sellers,
              lbtt_return.new_tenants]

    search.each do |party_location|
      output = fetch_party_from(party_location, party_id, delete)
      break unless output.nil?
    end

    # save the model if a party was deleted
    wizard_save(lbtt_return, Returns::LbttController) if delete && output

    output
  end

  private

  # Return party information from the provided lbtt return parties list if it exists @see #look_for_party.
  # @param delete [Boolean] option to delete the party
  # @return [Party] an existing party
  def fetch_party_from(parties, party_id, delete)
    return if parties.nil?

    return unless parties.key? party_id

    if delete
      Rails.logger.info("Deleting party_id #{party_id} from model")
      parties.delete(party_id)
    else
      parties.fetch(party_id)
    end
  end

  # Puts the new party data into the right place in LbttReturn
  def dump_party_into_lbtt_wizard
    @lbtt = wizard_load(Returns::LbttController)

    # pick with method to call
    method = "dump_#{@party.party_type.downcase}_into_lbtt_wizard"
    send method
    wizard_save(@lbtt, Returns::LbttController)
  end

  # @see #dump_party_into_lbtt_wizard - could do this with meta programming but this is quick and clear.
  def dump_seller_into_lbtt_wizard
    @lbtt.sellers = {} if @lbtt.sellers.nil?
    @lbtt.sellers[@party.party_id] = @party
  end

  # @see #dump_party_into_lbtt_wizard - could do this with meta programming but this is quick and clear.
  def dump_buyer_into_lbtt_wizard
    @lbtt.buyers = {} if @lbtt.buyers.nil?
    @lbtt.buyers[@party.party_id] = @party
  end

  # @see #dump_party_into_lbtt_wizard - could do this with meta programming but this is quick and clear.
  def dump_landlord_into_lbtt_wizard
    @lbtt.landlords = {} if @lbtt.landlords.nil?
    @lbtt.landlords[@party.party_id] = @party
  end

  # @see #dump_party_into_lbtt_wizard - could do this with meta programming but this is quick and clear.
  def dump_tenant_into_lbtt_wizard
    @lbtt.tenants = {} if @lbtt.tenants.nil?
    @lbtt.tenants[@party.party_id] = @party
  end

  # @see #dump_party_into_lbtt_wizard
  def dump_newtenant_into_lbtt_wizard
    @lbtt.new_tenants = {} if @lbtt.new_tenants.nil?
    @lbtt.new_tenants[@party.party_id] = @party
  end
end
