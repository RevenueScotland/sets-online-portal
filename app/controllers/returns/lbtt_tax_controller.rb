# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Manages the wizard steps that use the Tax model to do tax calculations.
  # Separated out of LbttController for clarity.
  # NB Overwrites some of the wizard process to specifically wizard save the LBTT model
  # even though we operate on the Tax model.
  class LbttTaxController < ApplicationController
    include Wizard
    include LbttTaxHelper

    # public users are allowed to access the tax calculations
    skip_before_action :require_user

    # the main tax calculation steps list
    STEPS = %w[calc_already_paid calculation].freeze

    # returns/lbtt/calculation Allows editing the tax calculation.
    # Always goes to summary after successful editing
    def calculation
      wizard_step(returns_lbtt_summary_path) { { params: :filter_params } }
    end

    # returns/lbtt/calc_already_paid step to collect info about tax already paid.  Is optionally
    # shown as the first page in the wizard based on return type.
    def calc_already_paid
      wizard_step(STEPS) { { params: :filter_params } }
    end

    # Last step in the ADS repayment wizard, redirects to the LBTT summary page afterwards
    # Moved here since it deals with the Tax model and this class already has the logic to handle that.
    # @see LbttAdsController#ads_repay_address
    def ads_repay_details
      wizard_step(returns_lbtt_summary_url) { { params: :filter_params } }
    end

    # a last step in the LbttTransactionsController wizard, moved here since it deals with NPV which needs to be in
    # the Tax model (data is set from the LBTTCalc response and passed as input into the request the 2nd time through).
    # npv stands for Net Present Value (NPV)
    def npv
      wizard_step(:returns_lbtt_summary) { { params: :filter_params, after_merge: :update_tax_calculations } }
    end

    private

    # Sets up @lbtt_return, @post_path and @calc
    # @return [Tax] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path
      @lbtt_return = wizard_load(Returns::LbttController)
      Lbtt::Tax.setup_tax(@lbtt_return)
      @tax = @lbtt_return.tax

      # do some extra setup to preset data for npv and calculate actions (user might overwrite data
      # when form is submitted - that is ok)
      # TODO: CR RSTP-547 should use setup_step override on 0.2
      unless params[:submitted]
        setup_npv if action_name == 'npv'

        # update tax_due_for_return at start of this step
        @tax.calculate_tax_due_for_return if action_name == 'calculation'
      end

      @tax
    end

    # Calls the back office to provide the NPV figure.
    # Clears the existing NPV figure first so it can't be sent as an override.
    # Stores the calculated tax data @see #store_calculated_tax
    def setup_npv
      @tax.npv = nil
      @tax.calculate_linked_totals(@lbtt_return)
      @tax.calculate_tax(current_user, @lbtt_return, true)

      store_calculated_tax
    end

    # Overwrites the wizard_save method to save @lbtt_return instead of @tax (which is why we don't need cache_index
    # overrides in the steps)  @see #setup_step where @tax is found inside @lbtt_return
    def wizard_save(_master_object, _controller_name = self.class.name)
      key = wizard_cache_key(LbttController)
      Rails.logger.debug "Saving tax in wizard params for #{key}"
      Rails.cache.write(key, @lbtt_return, expires_in: wizard_cache_expiry_time)
    end

    # Return the parameter list filtered for the attributes of the Calculate model
    def filter_params
      required = :returns_lbtt_tax
      attribute_list = Lbtt::Tax.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
