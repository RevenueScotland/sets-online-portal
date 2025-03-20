# frozen_string_literal: true

# Base Class for the application includes protection from
# forgery and also locale handling and security checking function
class ApplicationController < ActionController::Base
  # order in important, timeout needs to kick in before authorise
  # checking for user before checking access
  include Core::Timeout

  before_action :require_user

  include Core::Authorise
  include Error::WizardRedirectHandler
  include DS::Storage

  protect_from_forgery with: :exception
  before_action :set_locale
  before_action :set_response_headers

  helper_method :account_has_service?, :account_has_no_service?, :account_service
  helper_method :storage_permission?

  # Check if the current account has the supplied service
  # @return [Boolean] returns true if the account has the service otherwise false
  def account_has_service?(service)
    account = Account.find(current_user)
    account.service?(service)
  end

  # @return [String] returns the service of the current account
  def account_service
    return 'LBTT' if account_has_service?(:lbtt)

    return 'SAT' if account_has_service?(:sat)

    'SLFT' if account_has_service?(:slft)
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
    if current_user
      force_redirects
      true
    else
      Rails.logger.debug('User needs to be logged in')
      redirect_to login_url
      false
    end
  end

  # Forces redirects if the user needs to change the password or confirm the terms and conditions
  # or user has access to portal objects (enrolments)
  def force_redirects # rubocop:disable Metrics/AbcSize
    if current_user.check_password_change_required?
      Rails.logger.debug('User needs to change password')

      redirect_to user_change_password_path unless %w[change_password update_password].include?(action_name)
    elsif current_user.check_tcs_required?
      Rails.logger.debug('User needs to update T&C')
      redirect_to user_update_tcs_path unless %w[update_tcs process_update_tcs].include?(action_name)
    elsif current_user.check_object_needed? && current_user.portal_object_index.nil?
      redirect_enrolment
    end
  end

  # redirect to enrolment selection to select the portal object if there are multiple portal objects
  # else select the current portal object index
  def redirect_enrolment
    references = current_user.portal_objects_access
    if references.size == 1
      current_user.portal_object_index = 0
      request.env['warden'].set_user(current_user)
    elsif references.size > 1
      redirect_to user_select_enrolment_path unless %w[select_enrolment process_enrolment].include?(action_name)
    end
  end

  # The public transactions cannot be accessed if the user is logged in
  # Set this as a before action in the specific controller on the initial
  # public pages to redirect to the dashboard
  def enforce_public
    return unless current_user

    Rails.logger.info('Authenticated user accessing public page - redirecting to dashboard')
    redirect_to dashboard_url
  end

  # Used in a before action to stop browsers caching the transaction pages
  # otherwise on logout you can use back to see previous data
  # Note that turbo may override this as it uses it's own cache see application_ui.js
  def set_response_headers
    response.set_header('Cache-Control', 'no-cache,no-store')
    response.set_header('Pragma', 'no-cache')
    response.set_header('Expires', 'Tue, 01 Jan 1980 00:00:00 GMT')
    response.set_header('Cross-Origin-Embedder-Policy', 'require-corp')
    response.set_header('Cross-Origin-Opener-Policy', 'same-origin')
    response.set_header('Cross-Origin-Resource-Policy', 'same-origin')
  end
end
