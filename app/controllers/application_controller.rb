# frozen_string_literal: true

# Base Class for the application includes protection from
# forgery and also locale handling and security checking function
class ApplicationController < ActionController::Base
  include Error::ErrorHandler
  include Error::WizardRedirectHandler
  include Authorise
  include AuthorisationHelper

  protect_from_forgery with: :exception
  before_action :require_user
  before_action :authorise_action
  before_action :set_locale
  before_action :set_no_cache
  before_action :check_session_expiry
  default_form_builder FormBuilderHelper::LabellingFormBuilder

  helper_method :account_has_service?, :account_has_no_service?

  # Check if the current account has the supplied service
  # @return [Boolean] returns true if the account has the service otherwise false
  def account_has_service?(service)
    account = Account.find(current_user)
    account.service?(service)
  end

  # Check if the current account has the supplied service
  # @return [Boolean] returns true if the account does not have service otherwise false
  def account_has_no_service?
    account = Account.find(current_user)
    account.no_services?
  end

  # sets the local to the parameter URL or the default if not present
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  # defaults the URL to include the current locale
  def default_url_options
    { locale: I18n.locale }
  end

  private

  # set as a before_action to make sure the user is logged in when required
  def require_user
    manage_session_expiry(safe_lookup)
    return if current_user

    Rails.logger.debug('User needs to be logged in')
    redirect_to login_url
    false
  end

  # before action that calls manage_session_expiry to check if session has run out of time.
  def check_session_expiry
    manage_session_expiry(safe_lookup)
  end

  # Enforce session time to live (ie max time between activity) and maximum over-all session length.
  # We don't set the session TTL on the definition of the cookie session store (eg in a session_store.rb initializer)
  # because we want to be able to redirect to a helpful page when the session expires, rather than going straight to
  # the login page (which is what you get when the session doesn't exist anymore).
  # Also sets @session_ttl_warning to activate the session warning javascript (see session_expiry.js) (ie only on
  # pages that enforce session expiry hence part of this method).
  # @param sys_params [Hash] the system parameters configuration
  def manage_session_expiry(sys_params)
    # initialise the session values using failover values if needed
    max_idle_mins = default_ttl_value(sys_params['MAX_IDLE_MINS'], 60)
    update_ttl(:SESSION_TTL_INDEX, max_idle_mins, false)
    update_ttl(:MAX_SESSION_EXPIRE_TIME_INDEX, default_ttl_value(sys_params['MAX_SESS_MINS'], 600), false)

    # check if it's expired and show session ended page
    redirect_to logout_session_expired_path if session_has_expired

    update_ttl_warning(max_idle_mins, sys_params['IDLE_WARN_MINS'])

    # user has done something so update session TTL
    update_ttl(:SESSION_TTL_INDEX, max_idle_mins, true)
  end

  # Lookup the system parameters for session management.
  # Reports and swallow any StandardError.
  # @return [Hash] system parameters or else empty hash to allow failsafe values to be used.
  def safe_lookup
    sys_params = {}
    begin
      sys_params = ReferenceData::SystemParameter.lookup('PWS', 'SYS', 'RSTU')
    rescue StandardError => e
      Rails.logger.error(e)
    end
    sys_params
  end

  # Sets the selected session variable to the current time plus the provided value to
  # update the relevant session TTL information.
  # @param session_index - the session variable name
  # @param ttl_value - holds the new value, in minutes
  # @param [Boolean] force_update - true to overwrite the session variable, false to only set if doesn't exist already
  def update_ttl(session_index, ttl_value, force_update)
    if force_update
      session[session_index] = Time.now + (ttl_value * 1.minute)
    else
      session[session_index] ||= Time.now + (ttl_value * 1.minute)
    end
  end

  # Update the @session_ttl_warning variable using the given SystemParam (usually 'IDLE_WARN_MINS')
  # Note the parameter is the number of minutes before the idle time to warn
  # If it's not valid, sets it to null default.
  # @param max_idle_mins [time] - the max idle period
  # @param sys_param [SystemParameter] - the system parameters that has the value to use
  def update_ttl_warning(max_idle_mins, sys_param)
    if sys_param&.value.nil?
      Rails.logger.debug('Idle time system parameter is missing')
      @session_ttl_warning = nil
    else
      @session_ttl_warning ||= max_idle_mins - sys_param&.value.to_i
    end
  end

  # default the TTL value based on the parameter and the failsafe
  # @param sys_param - holds the new value, in minutes
  # @param [Integer] failsafe - if value is nil or less than 1, use this value instead
  def default_ttl_value(sys_param, failsafe)
    value = sys_param&.value&.to_i
    return failsafe if value.nil? || value < 1

    value
  end

  # @return true if either of the session expiry times are up, else false if the user may continue.
  def session_has_expired
    return true if Time.now >= session[:MAX_SESSION_EXPIRE_TIME_INDEX]

    return true if Time.now >= session[:SESSION_TTL_INDEX]

    false
  end

  # Used in a before action to stop browsers caching the transaction pages
  # otherwise on logout you can use back to see previous data
  def set_no_cache
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Tue, 01 Jan 1980 00:00:00 GMT'
  end
end
