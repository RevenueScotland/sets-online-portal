# frozen_string_literal: true

# Sets up Warden for authentication.
# See https://jeffkreeftmeijer.com/2010/simple-authentication-with-warden/ for a helpful guide.
Rails.configuration.middleware.use RailsWarden::Manager do |manager|
  # The failure app is called when the user fails to logon. Warden and rack forward to it
  # note the below forwards including the current rack environment
  manager.failure_app = ->(env) { LoginController.action(:unauthenticated).call(env) }
  manager.default_strategies :fl_users_strategy
end

# Override standard warden serializer
module Warden
  # This class is called by warden an handles the retrieval of the current user into the
  # current request scope based on the details stored in the cookie
  class SessionSerializer
    def serialize(user)
      # This will store the details and return the key
      user.serializable_hash
    end

    def deserialize(keys)
      # this will take the key and build the full user record
      User.new(keys)
    end
  end
end

# Adds our login checks to the Warden strategies list (ie tells Warden how we want it to do authentication).
Warden::Strategies.add(:fl_users_strategy) do
  # Checks if the we have enough information to authenticate
  def valid?
    user = params[:user]
    Rails.logger.debug { "Checking valid? with : #{user[:username]}" }
    return false if (user.key?(:password) && user[:password].blank?) || (user.key?(:token) && user[:token].blank?)

    user[:username].present?
  end

  # Check if a request contains authentic credentials (ie can they log in).
  # Note that we don't actually return the user, if successful current_user will be populated with the logged in user.
  def authenticate!
    Rails.logger.debug { "Authenticate with : #{params[:user][:username]}" }
    username, password, token = params[:user].values_at :username, :password, :token

    check_authentication User.authenticate(username, password, token)
  end

  # check the user details returned to make sure that the user is authenticated
  # has completed the registration and is not locked
  def check_authentication(user)
    return fail!(reason: handle_unauthenticated(user), user: user) unless user&.user_is_authenticated

    # If the user isn't registered they may not have completed/activated the registration
    # so need to signal back
    # Return fail if user has not been approved from BO
    return fail!(reason: :login_not_activated, user: user) unless user&.user_is_registered
    return fail!(reason: :unapproved_login, user: user) unless user.user_is_approved

    success!(user)
  end

  # handle the un-authentication case when logging in.
  def handle_unauthenticated(user)
    # check for the account being locked first, as both locked as 2FA are set to TRUE if 2FA is enabled
    return :login_invalid if user.nil? || user.user_locked
    return :invalid_token if user.token_invalid?
    return :token_expired if user.token_expired?
    return :token_required if user.user_is2_fa

    # if all else fails, just return this
    :login_invalid
  end
end
