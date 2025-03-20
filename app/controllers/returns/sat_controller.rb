# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller class for SAT returns
  # SAT return controller maintain(add/edit details) the information about the SAT returns
  class SatController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include FileUploadHandler
    include ControllerHelper
    include DownloadHelper

    authorise requires: RS::AuthorisationHelper::SAT_SUMMARY
    authorise route: :save_draft, requires: RS::AuthorisationHelper::SAT_SAVE

    # wizard steps in order
    STEPS = %w[return_period summary calculated_tax_liability].freeze

    # wizard steps for the DECLARATION wizard
    DECLARATION_STEPS = %w[amendment_reason declaration_calculation
                           declaration_submitted].freeze

    # wizard steps for the repayment wizard
    REPAYMENT_STEPS = %w[repayment_request declaration_calculation
                         declaration_submitted].freeze

    # wizard steps for the repayment bank details wizard
    REPAYMENT_B_STEPS = %w[repayment_request_bank_details repayment_declaration declaration_calculation
                           declaration_submitted].freeze

    authorise route: DECLARATION_STEPS, requires: RS::AuthorisationHelper::SAT_SUBMIT

    # Setting sat return period - custom step which clears the wizard cache before it starts a new return
    # (ie not when changing the site period of an existing one).
    def return_period
      # When the user has clicked on the Create sat return button, the return type would be a new one, so
      # make sure any old data is cleared out
      if params[:new]
        Rails.logger.debug('Starting new SAT return')
        clear_caches
      end

      wizard_step(nil) do
        { setup_step: :setup_step, next_step: :returns_sat_summary_path }
      end
    end

    # returns/sat/repayment_request_bank_details - step 2 in the repayment claim wizard
    def repayment_request_bank_details
      wizard_step(REPAYMENT_B_STEPS) { { cache_index: SatController } }
    end

    # determines the next step after the user has entered the bank details
    def repayment_next_steps
      return returns_sat_amendment_reason_path if @sat_return.amendment?

      REPAYMENT_B_STEPS
    end

    # determines the next step after the user has checked the declaration
    def repayment_declaration
      wizard_step(nil) { { cache_index: SatController, next_step: :repayment_next_steps } }
    end

    # returns/sat/repayment_request - step 1 in the repayment claim wizard
    def repayment_request
      wizard_step(nil) do
        { setup_step: :setup_step, next_step: :repayment_request_next_steps }
      end
    end

    # Decide what the next step will be after the repayment_request action, either into the claim wizard or
    # straight on to the sat declaration/amendment page.
    def repayment_request_next_steps
      return returns_sat_repayment_request_bank_details_path if @sat_return.claim_repayment?
      return returns_sat_amendment_reason_path if @sat_return.amendment?

      REPAYMENT_STEPS
    end

    # Summary of returns.
    def summary
      load_step

      # methods above could have updated the return so save it to give wizards access to the new data
      wizard_save(@sat_return)
      csv_upload
      if @sat_return.csv_taxable_data.present?
        redirect_to returns_sat_confirm_data_import_path
      else
        # manage the buttons AFTER wizard_save so we don't save the validation errors
        manage_draft(@sat_return) || redirect_submit
      end

      # manage the buttons AFTER wizard_save so we don't save the validation errors
      # manage_draft(@sat_return) || redirect_submit
    end

    # Redirect after a valid submit
    def redirect_submit
      return true unless params[:calc_return]

      if @sat_return.valid?(:calc_return)
        Rails.logger.debug('  validation passed')
        redirect_to returns_sat_bad_debt_claims_path
      else
        render(status: :unprocessable_entity)
      end
    end

    # returns/sat/calculated_tax_liability
    def calculated_tax_liability # rubocop:disable Metrics/MethodLength
      setup_step
      if params[:calculate_return]

        # if amendment is taking place redirect the user to the amendment screen
        # manage the buttons AFTER wizard_save so we don't save the validation errors
        if @sat_return.tax_payable_raw.negative? || @sat_return.amendment?
          redirect_to returns_sat_repayment_request_path
        else
          manage_calculate(@sat_return)
        end
        return # can't use && guard clause as wizard_step_submitted returns nil
      end

      # do/download calculations into model and store in wizard
      @sat_return.calculate_tax(current_user)

      # don't store if back office sent errors
      wizard_save(@sat_return) unless @sat_return.errors.any?
    end

    # performs the submit return on the declaration page
    def declaration_calculation
      wizard_step(DECLARATION_STEPS) { { after_merge: :submit_return } }
    end

    # returns/sat/amendment_reason - provide the reason for the amendment
    def amendment_reason
      wizard_step(DECLARATION_STEPS) { { cache_index: SatController } }
    end

    # returns/sat/declaration_submitted - custom final step in declaration wizard
    # (can't go in ControllerHelper as doesn't get picked up)
    def declaration_submitted
      setup_step # ie just load the return
    end

    # Send the return to the back office (and wizard_save unless there were errors returned.)
    # @return [Boolean] true if successful
    def submit_return
      return false unless @sat_return.prepare_to_save_latest

      # Save the prepared return in the cache in case the user navigates back and re-tries
      wizard_save(@sat_return)
      success = @sat_return.save_latest(current_user)
      # need to save even if not successful so the saved flag is cleared
      wizard_save(@sat_return)
      success
    end

    # Cleans and saves the return by sending to the back office.
    def save_draft
      @sat_return = load_step
      @post_path = '.'
    end

    # The method used to retrieve the pdf summary of the return
    def download_receipt
      @sat_return = load_step
      success, attachment = @sat_return.back_office_pdf_data(current_user,
                                                             @sat_return.back_office_receipt_request, 'Receipt')
      return unless success

      # Download the file
      send_file_from_attachment(attachment[:document_return])
    end

    # Confirm if data is to be overrridden
    def confirm_data_import
      @sat_return = load_step

      unless params[:overwrite_data].nil? # rubocop:disable Style/GuardClause
        @sat_return.save_csv_file_data if params[:overwrite_data] == 'yes'
        @sat_return.csv_taxable_data = []
        wizard_save(@sat_return, Returns::SatController)
        redirect_to returns_sat_summary_path
      end
    end

    private

    # Calls @see #wizard_end for SAT and sub-objects
    def clear_caches
      Rails.logger.debug('Clearing SAT wizard caches')
      wizard_end
      wizard_end(Returns::SatBadDebtCreditClaimsController)
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # @return [SatReturn] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path
      @sat_return = wizard_load || Sat::SatReturn.new(current_user: current_user)

      @sat_return
    end

    # Loads existing wizard models from the wizard cache or redirects to the summary page
    # @return [SatReturn] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @sat_return = wizard_load_or_redirect(returns_sat_return_period_url)

      @post_path = wizard_post_path
      @sat_return
    end

    # Call back from FileUploadHandler, which returns file types are allowed to be uploaded.
    def content_type_allowlist
      Rails.configuration.x.sat_file_upload_content_type_allowlist.split(/\s*,\s*/)
    end

    # Call back from FileUploadHandler, which returns additional/alias content types are allowed
    # i.e. CSV mime type should be text/csv, but with a machine with Excel on it, the
    # type would be application/vnd.ms-excel
    def alias_content_type
      Rails.configuration.x.sat_file_upload_alias_content_type_allowlist.split(/\s*,\s*/)
    end

    # Handles where a user has uploaded a CSV file
    def csv_upload
      return unless handle_file_upload(parent_param: :returns_sat_sat_return,
                                       add_processing: :validate_and_import_aggregate_file,
                                       clear_cache: true)

      wizard_save(@sat_return, Returns::SatController) if @sat_return.errors.none?
      # specifically clear the resource items as we don't want them shown, force the clear
      clear_resource_items(force: true)
      # Return 422 if there's no taxable_data available
      render(status: :unprocessable_entity) unless @sat_return.csv_taxable_data.present? # rubocop:disable Rails/Blank
    end

    # Callback from the file upload component. Validates and imports the site aggregate file. If the file isn't a well
    # formed CSV file, the file isn't imported and a validation message attached to the file_data element of
    # the resource_item in the hash.
    # If there are errors on the individual rows the file is imported, with errors attached to the individual
    # aggregate/credit claim that are created
    # @param resource_item [Object] The resource item being processed
    # @return [Boolean] indicator if the file has been imported correctly
    def validate_and_import_aggregate_file(resource_item)
      return if resource_item.nil?

      Rails.logger.debug { "Importing File #{resource_item.original_filename}" }

      @sat_return.import_site_csv_data(resource_item)
    end

    # Return the parameter list filtered for the attributes of the SatReturn model.
    # Special case for the repayment declaration, since it's the only thing on the page we need to treat
    # its absence as a value of false.
    def filter_params(_sub_object_attribute = nil)
      required = :returns_sat_sat_return
      output = {}
      output = params.require(required).permit(Sat::SatReturn.attribute_list) if params[required]

      output
    end
  end
end
