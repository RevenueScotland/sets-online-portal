# frozen_string_literal: true

# Authorisation helpers for this application
module AuthorisationHelper
  # Constants for the various authorisation checks

  # SLFT
  # View SLFT Summary, and the Create SLFT button
  SLFT_SUMMARY = %i[pwslftsb pwslftam pwslftup pwslftcr].freeze
  # Final Submit on SLFT
  SLFT_SUBMIT = %i[pwslftsb pwslftam].freeze
  # Amend link on return lists for SLFT (summary page and view all returns)
  SLFT_AMEND = %i[pwslftam].freeze
  # Continue link on return lists for SLFT (summary page and view all returns)
  SLFT_CONTINUE = %i[pwslftup].freeze
  # Save button on SLFT summary page
  SLFT_SAVE = %i[pwslftcr pwslftup].freeze
  # Access to Load SLFT 'page'
  SLFT_LOAD = %i[pwslftam pwslftup].freeze

  # LBTT
  # View LBTT Summary, and the Create LBTT button
  LBTT_SUMMARY = %i[pwlbttsb pwlbttam pwlbttup pwlbttcr].freeze
  # Final Submit on LBTT
  LBTT_SUBMIT = %i[pwlbttsb pwlbttam].freeze
  # Amend link on return lists for LBTT (summary page and view all returns)
  LBTT_AMEND = %i[pwlbttam].freeze
  # Continue link on return lists for LBTT (summary page and view all returns)
  LBTT_CONTINUE = %i[pwlbttup].freeze
  # Save button on LBTT summary page
  LBTT_SAVE = %i[pwlbttcr or pwlbttup].freeze
  # Access to Load LBTT 'page'
  LBTT_LOAD = %i[pwlbttam or pwslbttup].freeze

  # Messages/Dashboard
  # View all returns page and link/Returns region on the dashboard page
  VIEW_RETURNS = %i[tareview].freeze
  # View all message page and link/unread message region on the dashboard page
  VIEW_MESSAGES = %i[wssecmsg].freeze
  # Show/view link on messages (summary page and view)
  VIEW_MESSAGE_DETAIL = %i[wsmsgdtl].freeze
  # Create Message on dashboard/Reply to message show message page
  CREATE_MESSAGE = %i[wssmcre].freeze
  # Create an attachment on a message
  CREATE_ATTACHMENT = %i[wssmatt].freeze
  # Download attachment on show message page
  DOWNLOAD_ATTACHMENT = %i[wsgetatt].freeze
  # Delete attachment link on post submission page for messages
  DELETE_ATTACHMENT = %i[wssmdet].freeze
  # Dashboard home page (and minimum set of actions required to access application)
  DASHBOARD_HOME = %i[racpvw tareview wsgetatt wssecmsg wsprtdtl wslsttra wsmsgdtl wslstusr].freeze

  # Accounts/Users
  # Account Details link and  Page
  VIEW_ACCOUNTS = %i[wsprtdtl].freeze
  # Update Party links and pages
  UPDATE_PARTY = %i[wsmntpty].freeze
  # Edit and create a new user links and pages from Account users page
  CREATE_USERS = %i[usrupd].freeze

  # Claim Repayment
  CLAIM_REPAYMENT = %i[wsclaim].freeze

  # Determine if the supplied user is authorised to perform the action. If authorisation is disabled, via the
  # Rails.configuration.x.authorisation.disabled flag then this method returns true. Options is a hash, which
  # can contain the following authorisation options:
  #   requires_action: "action_code" or requires_action: ["action_code_1", "action_code_2"]
  #     This checks that the user has access to the action, in the case of an array, has access to at least one action
  #   requires_all_action: "action_code" or requires_all_action: ["action_code_1", "action_code_2"]
  #     This checks that the user has access to the action, in the case of an array, has access to all the actions
  # if both are present, then requires_all_action is checked first
  # @param user [User] user to check if they have the action_code
  # @param options [Hash] options to check for authorisation options
  # @return [Boolean] true if the user is authorised (or authorisation is disabled), otherwise false
  def authorised?(user, options)
    return true if Rails.configuration.x.authorisation.disabled || options.nil? || options.empty?
    return true if options.nil? || %i[requires_action requires_all_action].none? { |k| options.key? k }

    check_requires user, options
  end

  # returns true if the current user has access to one of the action codes. Returns false if the user doesn't
  # have access to the action code, or there is no current user, or if the current user has no roles
  # @param action_codes [String/Symbol/Array] Either a single action code, or an array of action codes. In the
  #        array case, at least one action must be present
  # @return [Boolean] true if the user is authorised (or authorisation is disabled), otherwise false
  def can?(action_codes)
    return true if Rails.configuration.x.authorisation.disabled || action_codes.empty?
    return false unless user_roles? current_user

    check_requires_action current_user.user_roles['user_role'], action_codes
  end

  # returns true if the current user hasn't access to one of the action codes
  # @param action_codes [String/Symbol/Array] Either a single action code, or an array of action codes.  In the
  #        array case, at least one action must be present
  # @return [Boolean] true if the user is not authorised (or authorisation is not disabled), otherwise false
  def cannot?(action_codes)
    !can? action_codes
  end

  private

  # Determine if the supplied user is authorised to perform the action. @see #authorised for more information.
  # @param user [User] user to check if they have the action_code
  # @param options [Hash] options to check for authorisation options
  # @return [Boolean] true if the user is authorised (or authorisation is disabled), otherwise false
  def check_requires(user, options)
    return false unless user_roles?(user)

    roles = user.user_roles['user_role']
    return check_requires_all_action(roles, options[:requires_all_action]) if options.key? :requires_all_action

    check_requires_action(roles, options[:requires_action]) if options.key? :requires_action
  end

  # Determine if supplied user roles has access to all of the supplied action_codes.
  # @param roles [Array] Array of roles
  # @param action_codes [String/Array] the action code(s) to check
  # @return [Boolean] true if the user has access to all the action codes, otherwise false
  def check_requires_all_action(roles, action_codes)
    return false if roles.empty?
    return true if action_codes.empty?

    action_codes = [action_codes] unless action_codes.is_a? Array
    action_codes.each do |action|
      return false unless ActionRoles.role_has(roles, action)
    end
    true
  end

  # Determine if supplied user roles has access to at least one of the supplied action_codes.
  # @param roles [Array] Array of roles
  # @param action_codes [String/Array] the action code(s) to check
  # @return [Boolean] true if the user has access to all the action codes, otherwise false
  def check_requires_action(roles, action_codes)
    return false if roles.empty?
    return true if action_codes.empty?

    action_codes = [action_codes] unless action_codes.is_a? Array
    action_codes.each do |action|
      return true if ActionRoles.role_has(roles, action)
    end
    false
  end

  # Determine if the supplied user has any roles
  # @param user [User] user to check
  # @return [Boolean] true if the user is non-nil, and has at least some roles
  def user_roles?(user)
    !user.nil? && !user.user_roles.nil? && !user.user_roles['user_role'].nil? && !user.user_roles['user_role'].empty?
  end

  # return 403/Forbidden status back to the browser
  def raise_forbidden
    render('home/forbidden', status: 403)
  end
end
