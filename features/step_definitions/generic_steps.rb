# frozen_string_literal: true

require 'capybara-screenshot/minitest'

not_present_wait = 2 # seconds to wait when checking an item is not present
js_processing_wait = 0.1 # seconds to wait when js processing is involved
page_processing_wait = 0.5 # seconds to wait if a page is refreshed (e.g when a delete is triggered)
download_file_wait = 5 # seconds to wait for a file to download

# feature/step_definitions/generic_steps.rb

# Generates a random string of the given length
# @param values - Specify 'UPCASE' to make the result string uppercase (otherwise it's lowercase)
def random_string(length, values = '')
  Array.new(length) { (values == 'UPCASE' ? Array('A'..'Z') : Array('A'..'Z') + Array('a'..'z')).sample }.join
end

# Generates a random password consisting of alphabets, an upper case letter, a lower case letter
# and a number; all of given length
def random_password_string(length)
  charset = Array('0'..'9') + Array('A'..'Z') + Array('a'..'z')
  Array.new(length) { charset.sample }.push('A', 'a', '0').last(length - 1).join + '!'
end

Given('I have signed in') do
  sign_in('portal.one', 'Password1!')
end

Given('I have signed out') do
  return unless page.has_link?('Sign out')

  log('Signing Out')
  click_link('Sign out')
  # Check we are on the login page
  find('h1:first-of-type', text: 'Sign in')
end

Given('I have signed in {string} and password {string}') do |username, password|
  sign_in(username, password)
end

# Login with given username and password
def sign_in(username, password)
  visit('/login')
  fill_in('Username', with: username)
  fill_in('Password', with: password)
  click_button('Sign in')
  # Check we are on the dashboard which will cause a wait
  find('h1:first-of-type', text: 'Dashboard')
end

When('I go to the {string} page') do |string|
  # allow access to the root page
  if string == '/'
    visit('/')
  else
    visit('/' + string.downcase)
  end
end

When('I click on the {string} button') do |string|
  click_button(string)
end

When('I click on the {int} st/nd/rd/th {string} button') do |integer, string|
  integer -= 1 # results array seems to be 0 based
  all('button', text: string)[integer].click
end

# JS mode or not may make a button visible or not.  This method clicks it if it's available and doesn't throw
# an exception if it is not.  (Jenkins always runs the browser so JS mode is on whereas on dev machine's it's off).
Then('if available, click the {string} button') do |string|
  if has_button?(string, wait: not_present_wait)
    click_button(string)
  else
    Rails.logger.info("Optional button #{string} not found")
  end
end

When('I open the {string} summary item') do |string|
  open = true
  if Capybara.current_driver == :rack_test
    clickable = find('details', text: string)
    open = false if clickable['open'].nil? || clickable['open'] == 'false'
  else
    # The JS code handles the summary differently so different selects
    clickable = find('span', text: string)
    details = clickable.ancestor('details')
    open = false if details['open'].nil? || details['open'] == 'false'
  end
  clickable.click if open == false
end

When('I click on the {string} text with class {string}') do |string, css_class|
  find(".#{css_class}", text: string).click
end

When('I clear the {string} field') do |string|
  fill_in(string, with: '')
end

When('I enter {string} in the {string} field') do |string, string2|
  if string.start_with?('RANDOM_')
    # If the string value starts with random then generate a value
    # the format is RANDOM_xxxxx,length,UPCASE
    # UPCASE if you want the variable to be uppercase
    @stored_values = {} if @stored_values.nil?
    list = string.split(',')
    @stored_values[list[0]] = random_string(list[1].to_i, list[2])
    string = @stored_values[list[0]]
  end
  fill_in(string2, with: string)
end

When('I enter {string} in the {string} date field') do |date_string, field|
  # Rack test supports both dd-mm-yyyy and yyy-mm-dd
  # Chrome only supports dd-mm-yyyy and firefox yyyy-mm-dd hence the below
  date = Date.parse(date_string) unless date.is_a? Date
  date_string = if %i[selenium_firefox selenium_remote_firefox].include?(Capybara.current_driver)
                  date.strftime('%Y-%m-%d')
                else
                  date.strftime('%d-%m-%Y')
                end
  fill_in(field, with: date_string)
