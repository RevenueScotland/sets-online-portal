# frozen_string_literal: true

# Controller for forgotten password to reset password
class ForgottenPasswordsController < ApplicationController
  # don't need to be logged in to have forgotten your password
  skip_before_action :require_user, only: %I[new create]

  # Renders password change form
  def new
    @forgotten_password = ForgottenPassword.new
  end

  # Calls forgotten-password service
  def create
    @forgotten_password = ForgottenPassword.new(password_params)
    if @forgotten_password.save
      render 'new-confirmation'
    else
      render 'new'
    end
  end

  private

  # controls the permitted parameters to this controller
  def password_params
    params.require(:forgotten_password).permit(:username, :email_address, :new_password, :new_password_confirmation)
  end
end
