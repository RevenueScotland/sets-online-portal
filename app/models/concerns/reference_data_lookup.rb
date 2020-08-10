# frozen_string_literal: true

# Common code to help handling look up of values for code where the lists are from the back office,
# avoids repeating the key values in the views and in the model.
# The code also optionally stores the lists in the model instance for the lifetime of the instance
# to avoid repeated calls to REDIS.
# This is normally just one request cycle. Note you don't want to store the lists for too long as there
# is no expiry on the values and they won't get refreshed.
# The exception to this is YESNO.SYS.RSTU which is unlikely to change and is therefore stored
# at the class not instance level and should be added to the uncached list.
#
# The lists are stored on a just in time basis so the lists are retrieved on the first call to get
# any list
#
# In order for this to work you need to provide two methods in the model, #cached_ref_data_codes lists
# the keys for those lists that can be stored locally; the key is usually an attribute name.
# Do not include YESNO.SYS.RSTU or long lists in this method
#
# @example
#   def cached_ref_data_codes
#     { year: comp_key('YEAR','SYS','RSTU'), fape_period: comp_key('PERIOD'.'SYS','RSTU') }
#   end
#
# #uncached_ref_data_codes lists those keys that we do not want to cache locally (just linking the back
# office code to an attribute name) eg long lists.
#
module ReferenceDataLookup
  extend ActiveSupport::Concern

  attr_accessor :cached_ref_data

  # held at the class level to cache yes no once per application instance
  @lookup_yesno = nil

  # Pre-populates @cached_ref_data based on the ref data codes in #cached_ref_data_codes if that method exists
  # and if it hasn't already been set up.
  # Can be called externally so that code can initialise at a key processing point
  # @see wizard for use
  def initialize_ref_data
    # don't do this if @cached_ref_data is already set up
    return true unless @cached_ref_data.nil?

    return false unless respond_to?(:cached_ref_data_codes)

    Rails.logger.debug("Initializing ref data into the model cache for #{self.class.name}")

    # lookup all the codes in one go
    codes = send(:cached_ref_data_codes)
    ref_data = ReferenceData::ReferenceValue.lookup_multiple(codes.values)

    # now organise them based on the requested key (usually an attribute symbol)
    @cached_ref_data = {}
    codes.each { |key, value| @cached_ref_data[key] = ref_data[value] }
    true
  end

  # Utility function provided as a wrapper for the ReferenceValue format_composite_key function
  # @see ReferenceData::ReferenceDataCaching.format_composite_key
  def comp_key(domain_code, service_code, workplace_code)
    ReferenceData::ReferenceValue.format_composite_key(domain_code, service_code, workplace_code)
  end

  # List version of @see #lookup_ref_data
  def list_ref_data(attribute)
    # duplicates parts of @see ReferenceData::ReferenceValue#list
    lookup_ref_data(attribute).values.sort_by(&:sort_key)
  end

  # Return reference data defined and cached in your model @see #initialize_ref_data.
  #
  # Whenever the same reference data is needed more than once alongside a model attribute you should consider
  # adding it to a #cached_ref_data_codes method in your model.  The reference data will be stored inside the model
  # (increasing the model size so don't use it for big lists but reducing the number of calls to Redis).
  #
  # Alternatively you can add it to a #uncached_ref_data_codes method in which case it won't be cached in the model
  # but you won't have to keep writing the domain_code, service_code, workplace_code codes each time.
  #
  # @param attribute [String] key linked to ref data defined in #cached_ref_data_codes or #uncached_ref_data_codes
  def lookup_ref_data(attribute)
    Rails.logger.debug("Model ref data lookup for #{attribute}")
    return @cached_ref_data[attribute] if initialize_ref_data && @cached_ref_data.key?(attribute)

    lookup_uncached_ref_data(attribute)
  end

  # Lookup the value of the attribute in the associated ref data.
  #
  # @example assuming your model has this in #(un)cached_ref_data_codes { year: 'YEAR.SYS.RSTU' }
  #          lookup_ref_data_value(:year) => ReferenceData::ReferenceValue.lookup(YEAR,SYS,RSTU)[year]
  #
  # @param value [String] the specific code to look up the value with, instead of the current code value
  #   from the object's attribute.
  # @see #lookup_ref_data
  def lookup_ref_data_value(attribute, value = nil)
    return lookup_ref_data(attribute)[send(attribute)]&.value if value.nil?

    lookup_ref_data(attribute)[value]&.value
  end

  # Returns the yesno list suitable for use in views
  # Provided for instances where you need YESNO with no linked attribute
  # Normally you would use the #list_ref_data with the attribute
  # @return [array] The YESNO list
  def self.list_yesno
    lookup_yesno.values.sort_by(&:sort_key)
  end

  # Returns the translation of the yes no value
  # Provided for instances where you need YESNO with no linked attribute
  # Normally you would use the #lookup_ref_data_value with the attribute
  # @param yesno The value to be translated
  # @return [string] Either Yes or No
  def self.lookup_yesno_value(yesno)
    lookup_yesno[yesno]&.value
  end

  # Returns the yesno hash from the global list
  # @return [hash] the hash for the yes no lookup
  def self.lookup_yesno
    @lookup_yesno ||= ReferenceData::ReferenceValue.lookup('YESNO', 'SYS', 'RSTU')
    @lookup_yesno
  end

  private

  # Return reference data defined and but not cached in your model @see #initialize_ref_data.
  #
  # called when the reference data is not defined in the cached model list
  #
  # @see lookup_ref_data
  #
  # @param attribute [String] key linked to ref data defined in #uncached_ref_data_codes
  def lookup_uncached_ref_data(attribute)
    raise Error::AppError.new('LOOKUP', 'uncached_ref_data_codes not defined') unless
         respond_to?(:uncached_ref_data_codes)

    comp_key = uncached_ref_data_codes[attribute]
    Rails.logger.debug("Model ref data uncached lookup for #{attribute} #{comp_key}")

    return ReferenceDataLookup.lookup_yesno if comp_key == comp_key('YESNO', 'SYS', 'RSTU')

    ReferenceData::ReferenceValue.lookup_multiple([comp_key])[comp_key]
  end
end
