# frozen_string_literal: true

# Abstract base class for application jobs.
class ApplicationJob < ActiveJob::Base
  queue_as :default

  # Utility function that gets the interval period based on config or failsafe
  def self.get_interval(how_long, config, failsafe)
    return how_long unless how_long.nil? || how_long < 1.second
    return config unless config.nil? || config < 1.second

    failsafe
  end

  # Schedules the next run
  # @param how_long - when to run the next job, defaults to 0 (ie now)
  def self.schedule_next_run(how_long)
    Rails.logger.info("Scheduling next #{name} for #{how_long} seconds time")
    set(wait: how_long).perform_later
    how_long # return value to facilitate tests
  end

  # Runs the job.  Calls job_action on the implementing class and attempts to always call {#self.schedule_next_run}.
  def perform
    job_action
  rescue StandardError => e
    Rails.logger.error("Job exception\n#{e.full_message}")
  ensure
    self.class.schedule_next_run
  end
end
