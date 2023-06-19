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
    PUBLIC_PAGES = %I[before_you_start return_reference_number claim_reason date_of_sale
                      main_residence_address claiming_amount taxpayer_details taxpayer_address
                      claim_payment_bank_details upload_evidence public_claim_landing
                      final_declaration confirmation_of_payment download_claim download_file
                      view_claim_pdf eligibility].freeze

    authorise requires: RS::AuthorisationHelper::CLAIM_REPAYMENT + RS::AuthorisationHelper::CLAIM_REPAYMENT_ATTACHMENT,
              allow_if: :public

    # to require authentication so we don't mix the two up
    skip_before_action :require_user, only: PUBLIC_PAGES

    # enforce the user isn't logged in on the public pages
    before_action :enforce_public, only: %w[public_claim_landing eligibility before_you_start]

    # List of steps for a claim. For public claim the entry point will be return_reference number
    # for authenticated claim it is claim reason. The following steps are skipped as you step through
    # ADS steps unless the reason is ADS
    # Agent steps unless unauthenticated and they says they are an agent
    # Second tax payer details unless there is a second tax payer, never for SLFT
    # see specific steps below
    NEW_STEPS = %w[eligibility before_you_start return_reference_number claim_reason main_residence_address
                   date_of_sale upload_evidence claiming_amount taxpayer_details taxpayer_address
                   claim_payment_bank_details final_declaration
                   confirmation_of_payment].freeze

    # Create the standard wizard step actions
    standard_wizard_step_actions(NEW_STEPS, %i[claim_payment_bank_details])

    # Home page for unauthenticated wizard
    def public_claim_landing; end

    # wizard page for unauthenticated user to check eligibility
    def eligibility
      # Call clear_cache whenever params[:new] is there
      clear_cache = params[:new].present?
      Rails.logger.debug('New Claim Repayment') if clear_cache

      wizard_step(NEW_STEPS) { { setup_step: :setup_eligibility_step, clear_cache: clear_cache } }
    end

    # wizard page for unauthenticated user to check eligibility
    def before_you_start
      wizard_step(NEW_STEPS)
    end

    # First step in the unAuthenticated user wizard
    def return_reference_number
      wizard_step(NEW_STEPS) { { next_step: :show_ads_main_address_step } }
    end

    # First step in the authenticated claim (also in in unauthenticated)
    # in claim link on dashboard page (@see save_params method)
    def claim_reason
      # Call clear_cache whenever params[:new] is there
      clear_cache = params[:new].present?
      Rails.logger.debug('New Claim Repayment') if clear_cache

      wizard_step(NEW_STEPS) do
        { setup_step: :setup_claim_reason_step, clear_cache: clear_cache, next_step: :show_ads_steps }
      end
    end

    # Only shown when reason is ADS
    def main_residence_address
      wizard_address_step(NEW_STEPS)
    end

    # Collects the amount of the claim, always shown
    # next step may be to get tax payer details (for authenticated LBTT), to ask if this is an agent (for authenticated)
    # or straight to bank details for SLFT
    def claiming_amount
      wizard_step(NEW_STEPS) { { loop: :start_next_step } }
    end

    # Gets the tax payer details (skipped for SLFT)
    def taxpayer_details
      wizard_step(NEW_STEPS) { { sub_object_attribute: :taxpayers, loop: :continue } }
    end

    # Gets the tax payer address details
    def taxpayer_address
      options = { sub_object_attribute: :taxpayers, loop: :taxpayer_details }
      options[:address_not_required] = :same_address if params[:sub_object_index].to_i != 1

      wizard_address_step(NEW_STEPS, options)
    end

    # get date of sale for ADS and decide which should be the next page after date of sale
    def date_of_sale
      wizard_step(NEW_STEPS) { { next_step: :calculate_date_of_sale_next_step } }
    end

    # For all types upload evidence
    def upload_evidence
      # loading wizard so that we can save the attachment in the claim_payment model
      @claim_payment ||= load_step
      # clearing previous file upload cache if its new get request
      # second && condition to avoid clear cache on back
      file_upload_end if request.get? && @claim_payment.evidence_files.nil?

      if handle_file_upload(parent_param: :claim_claim_payment, types: evidence_files_file_types)
        # files were uploaded so keep on this page
        save_evidence_files_in_model
        render(status: :unprocessable_entity)
      else
        wizard_step(NEW_STEPS) { { validates: :evidence_files } }
      end
    end

    # To use translation on page description
    # Effectively this returns the t(.<key>) Rails operation
    # @param key [String] the key to be used and @param index of buyer
    def translation_for_index(key, index)
      "#{key}_#{index.to_i > 4 ? 'other' : index.to_s}"
    end

    helper_method :translation_for_index

    # Last step in the authenticated and unauthenticated claim
    def confirmation_of_payment
      # if unauthenticated then set the response header for clear site data to wild card
      response.set_header('Clear-Site-Data', '"storage"') if current_user.blank?

      # As the last page not a standard page, but need to load the model
      @claim_payment ||= load_step

      # Clear the cache to remove previously upload resource files
      # This means if the user refreshes the page they lose the list of files uploaded
      # but prevents files being shown incorrectly
      if handle_file_upload(parent_param: :claim_claim_payment,
                            before_add: :add_additional_document,
                            before_delete: :delete_additional_document,
                            clear_cache: request.get?)
        render(status: :unprocessable_entity)
      else
        end_claim_flow
      end
    end

    # For all types do the declaration, this also triggers the submit
    # Ensures the correct validation context is checked on clicking Next (ie so won't submit until declaration ticked).
    def final_declaration
      wizard_step(NEW_STEPS) do
        { cache_index: true, validates: :declaration, after_merge: :save_data_in_back_office }
      end
    end

    # The method used to retrieve the pdf summary of the return
    # The "target: '_blank'" page used to download the pdf file of the return according
    # to its details.
    def view_claim_pdf
      @claim_payment ||= load_step
      success, claim_pdf = @claim_payment.view_claim_pdf
      return unless success

      # Download the file
      send_file_from_attachment(claim_pdf[:document_claim])
    end

    private

    # Returns the fallback_url if a model isn't loaded
    def fallback_url
      (current_user.nil? ? claim_claim_payments_public_claim_landing_url : dashboard_url)
    end

    # Save the evidence_file in the claim_payment model
    # calls back-office to send data collected in claim_payment wizard
    # @return [Boolean] was the after merge process successful
    def save_evidence_files_in_model
      @claim_payment.evidence_files = []
      @claim_payment.evidence_files = @resource_items unless @resource_items.nil?
      wizard_save(@claim_payment)
      true
    end

    # calls back office to save data collected in claim_payment wizard
    # explicitly save the data as the model is updated with details
    # @return [Boolean] was the after merge process successful
    def save_data_in_back_office
      return false unless @claim_payment.prepare_to_save

      @claim_payment.save(current_user)
      wizard_save(@claim_payment)
    end

    # which file types are allowed to be uploaded.cl
    def content_type_allowlist
      Rails.configuration.x.file_upload_content_type_allowlist.split(/\s*,\s*/)
    end

    # Send document to back office
    # @return [Boolean][String] true if document store successfully back office else false and
    #   document reference id
    def add_additional_document(resource_item)
      @claim_payment.add_additional_document(resource_item)
    end

    # Call delete evidence_file method of message to delete document from back office
    # @param doc_refno [String] document reference number to be delete from back office
    # @return [Boolean] true if document delete successfully from back office else false
    def delete_additional_document(doc_refno)
      @claim_payment.delete_additional_document(doc_refno)
    end

    # Overwrites the user method to pass unique id for unauthenticated user to create folder on server
    # folder will hold the file uploaded by user
    def sub_directory
      @claim_payment ||= load_step
      return @claim_payment.tare_reference if current_user.blank?

      current_user.username
    end

    # Calculates which wizard steps to be followed if return is conveyance with ADS
    def show_ads_main_address_step
      claim_claim_payments_main_residence_address_path if @claim_payment.reason == 'ADS'
    end

    # Calculates which wizard steps to be followed
    def show_ads_steps
      return claim_claim_payments_upload_evidence_path if @claim_payment.reason != 'ADS'

      NEW_STEPS
    end

    # Calculates which wizard steps to be followed after date_of_sale
    def calculate_date_of_sale_next_step
      return claim_claim_payments_upload_evidence_path if @claim_payment.post_date_of_sale?

      claim_claim_payments_claiming_amount_path
    end

    # Loads existing wizard models from the wizard cache or redirects to the dashboard page
    def load_step(sub_object_attribute = nil)
      @post_path = wizard_post_path
      if sub_object_attribute.nil?
        @claim_payment = wizard_load_or_redirect(fallback_url)
      elsif sub_object_attribute == :taxpayers
        @claim_payment, @party = wizard_load_or_redirect(fallback_url, sub_object_attribute)
      end
    end

    # Sets up wizard model if it doesn't already exist in the cache this is for unauthenticated
    # We set to ADS and LBTT as that is the only supported reason, this relies on the later validation to stop
    # the user going forward
    # This does rely on the clear cache having been called the main step
    # @return [LbttReturn] the model for wizard saving
    def setup_eligibility_step
      @post_path = wizard_post_path
      @claim_payment = wizard_load

      return @claim_payment unless @claim_payment.nil?

      # Set up the new claim including saving it back, otherwise it is lost when we post back to the same page
      # Set reason to ADS and LBTT as this is always the case in the unauthenticated flow, it does rely on reference
      # validation to enforce this
      # We need to set LBTT as well so the claim reason lookup is initialised correctly
      @claim_payment = Claim::ClaimPayment.new(current_user: current_user, reason: 'ADS', srv_code: 'LBTT')
      wizard_save(@claim_payment)
      @claim_payment
    end

    # Specific set up for the claim reason step.
    # Loads the claim payment if it exists else creates a new one
    # This does rely on clear cache having been called for a new claim
    # Follows the same pattern as @see LbttPropertiesController#setup_step
    # @return [ClaimPayment] model for the wizard to use
    def setup_claim_reason_step
      @post_path = wizard_post_path
      @claim_payment = wizard_load

      return @claim_payment unless @claim_payment.nil?

      # Set up the new claim including saving it back, otherwise it is lost when we post back to the same page
      setup_payment_check_params
      @claim_payment = Claim::ClaimPayment.new(srv_code: params[:srv_code],
                                               tare_reference: params[:reference],
                                               version: params[:version], current_user: current_user)
      wizard_save(@claim_payment)
      @claim_payment
    end

    # checks the parameters are correct to setup a claim payment
    # @raise [Error::AppError] if the required parameters were not passed
    def setup_payment_check_params
      return if %i[srv_code reference version].all? { |key| params[key].present? }

      raise Error::AppError.new('Claim Payments', 'Missing parameters detected')
    end

    # Return the parameter list filtered for the attributes of the ClaimPayment model
    def filter_params(sub_object_attribute = nil)
      required, attributes = if sub_object_attribute == :taxpayers
                               [:returns_lbtt_party, Returns::Lbtt::Party.attribute_list]
                             else
                               [:claim_claim_payment, Claim::ClaimPayment.attribute_list]
                             end
      params.require(required).permit(attributes, unauthenticated_declarations_ids: [], eligibility_checkers: []) if
                                                                                                params[required]
    end

    # @return array of file types depend upon Authenticate user or not
    # If there is a current_user present and it is a NON_ADS claim,
    #  (i.e. AUTHENTICATED NON_ADS CLAIM) then that means it does not need to return an array
    def evidence_files_file_types
      return %i[sale occupancy] if current_user.nil?

      return %i[portal_sale occupancy] if !current_user.nil? && @claim_payment.reason == 'ADS'

      nil
    end

    # Processing for ending the claim flow
    def end_claim_flow
      return unless params[:finish]

      clear_resource_items # clear cache
      redirect_to dashboard_path # For a non logged in user the button is replaced with a link on the page
    end
  end
end
