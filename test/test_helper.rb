# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'simplecov'

module ActiveSupport
  # Base application test case class
  class TestCase
    # Add more helper methods to be used by all tests here...
  end
end
