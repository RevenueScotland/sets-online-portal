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
    CONVEYANCE_STEPS = %w[property_type conveyance_dates about_the_transaction linked_transactions sale_of_business
                          reliefs_on_transaction about_the_calculation conveyance_values].freeze

    # store step flow of lbtt lease return transaction page name used for navigation
    LEASE_STEPS = %w[property_type conveyance_dates about_the_transaction linked_transactions reliefs_on_transaction
                     lease_values rental_years premium_paid relevant_rent npv].freeze

    # store step flow of lbtt lease return, assignation and termination transaction page name used for navigation
    LEASE_REV_ASSIGN_TERMINATE_STEPS = %w[conveyance_dates linked_transactions lease_values
                                          rental_years premium_paid relevant_rent npv].freeze

    # wizard step
    def property_type
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # wizard step
    def conveyance_dates
      wizard_step(nil) do
        { params: :filter_params, next_step: :calculate_next_step,
          cache_index: LbttController, after_merge: :handle_yearly_rent_value }
      end
    end

    # wizard step
    def sale_of_business
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # a last wizard step
    def conveyance_values
      wizard_step(:returns_lbtt_summary) do
        { params: :filter_params, cache_index: LbttController,
          after_merge: :update_tax_calculations }
      end
    end

    # wizard step
    def about_the_transaction
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # Custom step in the Lbtt wizard which handle add row and merge_list method for this page
    def linked_transactions
      wizard_list_step(nil, params: :filter_params,
                            next_step: :calculate_next_step, cache_index: LbttController,
                            merge_list: :merge_linked_transactions, add_row_handler: :add_linked_transactions_row,
                            delete_row_handler: :delete_linked_transactions_row)
    end

    # Custom wizard step to add new LinkTransactions object in its array
    def add_linked_transactions_row
      # need to save data in cache before adding new object otherwise we'll lose any new data on the form
      merge_linked_transactions
      @lbtt_return.linked_ind = 'Y'
      @lbtt_return.link_transactions.push(Lbtt::LinkTransactions.new)
      wizard_save(@lbtt_return, Returns::LbttController)
    end

    # Custom wizard step to add new ReliefClaim object in its array
    def add_relief_data_row
      # need to save data in cache before adding new object otherwise we'll lose any new data on the form
      merge_non_ads_relief_claims
      @lbtt_return.non_ads_reliefclaim_option_ind = 'Y'
      @lbtt_return.non_ads_relief_claims.push(Lbtt::ReliefClaim.new)
      wizard_save(@lbtt_return, Returns::LbttController)
    end

    # Custom wizard step to remove ReliefClaim object in its array
    def delete_relief_data_row(index)
      # need to save data in cache before adding new object
      merge_non_ads_relief_claims

      @lbtt_return.non_ads_relief_claims.delete_at(index)
      wizard_save(@lbtt_return, Returns::LbttController)
    end

    # Custom wizard step to remove ReliefClaim object in its array
    def delete_linked_transactions_row(index)
      # need to save data in cache before adding new object
      merge_linked_transactions

      @lbtt_return.link_transactions.delete_at(index)
      wizard_save(@lbtt_return, Returns::LbttController)
    end

    # Custom step in the Lbtt wizard which handle add row and merge_list method for this page
    def reliefs_on_transaction
      wizard_list_step(nil, params: :filter_params, next_step: :calculate_next_step, cache_index: LbttController,
                            delete_row_handler: :delete_relief_data_row,
                            add_row_handler: :add_relief_data_row, merge_list: :merge_non_ads_relief_claims)
    end

    # wizard step
    def lease_values
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # wizard step
    def rental_years
      wizard_list_step(nil, params: :filter_params, next_step: :calculate_next_step, merge_list: :merge_rental_years,
                            cache_index: LbttController)
    end

    # wizard step
    def premium_paid
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step, cache_index: LbttController } }
    end

    # Wizard step which always goes to the Tax.npv action afterwards
    def relevant_rent
      wizard_step(returns_lbtt_tax_npv_url) { { params: :filter_params, cache_index: LbttController } }
    end

    # wizard_step
    def about_the_calculation
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step, cache_index: LbttController } }
    end

    private

    # Sets up variables for the form to use based on the main LBTT controller which is
    # the basis for the transaction+calculations routes, model, wizard cache etc.
    # @return [LbttReturn] the model for wizard saving originally setup by LbttController#s
    def setup_step
      @post_path = wizard_post_path(LbttController.name)
      @lbtt_return = wizard_load(Returns::LbttController)

      initialise_row_details
      convert_transaction_date

      # get the ref data for relief types and only show the non-ADS ones @see LbttAdsController#ads_reliefs
      if action_name == 'reliefs_on_transaction'
        @relief_types = @lbtt_return.non_ads_relief_claims[0]
                                    .list_ref_data(:relief_type).delete_if { |r| r.code =~ /ADS.*/ }
      end

      setup_linked_totals

      @lbtt_return
    end

    # For the relevant pages, sets totals in the model based on linked transactions.
    # Only works if submitted not pressed, ie just to preset the form totals without overwriting totals the user
    # may have already edited on another page.
    def setup_linked_totals
      return if params[:submitted]

      @lbtt_return.calculate_linked_totals if %w[conveyance_values premium_paid].include? action_name
    end

    # Merge relief array hash data submitted in the params into the right ReliefClaim objects in the model
    def merge_non_ads_relief_claims # rubocop:disable Metrics/AbcSize
      return if params[:returns_lbtt_lbtt_return].nil?

      relief_data = params[:returns_lbtt_lbtt_return][:non_ads_relief_claims].to_unsafe_h&.values

      (0..relief_data.length - 1).each do |i|
        # @lbtt_return is created and returned by #setup_step
        @lbtt_return.non_ads_relief_claims[i].relief_type = relief_data[i][:relief_type]
        @lbtt_return.non_ads_relief_claims[i].relief_amount = relief_data[i][:relief_amount]
      end
    end

    # Merge rental year array hash data submitted in the params into the right RentalYear objects in the model
    def merge_rental_years
      return if params[:returns_lbtt_lbtt_return].nil?

      @transactions_values = params[:returns_lbtt_lbtt_return][:yearly_rents].to_unsafe_h&.values

      (0..@transactions_values.length - 1).each do |count|
        # @lbtt_return is created and returned by #setup_step
        @lbtt_return.yearly_rents[count] = Lbtt::YearlyRent.new(@transactions_values[count])
      end
    end

    # Merge link transactions array hash data submitted in the params into the right link transactions objects
    # in the model
    def merge_linked_transactions
      lbtt_return = params[:returns_lbtt_lbtt_return]
      linked_transactions = lbtt_return[:link_transactions] unless lbtt_return.nil?
      return if linked_transactions.nil?

      @transactions_values = linked_transactions.to_unsafe_h&.values

      (0..@transactions_values.length - 1).each do |count|
        @lbtt_return.link_transactions[count] = Lbtt::LinkTransactions.new(@transactions_values[count])
      end
    end

    # For actions with rows of data to be added, initialise the relevant datastructures if it's not already set.
    def initialise_row_details
      # nil or empty arrays should be reset to new LinkTransaction array
      case action_name
      when 'linked_transactions'
        return if @lbtt_return.link_transactions.present?

        # NB this syntax uses a separate object for each element in the list
        @lbtt_return.link_transactions = Array.new(1) { Lbtt::LinkTransactions.new }
      when 'reliefs_on_transaction'
        unless @lbtt_return.non_ads_relief_claims.present?
          @lbtt_return.non_ads_relief_claims = Array.new(1) { Lbtt::ReliefClaim.new }
        end
      end
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

    # Return the parameter list filtered for the attributes of the SlftReturn model
    def filter_params
      required = :returns_lbtt_lbtt_return
      attribute_list = Lbtt::LbttReturn.attribute_list
      # to store multiple check box values in model attribute we will require to
      # pass them as array in filter param this method will convert attribute to array
      # ref url :https://www.sitepoint.com/save-multiple-checkbox-values-database-rails/
      attribute_list[attribute_list.index(:sale_include_option)] = { sale_include_option: [] }
      params.require(required).permit(attribute_list) if params[required]
    end

    # default date are storing in string.
    # To attached it with date control it require to convert to date
    def convert_transaction_date # rubocop:disable Metrics/AbcSize
      return unless wizard_post_path == :returns_lbtt_transactions_conveyance_dates

      @lbtt_return.effective_date = @lbtt_return.effective_date.to_date unless @lbtt_return.effective_date.nil?
      @lbtt_return.relevant_date = @lbtt_return.relevant_date.to_date unless @lbtt_return.relevant_date.nil?
      @lbtt_return.contract_date = @lbtt_return.contract_date.to_date unless @lbtt_return.contract_date.nil?
      convert_lease_transaction_date
    end

    # convert lease return specific date
    def convert_lease_transaction_date
      @lbtt_return.lease_start_date = @lbtt_return.lease_start_date.to_date unless @lbtt_return.lease_start_date.nil?
      @lbtt_return.lease_end_date = @lbtt_return.lease_end_date.to_date unless @lbtt_return.lease_end_date.nil?
    end

    # Change yearly rent array value as per lease start and end date.
    # so example if the user has select least start date 1-4-2019 and end date 1-4-2020
    # it will create two rows array of yearly rent object and assign it to yearly_rents
    # field of @lbtt_return object
    # This method checks if the user has already visited the conveyance dates page or not
    # based on that method will add or delete rows of an existing array with retaining the current value
    def handle_yearly_rent_value
      return if @lbtt_return.flbt_type == 'CONVEY' || @lbtt_return.lease_start_date.nil? ||
                @lbtt_return.lease_end_date.nil?

      yearly_rents_count = count_year_rent_row
      # check if user has already set value and came to the page to modify the date
      previous_yearly_rents_count = @lbtt_return.yearly_rents.nil? ? 0 : @lbtt_return.yearly_rents.length

      # checking if new year added or delete when value of lease dates are updated.
      diff_yearly_rents_count = yearly_rents_count - previous_yearly_rents_count
      update_rental_year_value(diff_yearly_rents_count, previous_yearly_rents_count, yearly_rents_count)
      wizard_save(@lbtt_return, Returns::LbttController)
    end

    # update rental year array value based on input
    # @param diff_yearly_rents_count [Integer] difference in previously and currently selected new lease start
    #                                          and end date.
    # @param previous_yearly_rents_count [Integer] previously entered lease start and end date difference
    # @param yearly_rents_count [Integer] currently entered lease start and end date difference
    def update_rental_year_value(diff_yearly_rents_count,
                                 previous_yearly_rents_count,
                                 yearly_rents_count)
      if previous_yearly_rents_count.zero? && @lbtt_return.yearly_rents.nil?
        @lbtt_return.yearly_rents = Array.new(yearly_rents_count, Lbtt::YearlyRent.new)
      elsif diff_yearly_rents_count.negative?
        @lbtt_return.yearly_rents = @lbtt_return.yearly_rents.slice(0..(diff_yearly_rents_count - 1))
      elsif diff_yearly_rents_count.positive?
        handle_yearly_rents_add(diff_yearly_rents_count)
      end
    end

    # update yearly rent array rows if user update lease start and end date
    # due to which row need to add in existing yearly_rent array
    def handle_yearly_rents_add(diff_yearly_rents_count)
      (0..(diff_yearly_rents_count - 1)).each do
        @lbtt_return.yearly_rents.push(Lbtt::YearlyRent.new)
      end
    end

    # count year rent rows
    def count_year_rent_row
      convert_lease_transaction_date
      yearly_rents_count = 0
      lease_date = @lbtt_return.lease_start_date
      while @lbtt_return.lease_end_date >= lease_date
        yearly_rents_count += 1
        lease_date = lease_date.next_year(1).to_date
      end
      yearly_rents_count
    end
  end
end
