# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch('PORT', 3000)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV', 'development')
# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

web_concurrency = ENV.fetch('WEB_CONCURRENCY', 1).to_i

unless Gem.win_platform? || web_concurrency <= 1
  # Specifies the number of `workers` to boot in clustered mode.
  # Workers are forked webserver processes. If using threads and workers together
  # the concurrency of the application would be max `threads` * `workers`.
  # Workers do not work on JRuby or Windows (both of which do not support
  # processes).
  #
  workers web_concurrency

  # Use the `preload_app!` method when specifying a `workers` number.
  # This directive tells Puma to first boot the application and load code
  # before forking the application. This takes advantage of Copy On Write
  # process behaviour so workers use less memory.
  #
  preload_app!
end

# NOTE: rails logger isn't set up at this point, so logging to the console is the only option
# The below code disconnects the REDIS cache when a new worker is started, REDIS will then reconnect
# automatically. This avoids issues if the connection is shared
on_worker_boot do
  puts 'About to start a new puma worker, reconnecting rails cache'
  pool = ActionController::Base.cache_store.redis
  pool.reload { |c| c.close if c.connected? }
end

on_restart do
  puts 'Puma restarting, reconnecting rails cache'
  pool.reload { |c| c.close if c.connected? }
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
