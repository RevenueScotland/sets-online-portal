# frozen_string_literal: true

require 'test_helper'

NORMAL_ERROR_MESSAGE = 'Connection error from back office'
ORA_ERROR_MESSAGE = 'Oracle locked you in'
NO_METHOD_ERROR_MESSAGE = "these arn't the droids you're looking for"

# Test version of the controller with methods to aid testing
class StubController < ApplicationController
  skip_before_action :require_user # cleared globally for testing

  def raise_normal_error
    raise Error::AppError.new('error code', NORMAL_ERROR_MESSAGE)
  end

  # Simulate an ORA Oracle application error.
  def raise_ora_error
    raise Error::AppError.new('ORA-123', ORA_ERROR_MESSAGE)
  end

  # Simulate a no method error
  def raise_no_method_error
    raise NoMethodError, NO_METHOD_ERROR_MESSAGE
  end
end

# Create custom routing for this test
Rails.application.routes.disable_clear_and_finalize = true
Rails.application.routes.draw do
  get 'raise_normal_error', to: 'stub#raise_normal_error'
  get 'raise_ora_error', to: 'stub#raise_ora_error'
  get 'raise_no_method_error', to: 'stub#raise_no_method_error'
end

# The actual tests start here
class StubControllerTest < ActionController::TestCase
  test 'exceptions are caught and flash message provided' do
    get :raise_normal_error
    # check the message on the first item in the flash hash
    assert_match(/\d\d\d\d\d/, flash.first.last.to_s, 'Partial timestamp should be in the flash message')
    # since we can't successfully set the request HTTP_REFERER, we should be redirected to the general error page
    assert_redirected_to(controller: 'home', action: 'error')
  end

  test 'ora message' do
    get :raise_ora_error
    assert_match(/\d\d\d\d\d/, flash.first.last.to_s, 'Partial timestamp should be in the flash message')
    assert_redirected_to(controller: 'home', action: 'error')
  end

  test 'no method error' do
    get :raise_no_method_error
    assert_match(/\d\d\d\d\d/, flash.first.last.to_s, 'Partial timestamp should be in the flash message')
    assert_redirected_to(controller: 'home', action: 'error')
  end
end