end

When('I enter {string} in the {string} and {string} field') do |string, string2, string3|
  if string.start_with?('PASSWORD')
    # if string value starts with PASSWORD then generate a value
    # the format is PASSWORD,length
    @stored_values = {} if @stored_values.nil?
    list = string.split(',')
    @stored_values[list[0]] = random_password_string(list[1].to_i)
    string = @stored_values[list[0]]
  end
  fill_in(string2, with: string)
  fill_in(string3, with: string)
end

When('I click on the {string} link to download a file') do |string|
  @original_page = page.current_url if Capybara.current_driver == :rack_test
  step "I click on the 1 st '#{string}' link"
end

When('I click on the {int} st/nd/rd/th {string} link to download a file') do |integer, string|
  # @note there is a page.current_path which strips out the query strings and "http://www.example.com"
  @original_page = page.current_url if Capybara.current_driver == :rack_test
  step "I click on the #{integer} th '#{string}' link"
end

When('I click on the {string} link') do |string|
  click_link(string, wait: not_present_wait)
end

When('I click on the {string} link and switch to that window') do |string|
  if Capybara.current_driver == :rack_test
    # Rack test doesn't support multiple windows
    click_link(string, wait: not_present_wait)
  else
    switch_to_window(
      window_opened_by do
        click_link(string, wait: not_present_wait)
      end
    )
  end
end

When('I click on the {string} link with id {string}') do |text, id|
  click_link(text, id: id)
end

When('I click on the {int} st/nd/rd/th {string} link') do |integer, string|
  integer -= 1 # results array seems to be 0 based
  all('a', text: string)[integer].click
end

When('I check the {string} radio button') do |string|
  choose(string, visible: false) # the radio button may be hidden on javascript pages, this ensures it is still found
end

When('I select {string} from the {string}') do |text, dropdown|
  select(text, from: dropdown)
end

# When the field is either a text field or a select, used on the field with the javascript autocomplete.
# see also then equivalent for checking value
When('I enter {string} in the {string} select or text field') do |text, field|
  sleep(js_processing_wait) # wait for the JS to process
  if page.has_field?(field, type: 'select', wait: not_present_wait)
    select(text, from: field)
  elsif page.has_field?(field, type: 'text', wait: not_present_wait)
    fill_in(field, with: text)
    sleep(js_processing_wait) # give time for the autocomplete to complete
  else
    assert false, "Cannot find #{field} to complete"
  end
end

When('I click on the {string} link of the first entry displayed') do |string|
  click_link(string, match: :first)
end

When('I check the {string} checkbox') do |string|
  check(string, visible: false) # the checkbox may be hidden on javascript pages, this ensures it is still found
end

When('I uncheck the {string} checkbox') do |string|
  page.uncheck(string, visible: false) # the checkbox may be hidden on javascript pages, this ensures it is still found
end

When('I filter on {string}') do |name|
  value = if name.start_with?('RANDOM_SURNAME')
            @stored_values[name]
          else
            name
          end
  fill_in('Name', with: value)
  click_button('Find')
end

When('I upload {string} to {string} on the browser') do |filename, field|
  if %i[selenium_firefox selenium_remote_firefox].include?(Capybara.current_driver)
    step "I upload '#{filename}' to '#{field}'"
    step 'I click on the "Upload document" button'
  end
end

# Upload a file onto the field.
When('I upload {string} to {string}') do |filename, field|
  page.attach_file(field, File.join(ENV['TEST_FILE_UPLOAD_PATH'], filename))
end

# For a test which changes values, flip flop between two values.
# Ie detects the current value and sets it to the other one (or the first one if no value set)
# This means we don't have to reset values in tests, and means if a failure happens, it doesn't leave
# the values wrong for the next test.
# Stores the value set so the corresponding check step knows which one it should be checking for.
When('I flip {string} field between {string} and {string} using marker {string}') do |field_id, val1, val2, marker|
  field_value = find_field(field_id).value
  new_value = val1 == field_value ? val2 : val1
  log("...field value was #{field_value} so new value is #{new_value}")
  fill_in(field_id, with: new_value)
  store_result(marker, new_value)
