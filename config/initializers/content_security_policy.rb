# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
Rails.application.config.content_security_policy do |policy|
  policy.default_src :none
  policy.font_src    :self, 'https://fonts.gstatic.com/'
  policy.img_src     :self, 'https://www.google-analytics.com/'
  policy.object_src  :none
  policy.script_src  :self, 'https://www.googletagmanager.com/', 'https://www.google-analytics.com/'
  if Rails.env.development?
    policy.style_src   :self, 'https://fonts.googleapis.com/',
                       # hash to allow turbolinks progress bar
                       "'sha256-voXja0NHK+kj/CO6kVFGewEz+qyDFbxR+WW6e9vfN3o='",
                       # For development only allow the hashes for the performance button
                       "'unsafe-hashes'", "'sha256-XzJlZKVo+ff9ozww9Sr2p/2TbJXITZuaWMZ9p53zN1U='",
                       "'sha256-De7agAeYqm6ANIVvRRW6HFWi52AJW8inhFE0gSdgXnI='"
  else
    policy.style_src   :self, 'https://fonts.googleapis.com/',
                       # hash to allow turbolinks progress bar
                       "'sha256-voXja0NHK+kj/CO6kVFGewEz+qyDFbxR+WW6e9vfN3o='"
  end
  if Rails.env.development?
    policy.connect_src :self, 'https://www.google-analytics.com/'
  else
    # If you are using webpack-dev-server then specify webpack-dev-server host
    policy.connect_src :self, 'https://www.google-analytics.com/', 'http://localhost:3035', 'ws://localhost:3035'
  end

  # Specify URI for violation reports
  # policy.report_uri '/csp-violation-report-endpoint'
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
