# frozen_string_literal: true

# Job to refresh the public website text cache.
# (ActiveJob logs the methods running.)
# also this is 60 minutes the other is 15 minutes
# maybe create an CacheRefreshBaseJob or something?
class RefreshPwsTextJob < ApplicationJob
  # Just in case we don't have valid configuration, schedule jobs using this value
  FAILSAFE_SCHEDULE_TIME = 60.minutes

  # Configure and schedule the next job to run
  # @param how_long - when to run the next job, if not provided then set from config or failsafe
  def self.schedule_next_run(how_long = nil)
    # Set the interval for the run after this
    super(get_interval(how_long, Rails.configuration.x.scheduled_jobs.refresh_pws_text_every, FAILSAFE_SCHEDULE_TIME))
  end

  private

  # This method is what the job is set up to actually do.
  # Calls the {ReferenceData::PwsText.refresh_cache!} to update cache
  def job_action
    ReferenceData::PwsText.refresh_cache!
  end
end
