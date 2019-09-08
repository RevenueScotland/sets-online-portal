# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller class for SLfT (Scottish Landfill Tax) return
  class SlftController < ApplicationController # rubocop:disable Metrics/ClassLength
    # Wizard controller - allows fast generation of wizards storing merged parameters which can be converted
    # to FLApplication objects with the appropriate .new call.  Downside is when we load an object graph,
    # only the top level is created as that object (eg SlftReturn.new(wizard_load) makes a SlftReturn object
    # but the sites field will contain a hash of hashes and not a hash of Site objects).  Getting round
    # that is not worth the effort - at the moment it's only convenient to use the whole object graph in views
    # so conversion will be required as views are being set up (@see #sites).
    include Wizard
    include ControllerHelper

    authorise requires: AuthorisationHelper::SLFT_SUMMARY
    authorise route: :load, requires: AuthorisationHelper::SLFT_CONTINUE + AuthorisationHelper::SLFT_AMEND +
                                      AuthorisationHelper::SLFT_LOAD
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

      # check the model's data rules and update model (not calling clean_up_yes_nos because don't want to lose
      # text data, for fields associated with 'No' answers, at this point)
      summary_normal_setup

      # explicitly save the model in the wizard cache given the above calls which could have changed it
      wizard_save(@slft_return)

      # manage the buttons AFTER wizard_save so we don't save the validation errors
      return if manage_draft(@slft_return) || manage_calculate(@slft_return)

      # Setup summaries and pass the model path to re-use the relevant translations
      @transaction_summary = @slft_return.transaction_summary('activemodel.attributes.returns/slft/slft_return')
      @credit_summary = @slft_return.credit_summary('activemodel.attributes.returns/slft/slft_return')
    end

    # returns/slft/declaration_calculation
    # Custom step in declaration wizard to get the calculation before showing the page (and then storing it in the
    # wizard cache so we don't get it again unless the declaration_calculation page is visited again).
    # If the return is an amendment then the next page is declaration_repayment to give the user an option to do a
    # repayment.
    def declaration_calculation
      # do the submitted part first to get it out of the way
      if params[:submitted]
        wizard_step_submitted(nil, params: :filter_params, next_step: :declaration_calculation_next_step)
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
      wizard_step(nil) { { params: :filter_params, next_step: :declaration_repayment_next_step } }
    end

    # returns/slft/declaration - step in declaration wizard
    def declaration
      wizard_step(DECLARATION_STEPS) { { params: :filter_params, after_merge: :submit_return } }
    end

    # returns/<type>/declaration_submitted - custom final step in declaration wizard
    # (can't go in ControllerHelper as doesn't get picked up)
    def declaration_submitted
      setup_step # ie just load the return
    end

    # Cleans and saves the return by sending to the back office.
    def save_draft
      Rails.logger.debug('Actioning Save Draft')
      @slft_return = wizard_load
      Rails.logger.debug('Wizard Loaded')
      @slft_return.clean_up_yes_nos
      Rails.logger.debug('About to Save')
      @slft_return.save_draft(current_user)
      Rails.logger.debug('Out of Save')
      @post_path = '.'
      wizard_save(@slft_return)
    end

    # Loads an existing return and shows the summary screen or else an error page
    def load
      validate_load_param

      # load it
      @slft_return = Slft::SlftReturn.find(:slft_tax_return_details, params[:ref_no], current_user,
                                           :slft_tax_return) do |data|
        Slft::SlftReturn.new_from_fl(data)
      end

      Rails.logger.info("Loaded SLfT #{@slft_return}")

      # store in wizard (replaces anything that was there before)
      wizard_save(@slft_return)

      # run summary page
      redirect_to action: :summary
    end

    private

    # Extracted summary method
    # Unless it's a new slft return, cleans the data based on business rules so the summary will be correct.
    def summary_normal_setup
      download_sites_if_needed

      return if params[:new]

      Rails.logger.debug('Normal summary page')
      @slft_return.clean_up_money
      @slft_return.clean_up_yes_nos
    end

    # Send the return to the back office (and wizard_save unless there were errors returned.)
    def submit_return
      @slft_return.save_latest(current_user)
      wizard_save(@slft_return) unless @slft_return.errors.any?
    end

    # Sets up variables for the form to use (where to post the form to).
    # @return [SlftReturn] the model for wizard saving
    def setup_step
      @slft_return = wizard_load || Slft::SlftReturn.new

      # clear the declaration fields forcing them to tick it each time (and also make the 'accept' validation work)
      @slft_return.declaration = false if action_name == 'declaration'
      @slft_return.rrep_bank_auth_ind = false if action_name == 'repayment_declaration'

      @post_path = wizard_post_path
      @slft_return
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
      return REPAYMENT_STEPS if @slft_return.repayment_yes_no == 'Y'

      returns_slft_declaration_path
    end

    # Populates sites information if not present in @slft_return, and updates @slft_return in the wizard_cache
    # (so the sites data is also immediately available to the @see SlftSitesWasteController).
    def download_sites_if_needed
      return unless @slft_return.sites.nil?

      sites = {}
      Slft::Site.all(current_user).each do |site|
        sites[site.lasi_refno] = site
      end

      # if sites.keys list is empty then back office/cache provided invalid data
      Rails.logger.debug("Loading downloaded SLfT sites data #{sites.keys}")
      @slft_return.sites = sites
    end

    # Return the parameter list filtered for the attributes of the SlftReturn model.
    # Special case for the repayment declaration, since it's the only thing on the page we need to treat
    # its absence as a value of false.
    def filter_params
      required = :returns_slft_slft_return
      output = {}
      output = params.require(required).permit(Slft::SlftReturn.attribute_list) if params[required]

      return output unless action_name == 'repayment_declaration'

      output[:rrep_bank_auth_ind] = false if output[:rrep_bank_auth_ind].blank?

      output
    end
  end
end
