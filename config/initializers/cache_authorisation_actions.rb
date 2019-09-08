# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
if !Rails.env.development? && ENV['UNIT_TEST'].nil?

  Rails.logger.info('Pre-seeding action/roles cache before starting tests')

  ActionRoles.cache_all_actions

end
