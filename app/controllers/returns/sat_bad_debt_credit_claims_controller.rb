# frozen_string_literal: true

module Returns
  # Provides Bad debt credit claims specific controller functionality.
  class SatBadDebtCreditClaimsController < ApplicationController
    include Wizard

    authorise requires: RS::AuthorisationHelper::SAT_SUMMARY

    # Wizard steps to be followed
    STEPS = %w[bad_debts bad_debts_details].freeze

    # Bad debts page
    def bad_debts
      clear_cache = bad_debt_new?
      Rails.logger.debug('New Bad debt credit claim entry') if clear_cache
      wizard_step(STEPS) do
        { setup_step: :setup_step, next_step: :redirect_by_selection,
          after_merge: :dump_bad_debt_in_sat_return, clear_cache: clear_cache }
      end
    end

    # Bad debt details page
    def bad_debts_details
      @post_path = wizard_post_path
      wizard_step(nil) do
        { next_step: :redirect_to_calculation,
          after_merge: :dump_bad_debt_in_sat_return }
      end
    end

    # Redirect to calculated tax liability
    def redirect_to_calculation
      returns_sat_calculated_tax_liability_path
    end

    # Redirect to relevant pages upon selecting Yes/No
    def redirect_by_selection
      return returns_sat_bad_debt_details_path if @bad_debt.bad_debt_present == 'Y'

      returns_sat_calculated_tax_liability_path
    end

    # This method sets all params to the bad_debt if passed true as param
    # If not it will only load bad_debt into the @site
    def load_and_set_bad_debt_params
      @sat_return.bad_debt = @bad_debt

      wizard_save(@sat_return, SatController)
      wizard_end
    end

    private

    # Sets up @site (and @sat_return) ie gets the site id from the @see #selected_site method and the Site from the
    # SatController's wizard cache.
    def load_sat_return
      @sat_return = wizard_load_or_redirect(returns_sat_summary_url, nil, SatController)
      @sat_return
    end

    # @return [Integer] the selected site_id from the session
    def selected_site
      session[:returns_sat_site]
    end

    # Determines if the param id :bad_debt consists of the value 'new'.
    # Normally used in the creation of a new bad_debt type or editing an existing bad_debt.
    # @return [Boolean] does the bad_debt param consist of value 'new'?
    def bad_debt_new?
      params[:bad_debt] == 'new'
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # Bad debt credit claims are indexed by UUID so we don't get the wrong one when editing or deleting them.
    # @raise [Error::AppError] if the credit claim id is missing (provided as a param)
    # @return [BadDebt] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path

      # load sat_return
      load_sat_return

      # reload existing bad_debt entry from the wizard or create a new one
      @bad_debt = @sat_return.bad_debt || Sat::BadDebt.new
      @sat_return.bad_debt = @bad_debt
      # Reset previous bad_debt values if user selects No
      # A case when user selects Yes, fills the data and goes back to select No
      clear_bad_debt_values
      @bad_debt
    end

    # Extract Bad debt object from the site and save it in the wizard cache.
    # @return [BadDebt] loaded object
    # @raise [Error::AppError] if the credit claim doesn't exist
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @sat_return = wizard_load(Returns::SatController)
      @bad_debt = @sat_return.bad_debt || wizard_load
      @bad_debt
    end

    # Update the bad_debt into the sat_return model
    def dump_bad_debt_in_sat_return
      load_sat_return
      @sat_return.bad_debt = @bad_debt

      wizard_save(@sat_return, SatController)
      wizard_end # clear the cache
      true
    end

    # The permitted parameters which is filtered using the BadDebt model attributes.
    def filter_params(_sub_object_attribute = nil)
      attribute_list = Returns::Sat::BadDebt.attribute_list
      required = :returns_sat_bad_debt

      return unless params[required]

      params.require(required).permit(attribute_list) if params[required]
    end

    # Clear bad debt values and reset bad_debt from cache
    def clear_bad_debt_values
      debt_params = params[:returns_sat_bad_debt]
      return unless debt_params.present? && debt_params[:bad_debt_present] == 'N'

      # Clear the BadDebt from cache
      wizard_end
      # Reset bad_debt object
      @bad_debt = Returns::Sat::BadDebt.new(bad_debt_present: 'N')
      @sat_return.bad_debt = @bad_debt
      wizard_save(@sat_return, SatController)
      wizard_end # clear the cache
      true
    end
  end
end
