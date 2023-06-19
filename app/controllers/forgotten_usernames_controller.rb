# frozen_string_literal: true

# Controller for forgotten username to reset username
class ForgottenUsernamesController < ApplicationController
  # Allow specific pages to be unauthenticated
  skip_before_action :require_user, only: %I[new create confirmation]

  # Renders forgotten username form
  def new
    @forgotten_username = ForgottenUsername.new
  end

  # Calls forgotten-username service
  def create
    @forgotten_username = ForgottenUsername.new(params.require(:forgotten_username).permit(:email_address))
    if @forgotten_username.save
      redirect_to forgotten_username_confirmation_url
    else
      render('new', status: :unprocessable_entity)
    end
  end

  # confirmation page
  def confirmation; end
end
