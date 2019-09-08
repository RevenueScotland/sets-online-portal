# frozen_string_literal: true

# Controller for forgotten username to reset username
class ForgottenUsernamesController < ApplicationController
  # Allow specific pages to be unauthenticated
  skip_before_action :require_user, only: %I[new create]

  # Renders forgotten username form
  def new
    @forgotten_username = ForgottenUsername.new
  end

  # Calls forgotten-username service
  def create
    @forgotten_username = ForgottenUsername.new(params.require(:forgotten_username).permit(:email_address))
    if @forgotten_username.save
      render 'new-confirmation'
    else
      render 'new'
    end
  end
end
