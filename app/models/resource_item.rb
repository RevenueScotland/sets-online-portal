# frozen_string_literal: true

# Class used to store resource details
class ResourceItem
  include ActiveModel::Model
  include ActiveModel::Translation

  attr_accessor :original_filename, :file_name, :content_type, :description, :data, :uploaded_by, :upload_datetime,
                :doc_refno, :size

  validates :description, length: { maximum: 200 }
  validates :original_filename, presence: true
  validate :file_size?
  validate :content_type?

  # check if resource_item is valid
  def valid?(max_file_size, content_type_whitelist)
    @max_file_size = max_file_size
    @content_type_whitelist = content_type_whitelist

    super()
  end

  # create new resource item object
  def self.create(uploaded_io, username, description = nil)
    uuid = SecureRandom.uuid
    resource_item = ResourceItem.new
    from_uploaded_io resource_item, uploaded_io
    resource_item.doc_refno = resource_item.file_name = uuid
    resource_item.uploaded_by = username
    resource_item.upload_datetime = DateTime.current
    resource_item.description = description
    resource_item
  end

  # set attributes based on the uploaded_io parameter
  def self.from_uploaded_io(resource_item, uploaded_io)
    return if uploaded_io.nil?

    resource_item.original_filename = uploaded_io.original_filename
    resource_item.content_type = uploaded_io.content_type
    resource_item.data = uploaded_io.read
    resource_item.size = uploaded_io.size
  end

  private

  # Validate the file size isn't too big
  def file_size?
    return true if !defined?(@max_file_size) || @max_file_size.nil? || @size.nil?
    return true if @size <= @max_file_size.megabytes

    errors.add(:original_filename, :invalid_file_size, supported_max_size_mb: @max_file_size)
    false
  end

  # Validate the content type
  def content_type?
    return true if !defined?(@content_type_whitelist) || @content_type_whitelist.nil? || @content_type.nil?
    return true if Array(@content_type_whitelist).any? { |item| @content_type =~ /#{item}/ }

    errors.add(:original_filename, :invalid_file_type)
    false
  end
end
