# frozen_string_literal: true

# Holds settings for specific drivers in use

Capybara.register_driver :selenium_chrome do |app|
  opts = Selenium::WebDriver::Chrome::Options.new
  opts.add_option('useAutomationExtension', false)

  chrome_add_preference(opts)
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: opts)
end

# register a remote selenium chrome base driver. The URL for the remote driver selenium hub must be
# set using the environment variable CAPYBARA_REMOTE_URL
Capybara.register_driver :selenium_remote_chrome do |app|
  opts = Selenium::WebDriver::Chrome::Options.new
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(takes_screenshots: true,
                                                                  'chromeOptions' =>
                                                                  { 'args' => ['--ignore-certificate-errors'] })
  chrome_add_preference(opts)
  Capybara::Selenium::Driver.new(app,
                                 browser: :remote,
                                 url: ENV['CAPYBARA_REMOTE_URL'],
                                 desired_capabilities: capabilities,
                                 options: opts)
end

# register a local selenium firefox based driver, which ignores insecure certificates, and
# has a screen size of 800x800
Capybara.register_driver :selenium_firefox do |app|
  opts = Selenium::WebDriver::Firefox::Options.new(screen_size: [1920, 1024], profile: customized_firefox_profile)
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(accept_insecure_certs: true)
  Capybara::Selenium::Driver.new(app, browser: :firefox, options: opts, desired_capabilities: capabilities)
end

# register a remote selenium firefox based driver, which ignores insecure certs
Capybara.register_driver :selenium_remote_firefox do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(accept_insecure_certs: true,
                                                                   firefox_profile: customized_firefox_profile)
  Capybara::Selenium::Driver.new(app,
                                 browser: :remote,
                                 url: ENV['CAPYBARA_REMOTE_URL'],
                                 desired_capabilities: capabilities)
end
# enable screen shots for our various drivers
Capybara::Screenshot.register_driver(:selenium_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end
Capybara::Screenshot.register_driver(:selenium_remote_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end
Capybara::Screenshot.register_driver(:selenium_firefox) do |driver, path|
  driver.browser.save_screenshot(path)
end
Capybara::Screenshot.register_driver(:selenium_remote_firefox) do |driver, path|
  driver.browser.save_screenshot(path)
end

# Set the default and javascript driver from the environment if set
Capybara.default_driver = ENV['CAPYBARA_DRIVER'].to_sym unless ENV['CAPYBARA_DRIVER'].nil?
Capybara.javascript_driver = ENV['CAPYBARA_DRIVER'].to_sym unless ENV['CAPYBARA_DRIVER'].nil?

# override the default wait time as we seem to have network issues
Capybara.default_max_wait_time = 30

# Set the environment variable CAPYBARA_APP_HOST to run the tests against a remote instance
# or local instance of the application, on a local instance, fix the host and port
unless ENV['CAPYBARA_APP_HOST'].nil?
  Capybara.configure do |config|
    config.app_host = ENV['CAPYBARA_APP_HOST']
    config.run_server = ENV['CAPYBARA_RUN_SERVER'] || true
    if config.run_server
      config.server_host = '0.0.0.0'
      config.server_port = 2099
      config.always_include_port = true
    end
  end
end

private

# Sets up the profile for a selenium_firefox driver.
# Currently used to set up the downloading parts of the firefox.
def customized_firefox_profile
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile.assume_untrusted_certificate_issuer = ENV['SKIP_CERT_ISSUER'].present?
  # See https://www.toolsqa.com/selenium-webdriver/how-to-download-files-using-selenium/ for
  # some explanation about profile.
  #
  # The download directory destination
  profile['browser.download.dir'] = ENV['TEST_FILE_DOWNLOAD_PATH']
  # folderList set to 2 means to use the custom download directory
  profile['browser.download.folderList'] = 2
  profile['browser.helperApps.alwaysAsk.force'] = profile['browser.download.manager.showWhenStarting'] = false
  # @see https://www.sitepoint.com/mime-types-complete-list/ to see a list of MIME types - which is used to identify
  # the type of data/file.
  profile['browser.helperApps.neverAsk.saveToDisk'] =
    ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/zip',
     'application/pdf', 'application/octet-stream', 'application/msword'].join(',')
  profile['pdfjs.disabled'] = profile.native_events = profile['browser.download.useDownloadDir'] = true
  profile
end

# Adds preference to Chrome options.
# Currently used to set up the default directory for downloads.
# @see https://src.chromium.org/viewvc/chrome/trunk/src/chrome/common/pref_names.cc?view=markup to learn more about
# the Chrome preferences that can be added and what each of them mean.
def chrome_add_preference(options)
  options.add_preference(:download, directory_upgrade: true,
                                    prompt_for_download: false,
                                    default_directory: ENV['TEST_FILE_DOWNLOAD_PATH'])
  options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })
end
