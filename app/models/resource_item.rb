# frozen_string_literal: true

# Class used to store upload resource details
class ResourceItem < FLApplicationRecord
  attr_accessor :original_filename, :file_name, :content_type, :description, :file_data, :uploaded_by, :upload_datetime,
                :doc_refno, :size, :type, :attachment_type, :file_type

  validates :description, length: { maximum: 200 }
  validates :original_filename, length: { maximum: 500 }
  validates :file_data, presence: true
  validate :file_size?
  validate :content_type?
  validate :filename_length_valid?

  # check if resource_item is valid
  # @param max_file_size [Integer] @see file_upload_expected_max_size_mb to find where this is being set.
  # @param content_type_allowlist [Array] contains strings of MIME types which will be used to match against
  #   the content_type of the file being validated.
  # @param file_extension_allowlist [Array] contains strings which is the conversion of the content_type_allowlist
  #   to the suffix equivalent, for example ".csv" and ".docx"
  def valid?(max_file_size, content_type_allowlist, file_extension_allowlist, max_filename_length)
    @max_file_size = max_file_size
    @content_type_allowlist = content_type_allowlist
    @file_extension_allowlist = file_extension_allowlist
    @max_filename_length = max_filename_length
    super()
  end

  # create new resource item object
  def self.create(type, file_data, username, description = nil)
    uuid = SecureRandom.uuid
    resource_item = ResourceItem.new
    from_uploaded_file_data resource_item, file_data
    resource_item.doc_refno = resource_item.file_name = uuid
    resource_item.uploaded_by = username
    resource_item.upload_datetime = DateTime.current
    resource_item.description = description
    resource_item.type = type
    Rails.logger.debug { "Creating Resource Item #{type} for file #{file_data&.original_filename}" }
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

  # Generates a temporary directory for storing a file, if necessary the directory is created
  # @param type [Symbol]  type of the file used to create a subdirectory
  # @param sub_directory [string]  a subdirectory to create, normally the username
  # @param file_name [String]  name of the file
  # @return [String] file storage path
  def self.file_temp_storage_path(type, sub_directory, file_name)
    dir_name = Rails.configuration.x.temp_folder
    if dir_name.blank?
      Rails.logger.error("Temp folder '#{dir_name}' is missing")
      raise Error::AppError.new('Path', 'Temp folder is missing')
    end
    dir_name = File.join(dir_name, type.to_s, sub_directory)
    FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)
    File.join(dir_name, file_name)
  end

  # Create a new instance based on a back office style hash for attachments
  # @param raw_hash [Hash] the hash from the back office for an individual attachment
  def self.convert_attachment_back_office_hash(raw_hash)
    # Create new instance
    ResourceItem.new_from_fl(raw_hash.transform_keys(attachment_refno: :doc_refno, attachment_type: :type))
  end

  private

  def filename_length_valid?
    return true if !defined?(@max_filename_length) || !@max_filename_length.to_i.positive? || @max_filename_length.nil?

    length_exceeded = (original_filename.length >= @max_filename_length.to_i)
    errors.add(:file_data, :invalid_filename, count: @max_filename_length) if length_exceeded
    true
  end

  # Validate the file size isn't too big
  def file_size?
    return true if !defined?(@max_file_size) || @max_file_size.nil? || @size.nil?
    return true if @size <= @max_file_size.megabytes

    errors.add(:file_data, :invalid_file_size, supported_max_size_mb: @max_file_size)
    false
  end

  # Validate the content type
  def content_type?
    return true if !defined?(@content_type_allowlist) || @content_type_allowlist.nil? || @content_type.nil?
    return true if Array(@content_type_allowlist).any? { |item| @content_type =~ /#{item}/ }

    return true if valid_file_extension?

    add_invalid_file_type_error
  end

  # Add an invalid file type error, with some additional logging
  def add_invalid_file_type_error
    Rails.logger.debug do
      "File upload content type incorrect - actual type was #{@content_type} " \
        "expected one of #{@content_type_allowlist}"
    end
    Rails.logger.debug do
      'or file content unknown and file extension did not match - actual extension was ' \
        "#{File.extname(@original_filename)} expected one of #{@file_extension_allowlist}"
    end
    errors.add(:file_data, :invalid_file_type)
    false
  end

  # Checks if the file extension is valid. This is only check if the content type is the unknown.
  def valid_file_extension?
    return false if @content_type != Rails.configuration.x.file_upload_unknown_content_type

    @file_extension_allowlist.include? File.extname(@original_filename).downcase
  end
end
