# frozen_string_literal: true

# Job to refresh the tax relief type cache.
# (ActiveJob logs the methods running.)
# also this is 60 minutes the other is 15 minutes
# maybe create an CacheRefreshBaseJob or something?
class RefreshTaxReliefTypeJob < ApplicationJob
  # Just in case we don't have valid configuration, schedule jobs using this value
  FAILSAFE_SCHEDULE_TIME = 60.minutes

  # Configure and schedule the next job to run
  # @param how_long - when to run the next job, if not provided then set from config or failsafe
  def self.schedule_next_run(how_long = nil)
    # Set the interval for the run after this
    super(get_interval(how_long, Rails.configuration.x.scheduled_jobs.refresh_tax_relief_type_every,
                       FAILSAFE_SCHEDULE_TIME))
  end

  private

  # This method is what the job is set up to actually do.
  # Calls the {ReferenceData::TaxReliefType.refresh_cache!} to update cache
  def job_action
    ReferenceData::TaxReliefType.refresh_cache!
  end
end
