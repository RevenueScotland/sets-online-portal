# frozen_string_literal: true

module Returns
  # Provides sites/waste specific controller functionality.
  class SlftSitesWasteController < ApplicationController
    include Wizard

    authorise requires: AuthorisationHelper::SLFT_SUMMARY

    # wizard steps in order; to end a wizard go to the site_waste_summary
    SITE_STEPS = %w[waste_description waste_tonnage waste_exemption site_waste_summary].freeze

    # waste summary for a given [single] site
    # If the site is passed in with the params, that is used, otherwise we get the site id from the session.
    def site_waste_summary
      site_id = params[:site]
      site_id ||= selected_site

      # store the site id in the session
      Rails.logger.debug("Storing selected site #{site_id} in session")
      session[:returns_slft_site] = site_id

      load_site
      @wastes = @site.wastes

      manage_save_draft
    end

    # waste wizard step, next step is waste_exemption if waste_tonnage > 0 else go straight back to summary
    def waste_tonnage
      wizard_step(nil) { { params: :filter_params, next_step: :waste_exemption_or_summary } }
    end

    # last waste wizard step, on submit, merges waste data into site data @see #dump_waste_into_slft_wizard
    def waste_exemption
      wizard_step(SITE_STEPS) { { params: :filter_params, after_merge: :dump_waste_into_slft_wizard } }
    end

    # Delete the waste entry specified by ewc_code params[:waste]
    def delete
      load_site
      delete_waste_entry(params[:waste])
      redirect_to returns_slft_site_waste_summary_path
    end

    # First step in waste wizard.  This is a custom wizard step (code adapted from #wizard_step).
    # After clearing the cache of previous waste data, the first part loads the site information and optionally loads
    # selected waste data (for editing).
    # Second part submits the data to the normal wizard code but if that produces validation errors then it re-runs the
    # first part (to repopulate the EWC list).
    #
    # NB if params[:waste] is set, @see #load_waste_for_edit will load an existing Waste object into the wizard cache.
    def waste_description
      # first part - initial view
      unless params[:submitted]
        # clears cache before loading any variables (ie clear previous waste details)
        # checks for params[:new] so that pressing back on subsequent page will NOT clear cache
        wizard_end if params[:new]

        load_site
        setup_step
        load_waste
        return
      end

      # Second part - when step is submitted
      # On success, clears the edit_waste from the session (used for editing)
      wizard_step_submitted(SITE_STEPS, params: :filter_params)
    end

    private

    # Rather than using ControllerHelper#manage_draft which redirects if need to save draft,
    # this method duplicates most of that one to validate the model and save the draft in situ on the sites summary.
    def manage_save_draft
      return unless params[:save_draft]

      Rails.logger.debug('save_draft pressed')
      return unless @slft_return.valid?(:draft)

      Rails.logger.debug('  validation passed')
      @slft_return.clean_up_yes_nos
      Rails.logger.debug('  about to Save')
      @slft_return.save_draft(current_user)

      # save it so we keep the reference numbers rather than generating copies each time save draft is pressed
      wizard_save(@slft_return, SlftController)

      # store the reference number so we can confirm saving worked
      @site_summary_save_reference = @slft_return.tare_reference
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

    # The first part of the waste_description wizard step. @see #waste_description
    # When @param[:waste] is set, will copy that value into the wizard so the entry can be edited.
    def load_waste
      # do nothing if not clicked link for editing an existing waste entry
      uuid = params[:waste]
      return if uuid.nil?

      raise Error::AppError.new('WASTE', "Can't find index #{uuid}") unless @site.wastes.key?(uuid)

      # save in waste wizard
      @waste = @site.wastes[uuid]
      wizard_save(@waste)
    end

    # Sets up @site (and @slft_return) ie gets the site id from the @see #selected_site method and the Site from the
    # SlftController's wizard cache.
    def load_site
      site_id = selected_site
      Rails.logger.debug("Loading site #{site_id}")
      @slft_return = wizard_load(SlftController)
      @site = @slft_return.sites[site_id]
    end

    # Sets up variables for the form to use (where to post the form to).
    # Loads existing waste info (into @waste) if available in the wizard cache.
    # @return [Waste] the model for wizard saving
    def setup_step
      # Our routes are all based on the SLfT main controller
      @post_path = wizard_post_path(SlftController.name)

      # get waste from wizard cache if not done above or if that's empty, start a new one
      @waste ||= wizard_load || Slft::Waste.new
      @waste
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
    def dump_waste_into_slft_wizard
      # make sure we have the site set up
      load_site
      @site.wastes = {} if @site.wastes.nil?

      # insert the waste into @site and save @slft_return (@site is part of @slft_return)
      @site.wastes[@waste.uuid] = @waste
      wizard_save(@slft_return, SlftController)
    end

    # Decides what the next step should be and calls @see #dump_waste_into_slft_wizard if going to waste summary page.
    # @return either :waste_exemption if waste_tonnage > 0 else :site_waste_summary
    def waste_exemption_or_summary
      # exempt tonnage so show next page in wizard @see Waste validation rules which duplicates this
      return returns_slft_waste_exemption_path unless @waste.exempt_tonnage.nil? || @waste.exempt_tonnage.to_f <= 0

      # must save details before going to the summary page
      dump_waste_into_slft_wizard
      returns_slft_site_waste_summary_path
    end

    # Return the parameter list filtered for the attributes of the SlftReturn model.
    def filter_params
      required = :returns_slft_waste
      attribute_list = Slft::Waste.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
