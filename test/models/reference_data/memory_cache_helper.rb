# frozen_string_literal: true

# Test helper to specify a memory cache for the test and put back whatever the default is afterwards
module ReferenceData
  # Methods to provide a memory cache for a specific test and to put it back afterwards
  module MemoryCacheHelper
    # Configure an in memory cache to prevent us accessing Redis and potentially changing the data
    # other developers are using.  Also means Jenkins/build servers don't need access to Redis to run tests.
    def set_memory_cache
      Rails.logger.info('Setting memory_store cache for this test')
      @original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    end

    # Put the original cache back in place so other tests can rely on the default configuration.
    def restore_original_cache
      Rails.logger.info('Restoring previous cache')
      Rails.cache = @original_cache
    end
  end
end
