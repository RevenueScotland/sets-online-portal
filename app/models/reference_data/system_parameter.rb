# frozen_string_literal: true

module ReferenceData
  # Represents a system setting downloaded from the back office.
  # The complete list of system parameter values may be any length, they are retrieved and cached.
  # The parameters are indexed by DomainCode, ServiceCode and Workplace code.
  # @see BackOfficeDataCaching#lookup (and similar methods) for how to call this class.
  class SystemParameter < ReferenceDataCaching
    # additional fields
    attr_accessor :code, :value

    # @return [String] the contents of code and value.
    # NB may be used in drop down lists so don't just change it!
    def to_s
      "#{code} #{value}"
    end

    # Override == to compare code and value data.
    # @param other [Object] the other object to compare to this one
    def ==(other)
      (other.instance_of?(self.class) &&
        code == other.code &&
        value == other.value)
    end

    # Returns a sort key used when getting the list method
    # overrides default in ReferenceDataCaching
    # @return [object] value suitable for sorting
    def sort_key
      @code
    end

    # Create a new instance of this class using the back office data given.
    # value will be set to the one with data ie data[:string_value], data[:numeric_value] or data[:date_value]
    # (checks in that order).
    # @param data [Hash] data from the back office response
    # @note return [Object] a new instance
    private_class_method def self.make_object(data)
      data_value = data[:string_value]
      data_value ||= data[:number_value]
      data_value ||= data[:date_value]

      # calls .to_s to convert from Nori::StringWithAttributes to String so it won't confuse us
      SystemParameter.new(domain_code: data[:domain_code], service_code: data[:service_code],
                          workplace_code: data[:workplace_code],
                          code: data[:code], value: data_value&.to_s)
    end

    # Calls the correct service and specifies where the results are in the response body
    private_class_method def self.back_office_data
      lookup_back_office_data(:get_system_parameters, :system_parameters)
    end

    # @!method self.application_values(_existing_values)
    # CV lists which we need for the application but which don't exist in the back office.
    # @param _existing_values [Hash] the existing values in case we need to reference them
    # @return [Hash] a hash of objects needed for the application
    private_class_method def self.application_values(_existing_values)
      output = {}
      # example code :
      # output[composite_key] = { 'code' => System_Parameter.new(code: 'code', value: 'value') }
      # or for multiple codes under the same composite key :
      # app_codes = { 'Y' => ReferenceValue.new(code: 'Y', value: 'Current') }
      # output[composite_key('domain', 'service', 'workplace')] = app_codes
      output
    end
  end
end
