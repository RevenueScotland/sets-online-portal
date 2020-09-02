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
# 'model.json' and 'printdata.json' files. In some cases, we can also create the print data_receipt.json.
# See PRINT_TEST_ method for the path where the .json files are needed.
#
# Some methods in this helper could be overridden within the class of the unit test where this is included,
# if it needs to do a specific thing.
module PrintDataTestHelper
  # The print data path where the json files are stored
  PRINT_TEST_PATH = 'test/fixtures/print_data_test_data/'

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
    model_json = File.read(PRINT_TEST_PATH + folder + '/model.json')
    printdata_name = { print_layout: '', print_layout_receipt: '_receipt' }[layout]
    # An example is: test/fixtures/print_data_test_data/lbtt_conveyance_a/printdata.json
    printdata_json = File.read(PRINT_TEST_PATH + folder + "/printdata#{printdata_name}.json")

    [model_json, printdata_json]
  end

  # Used for making the json strings look pretty which makes it more readable and good for debugging.
  #
  # Depending on the layout, this will be used to get the print data in json format for both the
  # actual and expected data.
  # @return [Array] see the print_data_to_compare method.
  def readable_print_data_json(model_json, printdata_json, layout = :print_layout)
    object = Serializer.from_json_to_object(model_json)

    object_print_data_json = human_readable_json(object.print_data(layout, print_data_options(object, layout)))
    expected_print_data_json = human_readable_json(printdata_json)

    [object_print_data_json, expected_print_data_json]
  end

  # Used as the hash options of the print_data method. When calling print data from an object we may send in
  # extra hash values derived elsewhere. This allows us to add them into the print data
  # @note For the specific print_data_test this needs to be overridden if there are specific options needed.
  def print_data_options(_object, _layout)
    {}
  end

  # Add indentations to a json format string.
  # When debugging, this is very useful as it will show the developer exactly which lines
  # the mis matchings occur.
  def human_readable_json(json_string)
    JSON.pretty_generate(JSON.parse(json_string))
  end
end
