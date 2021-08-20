# frozen_string_literal: true

# Controller for the main home page
class HomeController < ApplicationController
  # No authentication for these pages
  skip_before_action :require_user, only: %I[index error forbidden new_page_error]

  # Index page
  def index; end

  # Standalone something has gone wrong page
  def error; end

  # Standalone authorisation failure page
  def forbidden; end

  # handle file download error
  def new_page_error; end
end
