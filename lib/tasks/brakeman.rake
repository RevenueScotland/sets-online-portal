# frozen_string_literal: true

# Add tasks to run brakeman in development

namespace :brakeman do
  desc 'Run Brakeman with standard options'
  task :run, :output_files do |_t, args|
    require 'brakeman'

    files = args[:output_files].split if args[:output_files]
    tracker = Brakeman.run app_path: '.', output_files: files, quiet: true,
                           run_all_checks: true, min_confidence: 2, skip_checks: ['CheckForceSSL']
    puts(tracker.report)
  end

  desc 'Run Brakeman to regenerate the ignore file'
  task :generate_ignore, :output_files do |_t, args|
    require 'brakeman'

    files = args[:output_files].split if args[:output_files]
    tracker = Brakeman.run app_path: '.', output_files: files, quiet: true, interactive_ignore: true,
                           run_all_checks: true, min_confidence: 2, skip_checks: ['CheckForceSSL']
    puts(tracker.report)
  end
end

desc 'Run Brakeman with standard options'
task :brakeman do
  Rake::Task['brakeman:run'].invoke
end
