# frozen_string_literal: true

# Class used to store upload resource details
class ResourceItem
  include ActiveModel::Model
  include ActiveModel::Translation

  attr_accessor :original_filename, :file_name, :content_type, :description, :file_data, :uploaded_by, :upload_datetime,
                :doc_refno, :size

  validates :description, length: { maximum: 200 }
  validates :original_filename, length: { maximum: 500 }
  validates :file_data, presence: true
  validate :file_size?
  validate :content_type?

  # check if resource_item is valid
  def valid?(max_file_size, content_type_whitelist, file_extension_whitelist)
    @max_file_size = max_file_size
    @content_type_whitelist = content_type_whitelist
    @file_extension_whitelist = file_extension_whitelist
    super()
  end

  # create new resource item object
  def self.create(file_data, username, description = nil)
    uuid = SecureRandom.uuid
    resource_item = ResourceItem.new
    from_uploaded_file_data resource_item, file_data
    resource_item.doc_refno = resource_item.file_name = uuid
    resource_item.uploaded_by = username
    resource_item.upload_datetime = DateTime.current
    resource_item.description = description
    resource_item
  end

  # set attributes based on the uploaded_io parameter
  def self.from_uploaded_file_data(resource_item, file_data)
    return if file_data.nil?

    resource_item.original_filename = file_data.original_filename
    resource_item.content_type = file_data.content_type
    resource_item.file_data = file_data.read
    resource_item.size = file_data.size
  end

  private

  # Validate the file size isn't too big
  def file_size?
    return true if !defined?(@max_file_size) || @max_file_size.nil? || @size.nil?
    return true if @size <= @max_file_size.megabytes

    errors.add(:file_data, :invalid_file_size, supported_max_size_mb: @max_file_size)
    false
  end

  # Validate the content type
  def content_type?
    return true if !defined?(@content_type_whitelist) || @content_type_whitelist.nil? || @content_type.nil?
    return true if Array(@content_type_whitelist).any? { |item| @content_type =~ /#{item}/ }

    return true if valid_file_extension?

    add_invalid_file_type_error
  end

  # Add an invalid file type error, with some additional logging
  def add_invalid_file_type_error
    Rails.logger.debug("File upload content type incorrect - actual type was #{@content_type}" \
                       " expected one of #{@content_type_whitelist}")
    Rails.logger.debug('or file content unknown and file extension did not match - actual extension was' \
                       " #{File.extname(@original_filename)} expected one of #{@file_extension_whitelist}")
    errors.add(:file_data, :invalid_file_type)
    false
  end

  # Checks if the file extension is valid. This is only check if the content type is the unknown.
  def valid_file_extension?
    false unless @content_type == Rails.configuration.x.file_upload_unknown_content_type
    false if @file_extension_whitelist.nil? || @file_extension_whitelist.empty?

    @file_extension_whitelist.include? File.extname(@original_filename).downcase
  end
end
