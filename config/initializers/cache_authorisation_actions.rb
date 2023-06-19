# frozen_string_literal: true

unless Rails.env.development?
  Rails.application.reloader.to_prepare do
    Rails.logger.info('Pre-seeding action/roles cache')

    ActionRoles.cache_all_actions
  end
end
