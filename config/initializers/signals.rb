# frozen_string_literal: true

unless Gem.win_platform?
  # on trapping SIGTSTP to change logging to debug
  trap('SIGTSTP') do
    Rails.logger.level = Logger::DEBUG
  end

  # on trapping SIGCONT to change logging to the RAILS_LOG_LEVEL
  # if present, otherwise default back to the configuration level
  trap('SIGCONT') do
    Rails.logger.level = ActiveSupport::Logger.const_get(if ENV['RAILS_LOG_LEVEL'].present?
                                                           ENV['RAILS_LOG_LEVEL'].upcase
                                                         else
                                                           Rails.configuration.log_level.to_s.upcase
                                                         end)
  end
end
