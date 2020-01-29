# frozen_string_literal: true

# Controller for users management
# note that most actions should be done in the context of the
# current user
class UsersController < ApplicationController
  authorise route: %i[new create index edit update], requires: AuthorisationHelper::CREATE_USERS

  # Renders an empty user ready for entry
  def new
    @user = User.new
  end

  # Calls create for a new user
  def create
    @user = User.new(user_params)

    # save was requested by either current_user or else must be a new registration
    if @user.save(current_user)
      redirect_to users_path
    else
      render 'new'
    end
  end

  # Renders a list of all users for the current user's account, optionally filtered by UserFilter.
  def index
    @user_filter = UserFilter.new(UserFilter.params(params))
    @users, @pagination_collection = current_user.list_users(params[:page], @user_filter)
    # Determines when the find functionality is executed in index page of financial transactions
    @on_filter_find = !params[:user_filter].nil?
  end

  # Show change your password form.
  def change_password
    @user = current_user
  end

  # Actually attempt to change the password of current_user
  def update_password
    @user = current_user

    # update_password assigns params to user object
    if @user.update_password(password_params)
      redirect_after_successful_password_update
    else
      render 'change_password'
    end
  end

  # Show the confirm the terms and conditions page
  def update_tcs
    @user = current_user
  end

  # Confirm the user has read the t&cs with the back office, and redirect to the
  # dashboard if that's successful
  def confirm_update_tcs
    @user = current_user

    if @user.confirm_tcs(tcs_params)
      redirect_to dashboard_path
    else
      render 'update_tcs'
    end
  end

  # Returns an existing user for editing
  def edit
    @user = find_user(params[:username])
  end

  # Calls update for an existing user.
  # Ensures the user being changed is in the list of users for the current user's account to prevent
  # misuse (ie changing another account's user!)
  def update
    @user = find_user(params[:username])

    if @user.update(user_params, current_user)
      redirect_to users_path
    else
      render 'edit'
    end
  end

  private

  # Lookup a user in the account of the current_user.
  # @param [String] username of the user to find
  def find_user(username)
    user = User.find(username, current_user)
    raise Error::AppError.new('UsersController.find_user', "Username #{username} not found") if user.nil?

    user
  end

  # controls the permitted parameters to this controller
  def user_params
    params.require(:user).permit(
      :new_username, :user_is_current, :forename, :surname, :email_address, :new_password, :new_password_confirmation,
      :email_address_confirmation, :phone_number, user_roles: []
    )
  end

  # controls the permitted parameters to this controller for password related operations
  def password_params
    params.require(:user).permit(:username, :old_password, :new_password, :new_password_confirmation)
  end

  # controls the permitted parameters to this controller for confirming tcs related operations
  def tcs_params
    params.require(:user).permit(:username, :user_is_signed_ta_cs)
  end

  # Redirect to logout if a password change is required on the current user else show the change_password_confirmation.
  def redirect_after_successful_password_update
    if current_user.check_password_change_required?
      redirect_to logout_path
    else
      render 'change_password_confirmation'
    end
  end
end
