# frozen_string_literal: true

# Wizard Steps for Registration
module RegistrationWizardSteps
  extend ActiveSupport::Concern

  # navigation steps in the new registration wizard
  STEPS = %w[account_for company org_contact rep_address taxes account_details address user_details confirmation].freeze

  # renders form for brand new account (and therefore user too) ie the registration form
  def account_details
    wizard_step(STEPS) { { params: :filter_params, next_step: :account_details_next_step } }
  end

  # renders form for who the account is for (company, individual, etc...)
  def account_for
    @account = wizard_load
    wizard_step(STEPS) { { params: :filter_params, next_step: :account_for_next_step } }
  end

  # renders form for obtaining company details, either through a companies house
  # search, or just entering a company name
  def company
    setup_step
    if AccountType.registered_organisation?(@account.account_type)
      initialize_company_variables
      wizard_company_step(STEPS, :store_company, load_company: :load_company, next_step: :company_next_step)
    else
      if @account.company.nil? && @company.nil? && AccountType.other_organisation?(@account.account_type)
        @account.company = Company.new
      end
      wizard_step(STEPS) { { params: :filter_params, next_step: :company_next_step } }
    end
  end

  # renders form for obtaining address details, through the standard address search
  # functionality
  def address
    setup_step
    if AccountType.other_organisation?(@account.account_type)
      wizard_address_step(STEPS, :store_org_address, load_address: :load_org_address, next_step: :address_next_step)
    else
      wizard_address_step(STEPS, :store_address, load_address: :load_address, pre_search: :pre_address_search,
                                                 next_step: :address_next_step)
    end
  end

  # renders form for obtaining representatives contact address details, through the standard address search
  # functionality
  def rep_address
    wizard_address_step(STEPS, :store_address, load_address: :load_address)
  end
  # renders form for obtaining which taxes the registration applies for

  def taxes
    wizard_step(STEPS) { { params: :filter_params } }
  end

  # renders form for obtaining which organisation contact details
  def org_contact
    wizard_step(STEPS) { { params: :filter_params, next_step: :org_contact_next_step } }
  end

  # renders form for obtaining user(name) and password details
  def user_details
    wizard_step(STEPS) { { params: :filter_params, after_merge: :save_account } }
  end

  # renders confirmation/complete registration form
  def confirmation
    setup_step
    wizard_end
  end

  private

  # Determines which is the next step after the account_for page, depending on the registration
  # type. For either of the companies type the next page is the company page, otherwise it's
  # the address page
  def account_for_next_step
    params = filter_params
    return accounts_registration_taxes_path if AccountType.individual?(params['registration_type'])

    accounts_registration_company_path
  end

  # Determines which is the next step after the company page, depending on the registration
  # type.
  def company_next_step
    accounts_registration_address_path
  end

  # Determines which is the next step after the address page, depending on the registration
  # type.
  def address_next_step
    return STEPS if AccountType.individual?(@account.account_type)

    accounts_registration_org_contact_path
  end

  # Determines which is the next step after the account details page, depending on the registration
  # type.
  def account_details_next_step
    return STEPS if AccountType.individual?(@account.account_type)

    accounts_registration_user_details_path
  end

  # Determines which is the next step after the organisations contact page, depending on the registration
  # type.
  def org_contact_next_step
    return accounts_registration_rep_address_path if AccountType.other_organisation?(@account.account_type)

    accounts_registration_taxes_path
  end
end
