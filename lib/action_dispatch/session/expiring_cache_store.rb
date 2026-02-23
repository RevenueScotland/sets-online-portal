# frozen_string_literal: true

require 'action_dispatch/middleware/session/cache_store'

# Rails ActionDispatch extension
module ActionDispatch
  # Rails ActionDispatch::Session extension
  module Session
    # A session store that overrides the standard Session::CacheStore so that the expiry time is set
    # when the session is written, rather than on initialisation
    #
    # It supports the same options as the Rails Cache store except the expire after when the session is closed
    # the nil will set this cookie to expire at session
    class ExpiringCacheStore < CacheStore
      # Set a session in the cache.
      def write_session(env, sid, session, options)
        options[:expire_after] = nil
        super
      end
    end
  end
end
