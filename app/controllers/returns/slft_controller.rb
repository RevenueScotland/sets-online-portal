# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller class for SLfT (Scottish Landfill Tax) return
  class SlftController < ApplicationController
    # Wizard controller - allows fast generation of wizards storing merged parameters which can be converted
    # to FLApplication objects with the appropriate .new call.  Downside is when we load an object graph,
    # only the top level is created as that object (eg SlftReturn.new(wizard_load) makes a SlftReturn object
    # but the sites field will contain a hash of hashes and not a hash of Site objects).  Getting round
    # that is not worth the effort - at the moment it's only convenient to use the whole object graph in views
    # so conversion will be required as views are being set up (@see #sites).
    include Wizard
    include ControllerHelper
    include DownloadHelper

    authorise requires: AuthorisationHelper::SLFT_SUMMARY
    authorise route: :save_draft, requires: AuthorisationHelper::SLFT_SAVE

    # wizard steps for the CREDIT simple wizard in order; to end a wizard go to summary
    CREDIT_STEPS = %w[credit_environmental credit_bad_debt credit_site_specific summary].freeze
    # wizard steps for the TRANSACTION simple wizard
    T_ACTION_STEPS = %w[transaction_period transaction_new_non_disposal transaction_ceased_non_disposal summary].freeze
    # wizard steps for the DECLARATION wizard
    DECLARATION_STEPS = %w[declaration_calculation declaration declaration_submitted].freeze
    # wizard steps for the REPAYMENT wizard
    REPAYMENT_STEPS = %w[declaration_repayment repayment_bank_details repayment_declaration declaration].freeze

    authorise route: DECLARATION_STEPS, requires: AuthorisationHelper::SLFT_SUBMIT

    # Define simple wizard actions, ie each of these makes a wizard_step calling action
    standard_wizard_step_actions(CREDIT_STEPS, %i[credit_environmental credit_bad_debt credit_site_specific])
    transaction_actions = %i[transaction_period transaction_new_non_disposal
                             transaction_ceased_non_disposal]
    standard_wizard_step_actions(T_ACTION_STEPS, transaction_actions)
    standard_wizard_step_actions(REPAYMENT_STEPS, %i[repayment_bank_details repayment_declaration declaration])

    # Summary of returns.
    # If params[:new] is set/true then calls wizard_end to ensure any previous SLfT return is cleared.
    # Downloads the list of sites, manages the Save draft and Calculate buttons, cleans summary data and saves the
    # model in the wizard_cache.
    def summary
      # do extra setup for new returns to clear wizard cache _before_ setup_step is called
      # so we don't populate @ variables with old data!
      if params[:new]
        Rails.logger.debug('Starting new SLfT return')
        wizard_end
      end

      setup_step

      # Need to save on the summary to make sure that we have a new return if one was created
      wizard_save(@slft_return)

      # manage the buttons AFTER wizard_save so we don't save the validation errors
      return if manage_draft(@slft_return) || manage_calculate(@slft_return)
    end

    # returns/slft/declaration_calculation
    # Custom step in declaration wizard to get the calculation before showing the page (and then storing it in the
    # wizard cache so we don't get it again unless the declaration_calculation page is visited again).
    # If the return is an amendment then the next page is declaration_repayment to give the user an option to do a
    # repayment.
    def declaration_calculation
      # do the submitted part first to get it out of the way
      if params[:continue]
        wizard_step_submitted(nil, next_step: :declaration_calculation_next_step)
        return # can't use && guard clause as wizard_step_submitted returns nil
      end

      setup_step

      # do/download calculations into model and store in wizard
      @slft_return.calculate_tax(current_user)

      # don't store if back office sent errors
      wizard_save(@slft_return) unless @slft_return.errors.any?
    end

    # returns/slft/declaration-repayment - step in declaration wizard which can switch to repayments wizard
    def declaration_repayment
      wizard_step(nil) { { next_step: :declaration_repayment_next_step } }
    end

    # returns/slft/declaration - step in declaration wizard
    def declaration
      wizard_step(DECLARATION_STEPS) { { after_merge: :submit_return } }
    end

    # returns/<type>/declaration_submitted - custom final step in declaration wizard
    # (can't go in ControllerHelper as doesn't get picked up)
    def declaration_submitted
      setup_step # ie just load the return
    end

    # The method used to retrieve the pdf summary of the return
    def download_receipt
      @slft_return = wizard_load
      success, attachment = Dashboard::DashboardReturn.return_pdf(current_user,
                                                                  @slft_return.back_office_receipt_request, 'Receipt')
      return unless success

      # Download the file
      send_file_from_attachment(attachment[:document_return])
    rescue StandardError => e
      Rails.logger.error(e)
      redirect_to controller: '/home', action: 'file_download_error'
    end

    # Cleans and saves the return by sending to the back office.
    def save_draft
      Rails.logger.debug('Actioning Save Draft')
      @slft_return = wizard_load
      Rails.logger.debug('Wizard Loaded')
      @slft_return.save_draft(current_user)
      Rails.logger.debug('Out of Save')
      @post_path = '.'
      wizard_save(@slft_return)
    end

    private

    # Send the return to the back office (and wizard_save unless there were errors returned.)
    # @return [Boolean] true if successful
    def submit_return
      return false unless @slft_return.prepare_to_save_latest

      # Save the prepared return in the cache in case the user navigates back and re-tries
      wizard_save(@slft_return)
      success = @slft_return.save_latest(current_user)
      # need to save even if not successful so the saved flag is cleared
      wizard_save(@slft_return)
      success
    end

    # Works out which steps to follow based on whether or not the return is an amendment.
    # @return If repayment is an amendment then returns the declaration_repayment page
    #         otherwise it's the DECLARATION_STEPS.
    def declaration_calculation_next_step
      @slft_return.amendment? ? returns_slft_declaration_repayment_path : DECLARATION_STEPS
    end

    # Works out which steps to follow based on whether or not the user has selected to do a repayment.
    # @return If repayment has been ticked then returns the REPAYMENT_STEPS otherwise it's the declaration page.
    def declaration_repayment_next_step
      return REPAYMENT_STEPS if @slft_return.repayment_details_needed?

      returns_slft_declaration_path
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # @return [SlftReturn] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path
      @slft_return = wizard_load || Slft::SlftReturn.new(current_user: current_user)
    end

    # Loads existing wizard models from the wizard cache or redirects to the summary page
    # @return [SlftReturn] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @slft_return = wizard_load_or_redirect(returns_slft_summary_url)

      # clear the declaration fields forcing them to tick it each time (and also make the 'accept' validation work)
      @slft_return.declaration = false if action_name == 'declaration'
      @slft_return.rrep_bank_auth_ind = false if action_name == 'repayment_declaration'

      @post_path = wizard_post_path
      @slft_return
    end

    # Return the parameter list filtered for the attributes of the SlftReturn model.
    # Special case for the repayment declaration, since it's the only thing on the page we need to treat
    # its absence as a value of false.
    def filter_params(_sub_object_attribute = nil)
      required = :returns_slft_slft_return
      output = {}
      output = params.require(required).permit(Slft::SlftReturn.attribute_list) if params[required]

      return output unless action_name == 'repayment_declaration'

      output[:rrep_bank_auth_ind] = false if output[:rrep_bank_auth_ind].blank?

      output
    end
  end
end
