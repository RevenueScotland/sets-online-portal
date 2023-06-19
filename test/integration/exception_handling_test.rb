# frozen_string_literal: true

require 'test_helper'
require 'savon/mock/spec_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # Make sure not dependent on REDIS and back office
  setup do
    @savon ||= Savon::SpecHelper::Interface.new
    @savon.mock!
    Rails.logger.debug { 'Mocking started' }
    fixture = File.read('test/fixtures/mocks/reference_data/system_parameters_response.xml')
    @savon.expects(:get_system_parameters_wsdl).returns(fixture)
  end

  teardown do
    @savon&.unmock!
    Rails.logger.debug { 'Mocking ended' }
  end

  # Test version of the controller with methods to aid testing
  class StubController < ApplicationController
    skip_before_action :require_user # cleared globally for testing

    NORMAL_ERROR_MESSAGE = 'Connection error from back office'

    def raise_error
      raise Error::AppError.new('error code', NORMAL_ERROR_MESSAGE)
    end
  end

  # Create custom routing for this test
  Rails.application.routes.disable_clear_and_finalize = true
  Rails.application.routes.draw do
    get 'raise_error', to: 'application_controller_test/stub#raise_error'
  end

  test 'exceptions are caught' do
    # going to index page to test the back link
    get '/index'
    assert_response(:ok)
    get '/raise_error'
    assert_response(:error)
    assert_select 'h1', 'Sorry, there is a problem with the service', 'Incorrect header'
    assert_select 'p',
                  /If the problem persists and you wish to report it, please contact Revenue Scotland quoting the \
reference E\d\d\d\d\d and the date and time it happened/, 'Incorrect text'
    Rails.logger.debug { "Respone is : #{response.body}" }
    assert_select 'a[href="/index"]', 'Back'
  end
end
