# frozen_string_literal: true

require 'capybara-screenshot/minitest'

short_wait = 2 # period to wait when checking an item is not present

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

Given('I have signed in {string} and password {string}') do |username, password|
  sign_in(username, password)
end

# Login with given username and password
def sign_in(username, password)
  visit('/login')
  fill_in('Username', with: username)
  fill_in('Password', with: password)
  click_button('Sign in')
end

When('(I )go to the {string} page') do |string|
  # allow access to the root page
  if string == '/'
    visit('/')
  else
    visit('/' + string.downcase)
  end
end

When('(I )click (on )the {string} button') do |string|
  click_button(string)
end

# JS mode or not may make a button visible or not.  This method clicks it if it's available and doesn't throw
# an exception if it is not.  (Jenkins always runs the browser so JS mode is on whereas on dev machine's it's off).
Then('if available, click the {string} button') do |string|
  if has_button?(string, wait: short_wait)
    click_button(string)
  else
    Rails.logger.info("Optional button #{string} not found")
  end
end

When('(I )click on the {string} text') do |string|
  find('span', text: string).click
end

When('(I )click on the {string} text with class {string}') do |string, css_class|
  find(".#{css_class}", text: string).click
end

When('(I )enter {string} in the {string} field') do |string, string2|
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

When('(I )enter {string} in the {string} and {string} field') do |string, string2, string3|
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

When('(I )click on the {string} link') do |string|
  click_link(string)
end

When('(I )click on the {string} link with id {string}') do |text, id|
  click_link(text, id: id)
end

When('(I )click on the {int} st/nd/rd/th {string} link') do |integer, string|
  integer -= 1 # results array seems to be 0 based
  all('a', text: string)[integer].click
end

When('(I )check (the ){string} radio button') do |string|
  choose(string, visible: false) # the radio button may be hidden on javascript pages, this ensures it is still found
end

When('(I )select {string} from the {string}') do |text, dropdown|
  select text, from: dropdown
end

# When the field is either a text field or a select, used on the field with the javascript autocomplete.
When('(I )enter {string} in the {string} select or text field') do |text, field|
  if page.has_field?(field, type: 'select', wait: short_wait)
    select text, from: field
  elsif page.has_field?(field, type: 'text', wait: short_wait)
    fill_in(field, with: text)
  else
    fill_in(field, with: text)
  end
end

When('(I )click on the {string} link of the first entry displayed') do |string|
  click_link(string, match: :first)
end

When('(I )check (the ){string} checkbox') do |string|
  check(string, visible: false) # the checkbox may be hidden on javascript pages, this ensures it is still found
end

When('(I )uncheck (the ){string} checkbox') do |string|
  page.uncheck(string, visible: false) # the checkbox may be hidden on javascript pages, this ensures it is still found
end

When('(I )filter on {string}') do |name|
  value = if name.start_with?('RANDOM_SURNAME')
            @stored_values[name]
          else
            name
          end
  fill_in('Name', with: value)
  click_button('Find')
end

# For a test which changes values, flip flop between two values.
# Ie detects the current value and sets it to the other one (or the first one if no value set)
# This means we don't have to reset values in tests, and means if a failure happens, it doesn't leave
# the values wrong for the next test.
# Stores the value set so the corresponding check step knows which one it should be checking for.
When('(I )flip {string} field between {string} and {string} using marker {string}') do |field_id, val1, val2, marker|
  field_value = find_field(field_id).value
  new_value = val1 == field_value ? val2 : val1
  puts "...field value was #{field_value} so new value is #{new_value}"
  fill_in(field_id, with: new_value)
  store_flip_flop_result(marker, new_value)
end

# Temp step to allow you to put a wait in an individual test
When('(I )wait for {int} seconds') do |period|
  puts("Zzzzzzzz for #{period} seconds")
  sleep(period)
end

# Temp step to allow you to put a wait in an individual test
When('(I )take a picture called {string}') do |filename|
  page.save_screenshot(filename)
end

Then('I should receive the message {string}') do |string|
  assert page.has_content?(string), "I cannot see the message #{string}"
end

Then('I should not receive the message {string}') do |string|
  assert !page.has_content?(string, wait: short_wait), "I can see the message #{string}"
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
  assert !page.has_content?(string, wait: short_wait)
end

Then('I should see a link with text {string}') do |string|
  assert has_link?(string)
end

Then('I should not see a link with text {string}') do |string|
  assert !has_link?(string, wait: short_wait)
end

Then('I should see the button with text {string}') do |string|
  assert has_button?(string)
end

Then('I should not see the button with text {string}') do |string|
  assert !has_button?(string, wait: short_wait)
end

Then('the table of data is displayed') do |table|
  data = table.hashes
  data.each do |row|
    row.each do |key, value|
      assert page.has_content?(key)
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

Then('{string} should contain the option {string}') do |dropdown, text|
  assert page.has_select?(dropdown, with_options: [text]), "#{dropdown} does not have the option #{text}"
end

Then('{string} should not contain the option {string}') do |dropdown, text|
  assert page.has_no_select?(dropdown, with_options: [text]), "#{dropdown} does have the option #{text}"
end

Then('I should see the text {string} in field {string}') do |string, field|
  assert find_field(field).value == string, "I cannot see the value #{string} in #{field}"
end

Then('I should see the empty field {string}') do |field|
  assert (find_field(field).value.nil? || find_field(field).value == ''),
         "I can see the field #{field} is not empty as it contains the value #{find_field(field).value}"
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
  sleep(0.1) # wait to allow page to process
rescue NoMethodError
  Rails.logger.info('No dialog found - fine if JS is not enabled')
end

Then('I should see the flipped value in {string} field using marker {string}') do |field_id, marker|
  actual_value = find_field(field_id).value
  expected_value = lookup_flip_flop_result(marker)
  assert expected == actual, "I cannot see the value #{expected_value} in #{field_id}, instead was '#{actual_value}'"
end

Then('I should see the value flipped using marker {string}') do |marker|
  expected_value = lookup_flip_flop_result(marker)
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
def store_flip_flop_result(marker, value)
  # initialise storage if not already available
  @flip_flop_results || @flip_flop_results = { ENV['APPLICATION_VERSION'] => {} }
  @flip_flop_results[ENV['APPLICATION_VERSION']][marker] = value
end

# Retrieve a result from a flipped value @see #store_flip_flop_result
# @param marker [String] the key used to store/lookup the value
def lookup_flip_flop_result(marker)
  puts "...Flip flop result for #{marker} is #{@flip_flop_results[ENV['APPLICATION_VERSION']][marker]}"
  @flip_flop_results[ENV['APPLICATION_VERSION']][marker]
end
