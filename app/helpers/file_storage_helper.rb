# frozen_string_literal: true

# This is a helper for File storage
module FileStorageHelper
  # method delete files from within the temporary directory
  # it will recursively delete the contents of directories
  # @param period [Integer] The age of the file (in seconds) before it can be deleted
  # @return nil
  def self.delete_stored_files(period)
    dir_name = Rails.configuration.x.temp_folder
    Rails.logger.debug("Path of files #{dir_name}")
    delete_files_in_directory(dir_name, period, delete_directory: false)
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

  # delete the files in given directory
  # @param dir_name [String]  file directory name whose file need to delete
  # @param period [Integer]  The seconds old the file needs to be
  # @param delete_directory [Boolean]  delete the directory if it is now empty
  # @return nil
  def self.delete_files_in_directory(dir_name, period, delete_directory: false)
    Rails.logger.info("Deleting files from directory #{dir_name} older than #{period} seconds")
    Dir.glob(File.join(dir_name, '*')).each do |file_name|
      delete_file_in_directory(file_name, period)
    end
    return unless delete_directory

    delete_empty_directory(dir_name)
  end

  # delete the file or recursively delete the content of the directory directory if it is such
  # @param file_name [String] the file or directory being processed
  # @param period [Integer]  The seconds old the file needs to be
  # @return nil
  def self.delete_file_in_directory(file_name, period)
    if File.directory?(file_name)
      delete_files_in_directory(file_name, period, delete_directory: true)
    else
      return unless File.mtime(file_name) < Time.new - period

      Rails.logger.info("Delete #{file_name}")
      File.delete(file_name)
    end
  end

  # delete the given directory if it is empty
  # @param dir_name [String]  file directory name to delete
  # @return nil
  def self.delete_empty_directory(dir_name)
    return unless Dir.glob(File.join(dir_name, '*')).empty?

    Rails.logger.info("Deleting empty directory #{dir_name}")
    Dir.delete(dir_name)
  end
end
