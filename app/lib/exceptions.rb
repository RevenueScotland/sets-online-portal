# frozen_string_literal: true

# Custom exceptions for this application
module Exceptions
  # Exception raised when encountering an error importing a CSV file
  class CsvImportError < StandardError; end
end
