# frozen_string_literal: true

require 'action_dispatch/middleware/session/cache_store'

# Rails ActionDispatch extension
module ActionDispatch
  # Rails ActionDispatch::Session extension
  module Session
    # A session store that overrides the standard Session::CacheStore so that the expiry time is set
    # when the session is written, rather than on initialisation
    #
    # It supports the same options as the Rails Cache store except the expire after is obtained from the back office
    class ExpiringCacheStore < CacheStore
      # Set a session in the cache.
      def write_session(env, sid, session, options)
        # get the maximum session time from the back office
        max_session_mins = ReferenceData::SystemParameter.lookup('PWS', 'SYS', 'RSTU',
                                                                 safe_lookup: true)['MAX_SESS_MINS']&.value&.to_i
        # Add 5 minutes as we want the application controller check which redirects to the correct page to fire first
        max_session_mins = (max_session_mins || 600) + 5
        options[:expire_after] = max_session_mins.minutes
        super
      end
    end
  end
end
