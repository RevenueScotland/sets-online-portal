# frozen_string_literal: true

module ReferenceData
  # Represents a CV item and provides cached, filtered access to back office Code-Value lists
  # (eg configurations, lists of data etc).
  # The complete list of reference values is long, so they are retrieved and cached.
  # The lists are grouped by DomainCode, ServiceCode and Workplace code.
  # @see BackOfficeDataCaching#lookup (and similar methods) for how to call this class.
  class ReferenceValue < SystemParameter
    # additional fields
    attr_accessor :default, :sequence

    # override the sort sequence to be the provided sequence if present
    def sort_key
      # Make sure sequence is at least 6 long to maintain numeric sorting
      @sequence&.rjust(6, '0') || @code
    end

    # Create a new instance of this class using the back office data given
    # @param data [Hash] data from the back office response
    # @note returns [Object] a new instance
    private_class_method def self.make_object(data)
      ReferenceValue.new(code: data[:code], value: data[:name], default: data[:default], sequence: data[:sequence])
    end

    # Calls the correct service and specifies where the results are in the response body
    private_class_method def self.back_office_data
      lookup_back_office_data(:get_reference_values, :reference_values)
    end

    # @!method self.application_values(existing_values)
    # CV lists which we need for the application but which don't exist in the back office.
    # @param existing_values [Hash] the existing values in case we need to reference them
    # @return [Hash] a hash of objects needed for the application
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    private_class_method def self.application_values(existing_values)
      output = {}
      # example code :
      # output[composite_key] = { 'code' => System_Parameter.new(code: 'code', value: 'value') }
      # or for multiple codes under the same composite key :
      # app_codes = { 'Y' => ReferenceValue.new(code: 'Y', value: 'Current') }
      # output[composite_key('domain', 'service', 'workplace')] = app_codes
      # app_codes = { 'Y' => ReferenceValue.new(code: 'Y', value: 'Current'),
      #               'N' => ReferenceValue.new(code: 'N', value: 'Inactive') }
      output[composite_key('CURRENT_INACTIVE', 'SYS', 'RSTU')] = {
        'Y' => ReferenceValue.new(code: 'Y', value: 'Current', sequence: '10'),
        'N' => ReferenceValue.new(code: 'N', value: 'Inactive', sequence: '20')
      }
      output[composite_key('DIRECTION', 'SYS', 'RSTU')] = {
        'O' => ReferenceValue.new(code: 'O', value: 'Received'),
        'I' => ReferenceValue.new(code: 'I', value: 'Sent')
      }
      output[composite_key('RETURN_STATUS', 'SYS', 'RSTU')] = {
        'L' => ReferenceValue.new(code: 'L', value: 'Filed'),
        'D' => ReferenceValue.new(code: 'D', value: 'Draft'),
        'Y' => ReferenceValue.new(code: 'Y', value: 'Disregarded')
      }
      output[composite_key('BUYER TYPES', 'SYS', 'RSTU')] = {
        'PRIVATE' => ReferenceValue.new(code: 'PRIVATE', value: 'A private individual', sequence: '10'),
        'REG_COM' => ReferenceValue.new(code: 'REG_COM', value: 'An organisation registered with Companies House',
                                        sequence: '20'),
        'OTHERORG' => ReferenceValue.new(code: 'OTHERORG', value: 'An other organisation', sequence: '30')
      }
      # merge the two EWC hashes into one
      output[composite_key('EWC_LIST', 'SLFT', 'RSTU')] = merge_ewc_codes(existing_values)

      output
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # Merge the two EWC lists together and sort
    # @return [hash] sorted EWC reference data codes list
    private_class_method def self.merge_ewc_codes(existing_values)
      haz = existing_values[composite_key('EWCHAZARDOUS', 'SLFT', 'RSTU')]
      non = existing_values[composite_key('EWCNONHAZARDOUS', 'SLFT', 'RSTU')]
      haz.merge!(non)
    end
  end
end
