# frozen_string_literal: true

# creates a hash map of connection parameters to the redis cache
def cache_connection
  {
    url: ENV['REDIS_CACHE_URL'],
    error_handler: lambda { |method:, returning:, exception:| # rubocop:disable Lint/UnusedBlockArgument
      Rails.logger.error("Cache store exception : #{exception}")
    }
  }
end
