# frozen_string_literal: true

require 'active_support'

# Logs summary request information into the main rails log file
#
# @see http://rubyjunky.com/cleaning-up-rails-4-production-logging.html
# @see https://github.com/gshaw/concise_logging
# @author Richard Tearle
module RequestSummaryLogging
  # LogSubscriber to get logging information from the ActionController
  class LogSubscriber < ActiveSupport::LogSubscriber
    # The parameters we're interested in on the event
    INTERNAL_PARAMS = %w[controller action format _method only_path].freeze

    # Called when rails redirects to another page. Stores the original location
    # in fibre thread storage, so it can be retrieved later, and shown in the
    # log file
    def redirect_to(event)
      Thread.current[:logged_location] = event.payload[:location]
    end

    # Call by rails when an action occurs. This extracts some data from the event
    # and from fibre thread storage, formats this data and the logs it to the
    # standard rails logger, using the INFO level
    def process_action(event)
      log_data = data_from_event(event)
      log_data = log_data.merge(data_from_thread_local)
      Thread.current[:logged_location] = nil
      message = format_log_message(log_data)
      logger.info message
    end

    private

    # Format the log message
    def format_log_message(log_data)
      message = format_status(log_data)
      message << format_extra_data(log_data)
      message
    end

    # Format the status message
    def format_status(log_data)
      format(
        '%<method>s %<status>s %<ip>s %<path>s', ip: log_data[:ip], method: log_data[:method],
                                                 status: log_data[:status], path: log_data[:path]
      )
    end

    # Format any extra data we may have
    def format_extra_data(log_data)
      message = ''
      message += " redirect_to=#{log_data[:location]}" if log_data.key?(:location)
      message += " parameters=#{log_data[:params]}" if log_data.key?(:params)
      message += " #{log_data[:exception_details]}" if log_data.key?(:exception_details)
      message += " (app:#{log_data[:app]}ms)"
      message
    end

    # Pull out the data we require from the event
    def data_from_event(event)
      payload = event.payload
      param_method = payload[:params]['_method']
      {
        method: format('%-6s', param_method ? param_method.upcase : payload[:method]),
        status: compute_status(payload),
        path: payload[:path].to_s.gsub(/\?.*/, ''),
        params: payload[:params].except(*INTERNAL_PARAMS),
        app: payload[:view_runtime].to_i
      }
    end

    # Pull out the data from thread local storage
    def data_from_thread_local
      {
        ip: format('%-15s', Thread.current[:logged_ip]),
        location: Thread.current[:logged_location]
      }
    end

    # Determines the status of a payload. This method is necessary because we aren't given a
    # status in the event payload if an exception has occurred during the processing of the request.
    # Rails doesn't provide a handy way to get the status in and we have to compute it ourselves
    # with code borrowed directly from ActionController::LogSubscriber
    def compute_status(payload)
      details = nil
      status = payload[:status]
      if status.nil? && payload[:exception].present?
        exception_class_name = payload[:exception].first
        status = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class_name)

        details = payload[:exception].uniq.join(' ') if payload[:exception].respond_to?(:uniq)
      end
      [status, details]
    end
  end
end
