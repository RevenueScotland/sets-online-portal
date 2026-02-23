# frozen_string_literal: true

# FileUploadHelper is a concern designed as a helper for file operation within the project.
#
# This concern contains 2 public method
# 1. content_type_allowlist: Provides the list of file types allowed to upload
# 2. supported_filename_format: This method provides the regex expression to check the invalid filename format.
module FileUploadHelper
  extend ActiveSupport::Concern

  # which file types are allowed to be uploaded
  def content_type_allowlist
    Rails.configuration.x.file_upload_content_type_allowlist.split(/\s*,\s*/)
  end

  # filename format allowed for upload
  def supported_filename_format
    Rails.configuration.x.file_upload_file_name_format_allowed
  end
end
