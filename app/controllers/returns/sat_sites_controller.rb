# frozen_string_literal: true

module Returns
  # Provides SAT sites specific controller functionality.
  class SatSitesController < ApplicationController
    include Wizard
    include FileUploadHandler

    authorise requires: RS::AuthorisationHelper::SAT_SUMMARY
    authorise route: :save_draft, requires: RS::AuthorisationHelper::SAT_SAVE

    # site summary for a given [single] site
    # If the site is passed in with the params, that is used, otherwise we get the site id from the session.
    def site_summary
      # @note Whenever we want to go to this page, we should always make sure to pass an instance of the loaded Site
      #   object into the path that loads this page. Example: returns_sat_site_summary_path(@site)
      #   So that the page will get loaded properly with the correct :site number.
      site_id = params[:site]
      site_id ||= selected_site

      # store the site id in the session
      Rails.logger.debug { "Storing selected site #{site_id} in session" }
      session[:returns_sat_site] = site_id

      load_site

      delete_all
      manage_save_draft
    end

    # Set Nil Submission Indicator data
    def aggregate_activity
      store_and_load_site
      redirect_on_aggregate_submit
    end

    private

    # This method stores and loads relevant site
    def store_and_load_site
      site_id = params[:site]
      site_id ||= selected_site

      # store the site id in the session
      Rails.logger.debug { "Storing selected site #{site_id} in session" }
      session[:returns_sat_site] = site_id

      load_site
    end

    # Redirect to relevant page upon submission of the aggregate activity form
    def redirect_on_aggregate_submit
      sat_sites_params = params[:returns_sat_sites]
      return if sat_sites_params.nil? || sat_sites_params.blank?

      return render(status: :unprocessable_entity) unless validate_nil_submission_form(sat_sites_params)

      @site.tld_nil_submit = sat_sites_params[:tld_display_value] == 'Y' ? 'N' : 'Y'
      wizard_save(@sat_return, SatController)
      wizard_end
      redirect_to(sat_sites_params[:tld_display_value] == 'N' ? returns_sat_summary_url : returns_sat_site_summary_url)
    end

    # Validate the nil submission form submission
    def validate_nil_submission_form(sat_sites_params)
      @site.validate_nil_submit = true
      @site.tld_nil_submit = sat_sites_params[:tld_display_value] if sat_sites_params[:tld_display_value].present?
      @site.valid?
    end

    # Rather than using ControllerHelper#manage_draft which redirects if need to save draft,
    # this method duplicates most of that one to validate the model and save the draft in site on the sites summary.
    def manage_save_draft
      return unless params[:save_draft]

      Rails.logger.debug('save_draft pressed')
      render(status: :unprocessable_entity) && return unless @sat_return.valid?(:draft)

      Rails.logger.debug('  validation passed')
      @sat_return.save_draft(current_user)

      # save it so we keep the reference numbers rather than generating copies each time save draft is pressed
      wizard_save(@sat_return, SatController)

      # store the reference number in a temporary variable so we can confirm saving worked this time (only)
      @site_summary_save_reference = @sat_return.tare_reference
      render(status: :unprocessable_entity)
    end

    # This method handles when the user clicks the delete all link to remove all aggregate/claim types.
    # Also deletes any errors on the site, as these may have come from imported rows.
    def delete_all
      return unless params[:delete_all] || request.delete?

      load_site if @site.nil?
      # based on the params it will delete the object
      delete_models(params)
      wizard_save(@sat_return, SatController)
      wizard_end
      render status: :unprocessable_entity
    end

    # This method is to delete all the types of selected aggregate/claim type
    # Based on the params passed in it will delete all the entries.
    def delete_models(params)
      if params[:aggregate]
        @taxable_aggregates = @site.taxable_aggregates = {}
      elsif params[:exempt_aggregate]
        @exempt_aggregates = @site.exempt_aggregates = {}
      elsif params[:credit_claim]
        @credit_claims = @site.credit_claims = {}
      end
    end

    # Sets up @site (and @sat_return) ie gets the site id from the @see #selected_site method and the Site from the
    # SatController's wizard cache.
    def load_site
      site_id = selected_site
      Rails.logger.debug { "Loading site #{site_id}" }
      @sat_return = wizard_load_or_redirect(returns_sat_summary_url, nil, SatController)
      # If they have entered part way through they may have a return with no sites so send them back
      raise Error::WizardRedirectError, returns_sat_summary_url if @sat_return.sites.nil?

      @site = @sat_return.sites[site_id]
    end

    # @return [Integer] the selected site_id from the session
    # @raise [Error:AppError] if the site id doesn't exist in the session
    def selected_site
      site_id = session[:returns_sat_site]
      raise Error::AppError.new('Sites', 'Missing site id') if site_id.nil?

      site_id
    end

    # Loads existing wizard models from the wizard cache or redirects to the first step.
    # @return [Sites] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @site = wizard_load_or_redirect(returns_sat_summary_url)

      @site
    end

    # Return the parameter list filtered for the attributes of the Sites model.
    def filter_params(_sub_object_attribute = nil)
      attribute_list = Returns::Sat::Sites.attribute_list
      required = :returns_sat_site

      return unless params[required]

      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
