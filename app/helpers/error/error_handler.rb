# frozen_string_literal: true

# Errors module - a place to put error handling related files
# see https://medium.com/rails-ember-beyond/error-handling-in-rails-the-modular-way-9afcddd2fe1b
module Error
  # include Error::ErrorHandler in application_controller.rb to handle errors globally (unless config says not to)
  module ErrorHandler
    # Code to mix into including classes to provide error handling
    def self.included(clazz)
      # log and handle errors unless configuration says to go with RoR default behaviour
      # (eg on development we may prefer the red stacktrace screen)
      return unless Rails.configuration.x.error_handler.rescue_standard_error

      clazz.class_eval do
        rescue_from StandardError do |exception|
          timestamp_ref = ErrorHandler.log_exception(exception)
          # redirect to appropriate error page
          redirect_with_error(timestamp_ref)
        end
      end
    end

    # Method to log exceptions in a standard way (includes a backtrace)
    # @return [String] the timestamp reference used
    def self.log_exception(exception)
      message = if exception.respond_to?(:code)
                  "#{exception.class}: #{exception&.code} #{exception&.message}"
                else
                  "#{exception.class}: #{exception&.message}"
                end

      timestamp_ref = log_message(message)
      Rails.logger.error("BACKTRACE: \n  #{exception.backtrace[0..17].join("\n  ")}")

      timestamp_ref
    end

    # Uses Time to get the current time now, which is used for timing the {.log_exception caught exceptions}
    # @return [String] last 5 digits of the current timestamp
    def self.error_timestamp_reference
      Time.now.to_i.to_s[5, 10]
    end

    # Logs the timestamp, message and a stacktrace
    # @return [String] the timestamp used
    def self.log_message(message)
      timestamp_ref = error_timestamp_reference
      Rails.logger.error("\nERROR: #{timestamp_ref}\n  #{message}")
      timestamp_ref
    end

    private

    # Redirect to the generic error page with details of the error in the flash hash.
    def redirect_with_error(timestamp_ref)
      # Prepare error details for display on screen to the user (so beware leaking information).
      # Currently only displaying the timestamp ref so the user has a number to report that we can also find in logs.
      flash[:fatal_error] = timestamp_ref
      Rails.logger.debug('  Redirecting to default error page')
      redirect_to(home_error_url)
    end
  end
end
