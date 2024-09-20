# frozen_string_literal: true

module ReferenceData
  # Represents Public Web Site (PWS) text details which are downloaded from the back office and cached.
  class PwsText < ReferenceDataCaching
    attr_accessor :text_code
    attr_reader :html_text, :page_title

    # the id function needs to return the primary key and is used to build the links
    # @return [String] the escaped URL-encoded code
    def to_param
      CGI.escape(text_code)
    end

    # @return [String] the contents of pws text
    delegate :to_s, to: :html_text

    # Setter to make sure html has correct tags
    # Also extracts the h1 to use as the page title
    def html_text=(value)
      h1_regex = %r{<h1>(?<title>.*)</h1>}
      @page_title = value.match(h1_regex)&.named_captures&.[]('title')
      value = value.gsub(h1_regex, '')
      @html_text = standardize_elements(value)
    end

    # Override == to compare code data.
    # @param other [Object] the other object to compare to this one
    def ==(other)
      other.instance_of?(self.class) &&
        html_text == other.html_text
    end

    # Create a new instance of this class using the back office data given.
    # @param data [Hash] data from the back office response
    # @note return [Object] a new instance
    private_class_method def self.make_object(data)
      PwsText.new(domain_code: data[:pws_text_type_code], service_code: data[:service_code],
                  workplace_code: data[:workplace_code],
                  text_code: data[:pws_text_type_code],
                  html_text: data[:pws_text])
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

    # Modifies the html text to give each elements the correct standard classes
    # @param html_text [HTML block element] contains the html which the correct classes will be added to.
    # @return [HTML block element] the elements modified to have the correct classes per element.
    def standardize_elements(html_text)
      standardize_table_elements(html_text)
        # Regex means to look for ("<a") + (zero or more characters thats not ">") + (">")
        .gsub(/<a[^>]*>/) { |link_tag| standardize_link_tag(link_tag) }
        .html_safe # rubocop:disable Rails/OutputSafety
    end

    # Modifies the html text to give each table elements the correct standard classes
    # @param html_text [HTML block element] see standardize_elements
    # @return [HTML block element] the elements modified to have the correct classes per element.
    def standardize_table_elements(html_text)
      html_text.gsub('<table>', '<table class="ds_table">')
    end

    # Modifies the link tag's properties to have the correct standard properties.
    # @param link_tag [HTML block tag] specific link tag to be modified.
    # @return [HTML block tag] the link tag modified so that it has the correct standard properties.
    def standardize_link_tag(link_tag)
      # Added to prevent the anchor tag's security issue of 'reverse tabnabbing'
      link_tag.gsub('target="_blank"', 'target="_blank" rel="noopener noreferrer"') unless link_tag.include?('rel=')
    end
  end
end
