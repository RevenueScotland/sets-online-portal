# frozen_string_literal: true

# Controller for users management
# note that most actions should be done in the context of the
# current user
class UsersController < ApplicationController # rubocop:disable Metrics/ClassLength
  authorise route: %i[new create show index edit update], requires: RS::AuthorisationHelper::CREATE_USERS

  # Renders a list of all users for the current user's account, optionally filtered by UserFilter.
  def index
    @user_filter = UserFilter.new(UserFilter.params(params))
    @users, @pagination_collection = current_user.list_users(params[:page], @user_filter)
    # Determines when the find functionality is executed in index page of financial transactions
    @on_filter_find = !params[:user_filter].nil?
  end

  # Support a show route and redirect to users list to avoid no route issue when using refresh after update
  def show
    redirect_to users_path
  end

  # Renders an empty user ready for entry
  def new
    @user = User.new
  end

  # Returns an existing user for editing
  def edit
    @user = find_user(params[:username])
  end

  # Calls create for a new user
  def create
    @user = User.new(user_params)

    # save was requested by either current_user or else must be a new registration
    if @user.save(current_user)
      redirect_to users_path
    else
      render('new', status: :unprocessable_content)
    end
  end

  # Show change your password form.
  def change_password
    @user = current_user
  end

  # Actually attempt to change the password of current_user
  def update_password
    @user = current_user

    # update_password assigns params to user object
    if @user.update_password?(password_params)
      request.env['warden'].set_user(update_current_user)
      redirect_after_successful_password_update
    else
      render('change_password', status: :unprocessable_content)
    end
  end

  # Update the current user password details in warden
  def update_current_user
    @pws_expiry_prd ||= ReferenceData::SystemParameter.lookup(
      'SYSTEM', 'SYS', 'RSTU', safe_lookup: true
    )['PWD_EXPIRY_PRD']&.value

    current_user.password_change_required = false
    current_user.password_expiry_date = Time.zone.today + @pws_expiry_prd.to_i.days
    current_user
  end

  # Show the confirm the terms and conditions page
  def update_tcs
    @user = current_user
  end

  # Confirm the user has read the t&cs with the back office, and redirect to the
  # dashboard if that's successful
  def process_update_tcs
    @user = current_user

    if @user.confirm_tcs?(tcs_params)
      # Store the fact Ts and Cs are signed in the warden session
      current_user.user_is_signed_ta_cs = 'Y'
      request.env['warden'].set_user(current_user)
      redirect_to dashboard_path
    else
      render('update_tcs', status: :unprocessable_content)
    end
  end

  # Show the select enrolment page
  def select_enrolment
    @user = current_user
  end

  # Set the portal object index which is selected by user, and redirect to the
  # dashboard if that's successful
  def process_enrolment
    @user = current_user

    if @user.confirm_portal_object?(user_params)
      current_user.portal_object_index = params[:user][:portal_object_index].to_i
      request.env['warden'].set_user(@user)
      redirect_to dashboard_path
    else
      render('select_enrolment', status: :unprocessable_content)
    end
  end

  # Calls update for an existing user.
  # Ensures the user being changed is in the list of users for the current user's account to prevent
  # misuse (ie changing another account's user!)
  def update
    @user = find_user(params[:username])

    if @user.update(user_params, current_user)
      redirect_to users_path
    else
      render('edit', status: :unprocessable_content)
    end
  end

  private

  # Lookup a user in the account of the current_user.
  # @param [String] username of the user to find
  def find_user(username)
    if username.is_a?(String) && Base64.strict_encode64(Base64.decode64(username)) == username
      username =  Base64.urlsafe_decode64(username)
    end
    user = User.find(username, current_user)
    raise Error::AppError.new('UsersController.find_user', "Username #{username} not found") if user.nil?

    user
  end

  # controls the permitted parameters to this controller
  def user_params
    attributes = %i[new_username user_is_current forename surname email_address new_password new_password_confirmation
                    email_address_confirmation phone_number portal_object_index]
    # Rubocop disable added as this breaks the functionality
    # https://github.com/rubocop/rubocop-rails/issues/1418
    params.require(:user).permit(attributes, user_roles: [], portal_objects_access: []) # rubocop:disable Rails/StrongParametersExpect
  end

  # controls the permitted parameters to this controller for password related operations
  def password_params
    # Rubocop disable added as this breaks the functionality
    # https://github.com/rubocop/rubocop-rails/issues/1418
    params.require(:user).permit(:username, :old_password, :new_password, :new_password_confirmation) # rubocop:disable Rails/StrongParametersExpect
  end

  # controls the permitted parameters to this controller for confirming tcs related operations
  def tcs_params
    # Rubocop disable added as this breaks the functionality
    # https://github.com/rubocop/rubocop-rails/issues/1418
    params.require(:user).permit(:username, :user_is_signed_ta_cs) # rubocop:disable Rails/StrongParametersExpect
  end

  # Redirect to logout if a password change is required on the current user else show the change_password_confirmation.
  def redirect_after_successful_password_update
    if current_user.check_password_change_required?
      redirect_to logout_path
    else
      redirect_to user_change_password_confirmation_url
    end
  end
end
