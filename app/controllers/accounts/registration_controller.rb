# frozen_string_literal: true

# Wizard for collecting information on new registrations
module Accounts
  # Controller class for new user/account registration
  class RegistrationController < ApplicationController
    include Wizard
    include WizardAddressHelper
    include WizardCompanyHelper
    include RegistrationAccountsCommon

    # navigation steps in the new registration wizard
    STEPS = %w[account_for company_registered company org_contact rep_address taxes account_details address
               user_details confirmation].freeze

    # Allow all wizard pages to be unauthenticated
    # rubocop exception as &:to_sym isn't supported here
    skip_before_action :require_user, only: STEPS.map { |s| s.to_sym } # rubocop:disable Style/SymbolProc

    # renders form for who the account is for (company, individual, etc...). First step, sets up the wizard model.
    def account_for
      wizard_step(STEPS) { { setup_step: :setup_step, next_step: :account_for_next_step } }
    end

    # renders form for brand new account (and therefore user too) ie the registration form
    def account_details
      wizard_step(STEPS) { { next_step: :account_details_next_step } }
    end

    # renders form for obtaining company details, either through a companies house search,
    # or just entering a company name
    def company_registered
      wizard_company_step(accounts_registration_address_url)
    end

    # company step
    def company
      wizard_step(accounts_registration_address_url)
    end

    # renders form for obtaining address details, through the standard address search
    # functionality
    def address
      load_step # Need to load the account to make the decision
      if AccountType.other_organisation?(@account.account_type)
        # Uses overrides as the address is at address.company not at company
        wizard_address_step(STEPS, address_attribute: :org_address,
                                   next_step: :address_next_step)
      elsif AccountType.registered_organisation?(@account.account_type)
        wizard_address_step(STEPS, address_not_required: :reg_company_contact_address_yes_no,
                                   next_step: :address_next_step)
      else # must be individual
        wizard_address_step(STEPS, next_step: :address_next_step)
      end
    end

    # renders form for obtaining representatives contact address details, through the standard address search
    # functionality
    def rep_address
      wizard_address_step(STEPS)
    end

    # renders form for obtaining which taxes the registration applies for
    def taxes
      wizard_step(STEPS)
    end

    # renders form for obtaining which organisation contact details
    def org_contact
      wizard_step(STEPS) { { next_step: :org_contact_next_step } }
    end

    # renders form for obtaining user(name) and password details
    def user_details
      wizard_step(STEPS) { { after_merge: :save_account } }
    end

    # renders confirmation/complete registration form
    def confirmation
      load_step
      wizard_end
    end

    private

    # Save the account to the back office
    # This must signal back if the save to the back office succeeded in order to prevent navigation to the next page
    # @return [Boolean] if the save was successful
    def save_account
      @account = copy_account_to_user(@account)
      wizard_save(@account)
      @account.save
    end

    # Determines which is the next step after the account_for page
    def account_for_next_step
      return accounts_registration_taxes_path if AccountType.individual?(@account.account_type)

      return accounts_registration_company_path unless AccountType.registered_organisation?(@account.account_type)

      accounts_registration_company_registered_path
    end

    # Determines which is the next step after the address page, depending on the registration type.
    def address_next_step
      return STEPS if AccountType.individual?(@account.account_type)

      accounts_registration_org_contact_path
    end

    # Determines which is the next step after the account details page, depending on the registration type.
    def account_details_next_step
      return STEPS if AccountType.individual?(@account.account_type)

      accounts_registration_user_details_path
    end

    # Determines which is the next step after the organisations contact page, depending on the registration type.
    def org_contact_next_step
      return accounts_registration_rep_address_path if AccountType.other_organisation?(@account.account_type)

      accounts_registration_taxes_path
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # @return [Account] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path
      @account = wizard_load || Account.new
    end

    # Loads existing wizard models from the wizard cache or redirects to the summary page
    # @return [Account] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @account = wizard_load_or_redirect(accounts_registration_account_for_url)
    end

    # Return the parameter list filtered for the attributes of the registration model
    def filter_params(_sub_object_attribute = nil)
      filtered_params = register_user_params
      if params[:account]
        filtered_params.merge!(register_account_params)
        filtered_params.merge!(register_company_params) if params[:account][:company]
      end

      filtered_params
    end
  end
end
