# frozen_string_literal: true

# Job to delete old uploaded files from server drive as per configuration
class DeleteTempFilesJob < ApplicationJob
  # Just in case we don't have valid configuration, schedule jobs using this value
  FAILSAFE_SCHEDULE_TIME = 15.minutes

  # Configure and schedule the next job to run
  # @param how_long - when to run the next job, if not provided then set from config or failsafe
  def self.schedule_next_run(how_long = nil)
    # Set the interval for the run after this
    super(get_interval(how_long, Rails.configuration.x.scheduled_jobs.delete_temp_files_job_run_every,
                       FAILSAFE_SCHEDULE_TIME))
  end

  private

  # This method is what the job is set up to actually do.
  def job_action
    period = Rails.configuration.x.scheduled_jobs.delete_temp_files_job_run_every
    delete_stored_files(period)
  end

  # method delete files from within the temporary directory
  # it will recursively delete the contents of directories
  # @param period [Integer] The age of the file (in seconds) before it can be deleted
  # @return nil
  def delete_stored_files(period)
    dir_name = Rails.configuration.x.temp_folder
    Rails.logger.debug { "Path of files #{dir_name}" }
    delete_files_in_directory(dir_name, period, delete_directory: false)
  end

  # delete the files in given directory
  # @param dir_name [String]  file directory name whose file need to delete
  # @param period [Integer]  The seconds old the file needs to be
  # @param delete_directory [Boolean]  delete the directory if it is now empty
  # @return nil
  def delete_files_in_directory(dir_name, period, delete_directory: false)
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
  def delete_file_in_directory(file_name, period)
    if File.directory?(file_name)
      delete_files_in_directory(file_name, period, delete_directory: true)
    else
      return unless File.mtime(file_name) < Time.zone.now - period

      Rails.logger.info("Delete #{file_name}")
      File.delete(file_name)
    end
  end

  # delete the given directory if it is empty
  # @param dir_name [String]  file directory name to delete
  # @return nil
  def delete_empty_directory(dir_name)
    return unless Dir.glob(File.join(dir_name, '*')).empty?

    Rails.logger.info("Deleting empty directory #{dir_name}")
    Dir.delete(dir_name)
  end
end
