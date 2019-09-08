# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for agent management- for editing agent details involved in lbtt return
  class LbttAgentController < ApplicationController
    include AddressHelper
    include Wizard

    authorise requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to parties actions
    skip_before_action :require_user

    # store step flow of lbtt agent  page name used for navigation
    AGENT_STEPS = %w[agent_details agent_address summary].freeze

    # wizard step lbtt/agent_details
    def agent_details
      wizard_step(AGENT_STEPS) { { params: :filter_params } }
    end

    # wizard step lbtt/agent_address - last step in the wizard so #store_address also copies data into the Lbtt wizard
    def agent_address
      wizard_address_step(returns_lbtt_summary_path, :store_address, load_address: 'load_previous_address')
    end

    private

    # Load previously entered address
    def load_previous_address
      if @agent.address.nil?
        initialize_address_variables
      else
        initialize_address_variables(@agent.address)
      end
    end

    # Loads existing agent info (into @agent) if available in the wizard cache.
    # First it take already preloaded details from lbtt controller (wizard_load(LbttController).agent)
    # In case when user modify some pre loaded details it load from in its own cache(wizard_load)
    # and finally at end of wizard in store into lbtt cache (see store_agent_into_lbtt_wizard )
    # @return @agent object to use on the form
    def setup_step
      # First time it load details from lbtt object where it already prepopulate details from account
      if params[:party_id]
        @agent = wizard_load(LbttController).agent
        wizard_save(@agent)
      else
        @agent = wizard_load
      end
      @agent
    end

    # Store address in the cache and since this the last step, store the agent in the LbttReturn wizard cache
    def store_address
      @agent.address = Address.new(address_params.to_h)
      unless @agent.address.valid?(address_validation_context)
        initialize_address_variables(@agent.address, search_postcode)
        return false
      end
      # store agent finally into lbtt return wizard
      store_agent_into_lbtt_wizard
      true
    end

    # save agent into lbtt return wizard
    def store_agent_into_lbtt_wizard
      # save agent address first in agent wizard
      wizard_save(@agent)
      # load lbtt wizard and save agent details into it and finally save lbtt_return wizard in cache.
      lbtt_return = wizard_load(LbttController)
      lbtt_return.agent = wizard_load
      # While submitting data to back-office, it is necessary to set party_type to differentiate. Hence, hard coded here
      lbtt_return.agent.party_type = 'AGENT'
      wizard_save(lbtt_return, LbttController) unless @agent.errors.any?
    end

    # Return the parameter list filtered for the attributes of the SlftReturn model
    def filter_params
      required = :returns_lbtt_party
      attribute_list = Lbtt::Party.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