end

# Temp step to allow you to put a wait in an individual test
When('I wait for {int} seconds') do |period|
  sleep(period)
end

# Temp step to allow you to put a wait in an individual test
When('I take a picture called {string}') do |filename|
  page.save_screenshot(filename)
end

# Step allows to store the value consist by particular control_id
Then('I should store the generated value with id {string}') do |id|
  refer_value = page.find_by_id(id).text
  store_result(id, refer_value)
end

# Step allows storing the value next to a heading in a display region table
Then('I should store the value with the display region heading {string}') do |string|
  th = page.find('th', text: string)
  tr = th.find(:xpath, './parent::tr')
  result = tr.find(:xpath, 'td', match: :first).text
  store_result(string, result)
end

# Retrieves the stored reference number
When('I enter stored reference number {string} in field {string}') do |marker, field|
  ref_value = lookup_result(marker)
  fill_in(field, with: ref_value)
end

# Check that we have downloaded a file type that has computer-generated names
Then('I should see the downloaded {string} content of {string} by looking up {string}') do |detail, type, lookup_id|
  # I should see the downloaded content "SLFT_WASTE" by looking up "ret_ref_value"
  return_reference = lookup_result(lookup_id)
  filename = type.upcase # This is the return type, it should either be SLFT or LBTT
  filename += "_Return#{return_reference}_v[0-9]+_#{Date.today.strftime('%Y%m%d')}[0-9]{6}.pdf" if detail == 'PDF'
  filename = "#{return_reference}-[0-9]+.zip" if detail == 'WASTE'
  log("...filename to look for should match #{filename.inspect}")
  step "I should see the downloaded content '#{filename}'"
end

Then('I should see the downloaded {string} content of {string}') do |detail, type|
  filename = type.upcase # This is the return type, it should either be SLFT or LBTT
  filename += "_Claim[0-9]+_#{Date.today.strftime('%Y%m%d')}[0-9]{6}.pdf" if detail == 'CLAIM'
  log("...filename to look for should match #{filename.inspect}")
  step "I should see the downloaded content '#{filename}'"
end

# Looks a the defined download directory path and gets a list of downloaded contents.
# @return [Array] downloaded files from the download directory.
def downloaded_files_list
  Rails.logger.info("  Download path is : #{ENV['TEST_FILE_DOWNLOAD_PATH'].inspect}")
  downloaded_files = Dir[File.join(ENV['TEST_FILE_DOWNLOAD_PATH'], '*.*').tr('\\', '/')]
  Rails.logger.info("  Download directory contains : #{downloaded_files.inspect}")
  downloaded_files
end

