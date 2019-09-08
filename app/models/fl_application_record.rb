# frozen_string_literal: true

# Base model for objects based on FL Calls
class FLApplicationRecord
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Translation
  include ServiceClient
  include ReferenceDataLookup

  attr_accessor :new_record

  # Is this record a new record, or an existing record on the back office.
  # return [Boolean] true if it is a new record, otherwise false if it not
  def new_record?
    @new_record
  end

  # Sets the new record value
  # @param value [Boolean] sets new_record to true or false
  def new_record!(value)
    @new_record = value
  end

  # initialises a new instance with the hash passed, uses Active model to do this
  # Pre-loads ref data we want to cache in the model rather than making repeated calls.
  # @param attributes [Hash] a hash of objects that uses Active model
  def initialize(attributes = {})
    super
    @new_record = true
  end

  # Sets up a new instance of the class when retrieved from the database
  # sets the new record to false
  # you can optionally pass a code block to make any changes to the object
  def self.new_from_fl(attributes = {})
    object = new(attributes)
    object.new_record!(false)
    yield(object) if block_given?
    object
  end

  # Does this record already exist on the back office
  # return [Boolean] checks if the record already exists
  def persisted?
    !new_record
  end

  # This is used for converting the boolean values of true or false to 'yes' or 'no'.
  # Useful for converting bool before sending requests to the backoffice.
  # @return [String] 'yes' or 'no'
  private_class_method def self.boolean_to_yesno(bool)
    return 'yes' if [true, 'true'].include?(bool)

    'no'
  end

  # Used when converting back office data.
  # When data is loaded from the back office we sometimes need to derive Y/N based on other fields. This method sets
  # them to 'Y' or 'N' based on whether some data exists.
  #
  # @example
  #    derive_yes_nos(back_office_hash, bad_debt_yes_no: :bad_debt_credit, true)
  #
  # @param hash [Hash] the datastructure representing back office data
  # @param to_derive [Hash] |key, value| key in hash to derive to 'Y' or 'N', value is the data to check.
  #                                      Can have many entries to derive many fields in one go.
  # @param clear_zero [Boolean] if true, a value of 0 will be deleted and will therefore dervice a 'N'
  private_class_method def self.derive_yes_nos(hash, to_derive, clear_zero)
    to_derive.each do |key, value|
      hash[value] = nil if clear_zero && hash[value] == '0'
      hash[key] = hash[value].blank? ? 'N' : 'Y'
    end
  end

  # @!method self.derive_yes_no_nil(value)
  # Used when converting back office data.
  # When data is loaded from the back office we sometimes need to derive Y/N based on other fields.
  # This method sets the flag to no yes or nil depending on if the value is 0, a value or nil
  #
  # @example
  #    derive_yes_no_nil(value)
  #
  # @param value [Number] the The numeric value to check
  # @return [String] Y or N or Nil
  private_class_method def self.derive_yes_no_nil(value)
    return if value.nil?

    (value.to_f != 0 ? 'Y' : 'N')
  end

  # Used when converting back office data.  The hash we get is a representation of the XML the back office sends.
  # Often there's an extraneous tag and we want the data under it to be on the same level as the parent tag.
  # This method takes the data under a given key in the hash and moves it up a level in the datastructure.
  # @example input { top: level, parent: { hello: 'world' } } output { top: level, hello: 'world' }
  # @param hash [Hash] the datastructure representing back office data
  # @param key [Object] key in hash to delete, its child objects will be merged with hash
  private_class_method def self.move_to_root(hash, key)
    removed_section = hash.delete(key)
    hash.merge!(removed_section) unless removed_section.nil?
  end

  # Used when converting back office data.
  # The back office uses a YesNoType ('yes' or 'no') but our radiobuttons use 'Y' or 'N'.
  # Convert the specified keys in the hash from yes/no to Y/N (ie can do many at the same time).
  # @param hash [Hash] the datastructure representing back office data
  # @param keys [Array] list of keys to look at and convert
  private_class_method def self.yes_nos_to_yns(hash, keys)
    keys.each { |key| hash[key] = hash[key] == 'yes' ? 'Y' : 'N' }
  end

  # Works out the total sum of some values list/hash of this model.
  # @param list [Object] list or hash containing the objects which need summing
  # @param method [Method] method to call on each of the list entry objects (ie the variable to sum)
  # @param round [Boolean] true to round the result, false to round down
  def self.sum_of_values_from_list(list, method)
    return 0 if list.blank?

    total = 0

    # pick right datastructure
    values = list.respond_to?(:values) ? list.values : list

    values&.each do |entry|
      amount = entry.send(method)
      amount = 0 if amount.blank?
      # treat all values as floats
      total += amount.to_f
      # removes trailing zeros from sum values
      total = total.to_i if total == total.to_i
    end
    total
  end

  # Works out the total sum of some values list/hash of this model.
  # In the code, some places it is unnecessarily need to create object just to call this method
  # hence split this method so that it is called using both object or using class @see sum_of_values_from_list
  def sum_from_values(list, method)
    FLApplicationRecord.sum_of_values_from_list(list, method)
  end
end
