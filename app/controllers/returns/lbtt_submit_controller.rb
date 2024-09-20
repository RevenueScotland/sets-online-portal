# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for managing repayment claim
  class LbttSubmitController < ApplicationController
    include Wizard
    include ControllerHelper
    include LbttControllerFilterParamsHelper
    include LbttTaxHelper

    authorise requires: RS::AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to claim actions
    skip_before_action :require_user

    # wizard steps for the submit return
    STEPS = %w[edit_calculation_reason amendment_reason repayment_claim repayment_claim_amount
               repayment_claim_bank_details repayment_claim_declaration declaration non_notifiable
               non_notifiable_reason declaration_submitted].freeze

    # Returns/lbtt/edit_calculation_reason Asks user reason for editing tax calculation.
    # Is optionally shown if user made changes in tax calculation.
    def edit_calculation_reason
      wizard_step(nil) { { cache_index: LbttController, next_step: :edit_calculation_reason_next_step } }
    end

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
      wizard_step(nil) do
        { after_merge: :submit_return, validates: :declaration, next_step: :declaration_next_step }
      end
    end

    # returns/lbtt/non_notifiable - step in the non notifiable wizard
    def non_notifiable
      wizard_step(nil) { { cache_index: LbttController, next_step: :non_notifiable_next_step } }
    end

    # returns/lbtt/non_notifiable_reason - step in the non notifiable wizard
    # Triggers validation to ensure that non_notifiable_reason is not blank
    # Submits the return to the back office
    def non_notifiable_reason
      wizard_step(STEPS) do
        { after_merge: :submit_return, validates: :non_notifiable_reason }
      end
    end

    # Returns a path to the next step after the non_notifiable action
    def non_notifiable_next_step
      return (current_user.present? ? dashboard_path : root_path) unless @lbtt_return.non_notifiable_submit_ind?

      STEPS
    end

    # Returns a path to the next step if the return is non notifiable or not
    def declaration_next_step
      return returns_lbtt_non_notifiable_path if @lbtt_return.non_notifiable?

      returns_lbtt_declaration_submitted_path
    end

    # returns/<type>/declaration_submitted - custom final step in declaration wizard
    # (can't go in ControllerHelper as doesn't get picked up)
    def declaration_submitted
      # if unauthenticated then set the response header for clear site data to wild card
      response.set_header('Clear-Site-Data', '"storage"') if current_user.blank?
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

      if @lbtt_return.any_lease_review? && @lbtt_return.tax.tax_due_for_return < '0'
        @lbtt_return.repayment_amount_claimed = -1 * @lbtt_return.tax.tax_due_for_return.to_i
        @lbtt_return.repayment_ind = 'Y'
      end

      return model unless @lbtt_return.show_ads?

      @lbtt_return.repayment_amount_claimed ||= @lbtt_return.ads.ads_repay_amount_claimed
      model
    end

    # Returns a path to the next step after the edit_calculation_reason action
    def edit_calculation_reason_next_step
      return returns_lbtt_amendment_reason_path if @lbtt_return.amendment?

      # for lease review,assign, termination and amount payable is less than zero
      if @lbtt_return.any_lease_review? && @lbtt_return.tax.tax_due_for_return < '0'
        return returns_lbtt_repayment_claim_amount_path
      end

      returns_lbtt_declaration_path
    end

    # Returns a path to the next step after the amendment_reason action,
    def amendment_reason_next_step
      if @lbtt_return.any_lease_review? && @lbtt_return.tax.tax_due_for_return < '0'
        return returns_lbtt_repayment_claim_amount_path
      end

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
