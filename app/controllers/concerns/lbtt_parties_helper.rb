# frozen_string_literal: true

# Helper class to support functionality to LbttPartiesController
module LbttPartiesHelper
  extend ActiveSupport::Concern

  # Searches the LBTT wizard model for a party, optionally deletes it.
  # @param party_id [String] the party_id to look for
  # @param delete [Boolean] option to delete the party if found
  # @return [Party] found (or deleted)
  def look_for_party(party_id, delete: false)
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
  # @return [Boolean] true if successful
  def dump_party_into_lbtt_wizard
    @lbtt = wizard_load(Returns::LbttController)

    party_list = @lbtt.send(@party.lbtt_return_attribute)

    # if the party_list is nil then we need to set the right attribute to a known object
    if party_list.nil?
      # setting empty hash in known Object
      @lbtt.send("#{@party.lbtt_return_attribute}=", party_list = {})
    end

    # saves the party details inside known object of lbtt controller
    party_list[@party.party_id] = @party
    wizard_save(@lbtt, Returns::LbttController)
    wizard_end # clears the party wizard
    true
  end
end
