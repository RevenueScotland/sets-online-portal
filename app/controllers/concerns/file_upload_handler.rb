# frozen_string_literal: true

# FileUploadHandler is a concern designed as a helper for file operation within the project.
#
# This concern contains 4 public method
# 1. handle_file_upload: which handles file upload and delete functionality, normally this should be enough on its own
# 2. download_file: This method deletes files from the server also delete session cache file metadata.
# 4. clear_resource_items : Clears the resource items and cache file metadata
#
# It stores file metadata in a session cache to maintain a state of the file when the page gets submitted or refreshed.
# @see "SessionCacheHandler" for details.
#
# How it works:
# 1. Store file in resource_item object @see ResourceItem
# 2. Validate resource_item object :
#  Along with basic validation, you can configure though application.rb file :
#  i) config.x.file_upload_content_type_whitelist
#     Default is to support all file types, to support a specific file type you need to overwrite a
#     #content_type_whitelist method which should return an array containing supporting files content type.
#     @example to support gif and jpeg file method defined as per below
#
#     def content_type_whitelist
#       ['image/gif', 'image/jpeg', image/jpg']
#     end
#
#  ii) config.x.file_upload_expected_max_size_mb - You can limit upload file size using this key
#
# for other validation configurations refer to the ResourceItem class.
#
# 3. On on successful validation it stores the file in a temporary folder for each login user based on their username.
#    If the session is unauthenticated then the calling controller should override the sub_directory function to specify
#    an alternative. The sub_directory function is held in the download_helper concern as it is shared with this concern
# 4. The file is renamed with a UUID before saving so that filename is unique inside the folder.
# 5. File upload path can be configured using "config.x.temp_folder" key.
#    E.g. :
#    Configure the temporary folder path is  "c:\data\ ".
#    When "temp.user" user upload file.
#    All the uploaded file by this user stored under the folder c:\data\upload\temp.user\
# 6. It store list of resource_item in session cache.
# 7. To upload the file to back office you need to provide method pointer by override method "after_add"
#    @example
#    handle_file_upload('confirmation', after_add: :add_document)
#
#    @see #handle_file_upload method for more details.
#
# Flow how file deletion works
# 1. Pass the document id using query parameter based on which it find document name from list of
#    resource_item which are saved in session cache.
# 2. Delete the file from the list and from server.
# 3. To delete the file to back office you need to provide method pointer by override method "before_delete"
#    @example
#    handle_file_upload('confirmation',before_delete: :delete_document)
#
# There is separate job called DeleteAttachmentFilesJob which deletes those all the uploaded files from the server.
module FileUploadHandler # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include SessionCacheHandler
  include DownloadHelper

  @resource_items = []
  # This is main method handle file upload and delete functionality
  # @param redirect_path [String] redirect path after uploading or deleting the file, this is regardless of if they
  #   are successful or not. It is usually used to redirect back to the current page on load or delete
  # @param overrides [Hash] hash of optional overrides with the following keys :
  #  :before_add - pointer to method to run before saving the file to the disk, use this if you still want to
  #                view the file after load, otherwise you can use add processing
  #  :add_processing  - pointer to method to run instead of saving on disk (e.g. saving in the back office)
  #  :before_delete - pointer to method to run before deleting file from the disk  (e.g. deleting in the back office)
  #  :types - an array of file types to upload
  # @return [Boolean] return true if file processing was required
  def handle_file_upload(redirect_path, overrides = {})
    # Clear the cache if indicated but not for an add or delete
    clear_resource_items if overrides[:clear_cache]

    initialise_fileupload_variables

    # If adding files then the below will create entries in the resource_items_hash
    # from the requests parameters.
    add_or_delete_files(overrides)

    # Add or delete files will have created items in the hash if they were uploaded (or are missing)
    # We call again after validation to make sure we have all the expected file types in the list
    # so the screen shows the expected file types
    initialise_resource_items_hash(overrides)

    return false unless params[:add_resource] || params[:delete_resource]

    # update data in cache
    session_cache_data_save(@resource_items, file_upload_session_key)

    render redirect_path unless redirect_path.nil?
    true
  end

  # This method send file to browser.
  # It is only used to download a file which not yet uploaded to the back office to verify
  # if the upload file is correct or not
  # Note: To download the back-office saved file, need to write a separate download method.
  # @return [File] return file to download
  def download_file
    return send_file_to_browser if params[:doc_refno]

    Rails.logger.error('file parameter is missing:')
    raise Error::AppError.new('download file', 'file not found')
  end

  # Clear the resource items from the session, and local variable, whilst keeping the last uploaded file
  # @param force [Boolean] Force a clear even if processing and add or delete
  # i.e. @resource_item
  def clear_resource_items(force = true)
    return if !force && (params[:add_resource] || params[:delete_resource])

    file_upload_end
    @resource_items = []
  end

  private

  # This method handles add file(s) or deleting a file
  # @param overrides [Hash] check handle_file_upload
  def add_or_delete_files(overrides)
    if params[:add_resource]
      add_files(overrides)
    elsif params[:delete_resource]
      delete_file(overrides)
    end
  end

  # This method handles file uploads, multiple files may be uploaded in one go
  # The files are either stored locally for later processing and added to the model
  # OR you can specify a process to handle them directly via the add_files override
  # @param overrides [Hash] check handle_file_upload
  def add_files(overrides)
    create_resource_items(overrides).each do |resource_item|
      if resource_item.valid? expected_max_size, valid_content_types, valid_file_extensions
        add_valid_individual_file(overrides, resource_item)
      end
    end
  end

  # @see add_files
  # This method handles processing an individual file/resource_item
  # note that errors may have been added to the resource items
  # @param overrides [Hash] check handle_file_upload
  # @param resource_item [Object] process an individual file
  def add_valid_individual_file(overrides, resource_item)
    success = run_add_file_overrides(resource_item, overrides)
    # The routines run as part of the overrides may end up adding errors
    # so handle this or if the call failed
    return if !success || resource_item.errors.any?

    save_attachment(resource_item) unless overrides[:add_processing]
    @resource_items << resource_item
    # Clear the stored resource item
    @resource_items_hash[resource_item.type] = ResourceItem.new(type: resource_item.type)
  end

  # This method will delete file from server and removed object from list.
  # It will run a pointer method if specified in overrides key before delete
  # @param overrides [Hash] check handle_file_upload
  def delete_file(overrides)
    success = true
    # handle delete event raise by parent controller
    success = send(overrides[:before_delete], params[:delete_resource]) if overrides[:before_delete]

    delete_resource_item(params[:delete_resource]) if success
  end

  # This method retrieves the file from the server base on a selected document from screen
  # and send it to the browser as 'attachment.'
  # @return [file] return file to browser  for download
  def send_file_to_browser
    resource_items = session_cache_data_load(file_upload_session_key) || []
    doc_refno = params[:doc_refno]
    resource_item = resource_items.select { |u| u.doc_refno == doc_refno }
    file_path = FileStorageHelper.file_temp_storage_path(:upload, sub_directory, resource_item[0].file_name)
    send_file_from_path file_path,
                        filename: resource_item[0].original_filename,
                        disposition: 'attachment'
  end

  # Initialise file upload required variables
  # The resource items hash is more complex and is processed separately
  # @return [Array][ResourceItem] array of resource items
  def initialise_fileupload_variables
    @supported_types = if respond_to?(:content_type_whitelist, true)
                         # @see locales/defaults/en.yml to learn about where this is getting the translated texts from.
                         content_type_whitelist.map { |name| (I18n.t 'label_' + name) }.join(', ')
                       else
                         ''
                       end
    @supported_max_size_mb = expected_max_size

    @resource_items = session_cache_data_load(file_upload_session_key) || []
  end

  # Make sure we have the correct types in the resource items hash
  # They also need to be in the correct order (otherwise they can swap around on the screen)
  # @param overrides [Hash] hash of optional overrides with the following keys :
  #  :types - an array of file types to upload
  # @param check_resource_items [Boolean] Only create a blank resource item if not already loaded
  #   if set to true then an item is not created in the hash if it exists in the already loaded resource items
  # @return [Array][ResourceItem] array of resource items
  def initialise_resource_items_hash(overrides, check_resource_items = false)
    old_resource_items_hash = @resource_items_hash || {}
    @resource_items_hash = {}

    expected_file_types(overrides).each do |type|
      # Copy the resource item if it has just been created
      # Note this is cleared in the validation processing if it validates
      unless old_resource_items_hash[type].nil?
        @resource_items_hash[type] = old_resource_items_hash[type]
        next
      end
      # if we are in validation processing this type exists in the main list skip
      next if check_resource_items && @resource_items.any? { |r| r.type == type }

      # If we get here make sure we have a blank entry
      @resource_items_hash[type] = ResourceItem.new(type: type)
    end
  end

  # Runs the overrides as part of the save processing
  # @param resource_item [Object] the resource_item being processed, may be changed as part of processing
  # @param overrides [Hash] check handle_file_upload
  # @return [Boolean] return true if the file was added successfully
  def run_add_file_overrides(resource_item, overrides)
    success = true
    if overrides[:before_add]
      success, doc_refno = send(overrides[:before_add], resource_item)
      resource_item.doc_refno = doc_refno
    end
    if overrides[:add_processing]
      success, doc_refno = send(overrides[:add_processing], resource_item)
      resource_item.doc_refno = doc_refno
    end
    success
  end

  # Create resource item objects based on input params
  # As we may not get a resource item of a particular type if we are only loading a file
  # @param overrides [Hash] check handle_file_upload
  # @return [Array] update list of resource items
  def create_resource_items(overrides)
    # We need to clear the hash as if the previous attempt had one failed and one succeeded the successful file is still
    # in the hash and would get loaded to the resource item list again
    @resource_items_hash = {}
    if params.key?(:resource_item)
      params[:resource_item].each_pair do |type, object|
        type = type.to_sym
        @resource_items_hash[type] = ResourceItem.create(type, object[:file_data], sub_directory, object[:description])
      end
    end
    # The below line will add in any missing resource item types if we don't have one in the hash
    # i.e. the user loaded only one file, the true means don't create one if the file loaded previously
    # (and is in the resource items list)
    initialise_resource_items_hash(overrides, true)
    @resource_items_hash.values
  end

  # Remove files for server and list.
  # @return [Array] update list of resource items
  def delete_resource_item(doc_refno)
    resource_item = @resource_items.select { |u| u.doc_refno == doc_refno }
    delete_attachment(resource_item[0].file_name)
    @resource_items.delete(resource_item[0])
  end

  # Save file on server. saving path is configured using "config.x.temp_folder" key.
  # @param resource_item [Object]  resource item object with file details require to save file
  # @return nil
  def save_attachment(resource_item)
    return if resource_item.nil? || resource_item.file_data.nil? || resource_item.file_name.nil?

    File.open(FileStorageHelper.file_temp_storage_path(:upload, sub_directory, resource_item.file_name),
              'wb') do |file|
      file.write(resource_item.file_data)
    end
  end

  # Delete file from server, if file not found then continue
  # @param file_name [String]  name of the file to be deleted
  # @return nil
  def delete_attachment(file_name)
    file_path = FileStorageHelper.file_temp_storage_path(:upload, sub_directory, file_name)
    File.delete(file_path) if File.exist?(file_path)
  end

  # Retrieve file size limit from configuration
  # @return [String] size limit of upload file
  def expected_max_size
    Rails.configuration.x.file_upload_expected_max_size_mb
  end

  # Provides the key to access file uploads cache key in the user's _session_ [cookie] (@see #session_cache_key).
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  def file_upload_session_key(cache_index = self.class.name)
    "FILEUPLOAD_#{cache_index}"
  end

  # Cleans up file upload data.(@see SessionCacheHandler#clear_session_cache).
  # Fails safe, won't throw exceptions if the deletion is unsuccessful due to a StandardError.
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  def file_upload_end(cache_index = self.class.name)
    Rails.logger.debug('Clearing file session cache')
    session_key = file_upload_session_key(cache_index)
    clear_session_cache(session_key, cache_index)
  end

  # Returns a list of valid content types, and any aliases for the content types
  # i.e. CSV mime type should be text/csv, but with a machine with Excel on it, the
  # type would be application/vnd.ms-excel
  def valid_content_types
    content_type = respond_to?(:content_type_whitelist, true) ? content_type_whitelist : []
    content_type += alias_content_type if respond_to?(:alias_content_type, true)
    content_type
  end

  # Returns a list of valid file extensions. File extensions are only checked if the content type
  # sent by the browser to the application matches that defined in config.x.file_upload_unknown_content_type
  def valid_file_extensions
    # This uses the list of the content_type_whitelist and alias_content_type to translate it into texts.
    # @see locales/defaults/en.yml to learn about where this is getting the translated texts from, which is
    #   used as the whitelist of suffixes for file uploads.
    valid_content_types.map { |name| '.' + (I18n.t 'label_' + name) }
  end

  # Returns the list of file types (symbols) to load (e.g. proof of sale, proof of occupancy)
  # If non provided in the overrides returns an array with one item of :default
  # Note: The file type should not be confused with the content type
  # The file type details the type of document to be upload e.g. passport, driving license
  # The content type is the format of the file e.g. jpeg, png, doc etc
  # @param overrides [Hash] check handle_file_upload
  # @return [Array] the array of file types
  def expected_file_types(overrides)
    file_types = overrides[:types] || [:default]
    # make sure we return a symbol
    file_types.map!(&:to_sym)
  end
end
