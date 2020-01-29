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
      wizard_step(returns_lbtt_summary_path)
    end

    # returns/lbtt/calc_already_paid step to collect info about tax already paid.  Is optionally
    # shown as the first page in the wizard based on return type.
    def calc_already_paid
      wizard_step(STEPS)
    end

    # a last step in the LbttTransactionsController wizard, moved here since it deals with NPV which needs to be in
    # the Tax model (data is set from the LBTTCalc response and passed as input into the request the 2nd time through).
    # npv stands for Net Present Value (NPV)
    def npv
      # setup_npv_step calls the back office in order to calculate the npv value on the npv_page
      wizard_step(:returns_lbtt_summary) { { after_merge: :update_tax_calculations } }
    end

    private

    # Overwrites the wizard_save method to save @lbtt_return instead of @tax (which is why we don't need cache_index
    # overrides in the steps)  @see #setup_step where @tax is found inside @lbtt_return
    def wizard_save(_master_object, _cache_index = self.class.name)
      key = wizard_cache_key(LbttController)
      Rails.logger.debug "Saving tax in wizard params for #{key}"
      Rails.cache.write(key, @lbtt_return, expires_in: wizard_cache_expiry_time)
    end

    # Loads existing wizard models (@lbtt_return and @tax) from the wizard cache or redirects to the summary page
    # @return [Tax] the model for wizard saving
    def load_step
      @post_path = wizard_post_path
      @lbtt_return = wizard_load(Returns::LbttController)
      Lbtt::Tax.setup_tax(@lbtt_return)
      @tax = @lbtt_return.tax
    end

    # Return the parameter list filtered for the attributes of the Calculate model
    def filter_params
      required = :returns_lbtt_tax
      attribute_list = Lbtt::Tax.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
