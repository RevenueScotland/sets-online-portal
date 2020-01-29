# frozen_string_literal: true

# Helper for print data tests, as the unit test is about testing the print_data functionality this helper
# helps the developer DRY up the unit tests by simply using the method print_data_to_compare to get the
# actual and expected results.
#
# Example of how to use this helper's methods in a test:
#   test 'print slft return amend pdf data' do
#     actual, expected = print_data_to_compare('slft_amend')
#     assert_equal(actual, expected, 'SLFT json strings do not match')
#   end
#
# There is a minimum of two .json files that are needed for the print_data unit tests and those are the
# 'model.json' and 'printdata.json' files. In some cases, we can also create the printdata_receipt.json.
# See print_test_path method for the path where the .json files are needed.
#
# Some methods in this helper could be overriden within the class of the unit test where this is included,
# if it needs to do a specific thing.
module PrintDataTestHelper
  FLApplicationRecord.class_eval do
    include Serializer
  end

  ReferenceDataLookup.class_eval do
    # Overriding the lookup_ref_data so that it can work with the data from the json format strings
    def lookup_ref_data(attribute)
      Rails.logger.debug("Model ref data lookup [OVERRIDE] for #{attribute}")
      # The stored data in the cached_ref_data are normally stored as symbols, however, storing it into json turns the
      # symbol into a string. So the attribute [Symbol] needs to be converted to a string.
      return @cached_ref_data[attribute.to_s] if initialize_ref_data && @cached_ref_data.key?(attribute.to_s)

      lookup_uncached_ref_data(attribute)
    end
  end

  ReferenceData::ReferenceDataCaching.class_eval do
    # Instead of getting the reference data from the backoffice we get it from the json file.
    def self.cached_values
      Rails.logger.debug("Getting [OVERRIDE] cache data for #{cache_key}")
      path = 'test/fixtures/print_data_test_data/'
      @cached_reference_value ||= Serializer.from_json_to_object(File.read(path + 'cached_reference_value.json'))
      @cached_tax_relief_type ||= Serializer.from_json_to_object(File.read(path + 'cached_tax_relief_type.json'))
      output = { 'ReferenceData::ReferenceValue' => @cached_reference_value,
                 'ReferenceData::TaxReliefType' => @cached_tax_relief_type }[cache_key]
      return output unless output.nil?

      normal_cached_values
    end

    # The old and normal cached_values method
    def self.normal_cached_values
      Rails.logger.debug("Getting cache data for #{cache_key}")
      Rails.cache.fetch(cache_key) do
        Rails.logger.debug("Cache miss for #{cache_key}")
        back_office_data
      end
    end
  end

  # As we're only testing the print data for this test, this is the generic step to get the
  # actual and expected results.
  #
  # Used for the assert_equals part of the unit test.
  #
  # @return [Array] two json values which are the actual and expected.
  def print_data_to_compare(folder, layout = :print_layout)
    model_json, printdata_json = model_and_printdata_json(folder, layout)
    readable_print_data_json(model_json, printdata_json, layout)
  end

  # Creates the print data json for both the model and the file.
  # @return [Array] two json values which are the print data of the model and file.
  # @note "printdata" associates with the file (and file name), and "print_data" associates with the output.
  def model_and_printdata_json(folder, layout)
    model_json = File.read(print_test_path + folder + '/model.json')
    printdata_name = { print_layout: '', print_layout_receipt: '_receipt' }[layout]
    # An example is: test/fixtures/print_data_test_data/lbtt_conveyance_a/printdata.json
    printdata_json = File.read(print_test_path + folder + "/printdata#{printdata_name}.json")

    [model_json, printdata_json]
  end

  # Used for making the json strings look pretty which makes it more readable and good for debugging.
  #
  # Depending on the layout, this will be used to get the print data in json format for both the
  # actual and expected data.
  # @return [Array] see the print_data_to_compare method.
  def readable_print_data_json(model_json, printdata_json, layout = :print_layout)
    object = insert_values(Serializer.from_json_to_object(model_json))

    object_print_data_json = human_readable_json(object.print_data(layout, print_data_options(object, layout)))
    expected_print_data_json = human_readable_json(printdata_json)

    [object_print_data_json, expected_print_data_json]
  end

  # Used for assigning values to an object's attribute(s) or changing it.
  # @note For the specific print_data_test this needs to be overriden if there are specific values needed.
  def insert_values(object)
    object
  end

  # Used as the hash options of the print_data method.
  # @note For the specific print_data_test this needs to be overriden if there are specific options needed.
  def print_data_options(_object, _layout)
    {}
  end

  # The print data path where the json files are stored
  def print_test_path
    'test/fixtures/print_data_test_data/'
  end

  # Add indentations to a json format string.
  # When debugging, this is very useful as it will show the developer exactly which lines
  # the mismatchings occur.
  def human_readable_json(json_string)
    JSON.pretty_generate(JSON.parse(json_string))
  end
end
