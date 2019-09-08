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
          # create a reference number we can display to user and record in logs
          timestamp_ref = ErrorHandler.error_timestamp_reference
          ErrorHandler.log_error(exception, timestamp_ref)
          # redirect to appropriate error page
          redirect_with_error(exception, timestamp_ref)
        end
      end
    end

    # Convenience utility method for other classes to call to log caught exceptions in a standard way.
    def self.log_exception(exception)
      log_error(exception, error_timestamp_reference)
    end

    # Uses Time to get the current time now, which is used for timing the {.log_exception caught exceptions}
    # @return [String] the current time now
    def self.error_timestamp_reference
      Time.now.to_i.to_s[5, 10]
    end

    # Logs the error by the exception and current time
    def self.log_error(exception, timestamp_ref)
      log_message = if exception.respond_to?(:code)
                      "#{exception.class}: #{timestamp_ref} #{exception&.code} #{exception&.message}"
                    else
                      "#{exception.class}: #{timestamp_ref} #{exception&.message}"
                    end
      Rails.logger.error("\nERROR: \n  #{log_message}")
      Rails.logger.error("BACKTRACE: \n  #{exception.backtrace[0..17].join("\n  ")}")
    end

    private

    # Redirect back to the page they came from with details of the error in the flash hash.
    # If redirecting causes an error then it redirects to the error page instead to protect against an infinite loop.
    # If current action was the error page then re-raises the error instead to protect against an infinite loop.
    def redirect_with_error(exception, timestamp_ref)
      will_redirect_back = flash[:error].nil?
      flash[:error] = prep_error_for_display(timestamp_ref)

      raise exception if action_name == 'error'

      do_redirecting(will_redirect_back)
    end

    # Does the redirecting for {#redirect_with_error} to avoid offending Rubocop.
    def do_redirecting(will_redirect_back)
      if will_redirect_back
        Rails.logger.debug('Redirecting back')
        redirect_back(fallback_location: home_error_url, allow_other_host: false)
      else
        Rails.logger.debug('Redirecting to default error')
        redirect_to(home_error_url)
      end
    end

    # Prepare error details for display on screen to the user (so beware leaking information).
    # Currently only displaying the timestamp ref so the user has a number to report that we
    # can also find in the logs.
    def prep_error_for_display(timestamp_ref)
      timestamp_ref
    end
  end
end
