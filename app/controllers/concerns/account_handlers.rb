# frozen_string_literal: true

# Account handlers for actions from screen
module AccountHandlers
  extend ActiveSupport::Concern
  include AddressHelper

  # Allow pages to be unauthenticated
  included do
    skip_before_action :require_user, only: %I[activate_account process_activate_account activate_account_confirmation]
  end

  # show account details
  def show
    # since this is the landing page after login, don't redirect to the login screen if there's a non-validation
    # error around logging in or initial account downloading
    # Ie this stops an error after login redirecting back to the login page
    request.headers['REFERER'] = nil
    @account = Account.find(current_user)
  end

  # display account basic details, and it associate data details on the edit screen
  def edit_basic
    @account = Account.find(current_user)
    @user = @account.current_user
    # Below is used to control post on generic layout
    @post_path = update_basic_account_path
  end

  # Update basic account details from the edit-base screen
  def update_basic
    update_params = update_account_params
    @account = Account.new(update_params)
    return redirect_to account_path if @account.update_basic(update_params, current_user)

    # Below is used to control post on generic layout
    @post_path = update_basic_account_path
    render('edit_basic', status: :unprocessable_entity)
  end

  # display the address page
  def edit_address
    @account = Account.find(current_user)
    initialize_address_variables(address_detail: @account.address)
  end

  # update the account's (contact) address
  def update_address
    @account = Account.new
    @account.address = populate_address_data
    if address_search?
      perform_address_search
    elsif @account.update_address(address_params, current_user, address_validation_contexts)
      redirect_to account_path
    else
      render('edit_address', status: :unprocessable_entity)
    end
  end

  # Show activate account screen
  def activate_account
    @account = Account.new
  end

  # Perform activate account processing
  def process_activate_account
    @account = Account.new(params.require(:account).permit(:registration_token))
    if @account.activate
      redirect_to activate_account_confirmation_account_url
    else
      render('activate_account', status: :unprocessable_entity)
    end
  end

  # confirmation page
  def activate_account_confirmation; end
end
