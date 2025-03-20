# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
# Also see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self
    policy.img_src     :self, 'https://*.google-analytics.com', 'https://*.googletagmanager.com'
    policy.object_src  :none
    policy.script_src  :self, 'https://www.googletagmanager.com/'
    policy.base_uri    :self
    policy.connect_src :self,
                       'https://*.google-analytics.com',
                       'https://*.analytics.google.com',
                       'https://*.googletagmanager.com'
    policy.style_src :self,
                     # Turbo hash
                     "'sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU='",
                     # Hash for SVG inline styles (Digital Scotland)
                     # Use for the close icon
                     "'sha256-HGGQBrwGJbmD2CnNIF3WBZgIUPoQBAyz43oky8CvV8s='",
                     # Below two are for the calendar
                     "'sha256-+QNAvwhfofBEu7McgI/DjPryU7YCUE89/EXjCODjXfg='",
                     "'sha256-Hcxnl5aSD1LytYlqL4UFkBx7fCQ1nGIqlyrDUM+dI8s='",
                     # Below two require unsafe hashes to work
                     "'unsafe-hashes'",
                     "'sha256-pOs4WtGebp+eyReRBDGzfPPLgZ8ztF12Yco/k2zyEMA='",
                     "'sha256-JGT1Gg3BRTrnd02vUlW2kiGzb3yZbcmN2ZK3qiGJMSA='"
  end
  #
  #   # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  #   config.content_security_policy_nonce_directives = %w(script-src)
  #
  #   # Report violations without enforcing the policy.
  #   # config.content_security_policy_report_only = true
end
