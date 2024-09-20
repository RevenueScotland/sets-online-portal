# frozen_string_literal: true

# Concerns for returns
module Returns
  # Helpful method to load agent, common to LBTT controllers.
  module LbttControllerLoadAgentHelper
    extend ActiveSupport::Concern

    # Load agent contact data (or populate with @see Party#populate_from_account) into @agent.
    # If there is no user then an blank @agent will be set up (ie the public user case).
    def load_agent
      # load agent data from current user if its blank
      if @lbtt_return.agent.nil?
        @lbtt_return.agent = Lbtt::Party.new(party_type: 'AGENT')
        # get login user details to pre-populate details for agent section
        # skip this step if there isn't a logged in user
        @lbtt_return.agent.populate_from_account(Account.find(current_user))
      end

      @agent = @lbtt_return.agent
    end
  end
end
