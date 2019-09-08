# frozen_string_literal: true

# Job to refresh the RefData cache.
# (ActiveJob logs the methods running.)
class RefreshRefDataJob < ApplicationJob
  # Just in case we don't have valid configuration, schedule jobs using this value
  FAILSAFE_SCHEDULE_TIME = 15.minutes

  # Configure and schedule the next job to run
  # @param how_long - when to run the next job, if not provided then set from config or failsafe
  def self.schedule_next_run(how_long = nil)
    # Set the interval for the run after this
    super(get_interval(how_long, Rails.configuration.x.scheduled_jobs.refresh_ref_data_every, FAILSAFE_SCHEDULE_TIME))
  end

  private

  # This method is what the job is set up to actually do.
  # Calls {ReferenceData::ReferenceValue.refresh_cache!} to update cache
  def job_action
    ReferenceData::ReferenceValue.refresh_cache!
  end
end
