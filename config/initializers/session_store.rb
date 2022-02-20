# frozen_string_literal: true

require 'action_dispatch/session/expiring_cache_store'

# The expiring cache store is specific to this application to allow the expiration from
# to be obtained from the back office see lib/action_dispatch/session/expiring_cache_store
Rails.application.config.session_store :expiring_cache_store, key: '_rev_scot_session'
