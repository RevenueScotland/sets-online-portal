# frozen_string_literal: true

# Wizard for collecting information on new registrations
module Accounts
  # Controller class for new user/account registration
  class RegistrationController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include AddressHelper
    include CompanyHelper
    include RegistrationWizardSteps
    include RegistrationAccountsCommon

    # Allow all wizard pages to be unauthenticated
    # rubocop exception as &:to_sym isn't supported here
    skip_before_action :require_user, only: STEPS.map { |s| s.to_sym } # rubocop:disable Style/SymbolProc

    private

    # Sets up variables for the form to use (where to post the form to).
    def setup_step
      @account = wizard_load || Account.new
      @post_path = wizard_post_path
      @account
    end

    # Return the parameter list filtered for the attributes of the registration model
    def filter_params
      filtered_params = register_user_params
      if params[:account]
        filtered_params.merge!(register_account_params)
        filtered_params.merge!(register_company_params) if params[:account][:company]
      end
      filtered_params
    end

    # Save the account to the back office
    def save_account
      @account = copy_account_to_user(@account)
      wizard_save(@account) unless @account.save
    end

    # Stores the company details within the account
    def store_company
      @account.company = Company.new(company_detail_params.to_h)
      valid = @account.company.valid?(Company.selected_validation_contexts)
      unless valid
        @account.errors.merge!(@account.company.errors)
        initialize_company_variables(@account.company)
      end
      wizard_save(@account) if valid
      valid
    end

    # Loads the company details from the account
    def load_company
      return initialize_company_variables if @account.company.nil?

      initialize_company_variables(@account.company)
    end

    # Called before an address search
    def pre_address_search
      check_company_contact_address
    end

    # Stores the address details within the account
    def store_address
      @account.address = Address.new(address_params.to_h)
      check_company_contact_address
      valid = address_valid?
      if valid
        wizard_save(@account)
      else
        # check/setup variables to show the address picker again
        initialize_address_variables(@account.address, search_postcode)
      end
      valid
    end

    # Loads the address details from the account
    def load_address
      return initialize_address_variables if @account.address.nil?

      initialize_address_variables(@account.address)
    end

    # Stores the organisation address details within the account
    def store_org_address
      @account.company.from_address! Address.new(address_params.to_h)
      valid = org_address_valid?
      if valid
        wizard_save(@account)
      else
        # check/setup variables to show the address picker again
        initialize_address_variables(@account.company.company_address, search_postcode)
      end
      valid
    end

    # Loads the organisation address details from the account
    def load_org_address
      address = @account.company.company_address
      return initialize_address_variables if address.nil?

      initialize_address_variables(address)
    end

    # If reg_company_contact_address_yes_no is on the form, then update the account with the information
    def check_company_contact_address
      @account.reg_company_contact_address_yes_no = ''
      return if params[:account].nil?

      @account.reg_company_contact_address_yes_no = params[:account][:reg_company_contact_address_yes_no]
    end

    # Checks if the address is valid
    # @return [Boolean] returns true if the address is valid otherwise false
    def address_valid?
      return false unless company_contact_address_valid?
      return true if @account.reg_company_contact_address_yes_no == 'Y'

      context = address_validation_context
      valid = @account.address.valid?(context)

      @account.errors.merge!(@account.address.errors) unless valid
      valid
    end

    # Checks if the organisation address is valid
    # @return [Boolean] returns true if the address is valid otherwise false
    def org_address_valid?
      address = @account.company.company_address
      return false if address.nil?

      valid = address.valid?(address_validation_context)
      @account.errors.merge!(address.errors) unless valid
      valid
    end

    def company_contact_address_valid?
      return true if params[:account].nil?

      @account.valid?(%i[reg_company_contact_address_yes_no])
    end

    # Returns the validation context for address validation based on whether the address read only
    # flag is set or not
    # @return [Array] validation context
    def address_validation_context
      if ActiveModel::Type::Boolean.new.cast(params[:address_read_only]) || params[:address_read_only].empty?
        Address.selected_validation_contexts
      else
        Address.save_validation_contexts
      end
    end

    # Gets the postcode for the search if it's available from the parameters
    def search_postcode
      params[:address_summary][:postcode] unless params[:address_summary].nil?
    end
  end
end
