# frozen_string_literal: true

# creates a hash map of connection parameters to the redis cache
def cache_connection
  {
    url: ENV.fetch('REDIS_CACHE_URL', nil),
    db: 0,
    error_handler: lambda { |method:, returning:, exception:| # rubocop:disable Lint/UnusedBlockArgument
      Rails.logger.error("Cache store exception : #{exception}")
    }
  }
end
