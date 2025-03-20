# frozen_string_literal: true

# Login/logout functions of a User class.
# Split out into a separate class to keep User class small/keep Rubocop happy.
module UserLogin
  # Logs this authenticate user out of the back office, NOT the app.
  # Called by @see LoginController#logout.  Call @see LoginController#logout to actually log out.
  # Logs and ignores any StandardError exceptions so we can still log out of the app later.
  def logout_back_office
    # NOTE: the back office is case sensitive but this is from the model which is already upcase
    call_ok?(:log_off_user, Username: username)
  end

  # @return true if the token is invalid, otherwise false
  def token_invalid?
    return false if token_valid2_fa.to_s.empty? || !user_is2_fa

    token_valid2_fa.casecmp('INVALID').zero?
  end

  # @return true if the token has expired, otherwise false
  def token_expired?
    return false if token_valid2_fa.to_s.empty? || !user_is2_fa

    token_valid2_fa.casecmp('EXPIRED').zero?
  end

  # This isn't a ActiveSupport::Concern but we still want to include class methods which is what this code does.
  # @param base is the 'HostClass' in our case
  def self.included(base)
    base.extend ClassMethods
  end

  # Methods which will be added to the host's class (ie User self.<methods>)
  module ClassMethods
    # Authenticate this user on the Back Office.  Called by Warden, do not call directly, use authenticate! instead.
    # @param username [String] the username to check
    # @param password [String] the password to check, set to nil to do 2 factor authentication
    # @param token [String] the token to check, set to nil to do username/password authentication
    # @return an authenticated/un-authenticated user or else nil if the call fails, or the back office fails
    def authenticate(username, password, token)
      return username_password_authenticate(username, password) unless password.nil?
      return two_factor_authenticate(username, token) unless token.nil?

      nil
    end

    private

    # Authenticate this user with their username and password on the Back Office
    # @param username [String] the username to check
    # @param password [String] the password to check
    # @return an authenticated/un-authenticated user or else nil if the call fails, or the back office fails
    def username_password_authenticate(username, password)
      user = nil

      # NOTE: We need to uppercase the username as back office is case sensitive
      call_ok?(:authenticate_user, Username: username.upcase, Password: password) do |body|
        user = from_backoffice body, username
      end

      user
    end

    # Authenticate this user with their username and token on the Back Office for two factor authentication
    # @param username [String] the username to check
    # @param token [String] the token to check
    # @return an authenticated/un-authenticated user or else nil if the call fails, or the back office fails
    def two_factor_authenticate(username, token)
      user = nil

      # NOTE: We need to uppercase the username as back office is case sensitive and trim the token
      # to handle dodgy cut and paste
      call_ok?(:authenticate_user, Username: username.upcase, Token: token.strip) do |body|
        # Set up the Authenticate user details from response
        user = from_backoffice body, username
      end

      user
    end

    # Create a user from the back office result
    # @param body [Object] the back office result
    # @param username [String] the username of the user to create
    # @return [User] the user from the back office result, with the password and token cleared
    def from_backoffice(body, username)
      # Convert the true and false from the back office to a Y/N
      # The TaCs is held as a Y/N to display the check box on the page
      # Note that we must get the false back otherwise we assume they are signed up
      body[:user_is_signed_ta_cs] = (body[:user_is_signed_ta_cs] == false ? 'N' : 'Y')
      body[:portal_objects_access] = convert_portal_objects_hash(body[:portal_objects_access])
      user = User.new(body)
      user.username = username # Back office doesn't pass the username back so need to add
      user.token = user.password = nil # clear any tokens or passwords

      # stringify the keys, as that's what the get user code does
      user.user_roles&.stringify_keys!

      user
    end

    # Extracts portal object details from the back office result to create the portal object item
    # and assigned back to user
    # @param body [Object] the back office result
    def convert_portal_objects_hash(body)
      portal_objects = []
      ServiceClient.iterate_element(body) do |object|
        portal_objects.push(object)
      end

      portal_objects
    end
  end
end
