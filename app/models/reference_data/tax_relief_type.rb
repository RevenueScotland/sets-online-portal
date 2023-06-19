# frozen_string_literal: true

module ReferenceData
  # Represents Tax Relief Type which are downloaded from the back office and cached.
  class TaxReliefType < ReferenceDataCaching
    attr_accessor :code, :service, :description, :current_ind, :transaction_type, :transaction_service,
                  :transaction_work_ref_no, :type_class, :upper_limit, :full_relief_ind, :return_types

    # Get relief type from cache
    # @param return_type [String] filter criteria for return type
    # @param current_only [Boolean] if set means ony shown me current else show all
    # @param show_ads_reliefs [Boolean] if set means shown all relief types else show all but ads relief types
    # @return [Array] a list for all relief types
    def self.filtered_list(return_type, current_only: false, show_ads_reliefs: false)
      list('RELIEF_TYPES', 'LBTT', 'RSTU').select do |r|
        r.filter_relief(return_type, current_only: current_only, show_ads_reliefs: show_ads_reliefs)
      end
    end

    # Returns a sort key used when getting the list method
    # overrides default in ReferenceDataCaching
    # @return [object] value suitable for sorting
    def sort_key
      @description
    end

    # Returns a code used to index in the list method
    # overrides default in ReferenceDataCaching
    # @return [String] Value suitable for indexing
    def code_expanded
      return nil if @code.nil?

      "#{code}>$<#{auto_calculated?}>$<#{@type_class}"
    end

    # Split the auto code into tax relief type and auto calculated/ads flag
    def self.split_code_expanded(value)
      data = value.split('>$<')
      [data[0], data[1] == 'true', data[2]]
    end

    # Return indicator if relief claim amount auto calculated or not.
    def auto_calculated?
      @full_relief_ind == 'yes' || !@upper_limit.nil?
    end

    # Filter the relief based on the criteria passed
    # @param return_type [String] Return type to filter for
    # @param current_only [Boolean] if set means ony shown me current else show all
    # @param show_ads_reliefs [Boolean] if set means shown all relief types else show all but ads relief types
    # @return [Boolean] True if this is to be included
    def filter_relief(return_type, current_only: false, show_ads_reliefs: false)
      return false if current_only && @current_ind != 'yes'
      return false if @type_class == 'ADS' && show_ads_reliefs == false
      return false if !@return_types.nil? && @return_types.split(':').exclude?(return_type)

      true
    end

    # @!method self.back_office_data(service)
    # Gets relief types data from the back office
    # @note return list of tax relief types
    private_class_method def self.back_office_data
      lookup_back_office_data(:get_tax_relief_types, :relief_types)
    end

    # Create a new instance of this class using the back office data given.
    # value will be set to the one with data ie data[:string_value], data[:numeric_value] or data[:date_value]
    # (checks in that order).
    # @param data [Hash] data from the back office response
    # @note return [Object] a new instance
    private_class_method def self.make_object(data)
      TaxReliefType.new(domain_code: 'RELIEF_TYPES', service_code: data[:service],
                        workplace_code: 'RSTU',
                        code: data[:type], service: data[:service], description: data[:description],
                        current_ind: data[:current_ind], transaction_type: data[:transaction_type],
                        transaction_service: data[:transaction_service], return_types: data[:return_types],
                        transaction_work_ref_no: data[:transaction_work_ref_no], type_class: data[:class],
                        upper_limit: data[:upper_limit], full_relief_ind: data[:full_relief_ind])
    end

    # @!method self.application_values(_existing_values)
    # CV lists which we need for the application but which don't exist in the back office.
    # @param _existing_values [Hash] the existing values in case we need to reference them
    # @return [Hash] a hash of objects needed for the application
    private_class_method def self.application_values(_existing_values)
      {}
    end
  end
end
