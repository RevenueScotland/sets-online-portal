# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # ADS = Additional Dwelling Supplements.  Wizard for collecting ADS information and putting it
  # into the main LbttController wizard (rather than creating separate ones then having to do a merge process).
  class LbttAdsController < ApplicationController
    include Wizard
    include WizardListHelper
    include AddressHelper
    include LbttTaxHelper
    include LbttControllerHelper

    authorise requires: AuthorisationHelper::LBTT_SUMMARY

    # wizard steps for the ADS simple wizard in order; last step responsible for redirecting @see #ads_intending_sell
    STEPS = %w[ads_dwellings ads_amount ads_intending_sell ads_reliefs].freeze

    # wizard steps for the repayment ADS wizard, @see LbttTaxController for the last step
    REPAYMENT_STEPS = %w[ads_repay_reason ads_repay_date ads_repay_address ads_repay_details].freeze

    # Define simple wizard actions that all have the same config
    standard_wizard_step_actions(STEPS, %i[ads_dwellings ads_amount],
                                 params: :filter_params, cache_index: LbttController)

    # returns/lbtt/ads_intending_sell - step in the ADS wizard
    def ads_intending_sell
      wizard_address_step(STEPS, :store_sell_address,
                          load_address: :load_sell_address, pre_search: :pre_address_search)
    end

    # returns/lbtt/ads_reliefs - custom step in the ADS wizard to handle the list of reliefs without them being in
    # their own special controller/wizard cache.
    # Navigates to the LBTT summary page after submitted.
    def ads_reliefs
      wizard_list_step(returns_lbtt_summary_url, params: :filter_params, cache_index: LbttController,
                                                 add_row_handler: :add_relief_data_row,
                                                 delete_row_handler: :delete_relief_data_row,
                                                 merge_list: :merge_list_data, after_merge: :update_tax_calculations)
    end

    # First step in ADS repayment wizard, chooses whether to continue with the REPAYMENT_STEPS or to switch to STEPS.
    def ads_repay_reason
      wizard_step(nil) do
        { next_step: :ads_repay_reason_next_steps, params: :filter_params, cache_index: LbttController }
      end
    end

    # Step in the ADS repayment wizard
    def ads_repay_date
      wizard_step(REPAYMENT_STEPS) { { params: :filter_params, cache_index: LbttController } }
    end

    # Step in the ADS repayment wizard, redirects to the Tax controller for the last step.
    # @see LbttTaxController#ads_repay_details
    def ads_repay_address
      wizard_address_step(returns_lbtt_tax_ads_repay_details_url, :store_repay_address,
                          load_address: :load_repay_address)
    end

    private

    # Decides the next step based on the user input on the ads_repay_reason step.
    # @return [array] either STEPS (plus the current page so the wizard navigation finds it) or REPAYMENT_STEPS.
    def ads_repay_reason_next_steps
      # @see Tax validation which has a copy of this
      return REPAYMENT_STEPS if @lbtt_return.ads_sold_main_yes_no == 'Y'

      ['ads_repay_reason', STEPS.first]
    end

    # Add new ReliefClaim object in its array
    def add_relief_data_row
      # need to save data in cache before adding new object otherwise we'll lose any new data on the form
      merge_list_data
      @lbtt_return.ads_reliefclaim_option_ind = 'Y'
      @lbtt_return.ads_relief_claims.push(Lbtt::ReliefClaim.new)
      wizard_save(@lbtt_return, Returns::LbttController)
    end

    # Remove ReliefClaim object in its array
    def delete_relief_data_row(index)
      # need to save data in cache before adding new object otherwise we'll lose any new data on the form
      merge_list_data

      @lbtt_return.ads_relief_claims.delete_at(index)
      wizard_save(@lbtt_return, Returns::LbttController)
    end

    # Sets up variables for the form to use based on the main LBTT controller which is
    # the basis for the ADS routes, model, wizard cache etc.
    # @return [LbttReturn] the model for wizard saving originally setup by LbttController#setup_step
    def setup_step
      @post_path = wizard_post_path(LbttController.name)
      @lbtt_return = wizard_load(LbttController)

      # ads_reliefs specific setup follows
      return @lbtt_return unless action_name == 'ads_reliefs'

      # ensure the form/model is populated with a list of ReliefClaim objects
      @lbtt_return.ads_relief_claims ||= Array.new(1) { Lbtt::ReliefClaim.new }

      # drop down list filtered to ADS reliefs
      @relief_types = @lbtt_return.ads_relief_claims[0].list_ref_data(:relief_type).keep_if { |r| r.code =~ /ADS.*/ }

      @lbtt_return
    end

    # Merge relief array hash data submitted in the params into the right ReliefClaim objects in the model
    def merge_list_data # rubocop:disable Metrics/AbcSize
      return unless params[:returns_lbtt_lbtt_return][:ads_relief_claims]

      relief_data = params[:returns_lbtt_lbtt_return][:ads_relief_claims].to_unsafe_h&.values

      (0..relief_data.length - 1).each do |i|
        # @lbtt_return is created and returned by #setup_step
        @lbtt_return.ads_relief_claims[i].relief_type = relief_data[i][:relief_type]
        @lbtt_return.ads_relief_claims[i].relief_amount = relief_data[i][:relief_amount]
      end
    end

    # Initialises address datastructures
    def load_sell_address
      initialize_address_variables(@lbtt_return.ads_main_address)
    end

    # Initialises address datastructures
    def load_repay_address
      initialize_address_variables(@lbtt_return.ads_sold_address)
    end

    # Stores the address and the ads_sell_residence_ind radio button value (needed to re-show the address on editing)
    # in the LbttController wizard
    # Stores the address details within the lbtt_return
    def store_sell_address
      @lbtt_return.ads_sell_residence_ind = filter_params[:ads_sell_residence_ind]
      @lbtt_return.ads_main_address = Address.new(address_params)
      unless address_valid?
        initialize_address_variables(@lbtt_return.ads_main_address, search_postcode)
        return false
      end
      wizard_save(@lbtt_return, LbttController)
      true
    end

    # Stores the sold/disposed of address
    def store_repay_address
      @lbtt_return.ads_sold_address = Address.new(address_params)

      unless @lbtt_return.ads_sold_address.valid?(address_validation_context)
        initialize_address_variables(@lbtt_return.ads_sold_address, search_postcode)
        return false
      end

      wizard_save(@lbtt_return, LbttController)
      true
    end

    # Called before an address search to store value of radio button ads_sell_residence_ind
    def pre_address_search
      return if filter_params.nil?

      @lbtt_return.ads_sell_residence_ind = filter_params['ads_sell_residence_ind']
      wizard_save(@lbtt_return)
    end

    # This method basically checks addeess is valid or not.
    # As this address submission is depend on parameter, so also checking value of that paramter and validation.
    # As logic is same while making changes also copy changes in @see LbttPartiesController#address_valid?
    def address_valid?
      # verify the radio button was selected before checking address
      return false unless @lbtt_return.valid?(:ads_sell_residence_ind)

      # if radio button was N then don't check address
      return true if @lbtt_return.ads_sell_residence_ind == 'N'

      # check addrss
      @lbtt_return.ads_main_address.valid?(address_validation_context)
    end
  end
end
