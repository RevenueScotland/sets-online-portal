# frozen_string_literal: true

module Returns
  # LBTT "About the transaction" wizards and steps.
  class LbttTransactionsController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include WizardListHelper
    include LbttTaxHelper

    authorise requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to calc actions
    skip_before_action :require_user

    # store step flow of lbtt conveyance return transaction page name used for navigation
    CONVEYANCE_STEPS = %w[property_type transaction_dates about_the_transaction linked_transactions sale_of_business
                          reliefs_on_transaction about_the_calculation conveyance_values].freeze

    # store step flow of lbtt lease return transaction page name used for navigation
    LEASE_STEPS = %w[property_type transaction_dates about_the_transaction linked_transactions reliefs_on_transaction
                     lease_values rental_years premium_paid relevant_rent npv].freeze

    # store step flow of lbtt lease return, assignation and termination transaction page name used for navigation
    LEASE_REV_ASSIGN_TERMINATE_STEPS = %w[transaction_dates linked_transactions lease_values
                                          rental_years premium_paid relevant_rent npv].freeze

    # wizard step
    def property_type
      wizard_step(nil) { { next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # wizard step
    def transaction_dates
      wizard_step(nil) do
        { setup_step: :setup_transaction_dates_step, next_step: :calculate_next_step,
          cache_index: LbttController, after_merge: :update_yearly_rents_and_calculate }
      end
    end

    # wizard step
    def sale_of_business
      wizard_step(nil) { { next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # a last wizard step
    def conveyance_values
      wizard_step(:returns_lbtt_summary) do
        { cache_index: LbttController, after_merge: :update_tax_calculations }
      end
    end

    # wizard step
    def about_the_transaction
      wizard_step(nil) { { next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # Custom step in the Lbtt wizard which handle add row and merge_list method for this page
    def linked_transactions
      wizard_list_step(nil, setup_step: :setup_linked_transactions_step,
                            next_step: :calculate_next_step, cache_index: LbttController,
                            merge_list: :merge_linked_transactions, list_attribute: :link_transactions,
                            new_list_item_instance: :new_list_item_link_transactions)
    end

    # Custom step in the Lbtt wizard which handle add row and merge_list method for this page
    def reliefs_on_transaction
      wizard_list_step(nil, setup_step: :setup_reliefs_on_transaction_step,
                            next_step: :calculate_next_step, cache_index: LbttController,
                            merge_list: :merge_non_ads_relief_claims, list_attribute: :non_ads_relief_claims,
                            new_list_item_instance: :new_list_item_non_ads_relief_claims)
    end

    # wizard step
    def lease_values
      wizard_step(nil) { { next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # wizard step
    def rental_years
      wizard_list_step(nil, setup_step: :setup_yearly_rents,
                            next_step: :calculate_next_step, cache_index: LbttController,
                            merge_list: :merge_rental_years, list_attribute: :yearly_rents,
                            new_list_item_instance: :new_list_item_yearly_rents)
    end

    # wizard step
    def premium_paid
      wizard_step(nil) do
        { next_step: :calculate_next_step, cache_index: LbttController }
      end
    end

    # Wizard step which always goes to the Tax.npv action afterwards
    def relevant_rent
      wizard_step(returns_lbtt_tax_npv_url) { { after_merge: :update_npv_calculation, cache_index: LbttController } }
    end

    # wizard_step
    def about_the_calculation
      wizard_step(nil) { { next_step: :calculate_next_step, cache_index: LbttController } }
    end

    private

    # Populate Yearly Rent field with Annual rent amount as default if the Rent field is nil.
    def setup_yearly_rents
      model = load_step
      (0..@lbtt_return.yearly_rents.size - 1).each do |i|
        @lbtt_return.yearly_rents[i].rent ||= @lbtt_return.annual_rent
      end
      model
    end

    # Used in wizard_list_step as part of the merging of data.
    # @return [Object] new instance of ReliefClaim class that has attributes with value.
    def new_list_item_non_ads_relief_claims(hash_attributes = {})
      Lbtt::ReliefClaim.new(hash_attributes)
    end

    # Merge relief array hash data submitted in the params into the right ReliefClaim objects in the model
    # @return [Boolean] if the merge was successful and the models are valid
    def merge_non_ads_relief_claims
      return true unless @lbtt_return.non_ads_reliefclaim_option_ind == 'Y'

      # Merge link transactions array hash data submitted in the params into the right link transactions objects
      # @see merge_params_and_validate_with_list to know more
      yield

      # Special case we need to validated that we don't have duplicated now we can only do this once
      # they are all loaded then trigger validation again on the model
      @lbtt_return.valid?(:non_ads_reliefclaim_option_ind)
      # Now we need to check if there are errors on the reliefs
      @lbtt_return.non_ads_relief_claims.all? { |obj| obj.errors.none? }
    end

    # Used in wizard_list_step as part of the merging of data.
    # @return [Object] new instance of YearlyRent class that has attributes with value.
    def new_list_item_yearly_rents(hash_attributes = {})
      Lbtt::YearlyRent.new(hash_attributes)
    end

    # Merge rental year array hash data submitted in the params into the right RentalYear objects in the model
    # @return [Boolean] if the merge was successful and the models are valid
    def merge_rental_years
      # If the flag isn't set then do not return
      # We have to do this in the controller rather than the model as this is about creating entries in the model
      return true unless @lbtt_return.rent_for_all_years == 'N'

      # Merges the params values with the wizard object's list attribute and validates each as they're merged
      # @see merge_params_and_validate_with_list to know more
      yield
    end

    # Used in wizard_list_step as part of the merging of data.
    # @return [Object] new instance of LinkTransactions class that has attributes with value.
    def new_list_item_link_transactions(hash_attributes = {})
      Lbtt::LinkTransactions.new(hash_attributes)
    end

    # Merge link transactions array hash data submitted in the params into the right link transactions objects
    # in the model
    # @return [Boolean] if the merge was successful and the models are valid
    def merge_linked_transactions
      # If the flag isn't set then do not return
      # We have to do this in the controller rather than the model as this is about creating entries in the model
      return true unless @lbtt_return.linked_ind == 'Y'

      # @see merge_params_and_validate_with_list to learn more about how this is being used
      @list_item_validation_key = @lbtt_return.flbt_type

      # Merges the params values with the wizard object's list attribute and validates each as they're merged
      # @see merge_params_and_validate_with_list to know more
      yield
    end

    # change the page flow as lbtt return type
    # @return [String] the next step
    def calculate_next_step
      flbt_type = @lbtt_return.flbt_type

      next_steps = if flbt_type == 'CONVEY'
                     CONVEYANCE_STEPS
                   elsif flbt_type == 'LEASERET'
                     LEASE_STEPS
                   elsif %w[LEASEREV ASSIGN TERMINATE].include? flbt_type
                     LEASE_REV_ASSIGN_TERMINATE_STEPS
                   end

      raise Error::AppError.new('Return type', "Invalid return type for calc #{flbt_type}") if next_steps.nil?

      next_steps
    end

    # convert lease return specific date
    def convert_lease_transaction_date
      @lbtt_return.lease_start_date = @lbtt_return.lease_start_date.to_date unless @lbtt_return.lease_start_date.nil?
      @lbtt_return.lease_end_date = @lbtt_return.lease_end_date.to_date unless @lbtt_return.lease_end_date.nil?
    end

    # Updates the yearly rents array as per the initial values of (or changes to) the lease start and end date.
    # so example if the user has select lease start date 1-4-2019 and end date 1-4-2020
    # it will create two rows array of yearly rent object and assign it to yearly_rents
    # field of @lbtt_return object
    # This method checks if the user has already visited the conveyance dates page or not
    # based on that method will add or delete rows of an existing array with retaining the current value
    # This routine also triggers a new calculation in case the dates have changed so the latest details are reflected
    # @return [Boolean] true if successful
    def update_yearly_rents_and_calculate
      unless @lbtt_return.flbt_type == 'CONVEY'
        # if the lease dates are nil then we don't need to calculate either
        return true if @lbtt_return.lease_start_date.nil? || @lbtt_return.lease_end_date.nil?

        # Stores the previous calculated years, which is the number of rows of the rental years if it's found,
        # otherwise it'll default to 0.
        # Normally, when the user has already entered the lease dates and then came back to change it, the old array
        # where the yearly_rents are stored will still be the same until when it gets changed later in this method.
        # So that's where the 'previous' comes from.
        previous = @lbtt_return.yearly_rents.nil? ? 0 : @lbtt_return.yearly_rents.length

        update_yearly_rents_array(previous)
      end
      update_tax_calculations
    end

    # Either creates a new array, deletes items or adds new instances of YearlyRents object to (/from) the yearly_rents
    # @param previous [Integer] See 'previous' description from {#update_yearly_rents} method
    def update_yearly_rents_array(previous)
      # The value of the difference between 'previous' calculated years and the calculated years now.
      difference = calculate_yearly_rents_years - previous
      # @note the return is being used to skip the next lines of code as they shouldn't be executed on this condition.
      return @lbtt_return.yearly_rents.pop(difference.abs) if difference.negative?

      @lbtt_return.yearly_rents ||= []
      # Adds new instances of YearlyRents to the yearly_rents array, at the end of the array.
      (0..(difference - 1)).each { |y| @lbtt_return.yearly_rents += [Lbtt::YearlyRent.new(year: previous + y + 1)] }
    end

    # Counts the rows of rental years by calculating the years difference between the lease start date and
    # lease end date.
    def calculate_yearly_rents_years
      convert_lease_transaction_date
      years = @lbtt_return.lease_end_date.year - @lbtt_return.lease_start_date.year
      years += 1 if @lbtt_return.lease_end_date >= @lbtt_return.lease_start_date.next_year(years)
      years
    end

    # Loads existing wizard models from the wizard cache or redirects to the first step.
    # @return [Waste] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path(LbttController.name)
      @lbtt_return = wizard_load_or_redirect(returns_lbtt_summary_url, {}, Returns::LbttController)
    end

    # Custom setup for this step.  Calls @see #load_step to set up the model.
    def setup_reliefs_on_transaction_step
      model = load_step

      # initialise row data if not already present
      unless @lbtt_return.non_ads_relief_claims.present?
        @lbtt_return.non_ads_relief_claims = Array.new(1) { Lbtt::ReliefClaim.new }
      end

      # get the ref data for relief types and only show the non-ADS ones @see LbttAdsController#ads_reliefs
      @relief_types = ReferenceData::TaxReliefType.list_standard(@lbtt_return.flbt_type, true)

      model
    end

    # Custom setup for this step.  Calls @see #load_step to set up the model.
    # Initialise the relevant row data structures if it's not already set.
    def setup_linked_transactions_step
      model = load_step
      return model if @lbtt_return.link_transactions.present?

      # NB this syntax uses a separate object for each element in the list
      @lbtt_return.link_transactions = Array.new(1) { Lbtt::LinkTransactions.new }
      model
    end

    # Custom setup for this step.  Calls @see #load_step to set up the model.
    # Converts date values from strings to dates so the date control works.
    def setup_transaction_dates_step
      model = load_step

      @lbtt_return.effective_date = @lbtt_return.effective_date.to_date unless @lbtt_return.effective_date.nil?
      @lbtt_return.relevant_date = @lbtt_return.relevant_date.to_date unless @lbtt_return.relevant_date.nil?
      @lbtt_return.contract_date = @lbtt_return.contract_date.to_date unless @lbtt_return.contract_date.nil?
      convert_lease_transaction_date

      model
    end

    # Return the parameter list filtered for the attributes of the LbttReturn model
    def filter_params(_sub_object_attribute = nil)
      required = :returns_lbtt_lbtt_return
      attribute_list = Lbtt::LbttReturn.attribute_list
      # to store multiple check box values in model attribute we will require to
      # pass them as array in filter param this method will convert attribute to array
      # ref url :https://www.sitepoint.com/save-multiple-checkbox-values-database-rails/
      attribute_list[attribute_list.index(:sale_include_option)] = { sale_include_option: [] }
      params.require(required).permit(attribute_list) if params[required]
    end

    # Return the parameter list filtered for the attributes of the link transactions model
    # note we have to permit everything because we get a hash of the records returned e.g. "0" => details
    def filter_list_params(list_attribute, _sub_object_attribute = nil)
      return unless params[:returns_lbtt_lbtt_return] && params[:returns_lbtt_lbtt_return][list_attribute]

      params.require(:returns_lbtt_lbtt_return).permit(list_attribute => {})[list_attribute].values
    end
  end
end
