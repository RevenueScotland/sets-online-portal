# frozen_string_literal: true

# Provides common code for CSV data import and data export
module CsvHelper
  extend ActiveSupport::Concern

  private

  # Loads the CSV file into an array of rows, which are themselves arrays of data.
  # @param resource_item [Object] A resource item that represents the CSV file to be imported, any errors
  #   at a file level (can't open file, not a well formed CSV file) will be added to this resource_item
  # @param model [Class] The type of object to import
  # @return [Array] The array of imported models
  def csv_import(resource_item, model)
    from_csv_data(CSV.parse(resource_item.file_data), model)
  rescue CSV::MalformedCSVError => e
    resource_item.errors.add(:file_data, :invalid_csv, details: e.message)
    []
  rescue Error::CsvImportError => e
    resource_item.errors.add(:file_data, e.message)
    []
  end

  # Exports an array of data into a CSV file. The first line of the file will contain the headers,
  # followed by the data
  # @param filename [String] the file path and name of the file to output the data to
  # @param model [Class] The type of object to export - supplied so the headers can be generated, even if
  #   the objects array is nil or empty.
  # @param objects [Array] the data to output.
  def csv_export(filename, model, objects)
    attributes = csv_attribute_list model
    CSV.open(filename, 'wb') do |csv|
      write_headers csv, model, attributes
      break if objects.blank?

      write_data csv, attributes, objects
    end
  end

  # Splits the CSV file into rows, and then calls import_csv_row to create the object from the row data
  # typically import_csv_row would be in the controller/model. If import_csv_row is not defined then this
  # method calls import_csv_row_for_model and it assumes no override processing is required. If the number of
  # rows that fails initial checking (basically number of columns per row = number of attributes to import), then
  # we fail fast, and don't import into the model, and don't do any model based validation
  # @param csv_data [Array] array of CSV data imported from the file, the first row is assumed to be the header row
  #   of the CSV file, and is ignored in all cases
  # @param model [Class] The type of object to import
  # @return [Array] The array of imported models
  def from_csv_data(csv_data, model)
    csv_data.shift
    attributes = csv_attribute_list model
    failure_percentage = Rails.configuration.x.slft_waste_file_upload_percent_invalid_reject
    validate_csv_data csv_data, model, attributes.count, failure_percentage
    import_csv_data csv_data, model, attributes
  end

  # Import the CSV data, using the supplied model, and list of attributes to import
  # @param csv_data [Array] array of CSV data imported from the file
  # @param model [Class] model class to import the data against
  # @param attributes [Array] array of attributes to import
  # @return [Array] The array of imported models
  def import_csv_data(csv_data, model, attributes)
    imported = []
    csv_data.each do |row|
      imported.push import_csv_row_for_model(model, attributes, row)
    end
    imported
  end

  # Using the supplied array of attributes, this method imports each item of the row into the model object and then
  # returns it. The CSV data order therefore needs to match the ordering in the csv_import_attribute_list/
  # attribute_list, and all attributes need to be included into the CSV file
  # @param model [Class] model class to import the data against
  # @param attributes [Array] array of attributes to import
  # @param row [String] A row of CSV data representing a line of model data
  # @return [Object] A model object initialised with the CSV data, and validated
  def import_csv_row_for_model(model, attributes, row)
    object = model.new
    col_index = 0
    attributes.each do |attr|
      object.send(:"#{attr}=", row[col_index])
      col_index += 1
    end
    object.send(:post_csv_import) if object.respond_to?(:post_csv_import, true)
    object.valid? attributes
    object
  end

  # Write headers to a CSV file based on the model and attributes supplied
  # @param csv [CSV] destination for the output
  # @param model [Class] the model of the data to generate the headers for
  # @param attributes [Array] array of attributes to use to generate the headers
  def write_headers(csv, model, attributes)
    headers = attributes.collect { |a| model.human_attribute_name(a) }
    csv << headers
  end

  # Write data to a CSV file based on the object and attributes supplied
  # @param csv [CSV] destination for the output
  # @param attributes [Array] array of attributes to use to generate the data
  # @param objects [Array] array of objects to export the data from
  def write_data(csv, attributes, objects)
    objects.each do |object|
      data = attributes.collect { |a| object.send(a) }
      csv << data
    end
  end

  # Get the list of attributes to import/export from the model supplied. Uses the model's csv_attribute_list
  # or attribute_list if csv_attribute_list isn't present on the model
  # @param model [Class] model class to import the data against
  # @return [Array] list of attributes to import
  def csv_attribute_list(model)
    if model.respond_to?(:csv_attribute_list)
      model.csv_attribute_list
    else
      model.attribute_list
    end
  end

  # Validate the CSV data imported simply based on the number of columns imported versus
  # the number of attributes to import. If the percentage number of failed rows is greater
  # then the threshold, then fail the import, by raising an exception
  # @param csv_data [Array] array of CSV data imported from the file
  # @param model [Class] model class to import the data against
  # @param attribute_count [Integer] the number of attributes/columns expected to import
  # @param failure_percentage [Integer] the limit of failed rows, as a percentage
  def validate_csv_data(csv_data, model, attribute_count, failure_percentage)
    limit = (csv_data.size * (failure_percentage / 100.0)).to_i
    failures = 0
    value = model.new.errors.generate_message(:base, :csv_too_many_errors, failure: failure_percentage)
    csv_data.each do |row|
      if row.size != attribute_count
        failures += 1
        raise Error::CsvImportError, value if failures > limit
      end
    end
  end
end
