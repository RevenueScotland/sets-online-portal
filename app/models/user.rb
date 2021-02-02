# frozen_string_literal: true

# Represents a user, whether they are logged in, backing a new user form or linked to an account.
#
# Warden manages our security (@see warden.rb and @see UserLogin).  The logged in user is stored in the encrypted rails
# session cookie.  We sometimes call it the "skinny" user because we only store a few fields in the cookie to keep it
# small (@see User#attributes).  Importantly, one of these attributes is the account id (party_refno) which is used
# for caching.
#
# User includes AccountBasedCaching to manage caching of the list of users that an account has.
# The account involved is usually the one associated with the current_user/logged in user.
#
# Calling User.find will find a single user in the account. Calling User.all will find all users in the account.
# The users returned we sometimes call "fat" users because all user details will be populated (eg name, email address).
#
# The skinny logged in user is found in the current_user security variable in controllers.  It's passed into
# AccountBasedCaching methods to provide the account ID (party_refno) and also the username, which is added to
# back office requests as the requestor.
#
# Note that to find the [fat] details of the [skinny] current_user you have to call User.find(current_user).
#
class User < FLApplicationRecord # rubocop:disable Metrics/ClassLength
  include UserLogin
  include UserValidation
  include Pagination
  include AccountBasedCaching

  # Attributes for this class, in list so can re-use as permitted params list in the controller
  # note memorable answer and memorable question and are shown as memorable word and hint on the page
  def self.attribute_list
    %i[party_refno user_roles work_place_refno forename surname email_address phone_number preferred_language
       email_address_confirmation old_password new_password new_password_confirmation password password_change_required
       password_expiry_date user_is_authenticated user_is_registered user_locked user_is_current username new_username
       token user_is2_fa token_valid2_fa user_is_signed_ta_cs memorable_question memorable_answer]
  end

  # Fields that can be set on a user
  attribute_list.each { |attr| attr_accessor attr }

  # Define the ref data codes associated with the attributes to be cached in this model
  # @return [Hash] <attribute> => <ref data composite key>
  def cached_ref_data_codes
    { user_roles: comp_key('PORTALROLES', 'SYS', 'RSTU'), user_is_current: comp_key('CURRENT_INACTIVE', 'SYS', 'RSTU') }
  end

  # Define the ref data codes associated with the attributes not to be cached in this model
  # @return [Hash] <attribute> => <ref data composite key>
  def uncached_ref_data_codes
    { user_is_signed_ta_cs: YESNO_COMP_KEY }
  end

  # Custom override getter for user_is_current to return default of 'Y' if not set (important for validation of new
  # record).
  # @return @user_is_current or 'Y' as fail-safe default value
  def user_is_current
    @user_is_current || 'Y'
  end

  # Custom override setter for username to make sure it is stored uppercase as the back office requires it
  # @param [String] value the value to set the username to
  def username=(value)
    @username = (value.nil? ? value : value.upcase)
  end

  # Custom override setter for new username to make sure it is stored uppercase as the back office requires it
  # @param [String] value the value to set the new username to
  def new_username=(value)
    @new_username = (value.nil? ? value : value.upcase)
  end

  # Update the user's password
  def update_password(password_params)
    assign_attributes(password_params)
    return false unless valid?(:update_password)

    call_ok?(:maintain_user, update_password_request)
  end

  # Update the back office that the user has read the T&Cs
  def confirm_tcs(update_tcs_params)
    assign_attributes(update_tcs_params)

    return false unless valid?(:confirm_tcs)

    call_ok?(:maintain_user, confirm_tcs_request)
  end

  # Update the user's memorable word
  def update_memorable_word(word_params, requested_by)
    assign_attributes(word_params)

    return false unless valid?(:update_memorable_word)

    success = call_ok?(:maintain_user, update_memorable_word_request)
    User.refresh_cache!(requested_by) if success
  end

  # Getting the formatted full name of the user.
  # @return [String] the formatted full name of the user.
  def full_name
    [forename, surname].join(' ')
  end

  # the id function needs to return the primary key and is used to build the links
  # @return [String] the username
  def to_param
    username
  end

  # sets the attributes that wil be serialised
  def attributes
    { 'username' => nil, 'work_place_refno' => nil, 'party_refno' => nil, 'user_roles' => nil,
      'password_change_required' => nil, 'password_expiry_date' => nil }
  end

  # Returns the paginated users list linked to the current username, optionally restricted by a UserFilter.
  # @param  [Integer] page number
  # @param  [Filter] filter criteria
  # @return [User] [Pagination Collection] return filtered  paginated list of users and pagination collection required
  #                                         to render pagination html
  def list_users(page, filter = nil)
    return unless filter.nil? || filter.valid?

    user_values = User.all(self).values
    users = user_values.select { |u| filter.include?(u) } unless filter.nil?
    users_filtered, pagination_collection = Pagination.paginate_record(users, page, 10)
    [users_filtered, pagination_collection]
  end

  # what is the account type
  # Utility function that returns the account type even if there isn't a current user otherwise
  # defers to the current user
  # @param current_user [Object] details for the current user
  # @return [String] returns true if the account has the service otherwise false
  #   The three possible outcome of this is ['PUBLIC', 'TAXPAYER', 'AGENT']
  def self.account_type(current_user)
    return 'PUBLIC' if current_user.nil?

    current_user.account_type
  end

  # what is the account type
  # Utility function that returns the account type for the account linked to this user
  # @return [String] returns true if the account has the service otherwise false
  def account_type
    @account ||= Account.find(self)
    @account.party_account_type
  end

  # Find a specific user in the account of requested_by
  # @param [String] user_to_find is the username of the user to find
  # @param [User] requested_by - user making the request (usually the current_user)
  # @return [User] the user we want to find or nil if it doesn't exist
  def self.find(user_to_find, requested_by)
    User.all(requested_by)[user_to_find]
  end

  # User <requested_by> wants to update this user's record in the back office using <user_params>.
  # Sets the params, checks update validation then calls {#save_or_update}
  def update(user_params, requested_by)
    assign_attributes(user_params)
    return false unless valid?(:update)

    save_or_update(requested_by)
  end

  # Create a new user record on the back office.
  # Checks validation then calls {#save_or_update}.
  def save(requested_by)
    return false unless valid?(:save)

    save_or_update(requested_by)
  end

  # Returns a alternative translation key where necessary.
  # "MEMORABLE_password" translated key returned if is been called from Memorable word page
  # "new password" and "new password confirmation" fields are "password" and "password confirmation" for new user.
  # @param attribute [Symbol] the name of the attribute to translate
  # @param translation_options [Object] in this case the party type being processed passed from the page
  # @return [Symbol] the name of the translation attribute
  def translation_attribute(attribute, translation_options = nil)
    return "MEMORABLE_#{attribute}".to_sym if attribute == :password && translation_options == :memorable_word

    return attribute unless %i[new_password new_password_confirmation].include?(attribute)

    return "CREATE_#{attribute}".to_sym if translation_options == :new_user

    "UPDATE_#{attribute}".to_sym
  end

  private

  # Do the save processing for either update or create as long as validation passes
  # This is using {#save_request}
  # Updates the cached list of users if saved successfully.
  def save_or_update(requested_by)
    success = call_ok?(:maintain_user_registration, save_request(requested_by))
    User.refresh_cache!(requested_by) if success
    success
  end

  # @return [Hash] request to save a user object using the authority of requested_by
  def save_request(requested_by)
    if new_record?
      action = 'CREATE'
      self.username = new_username
    else
      action = 'UPDATE'
    end
    { Requestor: requested_by.username, Username: username, Action: action, Forename: forename, Surname: surname,
      EmailAddress: email_address, UserIsCurrent: user_is_current, WorkplaceCode: requested_by.work_place_refno,
      PartyReference: requested_by.party_refno, Password: new_password, ServiceCode: 'SYS',
      UserPhoneNumber: phone_number, UserRolesType: { 'ins2:UserRole' => user_roles.reject(&:empty?) } }
  end

  # @return [Hash] request to update the password of this user using the authority of this user
  def update_password_request
    { Username: username, Requestor: username, Action: 'ChangePassword',
      OldPassword: old_password, NewPassword: new_password, ServiceCode: 'SYS' }
  end

  # @return [Hash] request to update the memorable word and hint of this user using the authority of this user
  def update_memorable_word_request
    { Username: username, Requestor: username, Action: 'MemorableDetails', Password: password,
      MemorableQuestion: memorable_question, MemorableAnswer: memorable_answer, ServiceCode: 'SYS' }
  end

  # @return [Hash] request to update the user that they've confirmed the terms and conditions
  def confirm_tcs_request
    { Username: username, Requestor: username, Action: 'TaCsSignUp' }
  end

  # Gets users data from the back office for the account of the given user.
  # @example Do not call this method directly, use the @see AccountBasedCaching#all method eg use :
  #   "users = User.all(current_user)"
  # as then you'll access cached data rather than hitting the back office each time.
  # @param requested_by [User] is usually the current_user, who is requesting the data and containing the account id
  # @note return list of users for the account
  private_class_method def self.back_office_data(requested_by)
    users = {}
    call_ok?(:maintain_user, Action: 'ListUsers', Requestor: requested_by.username) do |body|
      ServiceClient.iterate_element(body[:users]) do |user|
        users[user[:username]] = User.new_from_fl(convert_back_office_data(user))
      end
    end
    users
  end

  # Converts back office response data format to format we can use to create an object.
  private_class_method def self.convert_back_office_data(user)
    # Fiddle as FL gives yes and no but expect Y and N to be passed back so make the change on load
    yes_nos_to_yns(user, %i[user_is_current])
    # We don't use title so remove it
    user.delete(:title)

    # Set the confirm e-mail to be the same as the original e-mail
    user[:email_address_confirmation] = user[:email_address]
    # Fiddle as FL gives user roles inside a hash and to populate check box we just want the array
    user[:user_roles] = user[:user_roles][:user_role] unless user[:user_roles].nil?
    user
  end

  # Hash to translate back office logical data item into an attribute
  def back_office_attributes
    { PASSWORD: { attribute: :new_password },
      OLD_PASSWORD: { attribute: :old_password } }
  end
end
