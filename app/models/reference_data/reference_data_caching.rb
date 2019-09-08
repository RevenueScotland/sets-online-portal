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

    # The code field under a given Domain, Service and Workplace composite key
    attr_accessor :code
    validates :code, presence: true

    # Where this data is stored in the cache.  Must be unique to the implementing class so setting to the class' name.
    # Overrides cache_key in CachedBackOfficeData as reference data is not dependent on party ref no (account id).
    def self.cache_key
      name
    end

    # Get the data from the cache and return the list associated with the parameters
    # (the result is suitable for iterating over).
    # If you need to call this method mulitple times, consider calling cached_values once to get the raw data and
    # operate on that rather than making multiple calls to the cache.
    # @param [String] domain_code - back office key
    # @param [String] service_code - back office key
    # @param [String] workplace_code - back office key
    # @return a list for the given domain, service and workplace codes.
    def self.list(domain_code, service_code, workplace_code)
      output = lookup(domain_code, service_code, workplace_code).values.sort_by(&:sort_key)

      comp_key = composite_key(domain_code, service_code, workplace_code)
      raise Error::AppError.new(500, "No  #{name} list data found for #{comp_key}") if output.blank?

      output
    end

    # Get the data from the cache and return the hash associated with the parameters
    # (We can't call this method "hash" since that's a reserved word in Rails.)
    # @param [String] domain_code - back office key
    # @param [String] service_code - back office key
    # @param [String] workplace_code - back office key
    # @raise [Error::AppError] if the data doesn't exist.
    # @return [Hash] the hash for the given domain, service and workplace codes.
    def self.lookup(domain_code, service_code, workplace_code)
      comp_key = composite_key(domain_code, service_code, workplace_code)
      lookup_composite_key(comp_key)
    end

    # Get the data from the cache and return the hash associated with the key.
    # @param [String] comp_key in the format returned by #composite_key (ie <domain>.>service>.<workplace>)
    # @return [Hash] the hash for the given composite key
    def self.lookup_composite_key(comp_key)
      Rails.logger.debug("Looking up #{comp_key}")
      output = cached_values[comp_key]
      raise Error::AppError.new(500, "No #{name} lookup data found for #{comp_key}") if output.blank?

      output
    end

    # Helper method to get the cached data for mulitple keys at once (ie only 1 call to the cache).
    # @param [Array] composite_keys - list of composite keys made from calling @see composite_key.
    # @return [Hash] output[composite_key] = <result>
    def self.lookup_multiple(composite_keys)
      Rails.logger.debug("Looking up multiple keys #{composite_keys}")
      output = cached_values.slice(*composite_keys)
      raise Error::AppError.new(500, "No #{name} lookup multiple data found for #{composite_keys}") if output.blank?

      output
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

    # Get (and populate if needed) the cached data.
    # The data is stored in the cache under the result of calling the cache_key method (on implementing classes).
    # Under that, it's stored in a 2 dimensional hash using the composite_key method and then the code field
    # so the complete in cache structure is : cache[cache_key][composite_key][code] = object
    # @return [Hash] the cached version/entire hash of the values for this object's cache_key.
    def self.cached_values
      Rails.logger.debug("Getting cache data for #{cache_key}")
      Rails.cache.fetch(cache_key) do
        Rails.logger.debug("Cache miss for #{cache_key}")
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
    # @param index [Symbol] where in the message body to find the results (eg :reference_values)
    private_class_method def self.lookup_back_office_data(back_office_service, index)
      output = {}
      Rails.logger.info('Fetching system parameters from the back office for caching')
      success = call_ok?(back_office_service, nil) do |body|
        output = organise_results(body[index])
        output.merge!(application_values(output))
      end
      output if success
    end

    # Converts the back office data response to a 2 dimensional hash object indexed first by @see composite_key
    # and then by the mandatory code field.
    # @note return [Hash] output [composite_key][code]=[object].
    # Each index in our output map is an array of the values returned for that key.
    # @param element [Hash] an element from the result message body from back office
    private_class_method def self.organise_results(element)
      output = {}
      ServiceClient.iterate_element(element) do |data|
        key = composite_key(data[:domain_code], data[:service_code], data[:workplace_code])

        # initialise the array ready for data if it doesn't exist already
        output[key] = {} unless output.key?(key)
        # call to_s for the key so we have String keys not Nori::StringWithAttributes
        output[key][data[:code].to_s] = make_object(data)
      end
      output
    end

    # Generate the hash composite key for the given parameters.
    # @param domain_code [String] back office key
    # @param service_code [String] back office key
    # @param workplace_code [String] back office key
    # @return [String] the hash composite key for the given parameters
    def self.composite_key(domain_code, service_code, workplace_code)
      "#{domain_code}.#{service_code}.#{workplace_code}"
    end

    # CV lists which we need for the application but which don't exist in the back office.
    # @param _existing_values[Hash] the existing values in case we need to reference them
    # @return [Hash] a hash of objects needed for the application
    def self.application_values(_existing_values)
      output = {}
      # example code :
      # app_codes = { 'Y' => SystemParameter.new(code: 'Y') }
      # output[composite_key('domain', 'service', 'workplace')] = app_codes
      output
    end

    # Returns a sort key used when getting the list method
    # can be overridden by individual classes
    # @return [object] value suitable for sorting
    def sort_key
      @code
    end
  end
end
