# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller class for Lbtt (Land and Buildings Transaction Tax) return
  # Lbtt return controller maintain(add/edit details) the information about parties (buyer, seller or agent,
  # calculation and transaction) transacting for properties.
  # It also keeps all details of the properties.
  class LbttController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include AddressHelper
    include ControllerHelper
    include LbttControllerHelper

    # all public pages, not just wizard steps for the public part of LBTT
    PUBLIC_PAGES = %I[public_landing public_return_type return_reference_number summary
                      declaration declaration_submitted].freeze

    authorise requires: AuthorisationHelper::LBTT_SUMMARY
    authorise routes: PUBLIC_PAGES, requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    authorise route: :load, requires: AuthorisationHelper::LBTT_CONTINUE
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

    # publically available steps (feeds into the steps above)
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

    # Summary of returns.
    def summary
      clean_on_new_type

      setup_step

      summary_clean_up_setup

      load_party_summary

      # methods above could have updated the return so save it to give wizards access to the new data
      wizard_save(@lbtt_return)

      # manage the buttons AFTER wizard_save so we don't save the validation errors
      return if manage_draft(@lbtt_return) || manage_submit

      summary_normal_setup
    end

    # Setting lbtt return type - custom step which clears the wizard cache before it starts
    def return_type
      clear_cache = nil
      # When the user has clicked on the Create lbtt return button, the return type would be a new one.
      if params[:new]
        Rails.logger.debug('New Lbtt return type')
        wizard_end
        clear_cache = LbttController
      else
        @lbtt_return = wizard_load
      end

      wizard_step(nil) { { params: :filter_params, next_step: :return_type_next_steps, clear_cache: clear_cache } }
    end

    # Custom wizard step.  Clears the cache and sets up the return type list.
    # This is the public version of the #return_type page.  It's separate mainly so we can distinguish the links
    # between a version that needs login and one that doesn't (ie so we don't mix them up accidentally).
    def public_return_type
      if params[:submitted]
        wizard_step_submitted(PUBLIC_STEPS, params: :filter_params)
        return
      end

      # clear cache before setup
      wizard_end(LbttController)
      setup_step
    end

    # lease review, assignation and termination step
    def return_reference_number
      wizard_step(nil) { { params: :filter_params, next_step: :return_type_next_steps } }
    end

    # returns/lbtt/calculation Allows editing the tax calculation.
    # A 1 step wizard, always goes to summary after succesful editing
    def calculation
      wizard_step(returns_lbtt_summary_path) { { params: :filter_calculate_params } }
    end

    # returns/lbtt/declaration - step in declaration wizard
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
      @lbtt_return = wizard_load
      @lbtt_return.clean_up_yes_nos
      @lbtt_return.save_draft(current_user)
      @post_path = '.'
      wizard_save(@lbtt_return)
    end

    # Loads an existing return and shows the summary screen or else an error page
    def load
      validate_load_param

      # load it
      @lbtt_return = Lbtt::LbttReturn.find(:lbtt_tax_return_details, params[:ref_no], current_user,
                                           :lbtt_tax_return) do |data|
        Lbtt::LbttReturn.new_from_fl(data)
      end
      @lbtt_return.is_public = false # if we are loading it can't be public

      # make sure tax calculations object is defined before wizard_save (copied from setup_step)
      Lbtt::Tax.setup_tax(@lbtt_return, false, flbt_type: params[:flbt_type])
      Rails.logger.info("Loaded Lbtt #{@lbtt_return}")

      # store in wizard (replaces anything that was there before)
      wizard_save(@lbtt_return)

      # run summary page
      redirect_to action: :summary
    end

    private

    # Extracted summary method
    def summary_normal_setup
      # prefixes the model path to re-use the translations
      return_prefix = 'activemodel.attributes.returns/lbtt/lbtt_return'
      tax_prefix = 'activemodel.attributes.returns/lbtt/tax'
      @transaction_summary = @lbtt_return.transaction_summary(return_prefix, tax_prefix)
      @properties = @lbtt_return.properties.values unless @lbtt_return.properties.nil?
      @ads_summary = @lbtt_return.ads_summary(return_prefix)
      @new_tenants = @lbtt_return.new_tenants.values unless @lbtt_return.new_tenants.nil?
      @calculation_summary = @lbtt_return.tax.calculation_summary(@lbtt_return)
    end

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

    # Clears the wizard if a new lbtt return type is selected, otherwise keep it.
    def clean_on_new_type
      @lbtt_return = wizard_load
      # We're comparing the flbt_type with the current_flbt_type to determine whether if we need to clean the pages
      # or not. The current_flbt_type is the old one, and flbt_type is the user's latest request of return type.
      current_flbt_type = @lbtt_return.current_flbt_type
      flbt_type = @lbtt_return.flbt_type
      # If the return type matches with the old type or if this is the first time the return type has been chosen
      # then there's no need to clean it.
      return unless (flbt_type != current_flbt_type) && !current_flbt_type.blank?

      # Clears the cache
      wizard_end
      # Creates a clean and new LBTT with some initial data added as these are data from before the summary page.
      # The current_flbt_type is set to flbt_type to reset it.
      @lbtt_return = Lbtt::LbttReturn.new(flbt_type: flbt_type, current_flbt_type: flbt_type,
                                          orig_return_reference: @lbtt_return.orig_return_reference,
                                          is_public: (current_user.nil? ? true : false))
      Lbtt::Tax.setup_tax(@lbtt_return, true, flbt_type: flbt_type)

      wizard_save(@lbtt_return, LbttController)
    end

    # Sets up @lbtt_return and @post_path ie variables for the form and controller to use
    # @return [LbttReturn] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path
      @lbtt_return = wizard_load || Lbtt::LbttReturn.new(is_public: (current_user.nil? ? true : false))

      # make sure tax calculations object is defined and up to date before wizard_save
      Lbtt::Tax.setup_tax(@lbtt_return)

      # clear the declaration fields forcing them to tick it each time and so validation works
      clear_declarations if action_name == 'declaration'
      clear_repayment_declarations if action_name == 'repayment_claim_declaration'

      @lbtt_return
    end

    # clears the declarations
    def clear_declarations
      @lbtt_return.declaration = false
      @lbtt_return.lease_declaration = false
    end

    # clears the repayment declarations
    def clear_repayment_declarations
      @lbtt_return.repayment_declaration = false
      @lbtt_return.repayment_agent_declaration = false
    end

    # Return the parameter list filtered for the attributes of the Calculate model
    def filter_calculate_params
      required = :returns_lbtt_calculate
      attribute_list = Lbtt::Calculate.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end

    # load all the parties data involved in lbtt return
    def load_party_summary
      @buyers = @lbtt_return.buyers&.values
      @sellers = @lbtt_return.sellers&.values
      @landlords = @lbtt_return.landlords&.values
      @tenants = @lbtt_return.tenants&.values
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
    def submit_return
      @lbtt_return.save_latest(current_user)
      wizard_save(@lbtt_return) unless @lbtt_return.errors.any?
    end
  end
end
