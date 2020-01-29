# frozen_string_literal: true

# FileUploadHandler is a concern designed as a helper for file operation within the project.
#
# This concern contains 4 public method
# 1. handle_file_upload: which handles file upload and delete functionality
# 2. download_file: This method deletes files from the server also delete session cache file metadata.
# 3. initialize_fileupload_variables: This method initialize required variables for this functionality
# 4. file_upload_end : Clear cache file metadata
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
module FileUploadHandler # rubocop:disable ModuleLength
  extend ActiveSupport::Concern
  include SessionCacheHandler
  include DownloadHelper

  @resource_items = []
  # This is main method handle file upload and delete functionality
  # @param redirect_path [String] redirect path after uploading or deleting the file
  # @param overrides [Hash] hash of optional overrides with the following keys :
  #  :after_add  - pointer to method to run after adding file in cache
  #  :before_delete - pointer to method to run before deleting file
  #  :post_upload_process - pointer to a method to run before adding to perform any post upload processing
  # @return [Boolean] return true if file add or delete operation perform successfully
  def handle_file_upload(redirect_path, overrides = {})
    initialize_fileupload_variables
    return false unless params[:add_resource] || params[:delete_resource]

    if params[:add_resource]
      add_file(overrides)
    else
      delete_file(overrides)
    end
    # update data in cache
    session_cache_data_save(@resource_items, file_upload_session_key)
    render redirect_path unless redirect_path.nil?
  end

  # This method send file to browser.
  # It is only used to download a file which not yet uploaded to the back office to verify
  # if the upload file is correct or not
  # Note: To download the back-office saved file, need to write a separate download method.
  # @return [File] return file to download
  def download_file
    return send_file_to_browser if params[:doc_refno]

    Rails.logger.error("\file parameter is missing:")
    raise Error::AppError.new('download file', 'file not found')
  end

  private

  # This method upload file on temporary location on server
  # @param overrides [Hash] check handle_file_upload
  def add_file(overrides)
    return_status = add_resource_item(overrides)
    if return_status
      if overrides[:after_add]
        return_status, doc_refno = send(overrides[:after_add])
        @resource_item.doc_refno = doc_refno
      end
      save_attachment(@resource_item) if return_status
    end
    return_status
  end

  # This method will delete file from server and removed object from list.
  # It will run a pointer method if specified in overrides key before delete
  # @param overrides [Hash] check handle_file_upload
  def delete_file(overrides)
    success = if overrides[:before_delete]
                # handle delete event raise by parent controller
                send(overrides[:before_delete], params[:delete_resource])
              else
                true
              end

    delete_resource_item(params[:delete_resource]) if success

    success
  end

  # This method retrieves the file from the server base on a selected document from screen
  # and send it to the browser as 'attachment.'
  # @return [file] return file to browser  for download
  def send_file_to_browser
    initialize_fileupload_variables
    doc_refno = params[:doc_refno]
    resource_item = @resource_items.select { |u| u.doc_refno == doc_refno }
    file_path = FileStorageHelper.file_temp_storage_path(:upload, sub_directory, resource_item[0].file_name)
    send_file_from_path file_path,
                        filename: resource_item[0].original_filename,
                        disposition: 'attachment'
  end

  # Initialize file upload required variables
  # @return [Array][ResourceItem] array of resource items
  def initialize_fileupload_variables
    @supported_types = if respond_to?(:content_type_whitelist, true)
                         content_type_whitelist.map { |name| (I18n.t 'label_' + name) }.join(', ')
                       else
                         ''
                       end
    @supported_max_size_mb = expected_max_size
    session_key = file_upload_session_key
    @resource_items = session_cache_data_load(session_key) || []
    @resource_item = ResourceItem.new
    delete_old_error_resource_item
  end

  # Clear the resource items from the session, and local variable, whilst keeping the last uploaded file
  # i.e. @resource_item
  def clear_resource_items
    file_upload_end
    @resource_items = []
  end

  # This method remove old resource item containing validation error
  def delete_old_error_resource_item
    return unless !@resource_items.empty? && @resource_items.last.errors.any?

    resource_item = @resource_items.last
    @resource_items.delete(resource_item)
  end

  # Validate and add resource item object in Array list.
  # @param overrides [Hash] check handle_file_upload
  # @return [Boolean] return true if file add perform successfully
  def add_resource_item(overrides)
    return_status = true
    if params[:add_resource]
      resource_item = create_resource_item(params)
      return_status = resource_item.valid? expected_max_size, valid_content_types, valid_file_extensions
      return_status = send(overrides[:post_upload_process]) if overrides[:post_upload_process] && return_status
      @resource_items << resource_item if return_status
    end
    return_status
  end

  # Create resource item  object based on input params
  # @param params [Array] holding uploaded file detail
  # @return [Array] update list of resource items
  def create_resource_item(params)
    file_data = description = nil
    if params.key?(:resource_item)
      file_data = params[:resource_item][:file_data]
      description = params[:resource_item][:description]
    end
    @resource_item = ResourceItem.create(file_data, sub_directory, description)
  end

  # returns the username if current user is authorized
  # for unauthorized user this method will be overridden in the claim_payment_controller
  def sub_directory
    current_user.username || 'unauthenticated'
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

    File.open(FileStorageHelper.file_temp_storage_path(:upload, sub_directory, resource_item.file_name), 'wb') do |file|
      file.write(resource_item.file_data)
    end
  end

  # Delete file from server.
  # @param file_name [String]  name of the file to be deleted
  # @return nil
  def delete_attachment(file_name)
    file_path = FileStorageHelper.file_temp_storage_path(:upload, sub_directory, file_name)
    return File.delete(file_path)  if File.exist?(file_path)

    Rails.logger.error("File not found: ##{file_name}")
    raise Error::AppError.new('Delete attachment', 'file not found')
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
    respond_to?(:file_extension_whitelist, true) ? file_extension_whitelist : []
  end
end
