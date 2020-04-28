# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock calls associated with the limited permission tests

# Mock a forced password change user and confirming terms and conditions for a user with limited
# permissions
Before('@mock_force_password_change_and_tc_limited_permissions') do
  start_mock
  message = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'limited_perms/forced_password_change_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_get_account_details('189', 'VALID.USER', 'get_account_details')
  mock_list_user

  message_pwd = { Username: 'VALID.USER', Requestor: 'VALID.USER', Action: 'ChangePassword',
                  OldPassword: 'valid.password', NewPassword: 'New.password1', ServiceCode: 'SYS' }
  fixture_pwd = File.read(FIXTURES_MOCK_ROOT + 'registration/change_password.xml')
  @savon.expects(:maintain_user_wsdl).with(message: message_pwd).returns(fixture_pwd)

  message_logoff = { Username: 'VALID.USER' }
  fixture_logoff = File.read(FIXTURES_MOCK_ROOT + 'limited_perms/logoff.xml')
  @savon.expects(:log_off_user_wsdl).with(message: message_logoff).returns(fixture_logoff)

  message_tc = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture_tc = File.read(FIXTURES_MOCK_ROOT + 'limited_perms/confirm_tcs.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message_tc).returns(fixture_tc)
  mock_get_account_details('189', 'VALID.USER', 'get_account_details')
  mock_list_user

  message = { Username: 'VALID.USER', Action: 'TaCsSignUp' }
  fixture = File.read(FIXTURES_MOCK_ROOT + 'registration/update_confirm_tcs.xml')
  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)

  mock_list_secure_messages('189', 'VALID.USER')
  mock_all_returns('189', 'VALID.USER')
  mock_all_returns('189', 'VALID.USER')
end
