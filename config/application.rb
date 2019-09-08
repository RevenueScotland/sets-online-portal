# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
# require "active_record/railtie"
# require "active_storage/engine"
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RevScot
  # Main application class
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

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
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      if File.exist?(env_file)
        YAML.safe_load(File.open(env_file)).each do |key, value|
          ENV[key.to_s] = value
        end
      end
    end

    # REVSCOT Specific config below this line

    # back office config
    config.x.fl_endpoint.root = ENV['FL_ENDPOINT_ROOT']
    config.x.fl_endpoint.uid = ENV['FL_USERNAME']
    config.x.fl_endpoint.pwd = ENV['FL_PASSWORD']
    config.x.fl_endpoint.timeout = (ENV['FL_TIMEOUT'] || '60').to_i

    config.x.nadr_endpoint.root = ENV['ADDRESS_SEARCH_ENDPOINT']
    config.x.nadr_endpoint.uid = ENV['ADDRESS_SEARCH_UID']
    config.x.nadr_endpoint.pwd = ENV['ADDRESS_SEARCH_PWD']
    config.x.nadr_endpoint.proxy = ENV['ADDRESS_SEARCH_PROXY']
    config.x.nadr_endpoint.timeout = (ENV['ADDRESS_SEARCH_TIMEOUT'] || '60').to_i

    config.x.ch_endpoint.root = ENV['COMPANY_SEARCH_ENDPOINT']
    config.x.ch_endpoint.uid = ENV['COMPANY_SEARCH_UID']
    config.x.ch_endpoint.pwd = ENV['COMPANY_SEARCH_PWD']
    config.x.ch_endpoint.proxy = ENV['COMPANY_SEARCH_PROXY']

    # Version number for displaying on the page
    config.x.version = ENV['APPLICATION_VERSION']

    # Earliest start date for return
    config.x.earliest_start_date = '01/04/2015'

    # Number of days before expiry that password expiry warning is issued
    config.x.authentication.password_due_period = 5

    # hold number of rows shown per page on table where pagination applied
    config.x.pagination.per_page = 10

    # hold external scottish revenue url
    config.x.external_links.accessibility = 'http://www.revenue.scot/accessibility'
    config.x.external_links.legal_notices = 'http://www.revenue.scot/legal-notices'
    config.x.external_links.site_map = 'http://www.revenue.scot/site-map'
    config.x.external_links.foi = 'http://www.revenue.scot/contact-us/freedom-information-guide'
    config.x.external_links.public_landing_return_page = 'https://www.revenue.scot/'

    # hold temporary file upload path
    config.x.file_upload_path = ENV['FILE_UPLOAD_PATH']

    # Secure message limit type of file upload
    config.x.secure_message_file_upload_content_type_whitelist =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, ' \
      'application/vnd.ms-excel, image/tiff, application/pdf, image/png, image/gif, image/jpeg, image/jpg, ' \
      'application/rtf, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document'

    # limit size of upload file
    config.x.file_upload_expected_max_size_mb = 10

    # Configuration for the days until amend is no longer visible/valid
    config.x.returns.amendable_days = 365.days

    # configure how many day old file need to removed
    config.x.scheduled_jobs.delete_attachment_files_days_old = 1.days

    # configure when to run job
    config.x.scheduled_jobs.delete_attachment_files_job_run_every = 1.days

    # Configuration for ActiveJobs
    config.x.scheduled_jobs.refresh_ref_data_every = 15.minutes
    config.x.scheduled_jobs.refresh_sys_params_every = 60.minutes
    config.x.scheduled_jobs.refresh_pws_text_every = 60.minutes

    # Cache expiry times
    config.x.accounts.cache_expiry = 10.minutes

    # Disable authorisation and cache expiry times
    config.x.authorisation.disabled = false
    config.x.authorisation.cache_expiry = 60.minutes

    # Existing application reference validation regular expression
    pattern = ENV['APPLICATION_REF_REGEX'] || /(\ARS\d{7,10}\w{4}\z)|(\ARS\d{7}\z)|(\ARSL\d{6}\z)/.freeze
    config.x.app_ref.validation_pattern = Regexp.new pattern

    # Constant for allowed Country Code
    config.x.allowed_country_code = 'S92000003'
  end
end
