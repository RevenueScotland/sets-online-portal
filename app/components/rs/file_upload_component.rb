# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a file upload component. The file upload component can render one or more files "types" to upload,
  # depending on the hash provided, for each type it can also collect multiple files (although normally we only
  # collect one file of each type)
  #
  # You can also surround the file upload with a field set that contains more info, with a legend and optional hint.
  # To trigger this functionality provide the fieldset key
  # The legend is then derived as below
  # <fieldset key>:
  #    <type>:
  #       legend:
  #       hint:
  # hint is optional and if not provided then no hint is output
  #
  class FileUploadComponent < ViewComponent::Base
    attr_reader :builder, :resource_items_hash, :multiple, :control_hash,
                :description, :optional, :supported_file_types, :max_file_size_mb, :text

    include DS::FieldsFor
    include DS::ComponentHelpers
    # Needed for the resource item table
    include RS::ComponentHelpers

    # @param builder [Object] The current builder
    # @param resource_items_hash [Hash] a hash of resource items that need to be uploaded or have already been
    #   uploaded, may be one or multiple of different types
    # @param resource_items [Array] the current resource items being uploaded, for example a file with
    #   and error, each of which them has the embedded type
    # @param fieldset_key [String] If provided then the file field is wrapped in a field set
    # @param interpolations [String] These are provided to the hints and labels
    # @param multiple [Boolean] Can you load more than one file of each type
    # @param optional [Boolean] Is the file optional on the page, controls the prompts
    # @param description [Boolean] Get a description of the file
    # @param supported_file_types [Array] Array of supported file types
    # @param max_file_size_mb [Integer] the maximum size of file that can be uploaded
    def initialize(resource_items_hash:, resource_items:, builder: nil, fieldset_key: nil, interpolations: {}, # rubocop:disable  Metrics/MethodLength
                   multiple: false, optional: false, description: true,
                   supported_file_types: nil, max_file_size_mb: nil, max_uploads: nil,
                   button_label: nil, button_type: nil, hide_upload_section: false,
                   hide_uploaded_files_section: false)
      super()

      @builder = builder
      @resource_items_hash = resource_items_hash
      @resource_items = resource_items
      @multiple = multiple
      @description = description
      @optional = optional
      @supported_file_types = supported_file_types
      @max_file_size_mb = max_file_size_mb
      @fieldset_key = fieldset_key
      @interpolations = interpolations
      @control_hash = build_control_hash
      @max_uploads = max_uploads
      @button_label = button_label
      @button_type = button_type
      @hide_upload_section = hide_upload_section
      @hide_uploaded_files_section = hide_uploaded_files_section
    end

    private

    # Iterates through the hash to work out the details for each type
    #   - Does the file upload need to be shown
    #   - has it already been uploaded
    #   - Assigns the resource items to the correct type
    #
    # It also works out which is the last type to be uploaded so it can show
    # the upload button with the correct single or plural text
    def build_control_hash
      control_hash, upload_button_type, upload_count = process_resource_items
      if upload_button_type
        control_hash[upload_button_type][:button_label] =
          (upload_count > 1 ? '.add_resources' : '.add_resource')
      end
      control_hash[:hide_upload_section] = @hide_upload_section
      control_hash
    end

    # @see build_control_hash
    def process_resource_items
      control_hash = {}
      upload_button_type = nil
      upload_count = 0
      @resource_items_hash.each do |type, current_resource_item|
        control_hash[type] = type_hash(type, current_resource_item)
        next unless control_hash[type][:show_upload]

        upload_button_type = type
        upload_count += 1
      end
      [control_hash, upload_button_type, upload_count]
    end

    # Returns the hash for a given type
    # @param type [Symbol] the current type
    # @param current_resource_item [Object] Any current resource items for this type
    def type_hash(type, current_resource_item)
      resource_items = @resource_items.select { |resource_item| resource_item.type == type }
      # If multiple uploads are allowed always show upload option
      # or if not file uploaded or errors on the previous file
      show_upload = @multiple || resource_items.empty? || current_resource_item.errors.any?
      legend, hint = legend_and_hint(type)
      { show_upload: show_upload,
        legend: legend,
        hint: hint,
        resource_items: resource_items }
    end

    # sets the legend and hint text for this type based on the fieldset key
    def legend_and_hint(type)
      if @fieldset_key
        legend = I18n.t("#{@fieldset_key}.#{type}.legend", **@interpolations).html_safe
        hint = I18n.t("#{@fieldset_key}.#{type}.hint", default: '', **@interpolations).html_safe
      else
        legend = ''
        hint = ''
      end
      [legend, hint]
    end

    delegate :can?, to: :helpers
  end
end
