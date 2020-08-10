# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for parties management- for adding/editing buyers/ sellers details involved in lbtt return
  class LbttPartiesController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include WizardAddressHelper
    include LbttPartiesHelper
    include WizardCompanyHelper

    authorise requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to parties actions
    skip_before_action :require_user

    # Navigation page flow for party wizard pages depending on party type like club, company or individual
    # For Individual wizard steps
    INDVAL_STEPS = %w[about_the_party party_details party_address party_alternate_address parties_relation
                      acting_as_trustee summary].freeze

    # For Company wizard steps
    REG_COMPANY_STEPS = %w[about_the_party company_number organisation_contact_details parties_relation
                           acting_as_trustee summary].freeze

    # For other organisation wizard steps
    OTHER_ORG_STEPS = %w[about_the_party organisation_type_details organisation_details
                         representative_contact_details parties_relation acting_as_trustee summary].freeze

    # @see about_the_party_next_step
    STEP_CHOICES = { 'PRIVATE' => INDVAL_STEPS, 'REG_COM' => REG_COMPANY_STEPS,
                     'OTHERORG' => OTHER_ORG_STEPS }.freeze

    # Party wizard page
    # Depending on selection of radio button, next page flow decide
    def about_the_party
      wizard_step(nil) { { setup_step: :setup_step, next_step: :about_the_party_next_steps } }
    end

    # Party wizard - individual steps page
    def party_details
      # If the NINO is entered then we shouldn't have to store the data about the country on does not have a NINO.
      party_details_hash = params[:returns_lbtt_party]
      unless party_details_hash.nil?
        params[:returns_lbtt_party][:ref_country] = '' if !party_details_hash[:nino].blank? &&
                                                          party_details_hash[:alrt_type].blank? &&
                                                          party_details_hash[:alrt_reference].blank?
      end
      wizard_step(INDVAL_STEPS)
    end

    # Party wizard - individual steps page
    # Calls @see #next_page_or_summary to save the data and skip to the summary for certain types of party
    def party_address
      # important that :next_page_or_summary is passed as a next_step pointer so it doesn't get resolved before
      # :store_address - ie don't want to copy party data and redirect before we've saved the address into the party
      wizard_address_step(nil, next_step: :next_page_or_summary)
    end

    # Party wizard - individual steps last page
    def party_alternate_address
      wizard_address_step(INDVAL_STEPS, address_attribute: :contact_address,
                                        address_required: :is_contact_address_different)
    end

    # Party wizard - parties relationship page
    def parties_relation
      wizard_step(returns_lbtt_acting_as_trustee_path)
    end

    # Representative acting as either trustee or representative for tax purposes.
    # Final step in the wizards, copies the party data into the LBTT wizard cache at the end.
    def acting_as_trustee
      wizard_step(returns_lbtt_summary_path) { { after_merge: :dump_party_into_lbtt_wizard } }
    end

    # Party wizard - company steps page
    # A next step is added as we don't want to go to the contact details page for Seller/Landlord
    def company_number
      wizard_company_step(nil, next_step: :next_page_or_summary)
    end

    # Party wizard - company steps page
    def organisation_contact_details
      wizard_address_step(REG_COMPANY_STEPS, address_attribute: :org_contact_address)
    end

    # Party wizard - organisation steps page
    # Clear previously stored organisation details on pages after organisation_type_details page if type is changed
    # If user edit organisation details and changed type from "Trust" to "Club" on organisation_type_details
    # then clear details related to trust, so user can see blank option on next pages to enter club details.
    def organisation_type_details
      load_step
      return unless params[:continue]

      reset_party_details if filter_params.present? && @party.org_type != filter_params[:org_type]
      wizard_step_submitted(OTHER_ORG_STEPS)
    end

    # Party wizard - organisation steps page @see #next_page_or_summary
    def organisation_details
      wizard_address_step(nil, next_step: :next_page_or_summary)
    end

    # Party wizard - organisation steps page
    def representative_contact_details
      # @see party_address
      wizard_address_step(OTHER_ORG_STEPS, address_attribute: :org_contact_address)
    end

    # Delete the party entry entry specified by params[:party_id]
    def destroy
      look_for_party(params[:party_id], delete: true)
      redirect_to returns_lbtt_summary_path
    end

    private

    # @return the next steps list to use given the choice made on the about_the_party page
    def about_the_party_next_steps
      params = filter_params
      return INDVAL_STEPS if params.nil?

      Rails.logger.debug("Chosen party type is #{params[:type]}")
      STEP_CHOICES[params[:type]]
    end

    # For buyer and tenant party, next page will be whatever's defined in the appropriate steps list @see STEP_CHOICES.
    # For landlord and seller, save the party data into the LBTT wizard and skip to summary page.
    def next_page_or_summary
      # need to load party object here otherwise it returns nil
      @party = wizard_load
      if %w[TENANT NEWTENANT BUYER].include?(@party.party_type)
        STEP_CHOICES[@party.type]
      else
        dump_party_into_lbtt_wizard
        returns_lbtt_summary_path
      end
    end

    # Stores required data like party_id, party_type selected in previous pages and then clears all other party details
    # by creating a new Party object with the same party_id and party_type.
    def reset_party_details
      # Stores necessary details before clearing
      party_id = @party.party_id
      party_type = @party.party_type
      type = @party.type

      # restore back original party
      @party = Lbtt::Party.new(party_id: party_id, party_type: party_type, type: type)
      wizard_save(@party)
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # Parties are indexed by UUID so we don't get the wrong one when editing or deleting them.
    # Follows the same pattern as @see LbttPropertiesController#setup_step
    # @raise [Error::AppError] if the party_id is missing (provided as a param)
    # @return [Party] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path(LbttController.name)

      party_id, party_type = about_the_party_params
      setup_party(party_id, party_type)

      # @party MUST have a party_id at this point or we've done something wrong
      raise Error::AppError.new('Party', 'Missing party_id') if @party.party_id.nil?

      # save the newly loaded party into this wizard's cache ready for the next step
      wizard_save(@party)

      Rails.logger.debug("Loaded party #{@party.party_id}")
      @party
    end

    # Called by setup_step to setup or re-load @party
    def setup_party(party_id, party_type)
      @party = if party_id == 'new' && !party_type.nil?
                 # Add a buyer/seller/tenant/new-tenant/landlord
                 # New party case - assign a UUID
                 Lbtt::Party.new(party_id: SecureRandom.uuid, party_type: party_type)
               elsif !party_id.nil? && party_id != 'new'
                 # Click on the Edit row - triggers when user wants to edit a party.
                 # or lookup the existing party by it's ID (which is a UUID)
                 look_for_party(party_id)
               else
                 # When we come back to the about the party page after either an add or edit, so we don't
                 # refresh either the re-loading of the party details or creation of the new party object.
                 #
                 # Moreover, the reason why we don't want the reloading to happen is because the data
                 # only gets merged back into the cache after the 'Add a <party_type>' or 'Edit row' flow of
                 # pages has finished. This means that if we do re-load the party details, then we overwrite all
                 # the new edits we have done (if there's any) on this instance of Edit row.
                 #
                 # This is also the normal load from cache. if it didn't get setup above.
                 wizard_load
               end

      # assign hash of used NINO'S to hash_for_nino
      lbtt_return = wizard_load(LbttController)
      @party.hash_for_nino = lbtt_return.list_of_used_ninos(@party.nino)

      @party
    end

    # Loads existing wizard models from the wizard cache or redirects to the summary page
    # (The first step clears the cache and loads a specific party so this shouldn't ever see the wrong party's data!
    # @see #setup_step)
    # @return [Party] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path(LbttController.name)
      @party = wizard_load_or_redirect(returns_lbtt_summary_url)
    end

    # Return the parameter list filtered for the attributes of the Party model
    def filter_params(_sub_object_attribute = nil)
      required = :returns_lbtt_party
      attribute_list = Lbtt::Party.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end

    # Parameters used in the about the party page.
    def about_the_party_params
      [params[:party_id], params[:party_type]]
    end
  end
end
