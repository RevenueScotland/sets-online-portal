# frozen_string_literal: true

if !Rails.env.development? && ENV['UNIT_TEST'].nil?
  Rails.application.reloader.to_prepare do
    Rails.logger.info('Pre-seeding action/roles cache before starting tests')

    ActionRoles.cache_all_actions
  end
end
