# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for managing repayment claim
  class LbttClaimController < ApplicationController
    include Wizard
    include LbttControllerHelper

    authorise requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to claim actions
    skip_before_action :require_user

    # wizard steps for the repayment claim
    STEPS = %w[repayment_claim_amount repayment_claim_bank_details repayment_claim_declaration].freeze

    # returns/lbtt/repayment_claim_amount - step in the repayment claim wizard
    def repayment_claim_amount
      wizard_step(STEPS) { { setup_step: :repayment_claim_amount_setup_step, cache_index: LbttController } }
    end

    # returns/lbtt/repayment_claim_bank_details - step in the repayment claim wizard
    def repayment_claim_bank_details
      wizard_step(STEPS) { { cache_index: LbttController } }
    end

    # returns/lbtt/repayment_claim_declaration - last step in the repayment claim wizard
    # After this the next step is the main declarations page
    # Ensures the correct validation context is checked on clicking Next (ie so won't submit until declaration ticked).
    def repayment_claim_declaration
      wizard_step(returns_lbtt_declaration_path) do
        { setup_step: :repayment_claim_declaration_setup_step, validates: :repayment_declaration,
          cache_index: LbttController }
      end
    end

    # returns/lbtt/repayment_claim - check if they want to request a repayment
    def repayment_claim
      wizard_step(nil) { { cache_index: LbttController, next_step: :repayment_next_step } }
    end

    private

    # Sets up variables for the form to use based on the main LBTT controller
    def load_step
      @post_path = wizard_post_path(LbttController.name)
      @lbtt_return = wizard_load_or_redirect(returns_slft_summary_url, Returns::LbttController)
    end

    # Custom step to default the amount to claim in the ADS repayment case
    def repayment_claim_amount_setup_step
      model = load_step

      return model unless @lbtt_return.show_ads?

      @lbtt_return.repayment_amount_claimed ||= @lbtt_return.ads.ads_repay_amount_claimed
      model
    end

    # Custom setup step to clear the declaration fields forcing them to tick it each time.
    # @return [LbttReturn] result from load_step
    def repayment_claim_declaration_setup_step
      model = load_step
      @lbtt_return.repayment_declaration = false
      @lbtt_return.repayment_agent_declaration = false

      model
    end

    # Decide what the next step will be after the repayment_claim action, either into the claim wizard or
    # straight on to the LBTT declaration page.
    def repayment_next_step
      return returns_lbtt_declaration_path if @lbtt_return.repayment_ind == 'N'

      ['repayment_claim', STEPS.first]
    end
  end
end
