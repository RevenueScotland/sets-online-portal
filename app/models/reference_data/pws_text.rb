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
      html_text.to_s.html_safe
    end

    # Override == to compare code data.
    # @param other [Object] the other object to compare to this one
    def ==(other)
      (other.instance_of?(self.class) &&
        html_text == other.html_text)
    end

    # Modifies the html text to give each elements the correct standard classes
    def modify_elements
      @html_text.gsub!('<div>', '<div class="govuk-form-group">')
      @html_text.gsub!('<h1>', '<h1 class="govuk-heading-l">')
      @html_text.gsub!('<h2>', '<h2 class="govuk-heading-m">')
      @html_text.gsub!('<h3>', '<h3 class="govuk-heading-s">')
      @html_text.gsub!('<p>', '<p class="govuk-body">')
      @html_text.gsub!('<ul>', '<ul class="govuk-list govuk-list--bullet">')
      modify_table_elements
      self
    end

    # Modifies the html text to give each table elements the correct standard classes
    def modify_table_elements
      @html_text.gsub!('<table>', '<table class="govuk-table">')
      @html_text.gsub!('<thead>', '<thead class="govuk-table__head">')
      @html_text.gsub!('<tbody>', '<tbody class="govuk-table__body">')
      @html_text.gsub!('<th>', '<th class="govuk-table__header">')
      @html_text.gsub!('<tr>', '<tr class="govuk-table__row">')
      @html_text.gsub!('<td>', '<td class="govuk-table__cell">')
    end

    # Create a new instance of this class using the back office data given.
    # @param data [Hash] data from the back office response
    # @note return [Object] a new instance
    private_class_method def self.make_object(data)
      PwsText.new(html_text: data[:pws_text]).modify_elements
    end

    # Calls the correct service and specifies where the results are in the response body
    private_class_method def self.back_office_data
      lookup_back_office_data(:get_pws_text, :pws_text_details)
    end

    # Organise back-office response in the hash composite_key => pws_text object
    private_class_method def self.organise_results(element)
      output = {}
      ServiceClient.iterate_element(element) do |data|
        key = composite_key(data[:pws_text_type_code], data[:service_code], data[:workplace_code])
        # initialise the array ready for data if it doesn't exist already
        output[key] = {} unless output.key?(key)
        output[key] = make_object(data)
      end
      output
    end

    # @!method self.application_values(_existing_values)
    # CV lists which we need for the application but which don't exist in the back office.
    # @param _existing_values [Hash] the existing values in case we need to reference them
    # @return [Hash] a hash of objects needed for the application
    private_class_method def self.application_values(_existing_values)
      output = {}
      output
    end
  end
end
