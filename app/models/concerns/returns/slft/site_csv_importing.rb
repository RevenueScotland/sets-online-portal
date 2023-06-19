# frozen_string_literal: true

module Returns
  module Slft
    # Adds Import functionality to the Sites model
    module SiteCsvImporting
      extend ActiveSupport::Concern

      # Loads the CSV file into an array of rows, which are themselves arrays of data.
      # @param resource_item [Object] A resource item that represents the CSV file to be imported, any errors
      #   at a file level (can't open file, not a well formed CSV file) will be added to this resource_item
      # return [Array] array of imported data
      def import_waste_csv_data(resource_item)
        imported_wastes = csv_import resource_item, Returns::Slft::Waste
        any_errors = move_errors_into_site(imported_wastes)
        if any_errors
          # Mark the resource item as having errors
          errors.add(:base, :reimport_file)
        else
          copy_import_into_site(imported_wastes)
        end
      end

      private

      # moves any errors on the imported wastes into the site as the wastes will be
      # disregarded if there are errors
      # @param imported_wastes [Array] The imported wastes
      # @return [Boolean] were there any errors
      def move_errors_into_site(imported_wastes)
        any_errors = false
        imported_wastes.each do |waste|
          next if waste.errors.none?

          move_single_waste_errors_into_site(waste)
          any_errors = true
        end
        any_errors
      end

      # Copies the errors from a single wast item onto this site
      # @param waste [Object] The imported waste
      def move_single_waste_errors_into_site(waste)
        errors.add(:base, :import_row_error, description: waste.ewc_code_and_description,
                                             count: waste.errors.full_messages.count,
                                             messages: waste.errors.full_messages.join(', '))
      end

      # Copy the imported wastes into the site
      def copy_import_into_site(imported_wastes)
        imported_wastes.each { |w| wastes[w.uuid] = w }
      end
    end
  end
end
