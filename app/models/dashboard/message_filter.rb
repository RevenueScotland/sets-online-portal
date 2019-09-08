# frozen_string_literal: true

module Dashboard
  # Filter class used to control search of messages on the page, see also search
  class MessageFilter < BaseFilter
    attr_accessor :direction_code, :from_datetime, :to_datetime, :reference, :sent_by,
                  :subject_code, :unread_only, :selected_message_id, :smsg_original_refno

    validates :reference, length: { maximum: 30 }
    validate :all_dates_valid?

    # Define the ref data codes associated with the attributes to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def cached_ref_data_codes
      { subject_code: 'MESSAGE_SUBJECT.SYS.RSTU', direction_code: 'DIRECTION.SYS.RSTU' }
    end

    # Validation for each of the dates in the messages page to check if they're all in the correct format
    # and also check that the from date is before the to date
    def all_dates_valid?
      date_format_valid? :from_datetime unless from_datetime.blank?
      date_format_valid? :to_datetime unless to_datetime.blank?
      date_start_before_end? :from_datetime, :to_datetime
    end

    # Provides permitted filter request params
    def self.params(params)
      params.permit(dashboard_message_filter:
        %i[direction_code reference subject_code sent_by from_datetime to_datetime])[:dashboard_message_filter]
    end
  end
end
