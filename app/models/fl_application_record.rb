# frozen_string_literal: true

# Base model for objects based on FL Calls
class FLApplicationRecord
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Translation
  include ServiceClient
  include ReferenceDataLookup
  include StripAttributes

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
  # You may need to change the attributes to match what is expected from the back office before calling this routine
  # @param attributes [Hash] The attributes to be applied to this model
  # @return [Object] a populated instance of this object
  def self.new_from_fl(attributes = {})
    object = new(attributes)
    object.new_record!(false)
    object
  end

  # Does this record already exist on the back office
  # return [Boolean] checks if the record already exists
  def persisted?
    !new_record
  end

  # This returns a list of any sub objects that have a rails
  # error object attached. You can optionally restrict it to
  # those that actually have errors
  # @param check_errors [Boolean] only include the object if errors are included
  # @return [Array] an array of hashes containing the object that respond to errors and an optional index
  def error_objects(check_errors: true)
    errs = []
    instance_variables.each do |var|
      obj = instance_variable_get(var)

      if obj.instance_of?(Array)
        # check if the object in the array responds to error and if so add to the return hash
        obj.each_with_index { |this_obj, i| add_error_object(errs, var, this_obj, check_errors, i) }
      else
        add_error_object(errs, var, obj, check_errors)
      end
    end
    errs
  end

  # This is used for converting the boolean values of true or false to 'yes' or 'no'.
  # Useful for converting bool before sending requests to the back office.
  # @return [String] 'yes' or 'no'
  private_class_method def self.boolean_to_yesno(bool)
    return 'yes' if [true, 'true'].include?(bool)

    'no'
  end

  # When data is loaded from the back office we sometimes need to derive Y/N based on if child data has been entered.
  #
  # For example where you have a yes no flag revealing another field or fields. If the other field is populated then
  # the flag should be Y, if the other field is not populated then this may be because the indicator was N or the user
  # has not yet been through the page. We look for later data to identify if the user has been through this page to
  # determine if the value is 'N' or nil
  # The back office may return 0 as a default when a value was not populated for numeric fields. Depending on the
  # field we may need to treat 0 as 'N' or as a 'Y'
  #
  # When checking later data items these may also be Y/N flags set by this routine so make sure you chain them in the
  # correct order to match the screen starting from the end of the wizard.
  #
  # @example
  #    lbtt[:business_ind] = derive_yes_no(value: lbtt[:sale_include_option],
  #                                        default_n: lbtt[:non_ads_reliefclaim_option_ind].present? )
  #
  # @example This is a numeric field so we treat 0 as N but not defaulting to N if nil
  #    slft[:slcf_yes_no] = derive_yes_no(value: slft[:slcf_contribution], default_n: false)
  #
  # @example This is a text field so we treat 0 as populated
  #    slft[:non_disposal_add_ind] = derive_yes_no(value: slft[:non_disposal_add_text])
  #
  # @param value [object] The value that sets the indicator to Y
  # @param treat_zero_as_n [Boolean] Return N if a value is zero (otherwise 0 is treated as present and will return Y)
  # @param default_n [Boolean] if true always return N when the value is not present, otherwise nil is returned
  # @return [String] Y/N/nil depending on the rules value and parameters
  private_class_method def self.derive_yes_no(value:, treat_zero_as_n: false, default_n: true)
    # The below returns N if the value is zero. As floating points are not precise and the value may be a float
    # we check for the difference between the value (as a float) and the level of inaccuracy we allow
    # (Float::Epsilon may not be enough
    # https://stackoverflow.com/questions/30216575/why-float-epsilon-and-not-zero)
    return 'N' if treat_zero_as_n && value.present? && value.to_f.abs < 0.00001 # allow 1 thousandth of 2dp
    return 'Y' if value.present?

    (default_n ? 'N' : nil)
  end

  # Used when converting back office data.  The hash we get is a representation of the XML the back office sends.
  # Often there's an extraneous tag and we want the data under it to be on the same level as the parent tag.
  # This method takes the data under a given key in the hash and moves it up a level in the data structure.
  # @example input { top: level, parent: { hello: 'world' } } output { top: level, hello: 'world' }
  # @param hash [Hash] the data structure representing back office data
  # @param key [Object] key in hash to delete, its child objects will be merged with hash
  private_class_method def self.move_to_root(hash, key)
    removed_section = hash.delete(key)
    hash.merge!(removed_section) unless removed_section.nil?
  end

  # Used when converting back office data.
  # The back office uses a YesNoType ('yes' or 'no') but our radio buttons use 'Y' or 'N'.
  # Convert the specified keys in the hash from yes/no to Y/N (ie can do many at the same time).
  # @param hash [Hash] the data structure representing back office data
  # @param keys [Array] list of keys to look at and convert
  private_class_method def self.yes_nos_to_yns(hash, keys)
    keys.each { |key| hash[key] = (hash[key].upcase == 'YES' ? 'Y' : 'N') unless hash[key].nil? }
  end

  # Used when converting back office data.
  # The back office can strip of leading 0s from e.g. 0.78 which causes an issue with 2dp validation and looks bad
  # Convert the specified keys in the hash from .78 to 0.78
  # @param hash [Hash] the data structure representing back office data
  # @param keys [Array] list of keys to look at and convert only send it numeric values!
  private_class_method def self.add_leading_zero(hash, keys)
    keys.each do |key|
      value = hash[key]
      # NOTE: that nil is not the same as 0
      value = "0#{value}" if !value.nil? && value.start_with?('.')
      hash[key] = value
    end
  end

  # Works out the total sum of some values list/hash of this model.
  # Note: This assumes all values are only needed to 2dp
  # @param list [Object] list or hash containing the objects which need summing
  # @param method [Method] method to call on each of the list entry objects (ie the variable to sum)
  # @param integer [Boolean] return an integer value
  def sum_from_values(list, method, integer: false)
    return 0 if list.blank?

    total = 0

    # pick right data structure
    values = list.respond_to?(:values) ? list.values : list

    values&.each do |entry|
      amount = entry.send(method)
      # treat all values as pence
      total += (amount.to_f * 100).to_i
    end
    total /= 100.0 # convert from pence
    # removes trailing zeros from sum values or truncates as integer
    total = total.to_i if total == total.to_i || integer
    total
  end

  # Used for creating conditional hash if the value is present
  # example when we have following condition in your request
  #   output['ins1:Reference'] = @return_reference unless @return_reference.blank?
  # need to replace with
  #  xml_element_if_present(output, 'ins1:Reference', @return_reference)
  # @param hash [Hash] the data structure representing back office data
  # @param key [Object] key in hash
  # @param value [Object] value assigned to hash
  # @return [Array] The  hash with the object
  def xml_element_if_present(hash, key, value)
    hash[key] = value if value.present?
  end

  private

  # Adds the error object details to the array
  # @param errs [Array] The array to be added to
  # @param obj [Object] The object
  # @param var [String] The name of the object, used to build the eventual link
  # @param check_errors [Boolean] only include the object if errors are included
  # @param ind [Integer] The index of the object in an array
  # @return [Array] The  hash with the object: and optionally an index:
  def add_error_object(errs, var, obj, check_errors, ind = nil)
    return errs unless obj.is_a?(ActiveModel::Model)
    return errs if check_errors && obj.errors.none?

    Rails.logger.debug { "    Adding #{var}-#{ind} to error objects" }
    errs << object_and_index_hash(obj, var, ind)
  end

  # Returns the hash representing and error object and if needed its index
  # @param obj [Object] The object
  # @param var [String] The name of the object, used to build the eventual link
  # @param ind [Integer] The index of the object in an array
  # @return [Hash] The  hash with the object: and optionally an index:
  def object_and_index_hash(obj, var, ind = nil)
    { object: obj, attribute: var, index: ind }
  end

  # Helpful method to convert yes ,no value as per backoffice format
  # @param selected_value [String] contain "Y" , "N" , null value
  # @return the value yes , no or null
  def convert_to_backoffice_yes_no_value(selected_value)
    return selected_value if selected_value.blank?

    selected_value == 'Y' ? 'yes' : 'no'
  end
end
