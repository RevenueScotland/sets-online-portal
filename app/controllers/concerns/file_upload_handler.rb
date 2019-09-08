# frozen_string_literal: true

# File upload handlers
# Default it support all file types but to support specific  file type for upload ,
# will require to define method in controller called content_type_whitelist which should return
# array containing supporting files conten type
# for e.g. to support gif and jpeg file method should defined as per below
# def content_type_whitelist
#   ['image/gif', 'image/jpeg', image/jpg']
# end
module FileUploadHandler # rubocop:disable ModuleLength
  extend ActiveSupport::Concern
  include Wizard

  @resource_items = []
  # handle file upload and delete functionality
  # @param redirect_path [String] redirect path after uploading or deleting the file
  # @param overrides [Hash] hash of optional overrides with the following keys :
  #  :after_add_resource  - pointer to method to run after adding file
  #  :after_delete_resource - pointer to method to run after deleting file
  # @return [Boolean] return true if file add or delete operation perform successfully
  def handle_file_upload(redirect_path, parent_object, overrides = {})
    initialize_fileupload_variables
    return false unless params[:add_resource] || params[:delete_resource]

    return_status = add_resource_items

    merge_associated_file_upload_error_messages(parent_object) unless return_status
    # handle add event raise by parent controller
    handle_file_add_event(overrides) if return_status

    # handle delete event raise by parent controller
    handle_file_delete_event(overrides)

    # update data in cache
    wizard_save(@resource_items)
    render redirect_path
  end

  # file download functionality
  # @return [File] return file to download
  def download_file
    return handle_file_download if params[:file]

    Rails.logger.error("\file parameter is missing:")
    raise Error::AppError.new('download file', 'file not found')
  end

  private

  # call method after adding file
  # @param overrides [Hash] check handle_file_upload
  def handle_file_add_event(overrides)
    return true unless params[:add_resource]

    success = true
    if overrides[:after_add_resource]
      success, doc_refno = send(overrides[:after_add_resource])
      @resource_item.doc_refno = doc_refno
    end
    save_attachment(@resource_item) if success
    success
  end

  # call method after delete file
  # @param overrides [Hash] check handle_file_upload
  def handle_file_delete_event(overrides)
    return true unless params[:delete_resource]

    success = if overrides[:after_delete_resource]
                send(overrides[:after_delete_resource], params[:delete_resource])
              else
                true
              end

    delete_resource_item(params[:delete_resource]) if success

    success
  end

  # handle file download
  # @return [File] return file to download
  def handle_file_download
    initialize_fileupload_variables
    file_name = params[:file]
    resource_item = @resource_items.select { |u| u.file_name == file_name }
    send_file FileStorageHelper.file_storage_path(file_name, current_user.username),
              filename: resource_item[0].original_filename,
              disposition: 'attachment'
  end

  # Initialize file upload required variables
  # @return [Array][ResourceItem] array of resource items
  def initialize_fileupload_variables
    @supported_types = if defined?(content_type_whitelist)
                         content_type_whitelist.map { |name| (I18n.t 'label_' + name) }.join(', ')
                       else
                         ''
                       end
    @supported_max_size_mb = expected_max_size
    @resource_items = wizard_load || []
    @resource_item = ResourceItem.new
    handle_old_error_resource_item
  end

  # remove old resource item containing validation error
  def handle_old_error_resource_item
    return unless !@resource_items.empty? && @resource_items.last.errors.any?

    resource_item = @resource_items.last
    @resource_items.delete(resource_item)
  end

  # handle file save functionality
  # @return [Boolean] return true if file add perform successfully
  def add_resource_items
    return_status = true
    if params[:add_resource]
      return_status = add_resource_item(params)
      @resource_items << @resource_item if return_status
    end
    return_status
  end

  # add resource item to array
  # @return [Array] update list of resource items
  def add_resource_item(params)
    uploaded_io = params[:resource_item]
    description = params[:description]
    @resource_item = ResourceItem.create(uploaded_io, current_user.username, description)
    @resource_item.valid? expected_max_size, content_type_whitelist
  end

  # remove resource item for array
  # @return [Array] update list of resource items
  def delete_resource_item(doc_refno)
    resource_item = @resource_items.select { |u| u.doc_refno == doc_refno }
    delete_attachment(resource_item[0].file_name)
    @resource_items.delete(resource_item[0])
  end

  # save attachment
  # @param resource_item [Object]  resource item object with file details require to save file
  # @return nil
  def save_attachment(resource_item)
    return if resource_item.nil? || resource_item.data.nil? || resource_item.file_name.nil?

    File.open(FileStorageHelper.file_storage_path(resource_item.file_name, current_user.username), 'wb') do |file|
      file.write(resource_item.data)
    end
  end

  # delete attachment
  # @param file_name [String]  name of the file to be deleted
  # @return nil
  def delete_attachment(file_name)
    file_path = FileStorageHelper.file_storage_path(file_name, current_user.username)
    return File.delete(file_path)  if File.exist?(file_path)

    Rails.logger.error("file not found: ##{file_name}")
    raise Error::AppError.new('Delete attachment', 'file not found')
  end

  # retrieve file size limit from configuration
  # @return [String] size limit of upload file
  def expected_max_size
    Rails.configuration.x.file_upload_expected_max_size_mb
  end

  # merge associates class error in parent class
  # @return nil
  def merge_associated_file_upload_error_messages(parent_object)
    return if parent_object.nil?

    parent_object.errors.merge!(@resource_item.errors) unless @resource_item.nil? || @resource_item.errors.empty?
    parent_object
  end
end
