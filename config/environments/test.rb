# frozen_string_literal: true

require 'request_summary_log/log_middleware'
require_relative '../cache.rb'

Rails.application.configure do # rubocop:disable Metrics/BlockLength
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # pre-loads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Compress JavaScripts and CSS.
  # used harmony syntax https://github.com/lautis/uglifier/issues/127
  config.assets.js_compressor = Uglifier.new(harmony: true)
  # For now do not compress the css see https://github.com/sass/libsass/issues/2701
  config.assets.css_compressor = nil

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports
  config.consider_all_requests_local       = true

  # Turns caching on
  config.action_controller.perform_caching = true

  # use Redis for caching
  config.cache_store = :redis_cache_store, cache_connection

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Load the logging middleware
  config.middleware.use RequestSummaryLogging::LogMiddleware

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.log_formatter = ::Logger::Formatter.new

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Catch normal errors and display a nice "Something has gone wrong" message
  # rather than the RoR default.  Off on dev so we see the red stacktrace page.
  config.x.error_handler.rescue_standard_error = true

  # override the refresh so it doesn't run during the tests otherwise
  # it can break the savon mocking expectations
  config.x.scheduled_jobs.refresh_ref_data_every = 120.minutes
  config.x.scheduled_jobs.refresh_sys_params_every = 120.minutes
  config.x.scheduled_jobs.refresh_pws_text_every = 120.minutes
  config.x.scheduled_jobs.refresh_tax_relief_type = 120.minutes
  config.x.authorisation.cache_expiry = 120.minutes

  # Start ActiveJobs
  config.after_initialize do
    unless ENV['PREVENT_JOBS_STARTING'] == 'Y'
      # GetReferenceData/ReferenceValues refresh job
      RefreshRefDataJob.schedule_next_run(1.second)

      # GetSystemParameters refresh job
      RefreshSystemParametersJob.schedule_next_run(1.minutes)

      # GetSystemParameters refresh job
      RefreshPwsTextJob.schedule_next_run(2.minutes)

      # Tax Relief Type refresh job
      TaxReliefTypeJob.schedule_next_run(3.minutes)

      # Delete the temporary files job
      DeleteTempFilesJob.schedule_next_run(4.minutes)
    end
  end
end
