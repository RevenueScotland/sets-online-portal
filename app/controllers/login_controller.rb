# frozen_string_literal: true

# Handles login and log out via the Warden security gem.
class LoginController < ApplicationController # rubocop:disable Metrics/ClassLength
  # Allow specific pages to be unauthenticated
  skip_before_action :require_user, only: %I[new create unauthenticated destroy session_expired]
  # Don't stop these pages running because of session expiry
  skip_before_action :check_session_expiry, only: %I[destroy session_expired]

  # Skip verifying the CSRF token for the unauthenticated action as the session is reset
  # so the check doesn't work
  skip_before_action :verify_authenticity_token, only: [:unauthenticated]

  # Ensure the session is new, any previous user is logged off, then setup the login page user model.
  def new
    logout
    reset_session

    @user = User.new
  end

  # If password is not expired or no need of change of password then user can login successfully
  # otherwise they are redirected appropriately.
  def create
    # don't redirect to the login screen if there's a non-validation error around logging in
    request.headers['REFERER'] = nil

    params = login_params
    login_form = User.new(params)
    if two_factor?(params)
      handle_token_login login_form
    else
      handle_password_login login_form
    end
  end

  # Logout.
  # Log off the back office, logout warden session, reset the rails session, redirect to the login page
  # Can't be called "logout" as that would be confused with the Warden logout method.
  def destroy
    logout_process
    redirect_to login_path
  end

  # Same as destroy except doesn't redirect to the login page so will render the session_expired view.
  def session_expired
    Rails.logger.info("Session expired called for #{current_user}")
    logout_process
  end

  # Login failure action (eg incorrect credentials).  Takes the user back to the login page
  # populating a User model with the error message.
  def unauthenticated
    failure_message = failure_hash

    @user, reason = failure_message.values_at :user, :reason
    if reason == :token_required
      render 'token'
    else
      Rails.logger.debug { "User #{@user.username} was unauthenticated and the message was : #{reason}" }
      @user.errors.add(error_attribute(reason), reason)
      render reason == :invalid_token ? 'token' : 'new'
    end
    false # make sure we don't do anything else login related
  end

  private

  # Make sure we have a status of 401 in the logging payload
  # This is required as when the login fails the warden middleware interrupts the normal rails processing
  # so a status is not set and the logging then fails with
  # Could not log "process_action.action_controller" event. NoMethodError: undefined method `first'
  def append_info_to_payload(payload)
    payload[:status] ||= 401 unless payload[:exception]
    super
  end

  # handle what happens when a user enters their username/password
  # @param login_form [Object] user information from the login form
  def handle_password_login(login_form)
    Rails.logger.debug { "Checking credentials for #{login_form.username}" }
    authenticate! if login_form.valid?(:login)

    # clear the password to prevent any possible information leakage
    login_form.password = nil

    redirect(login_form)
  end

  # handle what happens when a user enters their username/token
  # @param login_form [Object] user information from the login form
  def handle_token_login(login_form)
    Rails.logger.debug { "Checking 2 factor authentication for #{login_form.username}" }
    authenticate! if login_form.valid? :two_factor

    login_form.token = nil

    redirect(login_form)
  end

  # Redirect the current_user based on their status after authentication (called by {#create}).
  # login_form is the user object holding their username and any validation errors so can be reused on new form.
  def redirect(login_form)
    if logged_in?
      setup_account_cache
      return redirect_to user_change_password_path if current_user&.check_password_change_required?
      return redirect_to user_update_tcs_path if current_user&.check_tcs_required?

      redirect_to dashboard_path
    else
      redirect_on_failure login_form
    end
  end

  # Redirect the current_user based on their status after authentication (called by {#create}).
  # login_form is the user object holding their username and any validation errors so can be reused on new form.
  def redirect_on_failure(login_form)
    if two_factor?(login_params)
      @user = login_form
      render 'token'
    else
      # Reset session, use previous user object so they see username and validation errors
      logout_process
      @user = login_form
      render 'new'
    end
  end

  # get the failure hash from the warden environment
  def failure_hash
    failure = warden.env['warden'].message
    # fail-safe error message (you'll see this if login validation doesn't catch missing username/password)
    failure = { reason: :login_invalid } if failure.nil? || !failure.is_a?(Hash)

    failure
  end

  # Logs the user out of back office, warden and the Rails session.
  def logout_process
    # let the back office know we logged out before we destroy the warden session (won't have current_user otherwise)
    # note the use of the & safe navigation as current_user may be null
    # If this fails they'll get a try again notice, this scenario must be mitigated by the cookie being limited to the
    # browser session.
    current_user&.logout_back_office
    logout if current_user # destroys the warden session
    reset_session
  end

  # get latest account data into cache
  def setup_account_cache
    return unless authorised? current_user, requires_all_action: AuthorisationHelper::DASHBOARD_HOME

    Account.refresh_cache!(current_user)
    User.refresh_cache!(current_user)
  end

  # @return the parameter object's permitted keys and values relating to :user
  def login_params
    params.require(:user).permit(:username, :password, :token)
  end

  # @return true if the user has just entered a two factor token
  def two_factor?(params)
    params.key?(:token)
  end

  # Associate the symbol for login failure to the correct attribute
  # @param reason [Symbol] the reason for failure
  # @return [Symbol] the attribute to associate the error with
  def error_attribute(reason)
    return :password if %i[login_invalid].include?(reason)
    return :token if %i[invalid_token token_expired token_required].include?(reason)

    :base
  end
end
