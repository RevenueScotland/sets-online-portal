# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Applications
  # Controller class for SLfT (Scottish Landfill Tax) return
  class SlftController < ApplicationController # rubocop:disable Metrics/ClassLength
    # Wizard controller - allows fast generation of wizards storing merged parameters which can be converted
    # to FLApplication objects with the appropriate .new call.  Downside is when we load an object graph,
    # only the top level is created as that object (eg SlftReturn.new(wizard_load) makes a SlftReturn object
    # but the sites field will contain a hash of hashes and not a hash of Site objects).  Getting round
    # that is not worth the effort - at the moment it's only convenient to use the whole object graph in views
    # so conversion will be required as views are being set up (@see #sites).
    include Wizard
    include WizardAddressHelper
    include FileUploadHandler

    # to require authentication so we don't mix the two up
    skip_before_action :require_user

    # enforce the user isn't logged in on the initial pages
    before_action :enforce_public, only: %w[public_landing applicant_type]

    # List of steps for a public slft application of landfill operator- (Restoration notification/ Non-disposal area or
    #    weigh bridge application) variant
    LO_STEPS = %w[applicant_type application_type existing_agreement applicant_details applicant_address
                  supporting_documents declaration confirmation_and_document_upload].freeze

    # List of steps for a public slft application of landfill operator- Water discount variant
    LO_WD_STEPS = %w[waste_producer_details waste_producer_address declaration].freeze

    # List of steps for a public slft application of waste producer variant
    WP_STEPS = %w[applicant_type existing_agreement waste_producer_details waste_producer_address about_waste_water
                  banned_from_landfill about_the_waste about_water_content water_treatment start_date].freeze

    # Home page for unauthenticated wizard
    def public_landing; end

    # wizard page for public slft application
    def applicant_type
      clear_cache = params[:new].present?
      wizard_step(LO_STEPS) do
        { setup_step: :applicant_type_setup, next_step: :applicant_type_next_step,
          clear_cache: clear_cache }
      end
    end

    # wizard page for public slft application
    def application_type
      wizard_step(LO_STEPS) { { setup_step: :application_type_setup } }
    end

    # wizard page for public slft application
    def existing_agreement
      wizard_step(nil) { { next_step: :applicant_type_next_step } }
    end

    # wizard page for public slft application
    def applicant_details
      wizard_step(LO_STEPS) { { sub_object_attribute: :landfill_operator } }
    end

    # wizard page for public slft application
    def applicant_address
      wizard_address_step(summary_applications_slft_sites_path, sub_object_attribute: :landfill_operator)
    end

    # wizard page for public slft application
    def supporting_documents
      wizard_step(LO_STEPS)
    end

    # wizard page for public slft application
    def waste_producer_details
      wizard_step(LO_WD_STEPS) { { sub_object_attribute: :waste_producer } }
    end

    # wizard page for public slft application
    def waste_producer_address
      wizard_address_step(nil, sub_object_attribute: :waste_producer, next_step: :waste_producer_address_next_step)
    end

    # wizard page for public slft application
    def about_waste_water
      wizard_step(WP_STEPS) { { validates: :added_for_transport } }
    end

    # wizard page for public slft application
    def banned_from_landfill
      wizard_step(WP_STEPS) { { validates: :not_banned_waste } }
    end

    # wizard page for public slft application
    def about_the_waste
      wizard_step(WP_STEPS)
    end

    # wizard page for public slft application
    def about_water_content
      wizard_step(WP_STEPS)
    end

    # wizard page for public slft application
    def water_treatment
      wizard_step(nil) { { next_step: :water_treatment_next_step } }
    end

    # wizard page for public slft application
    def start_date
      wizard_step(summary_applications_slft_sites_path)
    end

    # wizard page for public slft application
    def declaration
      wizard_step(LO_STEPS) { { validates: :declaration, after_merge: :save_data_in_back_office } }
    end

    # which file types are allowed to be uploaded
    def content_type_allowlist
      Rails.configuration.x.file_upload_content_type_allowlist.split(/\s*,\s*/)
    end

    # last wizard page for public slft application
    def confirmation_and_document_upload
      wizard_step(LO_STEPS)

      # Clear the cache to remove previously upload resource files
      # This means if the user refreshes the page they lose the list of files uploaded
      # but prevents files being shown incorrectly
      handle_file_upload('confirmation_and_document_upload',
                         before_add: :add_supporting_document,
                         before_delete: :delete_supporting_document,
                         clear_cache: request.get?)
    end

    # Send document to back office
    # @return [Boolean][String] true if document store successfully back office else false and
    #   document reference id
    def add_supporting_document(resource_item)
      @slft_application.add_supporting_document(resource_item)
    end

    # Call delete evidence_file method to delete document from back office
    # @param doc_refno [String] document reference number to be delete from back office
    # @return [Boolean] true if document delete successfully from back office else false
    def delete_supporting_document(doc_refno)
      @slft_application.delete_supporting_document(doc_refno)
    end

    # Overwrites the user method to pass unique id for unauthenticated user to create folder on server
    # folder will hold the file uploaded by user
    def sub_directory
      @slft_application ||= load_step
      @slft_application.case_references[0]
    end

    # The method used to retrieve the pdf summary of the application
    # The "target: '_blank'" page used to download the pdf file of the return according
    # to its details.
    def download_pdf
      @slft_application ||= load_step
      success, application_pdf = @slft_application.back_office_pdf_data
      return unless success

      # Download the file
      send_file_from_attachment(application_pdf[:document_case])
    rescue StandardError => e
      error_ref = Error::ErrorHandler.log_exception(e)

      redirect_to_error_page(error_ref, home_new_page_error_url)
    end

    private

    # calls back office service to save data on back office
    def save_data_in_back_office
      @slft_application.save
      wizard_save(@slft_application)
    end

    # Sets up wizard model if it doesn't already exist in the cache or applicant_type changes
    # @return [Object] the slft_application wizard cache object for wizard saving
    def applicant_type_setup
      @post_path = wizard_post_path
      # Do not use load and redirect as this is the first page
      @slft_application = wizard_load
      applicant_type = filter_params[:applicant_type] unless filter_params.nil?
      # The application_type is only set for the "Waste Producer" path as it doesn't go through application-type page
      application_type = 'WP-WD' if applicant_type == 'WP'
      return_model_on_applicant_type(applicant_type, application_type)
    end

    # Cleans the slft_application and adds some initial data if this is
    # the first time the form has been submitted on the applicant-type page,
    # or the applicant-type has changed on form submission.
    # @return [Object] the slft_application wizard cache object
    def return_model_on_applicant_type(applicant_type, application_type)
      # We're comparing the applicant_type with the previously selected applicant_type to determine
      # whether if we need to clean the pages or not.
      # @slft_application.applicant_type is a previously selected applicant_type.
      if @slft_application.nil? || (applicant_type.present? && (applicant_type != @slft_application.applicant_type))
        initialise_slft_application(applicant_type, application_type)
      end
      @slft_application
    end

    # Sets up new wizard model in the cache if new application_type selected
    # @return [Object] the slft_application wizard cache object for wizard saving
    def application_type_setup
      @post_path = wizard_post_path
      @slft_application = load_step
      applicant_type = @slft_application.applicant_type
      application_type = filter_params[:application_type] unless filter_params.nil?
      return_model_on_application_type(applicant_type, application_type)
    end

    # Cleans the slft_application and adds some initial data if this is
    # the first time the form has been submitted on the application-type page,
    # or the application-type has changed on form submission.
    # @return [Object] the slft_application wizard cache object
    def return_model_on_application_type(applicant_type, application_type)
      # We're comparing the application_type with the previously selected application_type to determine
      # whether if we need to clean the pages or not.
      # @slft_application.application_type is a previously selected application_type.
      previous_application_type = @slft_application.application_type
      if previous_application_type.nil? || ((application_type != previous_application_type) &&
                                             application_type.present? && !previous_application_type.nil?)
        initialise_slft_application(applicant_type, application_type)
      end

      @slft_application
    end

    # Initialise a new instance of the model and sub_objects like waste_producer and landfill_operator
    def initialise_slft_application(applicant_type, application_type)
      @slft_application =
        Applications::Slft::Applications.new(applicant_type: applicant_type, application_type: application_type)
      @slft_application.waste_producer = Applications::Slft::Applicants.new if @slft_application.water_discount?
      @slft_application.landfill_operator = Applications::Slft::Applicants.new if
                                              @slft_application.not_waste_producer_water_discount?
    end

    # Calculates which wizard steps to be followed after applicant_type page
    def applicant_type_next_step
      return WP_STEPS if @slft_application.waste_producer_water_discount?

      LO_STEPS
    end

    # Calculates which wizard steps to be followed after applicant_type page
    def waste_producer_address_next_step
      return WP_STEPS if @slft_application.waste_producer_water_discount?

      LO_WD_STEPS
    end

    # Calculates which wizard steps to be followed after applicant_type page
    def water_treatment_next_step
      return WP_STEPS if @slft_application.start_date_required?

      summary_applications_slft_sites_path
    end

    # Loads existing wizard models from the wizard cache or redirects to the dashboard page
    def load_step(sub_object_attribute = nil)
      @post_path = wizard_post_path

      case sub_object_attribute
      when :landfill_operator
        @slft_application, @landfill_operator = wizard_load_or_redirect(fallback_url, sub_object_attribute)
      when :waste_producer
        @slft_application, @waste_producer = wizard_load_or_redirect(fallback_url, sub_object_attribute)
      else
        @slft_application = wizard_load_or_redirect(fallback_url)
      end
    end

    # Holds the fallback url for when the wizard load fails
    def fallback_url
      # This function can't be a constant as the method is only available when the controller is instantiated
      public_landing_applications_slft_url
    end

    # Return the parameter list filtered for the attributes of the slft_applications model
    def filter_params(sub_object_attribute = nil)
      required, attributes = if %i[landfill_operator waste_producer].include?(sub_object_attribute)
                               [:applications_slft_applicants, Applications::Slft::Applicants.attribute_list]
                             else
                               [:applications_slft_applications, Applications::Slft::Applications.attribute_list]
                             end
      params.require(required).permit(attributes, supporting_document_list: []) if params[required]
    end
  end
end
