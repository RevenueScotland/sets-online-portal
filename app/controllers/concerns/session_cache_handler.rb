# frozen_string_literal: true

# This concern helps us in the storing data in cache
# (ie Redis, under a certain index that this code manages for you (and saves in the session cookie)).
module SessionCacheHandler
  extend ActiveSupport::Concern
  # Retrieves data from the cache.
  # @param session_key [String] key to access cache key in the user's _session_ [cookie]
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  #        ie if you don't provide a name the current controller will be used.
  #        If you do provide a name it will get that controller's wizard data instead.
  def session_cache_data_load(session_key, cache_index = self.class.name)
    key = session_cache_key(cache_index, session_key)
    Rails.logger.debug { "Loading data for #{key}" }
    Rails.cache.read(key)
  end

  # _Overwrite_ cache object.  Use with caution.
  # @param master_object - the object to store in the cache
  # @param session_key [String] key to access cache key in the user's _session_ [cookie]
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  def session_cache_data_save(master_object, session_key, cache_index = self.class.name)
    master_object.initialize_ref_data if master_object.respond_to?(:initialize_ref_data)
    key = session_cache_key(cache_index, session_key)
    Rails.logger.debug do
      "Saving wizard params for:#{key} master_object: #{master_object.class.name} " \
        "expiring:#{session_cache_data_expiry_time}"
    end
    Rails.cache.write(key, master_object, expires_in: session_cache_data_expiry_time)
  end

  # Cleans up wizard cache and session at the end to delete it/free up resources.
  # Fails safe, won't throw exceptions if the deletion is unsuccessful due to a StandardError.
  # @param session_key [String] key to access cache key in the user's _session_ [cookie]
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  def clear_session_cache(session_key, cache_index = self.class.name)
    cache_key = session_cache_key(cache_index, session_key)
    Rails.logger.debug { "Ending wizard #{cache_key}" }
    Rails.cache.delete(cache_key)
    session.delete(session_key) { |key| Rails.logger.warn "session #{key} not deleted, not found" }
  rescue StandardError => e
    Rails.logger.warn("wizard_end failing safe, not throwing exception #{e.message}")
  end

  # Provides the wizard cache key for the relevant controller and user.
  #
  # Gets the cache key from the session [cookie]. Creates it in the session if it doesn't already exist.
  #
  # The cache key will contain a UUID so that each persons' wizard entries are unique.
  #
  # @param cache_index [String] the identifier for the cache index
  # @param session_key [String] key to access cache key in the user's _session_ [cookie]
  # @return [String] the session cache key
  def session_cache_key(cache_index, session_key)
    validate_session_cache_name(cache_index)
    # if the session key doesn't exist, generate a new one including the session key itself (to help with debugging)
    # and a UUID to make it unique to the session
    session[session_key] = "#{session_key}_#{SecureRandom.uuid}" unless session.key?(session_key)

    session[session_key]
  end

  # Check assumption that self.class.name is available and valid (ie not "class" and contains "Controller")
  # to check it hasn't been redefined.
  # @param cache_index [String] the identifier for the cache index
  def validate_session_cache_name(cache_index)
    return unless cache_index.nil? && cache_index.casecmp('class') && cache_index.include?('Controller')

    raise Error::AppError.new('wizard', "'#{cache_index}' is not a controller class")
  end

  # How long the data will last for if @see #cache_clear isn't called.
  # @return the session max lifetime from system parameters or 10.hours if that doesn't exist for some reason
  def session_cache_data_expiry_time
    begin
      max = ReferenceData::SystemParameter.lookup('PWS', 'SYS', 'RSTU')['MAX_SESS_MINS']&.value&.to_i
      return max.minutes if max.present?
    rescue StandardError
      Rails.logger.warn('System parameter PWS.SYS.RSTU did not include MAX_SESS_MINS, returning arbitrary expiry')
      return 10.hours
    end

    Rails.logger.warn('System parameter PWS.SYS.RSTU did not include MAX_SESS_MINS, returning arbitrary expiry')
    10.hours
  end
end
