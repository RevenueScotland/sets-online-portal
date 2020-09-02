# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require 'request_summary_logging/log_subscriber'

RequestSummaryLogging::LogSubscriber.attach_to :action_controller unless Rails.env.development?
