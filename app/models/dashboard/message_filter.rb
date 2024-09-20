# frozen_string_literal: true

module Dashboard
  # Filter class used to control search of messages on the page, see also search
  class MessageFilter < BaseFilter
    include AllMessageSubject

    # see AllMessageSubject for accessors for subject_code
    attr_accessor :direction_code, :from_datetime, :to_datetime, :reference, :sent_by,
                  :subject_domain, :wrk_refno, :srv_code,
                  :unread_only, :selected_message_smsg_refno, :smsg_original_refno, :sort_by

    validates :reference, length: { maximum: 30 }
    validates :sent_by, length: { maximum: 255 }
    validates :from_datetime, :to_datetime, custom_date: true
    validates :from_datetime, compare_date: { end_date_attr: :to_datetime }

    # Define the ref data codes associated with the attributes to be cached in this model
    # @return [Hash] <attribute> => <ref data composite key>
    def cached_ref_data_codes
      { subject_code: comp_key('MESSAGE_SUBJECT', 'SYS', 'RSTU'), direction_code: comp_key('DIRECTION', 'SYS', 'RSTU'),
        sort_by: comp_key('MESSAGE_SORT_TYPES', 'SYS', 'RSTU') }
    end

    # Provides permitted filter request params
    def self.params(params)
      params.fetch(:dashboard_message_filter, {}).permit(
        :direction_code, :reference, :subject_code, :subject_full_key_code,
        :sent_by, :from_datetime, :to_datetime, :sort_by
      )
    end

    # @return a hash suitable for use in a list secure messages filter
    def request_list_secure_messages_filter
      { SmsgOriginalRefno: @smsg_original_refno.to_s,
        SubjectCode: @subject_code,
        SRVCode: @srv_code,
        SearchUserName: @sent_by,
        Reference: @reference,
        Direction: direction_description,
        UnreadOnly: @unread_only.to_s,
        SortBy: @sort_by }.merge(request_date_filter)
    end

    # @return a hash containing date values suitable for use in a list secure messages filter
    def request_date_filter
      { FromDate: DateFormatting.to_xml_date_format(@from_datetime),
        ToDate: DateFormatting.to_xml_date_format(@to_datetime) }
    end

    private

    # @return a hash suitable for use in a list secure messages filter
    def direction_description
      case @direction_code.to_s
      when 'I'
        'Inbound'
      when 'O'
        'Outbound'
      end
    end
  end
end
