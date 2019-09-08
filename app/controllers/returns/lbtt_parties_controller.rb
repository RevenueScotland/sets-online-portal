# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for parties management- for adding/editing buyers/ sellers details involved in lbtt return
  class LbttPartiesController < ApplicationController # rubocop:disable Metrics/ClassLength
    include AddressHelper
    include Wizard
    include LbttPartiesHelper
    include CompanyHelper

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
      wizard_step(nil) do
        { params: :filter_params, next_step: :about_the_party_next_steps }
      end
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
      wizard_step(INDVAL_STEPS) { { params: :filter_params } }
    end

    # Party wizard - individual steps page
    # Calls @see #next_page_or_summary to save the data and skip to the summary for certain types of party
    def party_address
      # important that :next_page_or_summary is passed as a next_step pointer so it doesn't get resolved before
      # :store_address - ie don't want to copy party data and redirect before we've saved the address into the party
      wizard_address_step(nil, :store_address, load_address: :load_previous_address, next_step: :next_page_or_summary)
    end

    # Party wizard - individual steps last page
    def party_alternate_address
      wizard_address_step(INDVAL_STEPS, :store_alternate_address,
                          load_address: :load_alternate_address, pre_search: :store_different_address_indicator)
    end

    # Party wizard - parties relationship page
    def parties_relation
      wizard_step(returns_lbtt_acting_as_trustee_path) { { params: :filter_params } }
    end

    # Representative acting as either trustee or representative for tax purposes.
    # Final step in the wizards, copies the party data into the LBTT wizard cache at the end.
    def acting_as_trustee
      wizard_step(returns_lbtt_summary_path) { { params: :filter_params, after_merge: :dump_party_into_lbtt_wizard } }
    end

    # Party wizard - company steps page
    # A next step is added as we don't want to go to the contact details page for Seller/Landlord
    def company_number
      wizard_company_step(nil, :store_company, load_company: :load_company, next_step: :next_page_or_summary)
    end

    # Party wizard - company steps page
    def organisation_contact_details
      wizard_address_step(REG_COMPANY_STEPS, :store_representative_address,
                          load_address: :load_previous_representative_address,
                          pre_search: :representative_address_pre_search)
    end

    # Party wizard - organisation steps page
    # Clear previously stored organisation details on pages after organisation_type_details page if type is changed
    # If user edit organisation details and changed type from "Trust" to "Club" on organisation_type_details
    # then clear details related to trust, so user can see blank option on next pages to enter club details.
    def organisation_type_details
      setup_step
      return unless params[:submitted]

      reset_party_details if filter_params.present? && @party.org_type != filter_params[:org_type]
      wizard_step_submitted(OTHER_ORG_STEPS, params: :filter_params)
    end

    # Party wizard - organisation steps page @see #next_page_or_summary
    def organisation_details
      wizard_address_step(nil, :store_address,
                          load_address: :load_previous_address, pre_search: :address_pre_search,
                          next_step: :next_page_or_summary)
    end

    # Party wizard - organisation steps page
    def representative_contact_details
      # @see party_address
      wizard_address_step(OTHER_ORG_STEPS, :store_representative_address,
                          load_address: :load_previous_representative_address,
                          pre_search: :representative_address_pre_search)
    end

    # Delete the party entry entry specified by params[:party_id]
    def delete
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

    # Return the parameter list filtered for the attributes of the SlftReturn model
    def filter_params
      required = :returns_lbtt_party
      attribute_list = Lbtt::Party.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end

    # Sets up @party for this wizard/form to use (where to post the form to).
    # If party_id is provided in params then will load that party from the LBTT wizard and save in this wizard.
    # Otherwise it will load from the wizard (ie the current party) (no extra saving needed).
    # Otherwise it's a new one, and will use party_id from the params and save it in this wizard.
    # (The first step clears the cache before calling this so shouldn't ever see the wrong party's data!)
    # @return [Party] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path(LbttController.name)
      load_party

      # @party MUST have a party_id at this point or we've done something wrong
      raise Error::AppError.new('Party', 'Missing party_id') if @party.party_id.nil?

      Rails.logger.debug("Loaded party #{@party.party_id}")

      @party
    end

    # Loads @party info if available in the wizard cache. @See #setup_step
    # Parties are indexed by UUID so we don't get the wrong one when editing or deleting them.
    def load_party
      party_id = params[:party_id]
      if party_id

        # new party case - assign a UUID
        @party = Lbtt::Party.new(party_id: SecureRandom.uuid, party_type: params[:party_type]) if party_id == 'new'

        # or lookup the existing party by it's ID (which is a UUID)
        @party ||= look_for_party(party_id)

        # save the newly loaded party into this wizard's cache ready for the next step
        wizard_save(@party)
      else
        @party = wizard_load
      end
      @party
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
  end
end
