# frozen_string_literal: true

require 'test_helper'

# Test LogMiddleware methods that aren't covered by an autotest
class LogMiddlewareTest < ActiveSupport::TestCase
  test 'can filter valid ips from list' do
    ip_list = '192.168.0.1, 127.0.0.1'
    log_middleware = RequestSummaryLogging::LogMiddleware.new(nil)
    result = log_middleware.send(:ips_from, ip_list)
    assert_equal result, ['192.168.0.1', '127.0.0.1'], 'Failed to return valid ips'
  end

  test 'can filter out invalid ips from list' do
    ip_list = '192.168.0.1, 127.0.0.1, 255.0'
    log_middleware = RequestSummaryLogging::LogMiddleware.new(nil)
    result = log_middleware.send(:ips_from, ip_list)
    assert_equal result, ['192.168.0.1', '127.0.0.1'], 'Failed to return valid ips from list that included invalid ip'
  end

  test 'can filter out netmask from list' do
    ip_list = '192.168.0.1, 127.0.0.1, 10.102.0.3/8'
    log_middleware = RequestSummaryLogging::LogMiddleware.new(nil)
    result = log_middleware.send(:ips_from, ip_list)
    assert_equal result, ['192.168.0.1', '127.0.0.1'], 'Failed to return valid ips from list that included netmask'
  end
end
