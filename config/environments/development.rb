# frozen_string_literal: true

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

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  # This is a RAILS thing, we didn't invent it.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    # use Redis for caching
    config.cache_store = :redis_cache_store, {
      url: ENV['REDIS_CACHE_URL'],
      error_handler: lambda { |method:, returning:, exception:| # rubocop:disable Lint/UnusedBlockArgument
        Rails.logger.error("Cache store exception : #{exception}")
      }
    }

    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
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
    unless ENV['PREVENT_JOBS_STARTING'] == 'Y'
      # GetReferenceData/ReferenceValues refresh job
      RefreshRefDataJob.schedule_next_run(3.seconds)

      # GetSystemParameters refresh job
      RefreshSystemParametersJob.schedule_next_run(5.seconds)

      # GetSystemParameters refresh job
      RefreshPwsTextJob.schedule_next_run(7.seconds)

      # DeleteAttachmentFilesJob file delete job specifically not included
    end
  end
end