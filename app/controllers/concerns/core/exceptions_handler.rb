# frozen_string_literal: true

module Core
  # Provides the controller functionality for displaying system exceptions
  # This needs to be included in an ExceptionsController that is configured as the
  # middleware exception app in the app
  # In the event of an error a unique reference is generated and displayed to the user
  # while a stack trace with that reference is written to the rails logging file
  module ExceptionsHandler
    extend ActiveSupport::Concern

    included do
      # => CSRF don't raise a new exception
      protect_from_forgery with: :null_session
      skip_before_action :require_user # no login required
    end

    # PORO Class to hold the details of the error that can be displayed on the exception page
    class ErrorDetails
      attr_accessor :reference, :rescue_response, :message, :status_code

      # Create a new instance of error details and generates the reference for tracking
      # this error
      # @param env [Object] the current request.env
      def initialize(env)
        @reference = generate_error_reference
        extract_information_from(env)
      end

      private

      # extract the information to populate this error from the request environment
      # @param env [Object] the current request.env
      def extract_information_from(env)
        exception = env['action_dispatch.exception']
        exception_wrapper = ActionDispatch::ExceptionWrapper.new(env, exception)
        @rescue_response = ActionDispatch::ExceptionWrapper.rescue_responses[exception.class.name]
        @message = exception.message
        @status_code = exception_wrapper.status_code
      end

      # Generated a unique error reference for tracking an error if reported
      # this is based on the current millisecond time
      # @return [String] The error reference to use
      def generate_error_reference
        "E#{Time.now.to_i.to_s[5, 10]}"
      end
    end

    # shows the standard something has gone wrong screen
    def show
      @error = ErrorDetails.new(request.env)
      Rails.logger.error("#{@error.reference} for #{@error.message}")
      template = (@error.status_code == 404 ? '404' : '500')
      render template, status: @error.status_code
    end

    # Show the 406 page - we can't call the method 406
    def show406
      render '406', status: :not_acceptable
    end
  end
end
