# frozen_string_literal: true

module Returns
  # LBTT "About the transaction" wizards and steps.
  class LbttTransactionsController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include WizardListHelper
    include LbttTaxHelper

    authorise requires: RS::AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to calc actions
    skip_before_action :require_user

    # store step flow of lbtt conveyance return transaction page name used for navigation
    CONVEYANCE_STEPS = %w[property_type non_residential_reason transaction_dates about_the_transaction
                          linked_transactions sale_of_business about_the_calculation
                          conveyance_values].freeze

    # store step flow of lbtt lease return transaction page name used for navigation
    LEASE_STEPS = %w[property_type transaction_dates about_the_transaction linked_transactions lease_values
                     rental_years premium_paid relevant_rent npv].freeze

    # store step flow of lbtt lease return, assignation and termination transaction page name used for navigation
    LEASE_REV_ASSIGN_TERMINATE_STEPS = %w[transaction_dates linked_transactions lease_values
                                          rental_years premium_paid relevant_rent npv].freeze

    # wizard step
    def property_type
      wizard_step(nil) { { next_step: :property_type_next_step, cache_index: LbttController } }
    end

    # in case of non-residential of CONVEY returns we need to give the reason
    def property_type_next_step
      if @lbtt_return.flbt_type == 'CONVEY'
        return returns_lbtt_non_residential_reason_path if @lbtt_return.property_type == '3'

        return returns_lbtt_transaction_dates_path
      end
      calculate_next_step
    end

    # custom step to handle non-residential reason
    def non_residential_reason
      wizard_step(nil) { { next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # wizard step
    def transaction_dates
      wizard_step(nil) do
        { next_step: :calculate_next_step, cache_index: LbttController,
          after_merge: :update_yearly_rents_and_calculate }
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
                            list_required: :linked_ind, list_attribute: :link_transactions,
                            new_list_item_instance: :new_list_item_link_transactions)
    end

    # wizard step
    def lease_values
      wizard_step(nil) { { next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # wizard step
    def rental_years
      wizard_list_step(nil, setup_step: :setup_yearly_rents,
                            next_step: :calculate_next_step, cache_index: LbttController,
                            list_not_required: :rent_for_all_years, list_attribute: :yearly_rents)
    end

    # Wizard step which always goes to the Tax.npv action afterwards
    def premium_paid
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
    # @return [Object] new instance of LinkTransactions class that has attributes with value.
    def new_list_item_link_transactions
      Lbtt::LinkTransactions.new(convey: @lbtt_return.convey?)
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
      @lbtt_return.lease_start_date = @lbtt_return.lease_start_date&.to_date
      @lbtt_return.lease_end_date = @lbtt_return.lease_end_date&.to_date
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
      setup_transaction_dates_step
      update_tax_calculations
    end

    # Either creates a new array, deletes items or adds new instances of YearlyRents object to (/from) the yearly_rents
    # @param previous [Integer] See 'previous' description from {#update_yearly_rents_and_calculate} method
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
    # @return [Object] An array consisting of the Return and Relief Claim, or just the return
    def load_step(sub_object_attribute = nil)
      @post_path = wizard_post_path
      if sub_object_attribute.nil?
        @lbtt_return = wizard_load_or_redirect(returns_lbtt_summary_url, sub_object_attribute, Returns::LbttController)
      elsif sub_object_attribute == :md_relief
        @lbtt_return, @relief_claim = wizard_load_or_redirect(returns_lbtt_summary_url, sub_object_attribute,
                                                              Returns::LbttController)
      end
    end

    # Custom setup for this step.  Calls @see #load_step to set up the model.
    # Initialise the relevant row data structures if it's not already set.
    def setup_linked_transactions_step
      model = load_step
      return model if @lbtt_return.link_transactions.present?

      # NB this syntax uses a separate object for each element in the list
      @lbtt_return.link_transactions = Array.new(1) { new_list_item_link_transactions }
      model
    end

    # Converts date values from strings to dates so the date control works.
    def setup_transaction_dates_step
      @lbtt_return.effective_date = @lbtt_return.effective_date&.to_date
      @lbtt_return.relevant_date = @lbtt_return.relevant_date&.to_date
      @lbtt_return.contract_date = @lbtt_return.contract_date&.to_date
      convert_lease_transaction_date
    end

    # Used to get the permitted attribute and list for filter list params
    def filtered_list(list_attribute)
      if list_attribute == :link_transactions
        [:returns_lbtt_link_transactions, Lbtt::LinkTransactions.attribute_list]
      else
        [:returns_lbtt_yearly_rent, Lbtt::YearlyRent.attribute_list]
      end
    end

    # Return the parameter list filtered for the attributes of the LbttReturn model
    def filter_params(_sub_object_attribute = nil)
      required = :returns_lbtt_lbtt_return
      return {} unless params[required]

      not_required = %i[returns_lbtt_link_transactions returns_lbtt_yearly_rent]
      permit = { returns_lbtt_link_transactions: Lbtt::LinkTransactions.attribute_list,
                 returns_lbtt_yearly_rent: Lbtt::YearlyRent.attribute_list }
      attribute_list = Lbtt::LbttReturn.attribute_list
      # to store multiple check box values in model attribute we will require to
      # pass them as array in filter param this method will convert attribute to array
      # ref url :https://www.sitepoint.com/save-multiple-checkbox-values-database-rails/
      attribute_list[attribute_list.index(:sale_include_option)] = { sale_include_option: [] }
      params.require(required).permit(attribute_list, permit).except(*not_required)
    end

    # Return the parameter list filtered for the attributes of the link transactions model
    # note we have to permit everything because we get a hash of the records returned e.g. "0" => details
    def filter_list_params(list_attribute, _sub_object_attribute = nil)
      param = params.require(:returns_lbtt_lbtt_return)
      permitted_attribute, permitted_list = filtered_list(list_attribute)
      return unless params[:returns_lbtt_lbtt_return] && params[:returns_lbtt_lbtt_return][permitted_attribute]

      if list_attribute == :link_transactions
        param.permit(:linked_ind, returns_lbtt_link_transactions: permitted_list)[permitted_attribute].values
      else
        param.permit(:rent_for_all_years, returns_lbtt_yearly_rent: permitted_list)[permitted_attribute].values
      end
    end
  end
end
