# frozen_string_literal: true

# Data cached from the back office that directs how the app works.
module ReferenceData
  # Base class for reference data from the back office that's then cached.
  # Implementing classes need to provide methods to get the relevant data from the back office
  # (@see ReferenceData::SystemParameter for an example).
  # The data is stored in the cache under the implementing class name and indexed by a composite key made up of the
  # domain, service and workplace codes used by the back office.
  class ReferenceDataCaching < ::FLApplicationRecord
    include ActiveModel::Model
    include ActiveModel::Serialization

    # The key fields for the base class we store the domain code, workplace code and service code as
    # although these are normally used for the cache key there are some instances where we combine across these fields
    # but still need to know what the underlying data is to filter.
    attr_accessor :domain_code, :workplace_code, :service_code

    # Where this data is stored in the cache.  Must be unique to the implementing class so setting to the class' name.
    # Overrides cache_key in CachedBackOfficeData as reference data is not dependent on party ref no (account id).
    def self.cache_key
      name
    end

    # Get the data from the cache and return the list associated with the parameters
    # (the result is suitable for iterating over).
    # If you need to call this method multiple times, consider calling cached_values once to get the raw data and
    # operate on that rather than making multiple calls to the cache.
    # @param domain_code [String] back office key
    # @param service_code [String] back office key
    # @param workplace_code [String] back office key
    # @param safe_lookup [Boolean] Default false if set to true don't raise and error if no data
    # @return a list for the given domain, service and workplace codes.
    def self.list(domain_code, service_code, workplace_code, safe_lookup: false)
      output = lookup(domain_code, service_code, workplace_code, safe_lookup: safe_lookup)&.values&.sort_by(&:sort_key)

      output || []
    end

    # Get the data from the cache and return the hash associated with the parameters
    # (We can't call this method "hash" since that's a reserved word in Rails.)
    # @param domain_code [String] back office key
    # @param service_code [String] back office key
    # @param workplace_code [String] back office key
    # @raise [Error::AppError] if the data doesn't exist.
    # @return [Hash] the hash for the given domain, service and workplace codes.
    def self.lookup(domain_code, service_code, workplace_code, safe_lookup: false)
      comp_key = format_composite_key(domain_code, service_code, workplace_code)
      output = lookup_multiple([comp_key], safe_lookup: safe_lookup)[comp_key]

      output || {}
    end

    # Helper method to get the cached data for multiple keys at once (ie only 1 call to the cache).
    # @param [Array] composite_keys - list of composite keys made from calling @see composite_key.
    # @return [Hash] output[composite_key] = <result>
    def self.lookup_multiple(composite_keys, safe_lookup: false)
      Rails.logger.debug { "Looking up multiple keys #{composite_keys}" }
      output = cached_values.slice(*composite_keys)
      log_or_raise_lookup_error(output, composite_keys, safe_lookup)

      output || {}
    end

    # Used for raising or logging an error depending on the output and if we want to do a safe lookup.
    # This can be used for any of the lookup, just ensure that you pass in the lookup_type to get a more appropriate
    # error message.
    # @param output [Hash|Array] the output of the method where this is called
    # @param comp_key [Array|String] the single or multiple composite key(s)
    # @param safe_lookup [Boolean] if true this will do a safe look up which means that we will only log the error
    #   and not raise one if it meets the certain condition.
    private_class_method def self.log_or_raise_lookup_error(output, comp_key, safe_lookup)
      # If we have an output then we don't need to log any error
      return if output.present?

      return Rails.logger.info("No #{name} data found for #{comp_key}") if safe_lookup

      raise Error::AppError.new(500, "No #{name} data found for #{comp_key}")
    end

    # Returns lists of reference data value arrays indexed by their composite keys ie so you only hit the cache once.
    # @see #list
    # @param [Array] composite_keys - list of composite keys made from calling @see composite_key.
    # @return [Hash] lists of reference data indexed by their composite keys.
    def self.list_multiple(composite_keys)
      multiple = lookup_multiple(composite_keys)
      output = {}
      composite_keys.each do |key|
        output[key] = multiple[key].values.sort_by(&:sort_key)
      end
      output
    end

    # Return the composite key for this object.
    # Normally domain code, service code and workplace code but may be overriden
    # @return [String] the hash composite key
    def composite_key
      ReferenceDataCaching.format_composite_key(@domain_code, @service_code, @workplace_code)
    end

    # Returns the code for this object used to index in the main hash if the stored object
    # at the main hash is a hash type
    # @return [String] The value used for the inner hash
    def code
      nil
    end

    # Returns a sort key used when getting the list method
    # must be overridden by individual classes
    # @return [object] value suitable for sorting
    def sort_key
      nil
    end

    # Get (and populate if needed) the cached data.
    # The data is stored in the cache under the result of calling the cache_key method (on implementing classes).
    # Under that, it's stored in a 2 dimensional hash using the composite_key method and then the code field
    # so the complete in cache structure is : cache[cache_key][composite_key][code] = object
    # @return [Hash] the cached version/entire hash of the values for this object's cache_key.
    def self.cached_values
      Rails.logger.debug { "Getting cache data for #{cache_key}" }
      Rails.cache.fetch(cache_key) do
        Rails.logger.debug { "Cache miss for #{cache_key}" }
        back_office_data
      end
    end

    # Update the cache with the latest back office data
    def self.refresh_cache!
      Rails.logger.info("Refreshing cache from back office for #{cache_key}")
      Rails.cache.write(cache_key, back_office_data)
    end

    # Go to the back office and get the complete list of data in a hash.
    # The hash keys will be a composite of domain, service and workplace codes.
    # Calls application_values to add extra data into the output.
    # The hash values will be Arrays of objects (ie can be more than one object per cache key).
    # @param back_office_service [Symbol] the service to call
    # @param request [Hash] submitted to the back office to retrieve the data
    # normally nil as all data is retrieved
    # @param index [Symbol] where in the message body to find the results (eg :reference_values)
    private_class_method def self.lookup_back_office_data(back_office_service, request = nil, index)
      output = {}
      Rails.logger.info('Fetching cacheable data from the back office for caching')
      success = call_ok?(back_office_service, request) do |body|
        output = organise_results(body[index])
        output.merge!(application_values(output))
      end
      return output if success

      raise Error::AppError.new('lookup_back_office_data', 'success was false from back office')
    end

    # Converts the back office data response to a 1 or 2 dimensional hash object indexed first by @see composite_key
    # and then optionally by a code field if one is provided.
    # @note return [Hash] output [composite_key][code]=[object] or [composite_key] = [object]
    # Each index in our output map is an array of the values returned for that key.
    # @param element [Hash] an element from the result message body from back office
    private_class_method def self.organise_results(element)
      output = {}
      ServiceClient.iterate_element(element) do |data|
        cache_object = make_object(data)

        add_object(output, cache_object)
      end
      output
    end

    # Adds the given object onto the output hash, either directly or if it exists at the code value point
    # @param output [Hash] The hash being built
    # @param cache_object [Object] The object, an instance of reference data caching, being added
    private_class_method def self.add_object(output, cache_object)
      code_key = cache_object.code
      composite_key = cache_object.composite_key

      if code_key.nil?
        output[composite_key] = cache_object
      else
        # initialise the array ready for data if it doesn't exist already
        output[composite_key] = {} unless output.key?(composite_key)
        # call to_s for the key so we have String keys not Nori::StringWithAttributes
        output[composite_key][code_key.to_s] = cache_object
      end
    end

    # Generate the hash composite key for the given parameters.
    # @param domain_code [String] back office key
    # @param service_code [String] back office key
    # @param workplace_code [String] back office key
    # @return [String] the hash composite key for the given parameters
    def self.format_composite_key(domain_code, service_code, workplace_code)
      "#{domain_code}>$<#{service_code}>$<#{workplace_code}"
    end

    # CV lists which we need for the application but which don't exist in the back office.
    # @param _existing_values[Hash] the existing values in case we need to reference them
    # @return [Hash] a hash of objects needed for the application
    def self.application_values(_existing_values)
      {}
      # example code :
      # app_codes = { 'Y' => SystemParameter.new(code: 'Y') }
      # output[composite_key('domain', 'service', 'workplace')] = app_codes
    end
  end
end
