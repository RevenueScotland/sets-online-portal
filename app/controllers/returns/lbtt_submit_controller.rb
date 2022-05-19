# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for managing repayment claim
  class LbttSubmitController < ApplicationController
    include Wizard
    include ControllerHelper
    include LbttControllerHelper

    authorise requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to claim actions
    skip_before_action :require_user

    # wizard steps for the submit return
    STEPS = %w[amendment_reason repayment_claim repayment_claim_amount repayment_claim_bank_details
               repayment_claim_declaration declaration declaration_submitted].freeze

    # returns/lbtt/amendment_reason - check if they want to request a repayment
    def amendment_reason
      wizard_step(nil) { { cache_index: LbttController, next_step: :amendment_reason_next_step } }
    end

    # returns/lbtt/repayment_claim - check if they want to request a repayment
    def repayment_claim
      wizard_step(nil) { { cache_index: LbttController, next_step: :repayment_next_step } }
    end

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
      wizard_step(STEPS) do
        { validates: :repayment_declaration,
          cache_index: LbttController }
      end
    end

    # returns/lbtt/declaration - step in declaration wizard
    # Triggers validation context :declaration since un-checked checkboxes produce empty params (so wouldn't trigger
    # the normal validation context detection).
    # Ensures the correct validation context is checked on clicking Next (ie so won't submit until declaration ticked).
    def declaration
      wizard_step(STEPS) do
        { after_merge: :submit_return, validates: :declaration }
      end
    end

    # returns/<type>/declaration_submitted - custom final step in declaration wizard
    # (can't go in ControllerHelper as doesn't get picked up)
    def declaration_submitted
      load_step # ie just load the return
    end

    private

    # Sets up variables for the form to use based on the main LBTT controller
    def load_step(sub_object_attribute = nil)
      @post_path = wizard_post_path
      @lbtt_return = wizard_load_or_redirect(returns_lbtt_summary_url, sub_object_attribute, LbttController)
      @lbtt_return
    end

    # Custom step to default the amount to claim in the ADS repayment case
    def repayment_claim_amount_setup_step
      model = load_step

      return model unless @lbtt_return.show_ads?

      @lbtt_return.repayment_amount_claimed ||= @lbtt_return.ads.ads_repay_amount_claimed
      model
    end

    # Returns a path to the next step after the amendment_reason action,
    def amendment_reason_next_step
      return returns_lbtt_declaration_path unless @lbtt_return.show_repayment?

      STEPS
    end

    # Decide what the next step will be after the repayment_claim action, either into the claim wizard or
    # straight on to the LBTT declaration page.
    def repayment_next_step
      return returns_lbtt_declaration_path unless @lbtt_return.repayment_ind?

      STEPS
    end

    # Send the return to the back office (and wizard_save unless there were errors returned.)
    # @return [Boolean] true if successful
    def submit_return
      return false unless @lbtt_return.prepare_to_save_latest

      # Save the prepared return in the cache in case the user navigates back and re-tries
      wizard_save(@lbtt_return, LbttController)
      success = @lbtt_return.save_latest(current_user)
      # need to save even if not successful so the saved flag is cleared
      wizard_save(@lbtt_return, LbttController)
      success
    end
  end
end
