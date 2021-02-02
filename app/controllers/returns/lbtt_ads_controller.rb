# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # ADS = Additional Dwelling Supplements.  Wizard for collecting ADS information and putting it
  # into the main LbttController wizard (rather than creating separate ones then having to do a merge process)
  # See tax wizard for a similar example
  class LbttAdsController < ApplicationController
    include Wizard
    include WizardListHelper
    include WizardAddressHelper
    include LbttTaxHelper
    include LbttControllerHelper

    authorise requires: AuthorisationHelper::LBTT_SUMMARY

    # wizard steps for the ADS simple wizard in order; last step responsible for redirecting @see #ads_intending_sell
    STEPS = %w[ads_dwellings ads_amount ads_intending_sell ads_reliefs].freeze

    # wizard steps for the repayment ADS wizard, @see LbttTaxController for the last step
    REPAYMENT_STEPS = %w[ads_repay_reason ads_repay_date ads_repay_address ads_repay_details].freeze

    # First step in ADS repayment wizard, chooses whether to continue with the REPAYMENT_STEPS or to switch to STEPS.
    def ads_repay_reason
      wizard_step(nil) { { next_step: :ads_repay_reason_next_steps } }
    end

    # Step in the ADS repayment wizard
    def ads_repay_date
      wizard_step(REPAYMENT_STEPS)
    end

    # Step in the ADS repayment wizard
    def ads_repay_address
      wizard_address_step(REPAYMENT_STEPS, address_attribute: :rrep_ads_sold_address)
    end

    # Last step in the ADS repayment wizard, redirects to the LBTT summary page afterwards
    def ads_repay_details
      wizard_step(returns_lbtt_summary_url)
    end

    # First step in the normal ADS wizard
    def ads_dwellings
      wizard_step(STEPS)
    end

    # returns/lbtt/ads_amount - step in the ADS wizard
    def ads_amount
      wizard_step(STEPS)
    end

    # returns/lbtt/ads_intending_sell - step in the ADS wizard
    def ads_intending_sell
      wizard_address_step(STEPS, address_attribute: :ads_main_address, address_required: :ads_sell_residence_ind)
    end

    # returns/lbtt/ads_reliefs - custom step in the ADS wizard to handle the list of reliefs without them being in
    # their own special controller/wizard cache.
    # Navigates to the LBTT summary page after submitted.
    def ads_reliefs
      wizard_list_step(returns_lbtt_summary_url, setup_step: :setup_ads_reliefs_step,
                                                 list_attribute: :ads_relief_claims,
                                                 new_list_item_instance: :new_list_item_ads_relief_claims,
                                                 list_required: :ads_reliefclaim_option_ind,
                                                 after_merge: :update_tax_calculations)
    end

    private

    # Decides the next step based on the user input on the ads_repay_reason step.
    # @return [array] either STEPS (plus the current page so the wizard navigation finds it) or REPAYMENT_STEPS.
    def ads_repay_reason_next_steps
      return REPAYMENT_STEPS if @ads.ads_repayment?

      ['ads_repay_reason', STEPS.first]
    end

    # Used in wizard_list_step as part of the merging of data.
    # @return [Object] new instance of ReliefClaim class that has attributes with value.
    def new_list_item_ads_relief_claims
      Lbtt::ReliefClaim.new
    end

    # Overwrites the wizard_save method to save @lbtt_return instead of @tax (which is why we don't need cache_index
    # overrides in the steps)  @see #setup_step where @tax is found inside @lbtt_return
    def wizard_save(_master_object, _cache_index = self.class.name)
      key = wizard_cache_key(LbttController)
      Rails.logger.debug "Saving tax in wizard params for #{key}"
      Rails.cache.write(key, @lbtt_return, expires_in: wizard_cache_expiry_time)
    end

    # Loads existing wizard models (@lbtt_return and @ads) from the wizard cache or redirects to the summary page
    # @return [Tax] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @lbtt_return = wizard_load(Returns::LbttController)
      Lbtt::Ads.setup_ads(@lbtt_return)
      @ads = @lbtt_return.ads
    end

    # Custom setup for the ads_reliefs step
    # @return [LbttReturn] the model for wizard saving
    def setup_ads_reliefs_step
      model = load_step

      # ensure the form/model is populated with a list of ReliefClaim objects
      @ads.ads_relief_claims ||= Array.new(1) { Lbtt::ReliefClaim.new }

      # drop down list filtered to ADS reliefs
      @relief_types = ReferenceData::TaxReliefType.list_ads(@lbtt_return.flbt_type, true)

      model
    end

    # Return the parameter list filtered for the attributes of the Calculate model
    def filter_params(_sub_object_attribute = nil)
      required = :returns_lbtt_ads
      output = params.require(required).permit(Lbtt::Ads.attribute_list) if params[required]
      output
    end

    # Return the parameter list filtered for the attributes in list_attribute
    # note we have to permit everything because we get a hash of the records returned e.g. "0" => details
    def filter_list_params(list_attribute, _sub_object_attribute = nil)
      return unless params[:returns_lbtt_ads] && params[:returns_lbtt_ads][list_attribute]

      params.require(:returns_lbtt_ads).permit(list_attribute => {})[list_attribute].values
    end
  end
end
