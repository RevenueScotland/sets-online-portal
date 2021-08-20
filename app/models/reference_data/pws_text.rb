# frozen_string_literal: true

module ReferenceData
  # Represents Public Web Site (PWS) text details which are downloaded from the back office and cached.
  class PwsText < ReferenceDataCaching
    # additional fields
    attr_accessor :html_text, :text_code

    # the id function needs to return the primary key and is used to build the links
    # @return [String] the escaped URL-encoded code
    def to_param
      CGI.escape(text_code)
    end

    # @return [String] the contents of pws text
    def to_s
      # HTML is supported from the back office so allow this
      html_text.to_s.html_safe # rubocop:disable Rails/OutputSafety
    end

    # Override == to compare code data.
    # @param other [Object] the other object to compare to this one
    def ==(other)
      (other.instance_of?(self.class) &&
        html_text == other.html_text)
    end

    # Create a new instance of this class using the back office data given.
    # @param data [Hash] data from the back office response
    # @note return [Object] a new instance
    private_class_method def self.make_object(data)
      PwsText.new(domain_code: data[:pws_text_type_code], service_code: data[:service_code],
                  workplace_code: data[:workplace_code],
                  text_code: data[:pws_text_type_code],
                  html_text: UtilityHelper.standardize_elements(data[:pws_text]))
    end

    # Calls the correct service and specifies where the results are in the response body
    private_class_method def self.back_office_data
      lookup_back_office_data(:get_pws_text, :pws_text_details)
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
