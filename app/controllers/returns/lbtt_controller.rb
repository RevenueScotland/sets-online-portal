# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller class for Lbtt (Land and Buildings Transaction Tax) return
  # Lbtt return controller maintain(add/edit details) the information about parties (buyer, seller or agent,
  # calculation and transaction) transacting for properties.
  # It also keeps all details of the properties.
  class LbttController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include ControllerHelper
    include LbttControllerFilterParamsHelper
    include LbttControllerLoadAgentHelper
    include LbttControllerDateWarningHelper
    include DownloadHelper

    # all public pages, not just wizard steps for the public part of LBTT
    PUBLIC_PAGES = %I[public_landing public_return_type return_reference_number
                      return_pre_population_declaration summary
                      declaration declaration_submitted download_pdf].freeze

    authorise requires: RS::AuthorisationHelper::LBTT_SUMMARY
    authorise routes: PUBLIC_PAGES, requires: RS::AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    authorise route: :save_draft, requires: RS::AuthorisationHelper::LBTT_SAVE
    # Allow unauthenticated/public access to specific actions - NB do not put return_type here, want that
    # to require authentication so we don't mix the two up
    skip_before_action :require_user, only: PUBLIC_PAGES

    # enforce the user isn't logged in on the public pages
    before_action :enforce_public, only: %w[public_landing public_return_type]

    # navigation steps in the lbtt conveyance and lease return wizard
    CONVEY_LEASERET_STEPS = %w[return_type summary].freeze

    # navigation steps in the lbtt lease review, assignation and termination wizard
    LEASE_REV_ASSIGN_TERMINATE_STEPS = %w[return_type return_reference_number
                                          return_pre_population_declaration summary].freeze

    # publicly available steps (feeds into the steps above)
    PUBLIC_STEPS = %w[landing_public public_return_type return_reference_number
                      return_pre_population_declaration summary].freeze

    # this can't be defined in authorise.rb, otherwise rails throws an error
    helper_method :public

    # Summary of returns.
    def summary
      load_step

      clean_on_new_type

      summary_clean_up_setup

      load_party_summary

      # To check whether user have changed the calculated tax values
      @lbtt_return.calculated_values_changed

      # methods above could have updated the return so save it to give wizards access to the new data
      wizard_save(@lbtt_return)

      # manage the buttons AFTER wizard_save so we don't save the validation errors
      manage_draft(@lbtt_return) || manage_submit
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

    # Public landing page, just renders the view
    def public_landing; end

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

    # lease review, assignation and termination pre population next step
    def return_pre_population_declaration
      wizard_step(LEASE_REV_ASSIGN_TERMINATE_STEPS)
    end

    # The method is used to retrieve the PDF of the submitted return
    def download_pdf
      @lbtt_return ||= load_step
      success, attachment = @lbtt_return.back_office_pdf_data(current_user,
                                                              @lbtt_return.back_office_receipt_request, 'Return')
      return unless success

      # Download the file
      send_file_from_attachment(attachment[:document_return])
    end

    # Overwrites the user method to pass unique id for unauthenticated user to create folder on server
    # folder will hold the file uploaded by user
    def sub_directory
      return current_user.username if current_user

      @lbtt_return ||= load_step
      @lbtt_return.tare_reference
    end

    # The method used to retrieve the pdf summary of the return
    def download_receipt
      @lbtt_return = load_step
      success, attachment = Dashboard::DashboardReturn.return_pdf(current_user,
                                                                  @lbtt_return.back_office_receipt_request, 'Receipt')
      return unless success

      # Download the file
      send_file_from_attachment(attachment[:document_return])
    end

    # Cleans and saves the return by sending to the back office.
    def save_draft
      @lbtt_return = load_step
      @post_path = '.'
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
      return unless (flbt_type != current_flbt_type) && current_flbt_type.present?

      # Clears the caches (LBTT and sub-types)
      clear_caches

      # Creates a clean and new LBTT with some initial data added as these are data from before the summary page.
      @lbtt_return = Lbtt::LbttReturn.new(flbt_type: flbt_type, current_flbt_type: flbt_type,
                                          orig_return_reference: @lbtt_return.orig_return_reference,
                                          current_user: current_user)
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
      load_agent if current_user # not needed for a public return
    end

    # Checks if submit button was pressed & redirects to the appropriate action if validation passes.
    # @return true if button was pressed, else false.
    def manage_submit
      return true unless params[:submit_return]

      Rails.logger.debug('submit_return pressed')
      if @lbtt_return.valid?(:submit)
        Rails.logger.debug('validation passed')
        redirect_submit
        true
      else
        render(status: :unprocessable_entity)
        false
      end
    end

    # Redirect after a valid submit
    def redirect_submit
      # for calculated values, provide the reason for changing the values
      if @lbtt_return.calculation_edited == 'Y'
        redirect_to returns_lbtt_edit_calculation_reason_path
      # for amendments, provide the amendment reason and check if they want to request a repayment
      elsif @lbtt_return.amendment?
        redirect_to returns_lbtt_amendment_reason_path
      # for lease review,assign, termination and amount payable is less than zero
      elsif @lbtt_return.any_lease_review? && @lbtt_return.tax.tax_due_for_return < '0'
        redirect_to returns_lbtt_repayment_claim_amount_path
      else
        redirect_to returns_lbtt_declaration_path
      end
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # @see #clean_on_new_type if you change this method, they need to match up
    # @return [LbttReturn] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path
      @lbtt_return = wizard_load || Lbtt::LbttReturn.new(current_user: current_user)

      setup_sub_models(save_wizard: false)

      @lbtt_return
    end

    # Make sure tax calculations object is defined and up to date and stored in the wizard cache
    # @param save_wizard [Boolean] to handle wizard save
    # @return [Boolean] true if successful
    def setup_sub_models(save_wizard: true)
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

    # Return the parameter list filtered for the attributes in list_attribute
    # note we have to permit everything because we get a hash of the records returned e.g. "0" => details
    def filter_list_params(list_attribute, _sub_object_attribute = nil)
      return unless params[:returns_lbtt_lbtt_return] && params[:returns_lbtt_lbtt_return][list_attribute]

      params.require(:returns_lbtt_lbtt_return).permit(list_attribute => {})[list_attribute].values
    end
  end
end
