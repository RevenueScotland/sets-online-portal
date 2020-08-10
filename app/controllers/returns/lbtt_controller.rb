# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller class for Lbtt (Land and Buildings Transaction Tax) return
  # Lbtt return controller maintain(add/edit details) the information about parties (buyer, seller or agent,
  # calculation and transaction) transacting for properties.
  # It also keeps all details of the properties.
  class LbttController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include WizardListHelper
    include ControllerHelper
    include LbttControllerHelper
    include LbttTaxHelper
    include DownloadHelper

    # all public pages, not just wizard steps for the public part of LBTT
    PUBLIC_PAGES = %I[public_landing public_return_type return_reference_number summary
                      declaration declaration_submitted].freeze

    authorise requires: AuthorisationHelper::LBTT_SUMMARY
    authorise routes: PUBLIC_PAGES, requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    authorise route: :save_draft, requires: AuthorisationHelper::LBTT_SAVE
    # Allow unauthenticated/public access to specific actions - NB do not put return_type here, want that
    # to require authentication so we don't mix the two up
    skip_before_action :require_user, only: PUBLIC_PAGES

    # navigation steps in the lbtt conveyance and lease return wizard
    CONVEY_LEASERET_STEPS = %w[return_type summary].freeze

    # navigation steps in the lbtt lease review, assignation and termination wizard
    LEASE_REV_ASSIGN_TERMINATE_STEPS = %w[return_type return_reference_number summary].freeze

    # declaration steps
    DECLARATION_STEPS = %w[declaration declaration_submitted].freeze

    # publicly available steps (feeds into the steps above)
    PUBLIC_STEPS = %w[landing_public public_return_type return_reference_number summary].freeze

    # this can't be defined in authorise.rb, otherwise rails throws an error
    helper_method :public

    # Does the account have a dd instruction
    # @return [String] returns true if the account has the service otherwise false
    def account_has_dd_instruction?
      return false if current_user.nil?

      @account ||= Account.find(current_user)
      @account.dd_instruction_available
    end
    helper_method :account_has_dd_instruction?

    # reliefs calculation
    def reliefs_calculation
      wizard_list_step(returns_lbtt_summary_url,
                       merge_list: :merge_relief_list_data,
                       after_merge: :update_relief_type_calculation,
                       list_attribute: :relief_claims, new_list_item_instance: :new_list_item_relief_claims)
    end

    # Summary of returns.
    def summary
      load_step

      clean_on_new_type

      summary_clean_up_setup

      load_party_summary

      # methods above could have updated the return so save it to give wizards access to the new data
      wizard_save(@lbtt_return)

      # manage the buttons AFTER wizard_save so we don't save the validation errors
      return if manage_draft(@lbtt_return) || manage_submit
    end

    # Setting lbtt return type - custom step which clears the wizard cache before it starts a new return
    # (ie not when changing the type of an existing one).
    def return_type
      # When the user has clicked on the Create lbtt return button, the return type would be a new one, so
      # make sure any old data is cleared out
      if params[:new].present?
        Rails.logger.debug('New Lbtt return type')
        clear_caches
      end

      # continue with normal first step (we don't pass clear_cache param since we've done that above)
      wizard_step(nil) do
        { setup_step: :setup_step, after_merge: :setup_sub_models, next_step: :return_type_next_steps }
      end
    end

    # This is the public version of the #return_type page/step.  It's separate mainly so we can distinguish the links
    # between a version that needs login and one that doesn't (ie so we don't mix them up accidentally).
    # Clears the cache and sets up the model.
    def public_return_type
      wizard_step(PUBLIC_STEPS) { { setup_step: :setup_step, clear_cache: true } }
    end

    # lease review, assignation and termination step
    def return_reference_number
      wizard_step(nil) { { next_step: :return_type_next_steps } }
    end

    # returns/lbtt/calculation Allows editing the tax calculation.
    # A 1 step wizard, always goes to summary after successful editing
    def calculation
      wizard_step(returns_lbtt_summary_path) { { params: :filter_calculate_params } }
    end

    # returns/lbtt/declaration - step in declaration wizard
    # Triggers validation context :declaration since un-checked checkboxes produce empty params (so wouldn't trigger
    # the normal validation context detection).
    # Ensures the correct validation context is checked on clicking Next (ie so won't submit until declaration ticked).
    def declaration
      wizard_step(DECLARATION_STEPS) do
        { setup_step: :declaration_setup_step, after_merge: :submit_return, validates: :declaration }
      end
    end

    # returns/<type>/declaration_submitted - custom final step in declaration wizard
    # (can't go in ControllerHelper as doesn't get picked up)
    def declaration_submitted
      load_step # ie just load the return
    end

    # The method used to retrieve the pdf summary of the return
    def download_receipt
      @lbtt_return = load_step
      success, attachment = Dashboard::DashboardReturn.return_pdf(current_user,
                                                                  @lbtt_return.back_office_receipt_request, 'Receipt')
      return unless success

      # Download the file
      send_file_from_attachment(attachment[:document_return])
    rescue StandardError => e
      Rails.logger.error(e)
      redirect_to controller: '/home', action: 'file_download_error'
    end

    # Cleans and saves the return by sending to the back office.
    def save_draft
      @lbtt_return = wizard_load
      @lbtt_return.clean_up_yes_nos
      @lbtt_return.save_draft(current_user)
      @post_path = '.'
      wizard_save(@lbtt_return)
    end

    private

    # Unless it's a new lbtt return, cleans the data based on business rules so the summary will be correct.
    def summary_clean_up_setup
      return if params[:new]

      Rails.logger.debug('Clean up summary page')
      @lbtt_return.clean_up_yes_nos
    end

    # Calculates which list of steps to follow after the return_type action.
    # @return [Array] the next steps list
    def return_type_next_steps
      flbt_type = params[:returns_lbtt_lbtt_return][:flbt_type]
      flbt_type = @lbtt_return.flbt_type if flbt_type.nil?
      next_steps = if %w[CONVEY LEASERET].include? flbt_type
                     CONVEY_LEASERET_STEPS
                   elsif %w[LEASEREV ASSIGN TERMINATE].include? flbt_type
                     LEASE_REV_ASSIGN_TERMINATE_STEPS
                   end
      raise Error::AppError.new('Return type', "Invalid return type #{flbt_type}") if next_steps.nil?

      next_steps
    end

    # Clears the wizard cache if a new lbtt return type is selected (replaces with a fresh one), otherwise keep it.
    # @see #setup_step if you change this method
    def clean_on_new_type
      @lbtt_return = wizard_load
      # We're comparing the flbt_type with the current_flbt_type to determine whether if we need to clean the pages
      # or not. The current_flbt_type is the old one, and flbt_type is the user's latest request of return type.
      current_flbt_type = @lbtt_return.current_flbt_type
      flbt_type = @lbtt_return.flbt_type

      # If the return type matches with the old type or if this is the first time the return type has been chosen
      # then there's no need to clean it.
      return unless (flbt_type != current_flbt_type) && !current_flbt_type.blank?

      # Clears the caches (LBTT and sub-types)
      clear_caches

      # Creates a clean and new LBTT with some initial data added as these are data from before the summary page.
      # The current_flbt_type is set to flbt_type to reset it.
      @lbtt_return = Lbtt::LbttReturn.new(flbt_type: flbt_type, current_flbt_type: flbt_type,
                                          orig_return_reference: @lbtt_return.orig_return_reference,
                                          is_public: (current_user.nil? ? true : false))
      setup_sub_models
    end

    # Calls @see #wizard_end for LBTT and sub-objects
    def clear_caches
      Rails.logger.debug('Clearing LBTT and sub-object wizard caches')
      wizard_end
      wizard_end(LbttPartiesController)
      wizard_end(LbttPropertiesController)
      wizard_end(LbttAgentController)
    end

    # load all the parties data involved in lbtt return
    def load_party_summary
      agent_data if current_user # not needed for a public return
    end

    # Load agent contact data (or populate with @see Party#populate_from_account) into @agent.
    # If there is no user then an blank @agent will be set up (ie the public user case).
    def agent_data
      # load agent data from current user if its blank
      if @lbtt_return.agent.nil?
        @lbtt_return.agent = Lbtt::Party.new(party_type: 'AGENT')
        # get login user details to pre-populate details for agent section
        # skip this step if there isn't a logged in user
        @lbtt_return.agent.populate_from_account(Account.find(current_user))
      end

      @agent = @lbtt_return.agent
    end

    # Checks if submit button was pressed & redirects to the appropriate action if validation passes.
    # @return true if button was pressed, else false.
    def manage_submit
      if params[:submit_return]
        Rails.logger.debug('submit_return pressed')
        if @lbtt_return.valid?(:submit)
          Rails.logger.debug('validation passed')
          redirect_submit
          return true
        end
      end

      false
    end

    # Redirect after a valid submit
    def redirect_submit
      # for amendments, check if they want to request a repayment
      if @lbtt_return.show_repayment?
        redirect_to returns_lbtt_repayment_claim_path
      else
        redirect_to action: :declaration
      end
    end

    # Send the return to the back office (and wizard_save unless there were errors returned.)
    # @return [Boolean] true if successful
    def submit_return
      return false unless @lbtt_return.prepare_to_save_latest

      # Save the prepared return in the cache in case the user navigates back and re-tries
      wizard_save(@lbtt_return)
      success = @lbtt_return.save_latest(current_user)
      # need to save even if not successful so the saved flag is cleared
      wizard_save(@lbtt_return)
      success
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # @see #clean_on_new_type if you change this method, they need to match up
    # @return [LbttReturn] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path
      @lbtt_return = wizard_load || Lbtt::LbttReturn.new(is_public: (current_user.nil? ? true : false))

      setup_sub_models(false)

      @lbtt_return
    end

    # Make sure tax calculations object is defined and up to date and stored in the wizard cache
    # @param save_wizard [Boolean] to handle wizard save
    # @return [Boolean] true if successful
    def setup_sub_models(save_wizard = true)
      Lbtt::Tax.setup_tax(@lbtt_return)
      Lbtt::Ads.setup_ads(@lbtt_return)
      wizard_save(@lbtt_return) if save_wizard
      true
    end

    # Loads existing wizard models from the wizard cache or redirects to the dashboard page
    # @return [LbttReturn] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      # redirects to the dashboard or public landing as needed
      @lbtt_return = wizard_load_or_redirect(current_user.nil? ? returns_lbtt_public_landing_url : dashboard_url)
    end

    # Custom setup step to clear the declaration fields forcing them to tick it each time.
    # @return [LbttReturn] result from load_step
    def declaration_setup_step
      model = load_step
      @lbtt_return.declaration = false
      @lbtt_return.lease_declaration = false

      model
    end

    # Used in wizard_list_step as part of the merging of data.
    # @return [Object] new instance of ReliefClaim class that has attributes with value.
    def new_list_item_relief_claims(hash_attributes = {})
      Lbtt::ReliefClaim.new(hash_attributes)
    end

    # merge and validate relief claim amount
    # @return [Boolean] true if the merge was successful and all the items were valid
    def merge_relief_list_data
      # The :relief_override_amount validation is only triggered on the edit page.
      # So this will apply all the validation and the on: :relief_override_amount.
      # @see merge_params_and_validate_with_list to learn more about how this is being used
      @list_item_validation_key = :relief_override_amount

      # Merges the params values with the wizard object's list attribute and validates each as they're merged
      # @see merge_params_and_validate_with_list to know more
      yield
    end

    # Return the parameter list filtered for the attributes in list_attribute
    # note we have to permit everything because we get a hash of the records returned e.g. "0" => details
    def filter_list_params(list_attribute, _sub_object_attribute = nil)
      return unless params[:returns_lbtt_lbtt_return] && params[:returns_lbtt_lbtt_return][list_attribute]

      params.require(:returns_lbtt_lbtt_return).permit(list_attribute => {})[list_attribute].values
    end

    # Return the parameter list filtered for the attributes of the Calculate model
    def filter_calculate_params
      required = :returns_lbtt_calculate
      attribute_list = Lbtt::Calculate.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
