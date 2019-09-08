# frozen_string_literal: true

# Provides common code for storing data in the cache that's originally downloaded from the back office
# for a given account (ie data is stored indexed by party_refno).
# This means that multiple users of the same account will share the same cached data.
module AccountBasedCaching
  extend ActiveSupport::Concern

  # Classes that the ActiveSupport::Concern automatically adds as class level methods
  module ClassMethods
    # Where this data is stored in the cache.
    # Must be unique to the account and the implementing class and always return the same value for the input.
    # @param [String] party_refno is the Account ID
    # @return <class_name>_<party_refno>
    def cache_key(party_refno)
      "#{name}_#{party_refno}"
    end

    # Update the cache with the latest back office data
    # The cache will be set to expire @see cache_expiry_time.
    # @param [User] requested_by is usually the current_user, who is requesting the data and containing the account id
    def refresh_cache!(requested_by)
      key = cache_key(requested_by.party_refno)
      Rails.logger.info("Refreshing cache from back office for #{key}")
      Rails.cache.write(key, back_office_data(requested_by), expires_in: cache_expiry_time)
    end

    # Get (and populate from back office if needed) the cached data.
    # The data is stored in the cache under the result of calling the cache_key method.
    # Under that is the result of the last call to @see #back_office_data on implementing classes (ie implementing
    # classes must have a back_office_data method).
    # The cache will be set to expire @see cache_expiry_time.
    # @param [User] requested_by is usually the current_user, who is requesting the data and containing the account id
    # @return the cached data @see #back_office_data on implementing classes for more details.
    def all(requested_by)
      key = cache_key(requested_by.party_refno)
      Rails.logger.debug("Getting cache data for #{key}")
      Rails.cache.fetch(key, expires_in: cache_expiry_time) do
        Rails.logger.debug("Cache miss for #{key}, fetching back office data")
        back_office_data(requested_by)
      end
    end

    # When the cache data for this class should expire.
    # @return Rails.configuration.x.accounts.cache_expiry or 10 minutes if that's not set.
    def cache_expiry_time
      Rails.configuration.x.accounts.cache_expiry || 10.minutes
    end
  end
end
