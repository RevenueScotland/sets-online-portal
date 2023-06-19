# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a table of resource items
  class ResourceItemTableComponent < ViewComponent::Base
    include DS::ComponentHelpers

    attr_reader :resource_items, :caption, :region_name, :id, :small_screen, :pagination_collection,
                :page_name, :format, :download_actions, :delete, :description

    # @param resource_items [Array] The array of resource_items
    # @param caption [String] The caption to use on the table
    # @param download_path [Symbol] The name of the download path used to download the file
    # @param download_extra_keys [Hash] A hash of extra keys that are used to build the path
    #   unless a value is passed these are assumed to be methods on the resource_item and populated
    #   from there. Doc_refno is always added
    # @param download_actions [Array<Symbol>] An array of actions the current user may have to have to download
    # @param description [Boolean] Show the description field
    # @param delete [Boolean] Show the delete option
    # @param id [String] The id of the table used for anchoring
    # @param small_screen [Symbol] How to display the table on a small screen
    # @param pagination_collection [Object] The pagination information used to render a pagination collection
    # @param page_name [String] The identifier used for paging the correct region on the page
    def initialize(resource_items:, caption:, id:, download_path: nil, download_extra_keys: {}, download_actions: nil, # rubocop:disable Metrics/MethodLength
                   delete: true, description: true, small_screen: nil, pagination_collection: nil, page_name: nil)
      super()

      @resource_items = resource_items
      @region_name = caption
      @id = id
      @caption = tag.h2(caption, class: 'ds_!_margin-bottom--0')
      @download_path = download_path
      @download_extra_keys = download_extra_keys
      @download_actions = download_actions
      @description = description
      @delete = delete
      @small_screen = small_screen
      @pagination_collection = pagination_collection
      @page_name = page_name
    end

    private

    # Returns the path for download either the standard download-file or
    # where a download path method has been provided it calls this for the given
    # resource item
    # @param resource_item [object] the current resource item
    # @return [string] the path to be used
    def derive_path(resource_item)
      # Standard path is download in the current controller
      return "download-file/?doc_refno=#{resource_item.doc_refno}" unless @download_path

      new_keys = { doc_refno: resource_item.doc_refno }
      @download_extra_keys.each_pair do |key, value|
        new_keys[key] = (value || resource_item.send(key))
      end
      send(@download_path, **new_keys)
    end

    delegate :can?, to: :helpers
  end
end
