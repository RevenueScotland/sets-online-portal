# frozen_string_literal: true

# This is a helper for File storage
module FileStorageHelper
  # method delete files from configure path
  # @param num_of_days [Integer]  days old file need to removed
  # @return nil
  def self.delete_stored_files(num_of_days)
    Dir.chdir(file_storage_folder_path)
    Rails.logger.debug("Path of upload files #{file_storage_folder_path}")
    Dir['*'].select { |f| File.directory?(f) }.each do |dir_name|
      delete_files(dir_name, num_of_days)
    end
  end

  # file storage path in public folder
  # @param file_name [String]  name of the file
  # @return [String] file storage path
  def self.file_storage_path(file_name, username)
    dir = file_storage_folder_path
    if  dir.blank?
      Rails.logger.error("\file upload path is missing in environment file")
      raise Error::AppError.new('Path', 'upload path is missing')
    end
    dir += '/' + username
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    dir + '/' + file_name
  end

  # retrieve file storage path from property
  def self.file_storage_folder_path
    Rails.configuration.x.file_upload_path
  end

  # delete the files in given directory
  # @param dir_name [String]  file directory name whose file need to delete
  # @param num_of_days [Integer]  days old file need to delete
  # @return nil
  def self.delete_files(dir_name, num_of_days)
    Dir.chdir(file_storage_folder_path + '\\' + dir_name)
    Dir.glob('*').each do |file_name|
      Rails.logger.info("delete #{file_name} from #{dir_name}")
      File.delete(file_name) if File.mtime(file_name) < Time.new - num_of_days
    end
  end
end
