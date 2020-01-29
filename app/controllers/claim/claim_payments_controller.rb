# frozen_string_literal: true

module Claim
  # claim payment controller which hold wizard steps for unauthenticated or authenticated claiming payment for
  # return
  # For authenticated this is only those filed more than 12 months ago
  # For unauthenticated it also allows ADS claims only prior to the 12 months
  class ClaimPaymentsController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include WizardAddressHelper
    include FileUploadHandler

    # all public pages, wizard steps for the public part of Claim repayment
    PUBLIC_PAGES = %I[public_claim_landing return_reference_number claim_reason date_of_sale
                      main_residence_address further_claim_info claiming_amount claimant_info agent_info
                      agent_address taxpayer_details taxpayer_address additional_tax_payer
                      second_taxpayer_info second_tax_payer claim_payment_bank_details upload_evidence
                      taxpayer_declaration more_uploads confirmation_of_payment download_claim download_file
                      view_claim_pdf].freeze

    authorise requires: AuthorisationHelper::CLAIM_REPAYMENT + AuthorisationHelper::CLAIM_REPAYMENT_ATTACHMENT,
              allow_if: :public

    # to require authentication so we don't mix the two up
    skip_before_action :require_user, only: PUBLIC_PAGES

    # List of steps for a claim. For public claim the entry point will be return_reference number
    # for authenticated claim it is claim reason. The following steps are skipped as you step through
    # ADS steps unless the reason is ADS
    # Agent steps unless unauthenticated and they says they are an agent
    # Second tax payer details unless there is a second tax payer, never for SLFT
    # see specific steps below
    STEPS = %w[return_reference_number claim_reason
               date_of_sale main_residence_address further_claim_info
               claiming_amount
               claimant_info agent_info agent_address
               taxpayer_details taxpayer_address
               additional_tax_payer second_taxpayer_info second_tax_payer
               claim_payment_bank_details upload_evidence taxpayer_declaration
               more_uploads confirmation_of_payment].freeze

    # Create the standard wizard step actions
    standard_wizard_step_actions(STEPS, %i[date_of_sale further_claim_info agent_info taxpayer_details
                                           second_taxpayer_info claim_payment_bank_details confirmation_of_payment])

    # Home page for unauthenticated wizard
    def public_claim_landing; end

    # First step in the unAuthenticated user wizard
    def return_reference_number
      # Call clear_cache whenever params[:new] is there
      clear_cache = params[:new].present?
      Rails.logger.debug('New Claim Repayment') if clear_cache

      wizard_step(STEPS) do
        { setup_step: :return_reference_setup_step, next_step: :show_reason_step, clear_cache: clear_cache }
      end
    end

    # First step in the authenticated claim (also in in unauthenticated)
    # in claim link on dashboard page (@see save_params method)
    def claim_reason
      # Call clear_cache whenever params[:new] is there
      clear_cache = params[:new].present?
      Rails.logger.debug('New Claim Repayment') if clear_cache

      wizard_step(STEPS) do
        { setup_step: :setup_claim_reason_step, clear_cache: clear_cache, next_step: :show_ads_steps }
      end
    end

    # Only shown when reason is ADS
    def main_residence_address
      wizard_address_step(STEPS, validates: :postcode_matches)
    end

    # Collects the amount of the claim, always shown
    # next step may be to get tax payer details (for authenticated LBTT), to ask if this is an agent (for authenticated)
    # or straight to bank details for SLFT
    def claiming_amount
      wizard_step(STEPS) { { next_step: :calculate_claiming_amount_next_step } }
    end

    # For unauthenticated only is this a tax payer or agent
    def claimant_info
      wizard_step(STEPS) { { next_step: :show_agent_info_step } }
    end

    # For unauthenticated only shown if this is an agent
    def agent_address
      wizard_address_step(STEPS, address_attribute: :agent_address)
    end

    # Gets the tax payer details (skipped for SLFT)
    def taxpayer_address
      wizard_address_step(STEPS, address_attribute: :tax_address)
    end

    # Is there a second tax payer
    def additional_tax_payer
      wizard_step(STEPS) { { next_step: :show_second_taxpayer_step } }
    end

    # Second tax payer details
    def second_tax_payer
      wizard_address_step(STEPS, address_attribute: :s_tax_address)
    end

    # For all types upload evidence
    def upload_evidence
      # loading wizard so that we can save the attachment in the claim_payment model
      @claim_payment ||= wizard_load
      # clearing previous file upload cache if its new get request
      # second && condition to avoid clear cache on back
      file_upload_end if request.get? && @claim_payment.upload_attachment.nil?

      handle_file_upload(nil)
      wizard_step(STEPS) { { after_merge: :save_attachment_in_model } }
    end

    # For all types do the declaration, this also triggers the submit
    # Ensures the correct validation context is checked on clicking Next (ie so won't submit until declaration ticked).
    def taxpayer_declaration
      wizard_step(STEPS) do
        { cache_index: true, setup_step: :taxpayer_declaration_setup_step,
          validates: :declaration, after_merge: :save_data_in_back_office }
      end
    end

    # For all types get any more files
    def more_uploads
      wizard_step(STEPS)
      if params[:add_resource] || params[:delete_resource]
        handle_confirmation_file_upload
      elsif params[:continue]
        # clear cache
        file_upload_end
        redirect_to claim_claim_payments_confirmation_of_payment_path
      else
        # clear previous cache
        file_upload_end
        initialize_fileupload_variables
      end
    end

    # The method used to retrieve the pdf summary of the return
    # The "target: '_blank'" page used to download the pdf file of the return according
    # to its details.
    def view_claim_pdf
      @claim_payment ||= wizard_load
      success, attachment = @claim_payment.view_claim_pdf
      return unless success

      # Download the file
      send_file_data(attachment[:document_claim])
    rescue StandardError => e
      Rails.logger.error(e)
      redirect_to controller: '/home', action: 'file_download_error'
    end

    private

    # Sets up wizard model if it doesn't already exist in the cache
    # @see #clean_on_new_type if you change this method, they need to match up
    # @return [LbttReturn] the model for wizard saving
    def return_reference_setup_step
      @post_path = wizard_post_path
      @claim_payment = wizard_load || Claim::ClaimPayment.new(is_public: (current_user.nil? ? true : false))

      @claim_payment
    end

    # save the attachment in the claim_payment model
    # calls back-office to send data collected in claim_payment wizard
    # @return [Boolean] was the after merge process successful
    def save_attachment_in_model
      @claim_payment.upload_attachment = @resource_items[0] unless @resource_items.nil?
      true
    end

    # calls back office to save data collected in claim_payment wizard
    # explicitly save the data as the model is updated with details
    # @return [Boolean] was the after merge process successful
    def save_data_in_back_office
      @claim_payment.save(current_user)
      wizard_save(@claim_payment)
    end

    # which file types are allowed to be uploaded.cl
    def content_type_whitelist
      Rails.configuration.x.file_upload_content_type_whitelist.split(/\s*,\s*/)
    end

    # Send document to back office
    # @return [Boolean][String] true if document store successfully back office else false and
    #   document reference id
    def add_claim_document
      @claim_payment.add_claim_attachment(@resource_item)
    end

    # Call delete attachment method of message to delete document from backoffice
    # @param doc_refno [String] document reference number to be delete from backoffice
    # @return [Boolean] true if document delete successfully from backoffice else false
    def delete_document(doc_refno)
      @claim_payment.delete_attachment(doc_refno)
    end

    # Permits the access to the data passed on the .permit of :claim_payment objects
    def claim_payment_params
      params.require(:claim_claim_payment).permit(:more_uploads)
    end

    # Overwrites the user method to pass unique id for unauthenticated user to create folder on server
    # folder will hold the file uploaded by user
    def sub_directory
      @claim_payment ||= wizard_load
      return @claim_payment.tare_reference if current_user.blank?

      current_user.username
    end

    # This method is specific to handle the file add and delete functionality
    # on confirmation page
    def handle_confirmation_file_upload
      @claim_payment.more_uploads = params[:claim_claim_payment][:more_uploads] if
       params[:claim_claim_payment][:more_uploads]
      handle_file_upload('more_uploads',
                         after_add: :add_claim_document,
                         before_delete: :delete_document)
    end

    # Sends file to browser for download, which automatically downloads the file.
    def send_file_data(attachment)
      send_data Base64.decode64(attachment[:binary_data]),
                type: attachment[:file_type], filename: attachment[:file_name],
                # This means to download the file, if we want to just view the file
                # this would have to be disposition: 'inline'
                disposition: 'attachment'
    end

    # Calculates which wizard steps to be followed if return is PRE/POST
    def show_reason_step
      return claim_claim_payments_date_of_sale_path if @claim_payment.pre_claim? == true

      STEPS
    end

    # Calculates which wizard steps to be followed
    def show_ads_steps
      return claim_claim_payments_claiming_amount_path if @claim_payment.reason != 'ADS'

      STEPS
    end

    # Calculates which wizard steps to be followed
    def calculate_claiming_amount_next_step
      return claim_claim_payments_claim_payment_bank_details_path if @claim_payment.srv_code != 'LBTT'
      return claim_claim_payments_taxpayer_details_path unless current_user.blank?

      STEPS
    end

    # Calculates which wizard steps to be followed
    def show_agent_info_step
      return claim_claim_payments_taxpayer_details_path if @claim_payment.claimant_info == 'Y'

      STEPS
    end

    # Calculates which wizard steps to be followed if :additional_taxpayer = yes
    def show_second_taxpayer_step
      return claim_claim_payments_claim_payment_bank_details_path if @claim_payment.additional_tax_payer == 'N'

      STEPS
    end

    # Loads existing wizard models from the wizard cache or redirects to the dashboard page
    def load_step
      @post_path = wizard_post_path
      @claim_payment = wizard_load_or_redirect(dashboard_url)
    end

    # specific setup for claim_reason method
    # When the "new" parameter is passed, calls @see #setup_payment_from_params to create the model.
    # Otherwise loads the model from the wizard cache.
    # Follows the same pattern as @see LbttPropertiesController#setup_step
    # @return [ClaimPayment] model for the wizard to use
    def setup_claim_reason_step
      @post_path = wizard_post_path

      # load existing or setup new claim on first entering the step
      @claim_payment = if params[:new]
                         setup_payment_from_params
                       else
                         wizard_load
                       end
    end

    # Handles setting up a new ClaimPayment and saving it in the wizard cache.
    # For lbtt these details are overridden by getting details from the back office based on the reference
    # @return [ClaimPayment] new object
    # @raise [Error::AppError] if the required parameters were not passed
    def setup_payment_from_params
      setup_payment_check_params

      # create new model
      claim_payment = ClaimPayment.new(srv_code: params[:srv_code], tare_reference: params[:reference],
                                       version: params[:version], current_user: current_user)
      wizard_save(claim_payment)
      claim_payment
    end

    # checks the parameters are correct to setup a claim payment
    # @raise [Error::AppError] if the required parameters were not passed
    def setup_payment_check_params
      return if %i[srv_code reference version].all? { |key| params[key].present? }

      raise Error::AppError.new('Claim Payments', 'Missing parameters detected')
    end

    # Custom setup step to clear the declaration fields forcing them to tick it each time.
    # @return [ClaimPayment] result from load_step
    def taxpayer_declaration_setup_step
      model = load_step
      @claim_payment.declaration_public = false
      @claim_payment.declaration = false

      model
    end

    # Return the parameter list filtered for the attributes of the ClaimPayment model
    def filter_params
      required = :claim_claim_payment

      params.require(required).permit(Claim::ClaimPayment.attribute_list) if params[required]
    end
  end
end
