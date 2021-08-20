# frozen_string_literal: true

# Use the cache_store for sessions (see config files setting it to use redis) instead of the cookie-based default
# This prevents cookies being replayed

# get the maximum session time from tbe back office if we have access to the back office which we
# may not do in some rake tasks
unless ENV['FL_ENDPOINT_ROOT'].nil?
  max_session_mins = ReferenceData::SystemParameter.lookup('PWS', 'SYS', 'RSTU',
                                                           safe_lookup: true)['MAX_SESS_MINS']&.value&.to_i
end

# Add 5 minutes as we want the application controller check which redirects to the correct page to fire first
max_session_mins = (max_session_mins || 600) + 5

Rails.application.config.session_store :cache_store, key: '_rev_scot_session', expire_after: max_session_mins.minutes
