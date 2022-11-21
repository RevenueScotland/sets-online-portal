# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
# require "active_record/railtie"
# require "active_storage/engine"
require 'action_controller/railtie'
# require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
# require 'action_cable/engine'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RevScot
  # Main application class
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # override Rails default behaviour of adding <div class=\"field_with_errors\"> in html tag when there is
    # validation failure
    config.action_view.field_error_proc = proc { |html_tag, _instance|
      html_tag
    }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Load the local environment file if it exists
    config.before_configuration do
      env_file = Rails.root.join('config/local_env.yml')
      if File.exist?(env_file)
        YAML.safe_load(File.open(env_file)).each do |key, value|
          ENV[key.to_s] = value
        end
      end
    end

    # REVSCOT Specific config below this line

    # back office config
    config.x.fl_endpoint.root = ENV.fetch('FL_ENDPOINT_ROOT', '')
    config.x.fl_endpoint.uid = ENV.fetch('FL_USERNAME', nil)
    config.x.fl_endpoint.pwd = ENV.fetch('FL_PASSWORD', nil)
    config.x.fl_endpoint.timeout = ENV.fetch('FL_TIMEOUT', '60').to_i

    config.x.nadr_endpoint.root = ENV.fetch('ADDRESS_SEARCH_ENDPOINT', '')
    config.x.nadr_endpoint.uid = ENV.fetch('ADDRESS_SEARCH_UID', nil)
    config.x.nadr_endpoint.pwd = ENV.fetch('ADDRESS_SEARCH_PWD', nil)
    config.x.nadr_endpoint.proxy = ENV.fetch('ADDRESS_SEARCH_PROXY', nil)
    config.x.nadr_endpoint.timeout = ENV.fetch('ADDRESS_SEARCH_TIMEOUT', '60').to_i

    config.x.ch_endpoint.root = ENV.fetch('COMPANY_SEARCH_ENDPOINT', '')
    config.x.ch_endpoint.uid = ENV.fetch('COMPANY_SEARCH_UID', nil)
    config.x.ch_endpoint.pwd = ENV.fetch('COMPANY_SEARCH_PWD', nil)
    config.x.ch_endpoint.proxy = ENV.fetch('COMPANY_SEARCH_PROXY', nil)

    # Version number for displaying on the page
    config.x.version = ENV.fetch('APPLICATION_VERSION', nil)

    # Earliest start date for return
    config.x.earliest_start_date = '01/04/2015'

    # Earliest start date to be displayed in error message in the long format
    config.x.earliest_start_date_long_format = '1st April 2015'

    # Number of days before expiry that password expiry warning is issued
    config.x.authentication.password_due_period = 5
    # hold number of rows shown per page on table where pagination applied
    config.x.pagination.per_page = 10

    # Holds the temporary directory for use in upload and download files
    config.x.temp_folder = File.join(Dir.tmpdir, 'revscot')
    FileUtils.mkdir_p(config.x.temp_folder) unless File.directory?(config.x.temp_folder)

    # Secure message limit type of file upload
    config.x.file_upload_content_type_allowlist =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, ' \
      'application/vnd.ms-excel, image/tiff, application/pdf, image/png, image/gif, image/jpeg, image/jpg, ' \
      'application/rtf, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document'

    # CSV file upload content type limit type (CSV)
    config.x.slft_waste_file_upload_content_type_allowlist = 'text/csv'

    # alias as CSV files are seen as Excel files if excel is installed on the users device
    # not combined with the above so that this is not shown to the users as a valid file type to upload.
    config.x.slft_waste_file_upload_alias_content_type_allowlist = 'application/vnd.ms-excel'

    # When a file is uploaded but the client doesn't know it's content/mime type, it sends it with the following
    # content type
    config.x.file_upload_unknown_content_type = 'application/octet-stream'

    # limit size of upload file
    config.x.file_upload_expected_max_size_mb = 10

    # Percentage of invalid CSV rows for SLFT waste import before the file is rejected. A row is invalid if it
    # contains the wrong number of columns for the model import.
    config.x.slft_waste_file_upload_percent_invalid_reject = 60

    # Configuration for the days until amend is no longer visible/valid
    config.x.returns.amendable_days = 365.days

    # The number of days before an amend can be completed to show the warning on the draft version
    config.x.returns.amendable_warning_days = 7.days

    # Configuration flag to turn off download file virus scanning
    config.x.no_download_file_virus_scanning = ENV.key?('NO_DOWNLOAD_VIRUS_SCANNING')

    # Configuration for ActiveJobs
    config.x.scheduled_jobs.refresh_ref_data_every = 15.minutes
    config.x.scheduled_jobs.refresh_sys_params_every = 60.minutes
    config.x.scheduled_jobs.refresh_pws_text_every = 60.minutes
    config.x.scheduled_jobs.refresh_tax_relief_type_every = 60.minutes
    config.x.scheduled_jobs.delete_temp_files_job_run_every = 2.hours

    config.x.scheduled_jobs.refresh_system_notice_every = 60.minutes

    # Cache expiry times
    config.x.accounts.cache_expiry = 10.minutes

    # Disable authorisation and cache expiry times
    config.x.authorisation.disabled = false
    config.x.authorisation.cache_expiry = 15.minutes

    # Existing application reference validation regular expression
    pattern = ENV.fetch('APPLICATION_REF_REGEX', nil) || /(\ARS\d{7,10}\w{4}\z)|(\ARS\d{7}\z)|(\ARSL\d{6}\z)/
    config.x.app_ref.validation_pattern = Regexp.new pattern

    # Constant for allowed Country Code
    config.x.allowed_property_country_code = 'SCO'

    config.after_initialize do
      # After initialisation log that we have stared
      Rails.logger.info { "Started RevScot at #{DateTime.now}" }
    end
  end
end
