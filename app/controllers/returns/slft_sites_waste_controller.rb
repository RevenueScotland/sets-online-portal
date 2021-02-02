# frozen_string_literal: true

module Returns
  # Provides sites/waste specific controller functionality.
  class SlftSitesWasteController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include FileUploadHandler

    authorise requires: AuthorisationHelper::SLFT_SUMMARY

    # wizard steps in order; to end a wizard go to the site_waste_summary
    SITE_STEPS = %w[waste_description waste_tonnage waste_exemption site_waste_summary].freeze

    # waste summary for a given [single] site
    # If the site is passed in with the params, that is used, otherwise we get the site id from the session.
    def site_waste_summary
      # @note Whenever we want to go to this page, we should always make sure to pass an instance of the loaded Site
      #   object into the path that loads this page. Example: returns_slft_site_waste_summary_path(@site)
      #   So that the page will get loaded properly with the correct :site number.
      site_id = params[:site]
      site_id ||= selected_site

      # store the site id in the session
      Rails.logger.debug("Storing selected site #{site_id} in session")
      session[:returns_slft_site] = site_id

      load_site
      @wastes = @site.wastes

      csv_upload
      delete_all
      manage_save_draft
    end

    # waste wizard step, next step is waste_exemption if waste_tonnage > 0 else go straight back to summary
    def waste_tonnage
      wizard_step(nil) { { next_step: :waste_exemption_or_summary } }
    end

    # last waste wizard step, on submit, merges waste data into site data @see #dump_waste_into_slft_wizard
    def waste_exemption
      wizard_step(nil) { { next_step: :waste_summary_after_adding_waste, after_merge: :dump_waste_into_slft_wizard } }
    end

    # Delete the waste entry specified by ewc_code params[:waste]
    def destroy
      load_site
      delete_waste_entry(params[:waste])
      redirect_to waste_summary_after_adding_waste
    end

    # First step in waste wizard.
    # If the params include a waste id then this wizard's cache is cleared and that entry loaded.
    # @raise [Error::AppError] if the waste id is missing (provided as a param)
    # @return [Waste] the model for wizard saving
    def waste_description
      clear_cache = waste_new?
      Rails.logger.debug('New Waste entry') if clear_cache

      wizard_step(SITE_STEPS) { { setup_step: :setup_step, clear_cache: clear_cache } }
    end

    private

    # Rather than using ControllerHelper#manage_draft which redirects if need to save draft,
    # this method duplicates most of that one to validate the model and save the draft in situ on the sites summary.
    def manage_save_draft
      return unless params[:save_draft]

      Rails.logger.debug('save_draft pressed')
      return unless @slft_return.valid?(:draft)

      Rails.logger.debug('  validation passed')
      @slft_return.save_draft(current_user)

      # save it so we keep the reference numbers rather than generating copies each time save draft is pressed
      wizard_save(@slft_return, SlftController)

      # store the reference number in a temporary variable so we can confirm saving worked this time (only)
      @site_summary_save_reference = @slft_return.tare_reference
    end

    # This method handles when the user clicks the delete all link to remove all waste types. Also deletes any errors
    # on the site, as these may have come from imported rows.
    def delete_all
      return unless params[:delete_all]

      load_site if @site.nil?
      @wastes = @site.wastes = {}
      wizard_save(@slft_return, SlftController)
      wizard_end
    end

    # Remove a waste entry from the current site
    # @param uuid [SecureRandom.uuid] the waste's ID in the current site's wastes list
    def delete_waste_entry(uuid)
      Rails.logger.debug("Deleting Waste entry #{uuid} from site #{@site.lasi_refno}")

      # check have required info
      load_site if @site.nil?

      # check the key exists
      raise Error::AppError.new('WASTE', "Cannot find index #{uuid}") unless @site.wastes&.key?(uuid)

      # remove it
      @site.wastes&.delete(uuid)

      # update SLfT wizard (@site is part of @slft_return)
      wizard_save(@slft_return, SlftController)

      # clear waste wizard for good measure
      wizard_end
    end

    # Sets up @site (and @slft_return) ie gets the site id from the @see #selected_site method and the Site from the
    # SlftController's wizard cache.
    def load_site
      site_id = selected_site
      Rails.logger.debug("Loading site #{site_id}")
      @slft_return = wizard_load(SlftController)
      @site = @slft_return.sites[site_id]
    end

    # @return [Integer] the selected lasi_refno from the session
    # @raise [Error:AppError] if the site id doesn't exist in the session
    def selected_site
      site_id = session[:returns_slft_site]
      raise Error::AppError.new('Waste', "Missing site id in session for waste: #{waste_data}") if site_id.nil?

      site_id.to_i
    end

    # Puts the SlftSitesWasteController wizard data (ie @waste @see #setup_step)
    # into the main SLfT Wizard cache
    # @return [Boolean] true if successful
    def dump_waste_into_slft_wizard
      # make sure we have the site set up
      load_site
      @site.wastes = {} if @site.wastes.nil?

      # insert the waste into @site and save @slft_return (@site is part of @slft_return)
      @site.wastes[@waste.uuid] = @waste

      wizard_save(@slft_return, SlftController)
      wizard_end # clear the waste cache
      true
    end

    # Decides what the next step should be and calls @see #dump_waste_into_slft_wizard if going to waste summary page.
    # @return either :waste_exemption if waste_tonnage > 0 else :site_waste_summary
    def waste_exemption_or_summary
      # exempt tonnage so show next page in wizard @see Waste validation rules
      return returns_slft_waste_exemption_path if @waste.exempt_breakdown_needed?

      # must save details before going to the summary page
      dump_waste_into_slft_wizard
      waste_summary_after_adding_waste
    end

    # The standard way of using the path of the waste summary details, which is used after adding a new waste type.
    def waste_summary_after_adding_waste
      returns_slft_site_waste_summary_path(@site)
    end

    # Handles where a user has uploaded a CSV file
    def csv_upload
      handle_file_upload(nil, add_processing: :validate_and_import_waste_file, clear_cache: true)
      return unless params[:csv_upload]

      wizard_save(@slft_return, Returns::SlftController)
      # specifically clear the resource items as we don't want them shown, force the clear
      clear_resource_items(force: true)
    end

    # Callback from the file upload component. Validates and imports the waste file. If the file isn't a well
    # formed CSV file, the file isn't imported and a validation message attached to the file_data element of
    # the resource_item in the hash.
    # If there are errors on the individual rows the file is imported, with errors attached to the individual
    # wastes that are created
    # @param resource_item [Object] The resource item being processed
    # @return [Boolean] indicator if the file has been imported correctly
    def validate_and_import_waste_file(resource_item)
      return if resource_item.nil?

      Rails.logger.debug("Importing File #{resource_item.original_filename}")

      imported_wastes = @site.import_waste_csv_data resource_item
      duplicate_waste_errors_into_resource_item(resource_item, imported_wastes)
      copy_import_into_site(imported_wastes) if resource_item.errors.none?

      resource_item.errors.none?
    end

    # As the controller doesn't handle correcting validation errors on the wastes, we copy the waste error
    # messages into the resource_item so that they can be displayed to the user
    # @param resource_item [Object] The resource item being processed
    # @param imported_wastes [Array] The imported wastes
    def duplicate_waste_errors_into_resource_item(resource_item, imported_wastes)
      any_errors = false
      imported_wastes.each do |w|
        next if w.errors.none?

        duplicate_single_waste_errors_into_resource_item(resource_item, w)
        any_errors = true
      end
      resource_item.errors.add(:base, :reimport_file) if any_errors
    end

    # see @duplicate_waste_errors_into_resource_item
    # This handles the individual waste item
    # @param resource_item [Object] The resource item being processed
    # @param waste [Object] The imported waste
    def duplicate_single_waste_errors_into_resource_item(resource_item, waste)
      resource_item.errors.add(:base, t(:import_row_error, description: waste.ewc_code_and_description,
                                                           count: waste.errors.full_messages.count,
                                                           messages: waste.errors.full_messages.join(', ')))
    end

    # Copy the imported wastes into the site
    def copy_import_into_site(imported_wastes)
      imported_wastes.each { |w| @site.wastes[w.uuid] = w }
    end

    # Call back from FileUploadHandler, which returns file types are allowed to be uploaded.
    def content_type_whitelist
      Rails.configuration.x.slft_waste_file_upload_content_type_whitelist.split(/\s*,\s*/)
    end

    # Call back from FileUploadHandler, which returns additional/alias content types are allowed
    # i.e. CSV mime type should be text/csv, but with a machine with Excel on it, the
    # type would be application/vnd.ms-excel
    def alias_content_type
      Rails.configuration.x.slft_waste_file_upload_alias_content_type_whitelist.split(/\s*,\s*/)
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # Wastes are indexed by UUID so we don't get the wrong one when editing or deleting them.
    # Follows the same pattern as @see LbttPartiesController#setup_step
    # @note This method is very similar to the setup_step method of lbtt_parties_controller.rb
    # @raise [Error::AppError] if the waste id is missing (provided as a param)
    # @return [Waste] the model for wizard saving
    def setup_step
      # these routes are all based on the SLfT main controller
      @post_path = wizard_post_path

      load_site

      # load existing or setup new Waste on first entering the step
      unless params[:continue] || params[:waste].nil? || waste_new?
        @waste = load_waste
        return @waste
      end

      # reload existing waste entry from the wizard or create a new one
      @waste = wizard_load || Slft::Waste.new(site_name: @site.site_name)
    end

    # Extract waste object from the site's waste list and save it in the wizard cache.
    # @return [Waste] loaded object
    # @raise [Error::AppError] if the waste doesn't exist
    def load_waste
      # ID of the object to load
      uuid = params[:waste]
      raise Error::AppError.new('WASTE', "Can't find index #{uuid}") unless @site.wastes.key?(uuid)

      waste = @site.wastes[uuid]
      wizard_save(waste)

      waste
    end

    # Determines if the param id :waste consists of the value 'new'.
    # Normally used in the creation of a new waste type or editing an existing waste.
    # @return [Boolean] does the waste param consist of value 'new'?
    def waste_new?
      params[:waste] == 'new'
    end

    # Loads existing wizard models from the wizard cache or redirects to the first step.
    # @return [Waste] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @waste = wizard_load_or_redirect(returns_slft_summary_url)
    end

    # Return the parameter list filtered for the attributes of the SlftReturn model.
    def filter_params(_sub_object_attribute = nil)
      required = :returns_slft_waste
      attribute_list = Slft::Waste.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
