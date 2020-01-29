# frozen_string_literal: true

# Download file/data to the user, via the browser, helper
module DownloadHelper
  extend ActiveSupport::Concern

  private

  # Sends a file held in the string object to the browser for download
  # @param attachment [Hash] attachment to send to the browser with the following keys:
  #            binary_data - the binary data to send to the browser
  #            file_type - the mime type of the file the binary data represents
  #            file_name - the filename
  # @param disposition [String] attachment for downloading the file, or inline for viewing the file
  def send_file_from_attachment(attachment, disposition = 'attachment')
    check_for_virus_in_attachment(attachment) unless Rails.configuration.x.no_download_file_virus_scanning

    send_data Base64.decode64(attachment[:binary_data]),
              type: attachment[:file_type], filename: attachment[:file_name],
              disposition: disposition
  end

  # Downloads a file held on the server at the given path to the users browser
  # @param path [String] path to the source file
  # @param options [Hash] same options supported as send_file @see ActionController::Streaming.send_file
  def send_file_from_path(path, options = {})
    check_for_virus(path) unless Rails.configuration.x.no_download_file_virus_scanning

    send_file path, options
  end

  # Checks if the attachment contains a virus - the binary data is saved to a file, the contents of the file
  # checked, and removed.
  # @param attachment [Hash] attachment to send to the browser @see send_attachment for details of the keys
  def check_for_virus_in_attachment(attachment)
    return unless attachment.key?(:binary_data) && attachment.key?(:file_name)

    tmp_filename = FileStorageHelper.file_temp_storage_path(:scanning, current_user.username, attachment[:file_name])
    File.open(tmp_filename, 'wb') { |file| file.write(Base64.decode64(attachment[:binary_data])) }
    check_for_virus tmp_filename
    File.delete tmp_filename
  end

  # Checks if the file on the file system contains a virus, if it does the file is removed, and error is logged
  # into the log files and an exception is thrown.
  # @param path [String] path to the source file
  def check_for_virus(path)
    return if Clamby.safe?(path)

    Rails.logger.error("Found virus in file #{path}")
    File.delete path
    raise Clamby::VirusDetected.new(message: "VIRUS DETECTED on #{Time.now}: #{path}")
  end
end
