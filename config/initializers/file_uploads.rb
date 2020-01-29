# frozen_string_literal: true

require 'fileutils'

# For each of the file testing regarding the upload, they need to be added here.
if Rails.env.test? && ENV['UNIT_TEST'].nil? && !ENV['TEST_FILE_UPLOAD_PATH'].nil?
  Rails.logger.info('Copying the files to the upload file folder')

  copy_from_path = Rails.root.join('test/fixtures/files/upload/')
  # On our local windows computer we have set this up with the directory separator as '\\'
  upload_path = Pathname.new(ENV['TEST_FILE_UPLOAD_PATH'])
  Rails.logger.debug("  Here is a list of files to be copied: #{Dir[File.join(copy_from_path, '*.*')].inspect}")
  Rails.logger.debug("  Attempting to copy files from #{copy_from_path.inspect} to #{upload_path.inspect}")
  # The IF-statement is to prevent us from copying files into our local windows computer.
  # This should always pass for the remote testing.
  if copy_from_path.to_s != upload_path.to_s.tr('\\', '/')
    # Copies the file into the destination folder
    FileUtils.cp_r(Dir[File.join(copy_from_path, '.')], upload_path)
    Rails.logger.debug('  File copy successful')
  end
end
