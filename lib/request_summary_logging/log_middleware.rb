# frozen_string_literal: true

require 'ipaddr'

module RequestSummaryLogging
  # Class to capture the incoming IP address of a request, and store it in
  # fiber-local variable storage mechanism
  #
  # @see http://rubyjunky.com/cleaning-up-rails-4-production-logging.html
  # @see https://github.com/gshaw/concise_logging
  # @author Richard Tearle
  class LogMiddleware
    def initialize(app)
      @app = app
      @trusted_proxies = nil
    end

    # Records the client IP address in fiber local storage. @see remote_ip for
    # details on how the client IP address is determined
    def call(env)
      request = ActionDispatch::Request.new(env)
      Thread.current[:logged_ip] = remote_ip(request, env)
      Rails.logger.debug do
        "Getting Client IP: remote ip is #{Thread.current[:logged_ip]} request.ip = #{request.ip} " \
          "request.remote_ip = #{request.remote_ip} request.x_forwarded_for = #{request.x_forwarded_for}"
      end
      @app.call(env)
    ensure
      Thread.current[:logged_ip] = nil
    end

    private

    # Determines the client IP address. In most cases, tries to use the request.remote_ip if it's set
    # If it's set, and still a trusted proxy, and the x_forwarded_for header is populated, use the left
    # most IP address from that instead.
    # This is opposite to how RAILs operates, but on corporate lans, most clients/servers are within
    # the trusted proxies IP ranges, so most of the time either localhost, or the nearest proxy
    # is logged as the client IP, which is less than ideal.
    # @note if the request.remote_ip is a real IP address (not in @trusted_proxies) this will ALWAYS
    # be returned
    def remote_ip(request, env)
      nil unless request
      request.ip unless request.remote_ip
      request.remote_ip unless request.x_forwarded_for

      init_trusted_proxies(env)
      forwarded_ips = ips_from(request.x_forwarded_for)
      @trusted_proxies.any? { |proxy| proxy.include?(request.remote_ip) } ? forwarded_ips.first : request.remote_ip
    end

    # Cache the rails list of trusted proxies
    def init_trusted_proxies(env)
      @trusted_proxies = ActionDispatch::RemoteIp.new(env).proxies if @trusted_proxies.nil?
    end

    # Copied from actionpack/lib/action_dispatch/middleware/remote_ip.rb
    # as the method is private. Converts a CSV string of IP addresses, and
    # returns a list of, only, valid IP addresses.
    def ips_from(header)
      return [] unless header

      # Split the comma-separated list into an array of strings.
      ips = header.strip.split(/[,\s]+/)
      ips.select do |ip|
        # Only return IPs that are valid according to the IPAddr#new method.
        range = IPAddr.new(ip).to_range
        # We want to make sure nobody is sneaking a netmask in.
        range.begin == range.end
      rescue ArgumentError
        nil
      end
    end
  end
end
