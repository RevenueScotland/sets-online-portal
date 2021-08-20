# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for agent management- for editing agent details involved in lbtt return
  class LbttAgentController < ApplicationController
    include Wizard
    include WizardAddressHelper

    authorise requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to parties actions
    skip_before_action :require_user

    # store step flow of lbtt agent  page name used for navigation
    AGENT_STEPS = %w[agent_details agent_address summary].freeze

    # wizard step lbtt/agent_details
    # First step in the wizard, sets up model etc
    def agent_details
      wizard_step(AGENT_STEPS) { { setup_step: :setup_step } }
    end

    # wizard step lbtt/agent_address - last step in the wizard so #store_address also copies data into the Lbtt wizard
    def agent_address
      wizard_address_step(returns_lbtt_summary_path, after_merge: :store_agent_into_lbtt_wizard)
    end

    private

    # save agent into lbtt return wizard
    # @return [Boolean] true if successful
    def store_agent_into_lbtt_wizard
      # load lbtt wizard and save agent details into it and finally save lbtt_return wizard in cache.
      lbtt_return = wizard_load_or_redirect(returns_lbtt_summary_url, nil, LbttController)
      lbtt_return.agent = @agent
      wizard_save(lbtt_return, LbttController)
      true
    end

    # Loads existing agent info (into @agent)
    # The parameter 'new' indicates this is the first call on the wizard so copy information from the cached lbtt_return
    # On subsequent steps it returns the result of @see #load_step
    # @return model to use on the form/wizard
    def setup_step
      # First time it loads details from lbtt object where it has already pre populated details from account
      # we use the party id of new to tell is if we need to re-load or not
      if params[:party_id] == 'new'
        @agent = wizard_load_or_redirect(returns_lbtt_summary_url, nil, LbttController).agent
        # make sure party type is set to agent
        @agent.party_type = 'AGENT'
        wizard_save(@agent)
        return @agent
      end

      load_step
    end

    # Loads existing wizard models from the wizard cache or redirects to the summary page
    # @return model to use on the form/wizard
    def load_step(_sub_object_attribute = nil)
      @agent = wizard_load_or_redirect(returns_lbtt_summary_url)
    end

    # Return the parameter list filtered for the attributes of the Party model
    def filter_params(_sub_object_attribute = nil)
      required = :returns_lbtt_party
      attribute_list = Lbtt::Party.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
