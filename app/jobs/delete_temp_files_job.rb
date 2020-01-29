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
    FileStorageHelper.delete_stored_files(period)
  end
end
