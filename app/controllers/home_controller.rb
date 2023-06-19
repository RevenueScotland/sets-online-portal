# frozen_string_literal: true

# Controller for the main home page
class HomeController < ApplicationController
  # No authentication for these pages
  skip_before_action :require_user

  # Index page
  def index; end

  # Cookies page note can't use cookies as that overrides the cookies method
  def cookies_page
    return unless params['cookie-preferences'].present? && params['cookie-statistics'].present?

    set_storage_permissions(preferences: params['cookie-preferences'], statistics: params['cookie-statistics'])
  end
end
