# frozen_string_literal: true

# Errors module - a place to put error handling related files
# see https://medium.com/rails-ember-beyond/error-handling-in-rails-the-modular-way-9afcddd2fe1b
module Error
  # Redirects to a URL specified in @see WizardRedirectError rather than allow them to continue with the current one.
  # Used to prevent wizards being started part way through if the user visits a specific URL rather than clicking
  # through the appropriate links.
  #
  # include Error::WizardRedirectHandler in application_controller.rb to handle WizardRedirectError errors
  module WizardRedirectHandler
    extend ActiveSupport::Concern

    # Code to mix into including classes to provide error handling
    included do
      rescue_from WizardRedirectError do |exception|
        # redirect to appropriate error page
        Rails.logger.warn "User entered wizard part way through [ip: #{request.ip}], redirecting to #{exception.url}"
        redirect_to(exception.url)
      end
    end
  end
end
