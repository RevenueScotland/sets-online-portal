# frozen_string_literal: true

module Returns
  # Provides sites/credit claims specific controller functionality.
  class SatCreditClaimsController < ApplicationController
    include Wizard

    authorise requires: RS::AuthorisationHelper::SAT_SUMMARY

    # wizard steps in order
    STEPS = %w[tax_credit_details tax_credit_tonnage].freeze

    # tax credit details page wizard step
    def tax_credit_details
      clear_cache = credit_claim_new?
      Rails.logger.debug('New tax credit entry') if clear_cache

      wizard_step(STEPS) { { setup_step: :setup_step, clear_cache: clear_cache } }
    end

    # tax credit tonnage page wizard
    def tax_credit_tonnage
      wizard_step(nil) do
        { setup_step: :setup_tax_credit_tonnage, next_step: :site_summary_after_adding_tax_credit,
          after_merge: :dump_credit_claim_into_sat_wizard }
      end
    end

    # Delete the credit claim entry specified by uuid params[:credit_claim]
    def destroy
      load_site
      delete_credit_claim_entry(params[:credit_claim])
      redirect_to(site_summary_after_adding_tax_credit, status: :see_other)
    end

    private

    # Sets up wizard model if it doesn't already exist in the cache
    # Credit_claims are indexed by UUID so we don't get the wrong one when editing or deleting them.
    # @raise [Error::AppError] if the credit claim id is missing (provided as a param)
    # @return [CreditClaim] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path

      # load site before setup model
      load_site

      # load existing or setup new credit_claim on first entering the step
      unless params[:continue] || params[:credit_claim].nil? || credit_claim_new?
        @credit_claim = load_claim
        return @credit_claim
      end

      # reload existing credit_claim entry from the wizard or create a new one
      @credit_claim = wizard_load || Sat::CreditClaim.new(store_additional_site_params)

      @credit_claim
    end

    # @return hash to store the values in credit claim model for further use
    def store_additional_site_params
      { rate_date: @site.rate_date, site_name: @site.site_name, period_start: @site.period_bdown_start,
        period_end: @site.period_bdown_end, current_user: current_user }
    end

    # Setup step for tax credit tonnage page
    # use to make a bo call based on tax_period_ind selected on previous page
    # @return [CreditClaim] the model for wizard saving
    def setup_tax_credit_tonnage
      @credit_claim ||= load_step

      if @credit_claim.tax_period_ind == 'Y'
        @credit_claim.current_return = @credit_claim.return_period_display
      elsif @credit_claim.tax_period_ind == 'N'
        @credit_claim.list_all_previous_return_periods
      end

      @credit_claim
    end

    # Extract credit claim object from the site and save it in the wizard cache.
    # @return [CreditClaim] loaded object
    # @raise [Error::AppError] if the credit claim doesn't exist
    def load_claim
      # ID of the object to load
      uuid = params[:credit_claim]
      unless @site.credit_claims.key?(uuid)
        raise Error::AppError.new('Credit Claims',
                                  "Can't find index #{uuid}")
      end

      @credit_claim = @site.credit_claims[uuid]
      wizard_save(@credit_claim)

      @credit_claim
    end

    # Remove a credit claim entry from the current site
    # @param uuid [SecureRandom.uuid] the claim's ID in the current site's list
    def delete_credit_claim_entry(uuid)
      Rails.logger.debug { "Deleting Tax Credit entry #{uuid} from site #{@site.site_name}" }

      # check have required info
      load_site if @site.nil?

      # check the key exists
      raise Error::AppError.new('CREDIT_CLAIMS', "Cannot find index #{uuid}") unless @site.credit_claims&.key?(uuid)

      # remove from site
      @site.credit_claims&.delete(uuid)

      # update SAT wizard (@site is part of @sat_return)
      wizard_save(@sat_return, SatController)

      # clear credit claim wizard for good measure
      wizard_end
    end

    # The standard way of using the path of the site summary details, which is used after adding a new credit claim type
    def site_summary_after_adding_tax_credit
      returns_sat_site_summary_path(@site)
    end

    # Sets up @site (and @sat_return) ie gets the site id from the @see #selected_site method and the Site from the
    # SatController's wizard cache.
    def load_site
      site_id = selected_site
      Rails.logger.debug { "Loading site #{site_id} for credit claims" }
      @sat_return = wizard_load_or_redirect(returns_sat_summary_url, nil, SatController)
      # If they have entered part way through they may have a return with no sites so send them back
      raise Error::WizardRedirectError, returns_sat_summary_url if @sat_return.sites.nil?

      @site = @sat_return.sites[site_id]
    end

    # @return [Integer] the selected site_id from the session
    def selected_site
      session[:returns_sat_site]
    end

    # Determines if the param id :credit_claim consists of the value 'new'.
    # Normally used in the creation of a new credit_claim type or editing an existing credit_claim.
    # @return [Boolean] does the credit_claim param consist of value 'new'?
    def credit_claim_new?
      params[:credit_claim] == 'new'
    end

    # Puts the SatCreditClaimsController wizard data (ie @credit_claim @see #setup_step)
    # into the main Sat Wizard cache
    # @return [Boolean] true if successful
    def dump_credit_claim_into_sat_wizard
      # make sure we have the site set up
      load_site
      @site.credit_claims = {} if @site.credit_claims.nil?

      # insert the credit_claim into @site and save @sat_return (@site is part of @sat_return)
      @site.credit_claims[@credit_claim.uuid] = @credit_claim

      wizard_save(@sat_return, SatController)
      wizard_end # clear the credit_claim cache
      true
    end

    # Loads existing wizard models from the wizard cache or redirects to the first step.
    # @return [CreditClaim] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @credit_claim = wizard_load_or_redirect(returns_sat_site_summary_url)
      @credit_claim
    end

    # Return the parameter list filtered for the attributes of the CreditClaim model.
    def filter_params(_sub_object_attribute = nil)
      required = :returns_sat_credit_claim
      attribute_list = Returns::Sat::CreditClaim.attribute_list

      return unless params[required]

      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
