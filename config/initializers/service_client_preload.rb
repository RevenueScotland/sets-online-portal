# frozen_string_literal: true

# Preload the back office client configurations
Rails.application.reloader.to_prepare do
  ServiceClient::Configuration.preload
end
