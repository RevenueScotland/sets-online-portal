# frozen_string_literal: true

# Errors module - a place to put error handling related files
# see https://medium.com/rails-ember-beyond/error-handling-in-rails-the-modular-way-9afcddd2fe1b
module Error
  # include Error::ErrorHandler in application_controller.rb to handle errors globally (unless config says not to)
  module ErrorHandler
    extend ActiveSupport::Concern

    # Code to mix into including classes to provide error handling
    included do
      # log and handle errors unless configuration says to go with RoR default behaviour
      # (eg on development we may prefer the red stacktrace screen)
      # return unless Rails.configuration.x.error_handler.rescue_standard_error

      #      clazz.class_eval do
      rescue_from StandardError do |exception|
        error_ref = Error::ErrorHandler.log_exception(exception)
        # redirect to appropriate error page
        redirect_to_error_page(error_ref)
      end
      #      end
    end

    # Method to log exceptions in a standard way (includes a backtrace)
    # We do not use the rails class_method as we use this in classes where this module is not included
    # @return [String] the error reference used
    def self.log_exception(exception)
      message = if exception.respond_to?(:code)
                  "#{exception.class}: #{exception&.code} #{exception&.message}"
                else
                  "#{exception.class}: #{exception&.message}"
                end

      error_ref = log_message(message)
      Rails.logger.error("BACKTRACE: \n  #{exception.backtrace[0..17].join("\n  ")}")

      error_ref
    end

    # Logs the error reference, message and a stacktrace
    # @return [String] the error reference used
    def self.log_message(message)
      error_ref = error_reference
      Rails.logger.error("\nERROR: #{error_ref}\n  #{message}")
      error_ref
    end

    # Generated an error reference
    # Uses Time to get the current time now, which is used for timing the {.log_exception caught exceptions}
    # @return [String] Error reference
    private_class_method def self.error_reference
      Time.now.to_i.to_s[5, 10]
    end

    # Redirect to the generic error page with details of the error in the flash hash.
    # @param [String] error_ref The reference for the error
    # @param [String] url The url to redirect to (using the helper)
    def redirect_to_error_page(error_ref, url = home_error_url)
      # Prepare error details for display on screen to the user (so beware leaking information).
      # Currently only displaying the error ref so the user has a number to report that we can also find in logs.
      flash[:fatal_error] = error_ref
      Rails.logger.debug { "  Redirecting to error page #{url}" }
      redirect_to(url)
    end
  end
end
