# frozen_string_literal: true

# Controller for account management
class AccountsController < ApplicationController
  include AddressHelper
  include CompanyHelper
  include AccountHandlers
  include RegistrationAccountsCommon

  # Allow pages to be unauthenticated
  skip_before_action :require_user, only: %I[activate_account process_activate_account new create]

  helper_method %I[registered_organisation? other_organisation? individual?]

  authorise route: :show, requires: AuthorisationHelper::VIEW_ACCOUNTS
  authorise route: %i[edit_basic update_basic edit_address update_address], requires: AuthorisationHelper::UPDATE_PARTY

  private

  # Permit update params
  def update_account_params
    register_account_params.merge!(register_company_params)
  end

  # Perform an address search
  def perform_address_search
    address_search
    render 'edit_address'
  end
end
