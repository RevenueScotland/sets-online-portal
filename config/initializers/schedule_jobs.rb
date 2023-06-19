# frozen_string_literal: true

Rails.application.configure do
  # Start ActiveJobs
  config.after_initialize do
    offset = Rails.configuration.x.scheduled_jobs.job_offset
    if offset == 0.seconds
      Rails.logger.info { 'Jobs not started' }
    else
      Rails.logger.info { "Jobs starting with offset #{offset}" }

      # GetReferenceData/ReferenceValues refresh job
      RefreshRefDataJob.schedule_next_run(1.second)

      # getListSystemNotices refresh job
      RefreshSystemNoticeJob.schedule_next_run(2 * offset)

      # GetSystemParameters refresh job
      RefreshSystemParametersJob.schedule_next_run(3 * offset)

      # GetSystemParameters refresh job
      RefreshPwsTextJob.schedule_next_run(4 * offset)

      # Tax Relief Type refresh job
      RefreshTaxReliefTypeJob.schedule_next_run(5 * offset)

      # Delete the temporary files job
      DeleteTempFilesJob.schedule_next_run(6 * offset)
    end
  end
end
