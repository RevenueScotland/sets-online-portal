# frozen_string_literal: true

# This concern handles the (de/)serializer for a model object to json-convertable hash and back.
#
# To use, ensure that the Serializer is included in your model so that it can be converted to a json format.
# Then to convert back, simply call the method with Serializer.
#
# Example 1: Object to json
#   @lbtt_returns = new LbttReturn
#   @lbtt_returns.from_object_to_json
#
# Example 2: Json to object
#   Serializer.from_json_to_object(<json format data>)
#
# Converts the object to a json format string by adding the key 'json_class' with the value of the object's class.name
# and then using the to_json to convert it to a json format.
#
# Converts from a json format string to to an object by initially parsing the json string (which turns it to a hash) and
# then looking for each 'json_class' in the any level of the hash then converting each of them to an object by doing
# the <model_string>.constantize, which works from the deepest level to the first level.
module Serializer
  require 'json'

  # Convert an object to a json format.
  # @return [String] the json converted from an object.
  def from_object_to_json(remove_keys = [])
    from_object_to_json_hash(remove_keys).to_json
  end

  # Convert a json format to an instance of an object.
  # @return [Object] the object created from the json converted data.
  def self.from_json_to_object(json)
    hash = JSON.parse(json)
    from_json_hash_to_object(hash)
  end

  # Converts a collection to a json format.
  # @return [String] the json converted from a collection, which may have objects within it.
  def self.from_collection_to_json(collection, remove_keys = [])
    from_collection_to_json_hash(collection, remove_keys).to_json
  end

  # Converts an object to a hash (in json format).
  # @param remove_keys [Array] is a list of items that shouldn't be included in the hash.
  # @return [Hash] the converted to hash
  def from_object_to_json_hash(remove_keys = [])
    # remove_keys << 'cached_ref_data' unless remove_keys.include?('cached_ref_data')
    # A false value is also equivalent to a blank value, but a blank value is not equals to false.
    output = instance_values.reject { |key, value| (value.blank? && value != false) || remove_keys.include?(key.to_s) }
    output = { 'json_class' => self.class.name }.merge(output)
    output.each { |key, value| output[key] = find_nested_value_from_object(value, remove_keys) }
  end

  # Converts a hash (in json format) to an object.
  # @return [Object|Hash] the converted to object or the hash value as there wasn't any 'json_class' found.
  def self.from_json_hash_to_object(hash)
    model_class = hash['json_class']
    hash.each { |key, value| hash[key] = find_nested_value_from_json(value) }
    return hash if model_class.nil?

    model_class.constantize.new(hash.reject { |key| key == 'json_class' })
  end

  # Converts a hash or array to a json format hash/array, normally used for when we need to start the conversion from
  # either a hash or array.
  # @param remove_keys [Array] see from_object_to_json_hash method.
  # @return [Hash|Array] the converted collection to json format.
  def self.from_collection_to_json_hash(collection, remove_keys = [])
    if collection.is_a?(Hash)
      collection.each { |key, value| collection[key] = find_nested_value_from_collection(value, remove_keys) }
    elsif collection.is_a?(Array)
      collection.collect { |value| find_nested_value_from_collection(value, remove_keys) }
    end
    collection
  end

  # Used for traversing through each levels of the hash or array and converting it from json format to an object.
  # @param value [Hash|Array|Data] Depending on the data type, this will handle it differently:
  #   [Hash] to be traversed and see whether if we'll convert the hash to an object or leave the hash as it is.
  #   [Array] Or if this is an array then it will go one level down into that array to see if there's any non-hash
  #   or non-array value.
  #   [Data] this is the data type that is not an array or hash, this doesn't need to be processed as it is the data
  #   that we're looking for.
  # @return [Object|Array|Hash] The data after being processed.
  private_class_method def self.find_nested_value_from_json(value)
    value = value.dup
    return from_json_hash_to_object(value) if value.is_a?(Hash)
    return value.collect { |item| find_nested_value_from_json(item) } if value.is_a?(Array)

    value
  end

  # Used for traversing through each levels of the hash or array and converting the found object to a json format hash.
  # This is similar to find_nested_value_from_json method.
  private_class_method def self.find_nested_value_from_collection(value, remove_keys)
    return from_collection_to_json_hash(value, remove_keys) if value.is_a?(Hash) || value.is_a?(Array)
    return value unless value.respond_to?(:from_object_to_json_hash)

    # When the object is found, we'll convert it from object to a json format hash.
    value.from_object_to_json_hash(remove_keys)
  end

  private

  # Similar to the find_nested_value_from_json but it's doing the opposite of it, so it's used for the conversion of
  # the object to a json format value.
  def find_nested_value_from_object(value, remove_keys)
    value = value.dup

    return value.each { |key, item| value[key] = find_nested_value_from_object(item, remove_keys) } if value.is_a?(Hash)
    return value.collect { |item| find_nested_value_from_object(item, remove_keys) } if value.is_a?(Array)
    # Note: if your model doesn't contain the inclusion of this Serializer, then that won't be converted to a
    #       json format hash.
    # This is done so that any of the actual values (like String, Integer, Float, etc.) aren't modified and
    # returned as they are.
    return value unless value.respond_to?(:from_object_to_json_hash)

    value.from_object_to_json_hash(remove_keys)
  end
end
