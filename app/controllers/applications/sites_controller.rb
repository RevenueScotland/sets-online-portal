# frozen_string_literal: true

# Sub-directory to organise the applications.
module Applications
  # Controller class for SLfT (Scottish Landfill Tax) application Sites.
  class SitesController < ApplicationController
    # Wizard controller - allows fast generation of wizards storing merged parameters which can be converted
    # to FLApplication objects with the appropriate .new call.  Downside is when we load an object graph,
    # only the top level is created as that object (eg SlftReturn.new(wizard_load) makes a SlftReturn object
    # but the sites field will contain a hash of hashes and not a hash of Site objects).  Getting round
    # that is not worth the effort - at the moment it's only convenient to use the whole object graph in views
    # so conversion will be required as views are being set up (@see #sites).
    include Wizard
    include WizardListHelper
    include WizardAddressHelper

    # to require authentication so we don't mix the two up
    skip_before_action :require_user

    # List of steps for the slft application's LO- Non disposal variant
    ND_STEPS = %w[address non_disposal_details summary].freeze

    # List of steps for the slft application's LO- Restoration notification/Water discount variant
    RA_OR_WD_STEPS = %w[address wastes summary].freeze

    # List of steps for the slft application's LO- weighbridge variant
    WB_STEPS = %w[details address summary].freeze

    # List of steps for the slft application's Waste producer applicant_type variant
    WP_WD_STEPS = %w[details address separate_mailing_address type_of_waste summary].freeze

    # The sites summary page initializers for the slft application
    def summary
      wizard_step(nil) { { setup_step: :setup_summary_step, validates: :added_sites, next_step: :summary_next_step } }
    end

    # Processes some data initially to set up site model before adding site and
    # saves added site inside application model's sites array and redirect to site details page
    def new
      load_step

      @slft_application.sites = [] if @slft_application.sites.nil?

      @slft_application.sites << Applications::Slft::Sites.new(application_type: @slft_application.application_type,
                                                               existing_agreement: @slft_application.existing_agreement)

      wizard_save(@slft_application, parent_controller)

      redirect_to details_applications_slft_site_path(@slft_application.sites.length)
    end

    # The site details page initializers for both adding a new and editing an existing site
    def details
      wizard_step(WB_STEPS) { { sub_object_attribute: :sites, cache_index: parent_controller } }
    end

    # The site address page initializers for both adding a new and editing an existing site
    def address
      wizard_address_step(nil, sub_object_attribute: :sites, next_step: :address_next_step,
                               cache_index: parent_controller)
    end

    # The site non_disposal_details page initializers for both adding a new and editing an existing site
    def non_disposal_details
      wizard_step(ND_STEPS) { { sub_object_attribute: :sites, cache_index: parent_controller } }
    end

    # The site wastes page initializers for both adding a new and editing an existing site
    def wastes
      wizard_list_step(RA_OR_WD_STEPS, sub_object_attribute: :sites,
                                       setup_step: :setup_waste_step, list_attribute: :wastes,
                                       new_list_item_instance: :new_list_item_wastes,
                                       cache_index: parent_controller)
    end

    # The site separate_mailing_address page initializers for both adding a new and editing an existing site
    def separate_mailing_address
      wizard_address_step(WP_WD_STEPS, sub_object_attribute: :sites, address_attribute: :operator_mailing_address,
                                       address_required: :operator_separate_mailing_address,
                                       cache_index: parent_controller)
    end

    # The site type_of_waste page initializers for both adding a new and editing an existing site
    def type_of_waste
      wizard_step(WP_WD_STEPS) { { sub_object_attribute: :sites, cache_index: parent_controller } }
    end

    # Delete the site entry specified by sub_object_index
    def destroy
      load_step
      return if @slft_application.sites.nil?

      # deletes the site and save the return to make the deletion permanent
      @slft_application.sites.delete_at(params[:sub_object_index].to_i - 1)
      wizard_save(@slft_application, parent_controller)
      redirect_to summary_applications_slft_sites_path
    end

    # Calculates which wizard steps to be followed after address page of sites
    def address_next_step
      return ND_STEPS if @site.non_disposal?

      return RA_OR_WD_STEPS if @site.wastes_required?

      return WP_WD_STEPS if @site.waste_producer_water_discount?

      WB_STEPS
    end

    # Calculates which wizard steps to be followed after summary page of sites
    def summary_next_step
      return waste_producer_details_applications_slft_path if @slft_application.application_type == 'LO-WD'

      supporting_documents_applications_slft_path
    end

    private

    # The slft controller which is the parent controller of the slft applications,
    # this is used to save (and load) data in the wizard cache.
    def parent_controller
      Applications::SlftController
    end

    # Loads existing wizard models from the wizard cache or redirects to the dashboard page
    def load_step(sub_object_attribute = nil)
      @post_path = wizard_post_path

      if sub_object_attribute == :sites
        @slft_application, @site =
          wizard_load_or_redirect(dashboard_url, sub_object_attribute, parent_controller)
      else
        @slft_application = wizard_load_or_redirect(dashboard_url, sub_object_attribute, parent_controller)
      end
    end

    # Used in wizard_list_step as part of the merging of data.
    # @return [Object] new instance of Wastes class that has attributes with value.
    def new_list_item_wastes
      Applications::Slft::Wastes.new(application_type: @site.application_type)
    end

    # Setup for the Wastes model
    # @return [Site] the model
    def setup_waste_step
      objects = load_step(:sites)

      # initialise row data if not already present
      @site.wastes ||= Array.new(1) { Applications::Slft::Wastes.new(application_type: @site.application_type) }

      objects
    end

    # A specific step to setup the summary page, this removes a blank site if one was created by the
    # user choosing to add a site and then taking the back option
    def setup_summary_step
      load_step
      sites = @slft_application.sites
      # return if there are no sites or the last site has details
      if sites.blank? || (sites.last.sepa_license_number.present? && sites.last.site_name.present?)
        return @slft_application
      end

      # deletes the site added in the last and saves the return to make the deletion permanent
      sites.delete_at(-1)

      wizard_save(@slft_application, parent_controller)
    end

    # The permitted parameters which is filtered using the Site model's attributes.
    def filter_params(_sub_object_attribute = nil)
      return unless params[:applications_slft_sites]

      params.require(:applications_slft_sites).permit(Applications::Slft::Sites.attribute_list)
    end

    # Return the parameter list filtered for the attributes in list_attribute
    # note we have to permit everything because we get a hash of the records returned e.g. "0" => details
    def filter_list_params(list_attribute, _sub_object_attribute = nil)
      return unless params[:applications_slft_sites] && params[:applications_slft_sites][list_attribute]

      params.require(:applications_slft_sites).permit(list_attribute => {})[list_attribute].values
    end
  end
end
