# frozen_string_literal: true

require_relative '../cache'

Rails.application.configure do # rubocop:disable Metrics/BlockLength
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Use the relative URL root if one is defined
  config.relative_url_root = "/#{ENV['APPLICATION_DOCROOT']}" if ENV['APPLICATION_DOCROOT'].present?

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  # This is a RAILS thing, we didn't invent it.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    # use Redis for caching
    config.cache_store = :redis_cache_store, cache_connection

    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.log_formatter = ::Logger::Formatter.new

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Catch normal errors and display a nice "Something has gone wrong" message
  # rather than the RoR default.  Off on dev so we see the red stacktrace page.
  config.x.error_handler.rescue_standard_error = false

  # Start ActiveJobs
  config.after_initialize do
    if ENV['PREVENT_JOBS_STARTING'] == 'Y'
      Rails.logger.info do
        "Jobs not started PREVENT_JOBS_STARTING=#{ENV['PREVENT_JOBS_STARTING']}"
      end
    else
      # GetReferenceData/ReferenceValues refresh job
      RefreshRefDataJob.schedule_next_run(1.second)

      # getListSystemNotices refresh job
      RefreshSystemNoticeJob.schedule_next_run(3.seconds)

      # GetSystemParameters refresh job
      RefreshSystemParametersJob.schedule_next_run(5.seconds)

      # GetSystemParameters refresh job
      RefreshPwsTextJob.schedule_next_run(7.seconds)

      # Tax Relief Type refresh job
      RefreshTaxReliefTypeJob.schedule_next_run(9.seconds)

      # Delete the temporary files job
      DeleteTempFilesJob.schedule_next_run(11.seconds)

    end
  end
end
