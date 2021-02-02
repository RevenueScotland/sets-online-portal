# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock calls associated with two factor authentication

def mock_two_factor_signin(token_value, two_factor_response)
  message = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}two_factor/valid_signin_2factor.xml")
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  message = { Username: 'VALID.USER', Token: token_value }
  fixture = File.read(File.join("#{FIXTURES_MOCK_ROOT}two_factor", two_factor_response))
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)

  mock_dashboard_calls('117', 'VALID.USER', 'get_account_details')
end

def mock_valid_two_factor_signin
  mock_two_factor_signin 'valid.token', 'valid_signin_token.xml'
end

def mock_invalid_two_factor_signin
  mock_two_factor_signin 'invalid.token', 'invalid_token.xml'
end

def mock_expired_two_factor_signin
  mock_two_factor_signin 'expired.token', 'expired_token.xml'
end

def mock_not_activated_two_factor_signin
  mock_two_factor_signin 'valid.token', 'not_activated_user_signin.xml'
end

def mock_password_expired_two_factor_signin
  mock_two_factor_signin 'valid.token', 'expired_password_signin.xml'
end

def mock_force_password_change_two_factor_signin
  mock_two_factor_signin 'valid.token', 'forced_password_change_signin.xml'
end

def mock_confirm_tc_two_factor_signin
  mock_two_factor_signin 'valid.token', 'confirm_tcs.xml'
end

Before('@mock_two_factor_login') do
  start_mock
  mock_valid_two_factor_signin
end

Before('@mock_two_factor_login_invalid_token') do
  start_mock
  mock_invalid_two_factor_signin
end

Before('@mock_two_factor_login_expired_token') do
  start_mock
  mock_expired_two_factor_signin
end

Before('@mock_two_factor_login_user_locked') do
  start_mock
  message = { Username: 'LOCKED.USER', Password: 'valid.password' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}two_factor/locked_user_signin.xml")
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
end

Before('@mock_two_factor_login_user_not_activated') do
  start_mock
  mock_not_activated_two_factor_signin
end

Before('@mock_two_factor_login_expired_password') do
  start_mock
  mock_password_expired_two_factor_signin
  mock_list_user
end

Before('@mock_two_factor_login_force_password_change') do
  start_mock
  mock_force_password_change_two_factor_signin
  mock_list_user
end

Before('@mock_two_factor_confirm_tcs') do
  start_mock
  mock_confirm_tc_two_factor_signin
end