# Searches the contents of download directory and see if it matches with the test's filename.
# @return [Array] the result of the found file with the matched test's filename.
def search_files_result(filename, downloaded_files)
  Rails.logger.info("  The exact (or regex value of) filename to look for is : #{filename.inspect}")
  result = downloaded_files.grep(/#{filename}/)
  Rails.logger.info("  Regex search for the filename contains : #{result.inspect}")
  result
end

# Check if the file has been downloaded.
# @return [Array] two values which are the is_file_found [Boolean] does the file exist, and
#   the result [String] the file name found that matches the filename param.
def check_file_downloaded_on_selenium_driver(filename, waiting_time)
  sleep(waiting_time)
  result = search_files_result(filename, downloaded_files_list)
  [!result.blank?, result.first || '']
end

# Check that we have downloaded the file.
# The filename can be the exact value of the file to look for or a regex value.
Then('I should see the downloaded content {string}') do |filename|
  sleep(download_file_wait)

  is_file_found = false
  # Normally selenium drivers don't respond to the response_headers['Content-Disposition'] so the downloaded
  # content will be checked by looking into the actual download directory and see if the file name exists there.
  if ENV['CAPYBARA_DRIVER'].to_s.include?('selenium')
    # Gets the full path for the downloaded file.
    # Trying to get the full path of the downloaded file (joined with the file name itself) normally gives a list
    # of files (with .file_type), so as this should only have one occurrence then we could always look for the first
    # one in the list.
    # String manipulation is needed here because Dir[] accepts a string with directory separator as '/'
    Rails.logger.info('Then I should see the downloaded content')
    result = ''

    # Looper is needed so that the file has been downloaded successfully if it really exists.
    5.times do |i|
      next if is_file_found

      Rails.logger.info("  --- File downloads checking attempt ##{i.inspect} ---")
      is_file_found, result = check_file_downloaded_on_selenium_driver(filename, download_file_wait)
    end

    # So that locally we won't have to clear things out manually, the file is removed when it's been viewed
    if is_file_found && !ENV['CAPYBARA_DRIVER'].to_s.include?('remote')
      Rails.logger.info('  Attempting to remove the file from the download directory')
      # Removes the downloaded file from where we have found it.
      FileUtils.rm_r(result) if File.exist?(result)
    end

    Rails.logger.info("\n\tCurrent url : #{page.current_url.inspect}\n\tWindow_handles : #{page.windows.inspect}")
    # NOTE: page.windows returns a list of #<Window @handle="<integer>"> and
    #       page.driver.window_handles is the same as page.windows but it's a list of "<number>"
    page.driver.close_window(page.driver.window_handles.last) if page.windows.size > 1
    Rails.logger.info("\n\tCurrent url : #{page.current_url.inspect}\n\tWindow_handles : #{page.windows.inspect}")
  else
    # On rack_test driver do below - non-selenium driver
    assert !page.response_headers['Content-Disposition'].nil?
    is_file_found = (/#{filename}/ =~ page.response_headers['Content-Disposition'])

    # Need to go back to the original page as we're currently on the page of the downloaded file
    visit(@original_page)
  end

  assert is_file_found
end

Then('I should receive the message {string} on the browser') do |string|
  if %i[selenium_firefox selenium_remote_firefox].include?(Capybara.current_driver)
    step "I should receive the message '#{string}'"
  else
    assert true
  end
end

Then('I should receive the message {string}') do |string|
  assert page.has_content?(string), "I cannot see the message #{string}"
end

Then('I should not receive the message {string}') do |string|
  assert !page.has_content?(string, wait: not_present_wait), "I can see the message #{string}"
end

Then('I should see the {string} page') do |string|
  # finds the first H1 in the parent
  find('h1:first-of-type', text: string)
rescue StandardError => e
  assert(false, "I am not on the #{string} page (#{e.message})")
end

Then('I should see the sub-title {string}') do |string|
  find('h2', text: string)
rescue StandardError => e
  assert(false, "I cannot see the sub-title #{string} (#{e.message})")
end

Then('I should see the text {string}') do |string|
  string.sub! 'NOW_DATE', DateFormatting.to_display_date_format(Date.today) if string.include?('NOW_DATE')
  assert page.has_content?(string)
end

Then('I should see the regex {string}') do |regex|
  assert page.has_content?(/#{regex}/)
end

Then('I should not see the text {string}') do |string|
  assert !page.has_content?(string, wait: not_present_wait)
end

Then('I should see a link with text {string}') do |string|
  assert has_link?(string)
end

Then('I should not see a link with text {string}') do |string|
  assert !has_link?(string, wait: not_present_wait)
end

Then('I should see the button with text {string}') do |string|
  assert has_button?(string)
end

Then('I should not see the button with text {string}') do |string|
  assert !has_button?(string, wait: not_present_wait)
end

Then('the table of data is displayed') do |table|
  data = table.hashes
  data.each do |row|
    row.each do |key, value|
      assert page.has_content?(key), "#{key} is missing" unless key.start_with?('Action_')
      value = @stored_values[value] if value.start_with?('RANDOM_')
      # Time.now.strftime - For items that has the current date
      value = DateFormatting.to_display_date_format(Date.today) if value.start_with?('NOW_DATE')
      assert page.has_content?(value), "#{value} is missing"
    end
  end
end

Then('the data is not displayed in table') do |table|
  data = table.hashes
  data.each do |row|
    row.each do |_key, value|
      assert_equal(false, page.has_content?(value), "#{value} display in the table")
    end
  end
end

# When the field is either a text field or a select, used on the field with the javascript autocomplete.
# see also when equivalent for setting value
Then('I should see {string} in the {string} select or text field') do |string, field|
  sleep(js_processing_wait) # wait for the JS to process
  if page.has_field?(field, type: 'select', disabled: true, wait: not_present_wait)
    assert page.has_select?(field, selected: string, disabled: true),
           "I cannot see the value #{string} selected in disabled #{field}"
  elsif page.has_field?(field, type: 'select', wait: not_present_wait)
    assert page.has_select?(field, selected: string), "I cannot see the value #{string} selected in #{field}"
  elsif page.has_field?(field, type: 'text', wait: not_present_wait)
    assert find_field(field).value == string, "I cannot see the value #{string} in #{field}"
  else
    assert false, "Cannot find #{field} to check"
  end
end

Then('{string} should contain the option {string}') do |dropdown, text|
  assert page.has_select?(dropdown, with_options: [text]), "#{dropdown} does not have the option #{text}"
end

Then('{string} should not contain the option {string}') do |dropdown, text|
  assert page.has_no_select?(dropdown, with_options: [text]), "#{dropdown} does have the option #{text}"
end

Then('I should see the text {string} in display field {string}') do |string, field|
  text_with_label = page.find('span', id: page.find('label', text: field)['for']).text
  assert string == text_with_label, "I cannot see the value #{string} in #{field}"
end

Then('I should see the text {string} in field {string}') do |string, field|
  assert find_field(field).value == string, "I cannot see the value #{string} in #{field}"
end

Then('field {string} should be readonly') do |string|
  assert  find_field(string, readonly: true)
end

Then('I should see the empty field {string}') do |field|
  assert (find_field(field).value.nil? ||
          find_field(field).value == ''),
         "I can see the field #{field} is not empty as it contains the value " \
            "#{find_field(field).value}"
end

Then('the checkbox {string} should be checked') do |string|
  assert page.has_checked_field?(string, visible: false)
end

Then('the radio button {string} should be selected') do |string|
  assert page.has_checked_field?(string, visible: false)
end

Then('the radio button {string} should not be selected') do |string|
  assert_not page.has_checked_field?(string, visible: false)
end

# Clicks the JS alert dialog if one is found.  It will only exist if test is run in JS mode/in a browser,
# which Jenkins does, meaning there's a difference between developer machines and the test server.
Then('if available, click the confirmation dialog') do
  page.driver.browser.switch_to.alert.accept
  sleep(page_processing_wait) # wait to allow page to process
rescue NoMethodError
  Rails.logger.info('No dialog found - fine if JS is not enabled')
end

Then('I should see the flipped value in {string} field using marker {string}') do |field_id, marker|
  actual_value = find_field(field_id).value
  expected_value = lookup_result(marker)
  assert expected == actual, "I cannot see the value #{expected_value} in #{field_id}, instead was '#{actual_value}'"
end

Then('I should see the value flipped\/stored using marker {string}') do |marker|
  expected_value = lookup_result(marker)
  assert page.has_content?(expected_value), "I cannot see the flipped value #{expected_value}"
end

# Check the selected option on a select drop-down
Then('I should see the {string} option selected in {string}') do |string, field|
  assert page.has_select?(field, selected: string), "I cannot see the value #{string} selected in #{field}"
end

# Stores a value for use in a later step so we can test a value which alternates each test, knowning we're
# testing the right value.  Stores under the ENV['APPLICATION_VERSION'] variable (and then under a specific
# marker) to eliminate any concerns about multi-threaded issues when running tests on Jenkins.
# @param marker [String] the key used to store/lookup the value
# @param value [Object] the data to store
def store_result(marker, value)
  # initialize storage if not already available
  @flip_flop_results || @flip_flop_results = { ENV['APPLICATION_VERSION'] => {} }
  @flip_flop_results[ENV['APPLICATION_VERSION']][marker] = value
end

# Retrieve a result from a Stored/Flipped value @see #store_result
# @param marker [String] the key used to store/lookup the value
def lookup_result(marker)
  log("...Flip flop/lookup result for #{marker} is #{@flip_flop_results[ENV['APPLICATION_VERSION']][marker]}")
  @flip_flop_results[ENV['APPLICATION_VERSION']][marker]
end
