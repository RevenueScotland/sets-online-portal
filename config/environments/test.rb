# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Turn false under Spring and add config.action_view.cache_template_loading = true.
  config.cache_classes = true

  # For unit testing do not use REDIS as we do not have access, and we will be caching
  # unit test data.
  config.cache_store = :memory_store if ENV.key?('UNIT_TEST')

  # Eager loading loads your whole application. When running a single test locally,
  # this probably isn't necessary. It's a good idea to do in a continuous integration
  # system, or in some way before deploying your code.
  config.eager_load = ENV['CI'].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Raise exceptions instead of rendering exception templates.
  #  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  config.log_formatter = Logger::Formatter.new

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Catch normal errors and display a nice "Something has gone wrong" message
  # rather than the RoR default.  Off on dev so we see the red stacktrace page.
  config.x.error_handler.rescue_standard_error = true

  # override the refresh so it doesn't run during the tests otherwise
  # it can break the savon mocking expectations
  config.x.scheduled_jobs.refresh_ref_data_every = 180.minutes
  config.x.scheduled_jobs.refresh_sys_params_every = 180.minutes
  config.x.scheduled_jobs.refresh_pws_text_every = 180.minutes
  config.x.scheduled_jobs.refresh_tax_relief_type_every = 180.minutes
  config.x.scheduled_jobs.refresh_system_notice_every = 180.minutes
  config.x.authorisation.cache_expiry = 180.minutes

  # Prevent jobs running during unit tests
  config.x.scheduled_jobs.job_offset = (ENV.key?('UNIT_TEST') ? 0.seconds : 2.seconds)
end
