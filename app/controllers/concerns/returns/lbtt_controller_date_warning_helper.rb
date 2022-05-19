# frozen_string_literal: true

# Concerns for returns
module Returns
  # Helpers for the summary view that determine if a warning message should be shown based on
  # the relevant date or effective date is too far in the past or future
  # It relies on two back office parameters
  #  PORTAL_HISTORIC_DATE_RANGE
  #  PORTAL_FUTURE_DATE_RANGE
  # If these are set to nil or zero no warning is given
  module LbttControllerDateWarningHelper
    extend ActiveSupport::Concern

    included do
      helper_method :show_dates_warning?
      helper_method :dates_warning_text
    end

    # Should the warning about dates be shown on the page
    # @param lbtt_return [Object] The return being processed
    # @return [Boolean] True if the message should be shown
    def show_dates_warning?(lbtt_return)
      return false unless lbtt_return.convey? || lbtt_return.lease?
      return false if lbtt_return.amendment?

      date_in_future(lbtt_return.relevant_date) || date_in_past(lbtt_return.relevant_date) ||
        date_in_future(lbtt_return.effective_date) || date_in_past(lbtt_return.effective_date)
    end

    # Returns the appropriate message for the screen
    # @param lbtt_return [Object] The return being processed
    # @return [HTMLText] True if the message should be shown
    def dates_warning_text(lbtt_return)
      messages = []
      relevant_date_name = lbtt_return.class.human_attribute_name(:relevant_date)
      effective_date_name = lbtt_return.class.human_attribute_name(:effective_date)
      messages << date_message(relevant_date_name, lbtt_return.relevant_date)
      messages << date_message(effective_date_name, lbtt_return.effective_date)
      messages.compact_blank.join('<br/>').html_safe # rubocop:disable Rails/OutputSafety
    end

    private

    # Returns the date message for the given attribute and date
    # @param human_attribute_name [String] The name to be shown for the attribute
    # @param check_date [Date] The date to be checked
    # @return [String] The message (future or past warning) for this date
    def date_message(human_attribute_name, check_date)
      # Date can only be in future or past
      days_in_future = date_in_future(check_date)
      if days_in_future
        t('.date_in_future', attribute_name: human_attribute_name, count: days_in_future)
      else
        days_in_past = date_in_past(check_date)
        return unless days_in_past

        t('.date_in_past', attribute_name: human_attribute_name, count: days_in_past)

      end
    end

    # Returns the number of days in the future if the days are past or equal to the threshold
    # @param check_date [Date] The date to be checked
    # @return [Integer] The number of days in the future (nil if not past threshold)
    def date_in_future(check_date)
      return if check_date.blank?

      # Date retrieved from back office may already be date
      check_date = Date.parse(check_date) unless check_date.is_a?(Date)

      diff = (check_date - Time.zone.today).to_i
      diff if diff >= future_days_allowed && future_days_allowed.positive?
    end

    # Returns the number of days in the past if the days are past or equal to the threshold
    # @param check_date [Date] The date to be checked
    # @return [Integer] The number of days in the past (nil if not past threshold)
    def date_in_past(check_date)
      return if check_date.blank?

      # Date retrieved from back office may already be date
      check_date = Date.parse(check_date) unless check_date.is_a?(Date)

      diff = (Time.zone.today - check_date).to_i
      diff if diff >= days_ago_allowed && days_ago_allowed.positive?
    end

    # Returns the cached number of days in the past that is allowed
    # @return [Integer] The number of days ago that is allowed
    def days_ago_allowed
      @days_ago_allowed ||= ReferenceData::SystemParameter.lookup(
        'COMMON', 'LBTT', 'RSTU', safe_lookup: true
      )['PWS_WARN_PAST_DAYS']&.value.to_i || 0
    end

    # Returns the cached number of days in the future that is allowed
    # @return [Integer] The number of days in the future that is allowed
    def future_days_allowed
      @future_days_allowed ||= ReferenceData::SystemParameter.lookup(
        'COMMON', 'LBTT', 'RSTU', safe_lookup: true
      )['PWS_WARN_FUTURE_DAYS']&.value.to_i || 0
    end
  end
end
