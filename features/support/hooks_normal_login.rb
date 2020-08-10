# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock calls associated with normal login

def mock_valid_signin
  message = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'normal_login/valid_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_dashboard_calls('117', 'VALID.USER', 'get_account_details')
end

# Mock a locked user sign in
Before('@mock_locked_user') do
  start_mock
  message = { Username: 'LOCKED.USER', Password: 'valid.password' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'normal_login/locked_user_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a non activated user sign in
Before('@mock_not_actived_user') do
  start_mock
  message = { Username: 'NOT.ACTIVATED.USER', Password: 'valid.password' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'normal_login/not_activated_user_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a forced password change user sign in
Before('@mock_forced_password_change') do
  start_mock
  message = { Username: 'FORCED.PASSWORD.CHANGE.USER', Password: 'valid.password' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'normal_login/forced_password_change_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_get_account_details('189', 'FORCED.PASSWORD.CHANGE.USER', 'get_account_details')
  mock_list_user
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a user whose password will expire after 4 days
Before('@mock_due_password') do
  start_mock
  message = { Username: 'DUE.PASSWORD', Password: 'valid.password' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'normal_login/due_password_signin.xml')

  # To run this test successfully,replaces expiry_date to 4 days future date
  fixture.sub!(/\d{4}-\d{2}-\d{2}/, (Date.today + 4).to_s)

  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_dashboard_calls('189', 'DUE.PASSWORD', 'get_due_password_account_details')
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a user that needs to confirm the t&cs
Before('@mock_confirm_tcs') do
  start_mock
  message = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'normal_login/confirm_tcs.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)

  mock_get_account_details('117', 'VALID.USER', 'get_account_details')
  mock_list_user

  message = { Username: 'VALID.USER', Action: 'TaCsSignUp' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'registration/update_confirm_tcs.xml')
  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)

  mock_list_secure_messages('117', 'VALID.USER')
  mock_all_returns('117', 'VALID.USER')
  mock_all_returns('117', 'VALID.USER')
end

# Mock an expired user signin
Before('@mock_expired_password') do
  start_mock
  message = { Username: 'EXPIRED.PASSWORD', Password: 'valid.password' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'normal_login/expired_password_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_get_account_details('189', 'EXPIRED.PASSWORD', 'get_account_details')
  mock_list_user
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end
