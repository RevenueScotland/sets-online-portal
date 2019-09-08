# frozen_string_literal: true

require 'test_helper'
# Unit test for username validation
class UsernameValidationTest < ActiveSupport::TestCase
  # test to check username validation
  test 'check invalid username' do
    new_user_account_test = user_account_instance
    new_user_test = user_instance('test')

    new_user_account_test.current_user = new_user_test
    assert_equal false, new_user_test.valid?(:save)
    message = 'Username is too short'
    assert_equal true, new_user_test.errors.full_messages.to_sentence.include?(message)
  end

  test 'check valid username' do
    new_user_account_test = user_account_instance
    new_user_test = user_instance('test1')

    new_user_account_test.current_user = new_user_test
    assert_equal true, new_user_test.valid?(:save)
  end

  # returns a user account object
  def user_account_instance
    Account.new
  end

  # returns a user object
  def user_instance(username)
    User.new(new_username: username, forename: 'forename', surname: 'surname',
             email_address: 'a@a.com', email_address_confirmation: 'a@a.com',
             new_password: 'P@ssword001', new_password_confirmation: 'P@ssword001',
             user_is_current: 'Y')
  end
end
