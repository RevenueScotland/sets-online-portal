# frozen_string_literal: true

# Class for calling methods on the Companies House API
class CompaniesHouseApi
  include HTTParty
  base_uri Rails.configuration.x.ch_endpoint.root

  # Initialize this class, by setting the authorisation parameters
  def initialize
    @auth = { username: Rails.configuration.x.ch_endpoint.uid, password: Rails.configuration.x.ch_endpoint.pwd }
  end

  # Find a company by it's company number
  def company(company_number)
    options = { basic_auth: @auth }
    options.merge!(proxy)
    self.class.get("/company/#{company_number}", options)
  end

  private

  # Return a hash of proxy details if that's required
  def proxy # rubocop:disable Metrics/AbcSize
    return {} if Rails.configuration.x.ch_endpoint.proxy.to_s.empty?

    proxy_uri = URI.parse(Rails.configuration.x.ch_endpoint.proxy)
    proxy = {
      http_proxyaddr: proxy_uri.host, http_proxyport: proxy_uri.port,
      http_proxyuser: proxy_uri.user, http_proxypass: proxy_uri.password
    }
    proxy.delete_if { |_, v| v.nil? }
  end
end
