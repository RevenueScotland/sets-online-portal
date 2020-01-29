# frozen_string_literal: true

require 'test_helper'

# Test the scheduled job class.
# See https://edgeapi.rubyonrails.org/classes/ActiveJob/TestHelper.html#method-i-assert_enqueued_jobs
# for details on job testing.
class DeleteTempFilesJobTest < ActiveJob::TestCase
  # Overwrite raise an exception
  class TestExceptionJob < DeleteTempFilesJob
    private

    def job_action
      raise Error::AppError
    end
  end

  # test job
  class TestJob < DeleteTempFilesJob
    private

    def job_action
      # does nothing
    end
  end

  test 'exceptions do not stop next run being scheduled' do
    assert_enqueued_jobs(0, only: TestExceptionJob)
    TestExceptionJob.perform_now
    assert_enqueued_jobs(1, only: TestExceptionJob) # the scheduled job
  end

  # Checks the how_long calculation is done correctly and that a job is scheduled
  test 'schedule_next_run' do
    # run a test without an input parameter
    assert_enqueued_jobs(0, only: TestJob)
    how_long = TestJob.schedule_next_run
    assert_equal(Rails.configuration.x.scheduled_jobs.delete_temp_files_job_run_every, how_long)
    assert_enqueued_jobs(1, only: TestJob)

    schedule_test(50, 50, 2)
    schedule_test(0, Rails.configuration.x.scheduled_jobs.delete_temp_files_job_run_every, 3)
    schedule_test(nil, Rails.configuration.x.scheduled_jobs.delete_temp_files_job_run_every, 4)
  end

  # Run test with the given values
  def schedule_test(input, expected_how_long, expected_jobs_enqueued)
    actual_how_long = TestJob.schedule_next_run(input)
    assert_equal(expected_how_long, actual_how_long)
    assert_enqueued_jobs(expected_jobs_enqueued, only: TestJob)
  end
end
