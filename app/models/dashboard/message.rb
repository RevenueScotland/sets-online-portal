# frozen_string_literal: true

require 'base64'
# The secure communication is part of the Dashboard.
module Dashboard
  # Models a user objects, not including authentication, see User Session for that.
  # @note the attribute :selected is for highlighting the row of data from the table whose :selected
  #   is set to true, which is used for determing if that message is currently being viewed.
  class Message < FLApplicationRecord # rubocop:disable Metrics/ClassLength
    include Pagination
    attr_accessor :id, :created_datetime,
                  :party_refno, :sent_by, :reference, :title, :body,
                  :subject_code, :from, :selected,
                  :attachment, :additional_file, :document, :smsg_refno,
                  :original_smsg_refno, :direction, :wrk_refno, :created_date,
                  :srv_code, :created_by, :read_indicator, :subject_domain, :has_attachment,
                  :read_datetime, :attachments, :forename, :surname

    validates :reference, presence: true, length: { maximum: 255 }
    validates :title, presence: true, length: { maximum: 255 }
    validates :body, presence: true, length: { maximum: 4000 }
    validates :subject_code, presence: true

    # Getting the formatted full name of the user.
    # @return [String] the formatted full name of the user.
    def full_name
      [forename, surname].join(' ')
    end

    # The list of cached message codes
    def cached_ref_data_codes
      { subject_code: 'MESSAGE_SUBJECT.SYS.RSTU', direction: 'DIRECTION.SYS.RSTU' }
    end

    # Uses the subject code to and translates it to the description of the subject
    def subject_description
      lookup_ref_data_value(:subject_code)
    end

    # @!method self.list_paginated_messages(requested_by, page, filter = nil, num_rows)
    # Loads the list of messages according to filter (if there's filters applied or not) and creates the pagination.
    #
    # This is mainly used for creating a table of messages and the correct pagination.
    # @param requested_by [Object] the user who requested to get access for the specific set of data.
    # @param page [String] is the page number.
    # @param filter [Object] is the MessageFilter created and passed in, for filtering the messages.
    # @return [Array] there are two return values the Hash value of the of the messages and
    #   the pagination collection. So the return value is like [{<Message>}, <Pagination>]
    def self.list_paginated_messages(requested_by, page, filter = nil, num_rows = 10)
      return unless filter.nil? || filter.valid?

      pagination = Pagination.initialise_pagination(num_rows, page)
      back_office_pagination, secure_messages = list_messages(requested_by, pagination, filter)
      secure_message_filtered = secure_messages.values

      pagination = Pagination.paginate_back_office(pagination, back_office_pagination)
      [secure_message_filtered, pagination]
    end

    # @!method self.modify_attributes(secure_message,filter)
    # When the back office data is being extracted, this method set the specific attributes
    # with values depending on some of the data retrieved.
    # @param secure_message [Object] is the secure_message
    # @return [Array] the Hash value of the of the messages
    private_class_method def self.modify_attributes(secure_message, filter) # rubocop:disable Metrics/AbcSize, Lint/UnneededCopDisableDirective, Metrics/LineLength
      message = Message.new_from_fl(secure_message)
      message.id = message.smsg_refno
      message.has_attachment = boolean_to_yesno(message.has_attachment)
      message.read_indicator = if message.direction == 'I'
                                 I18n.t('.sent', scope: [i18n_scope, model_name.i18n_key])
                               else
                                 boolean_to_yesno(message.read_indicator)
                               end
      message.selected = message.smsg_refno == filter.selected_message_id
      message
    end

    # Checks whether a save can be done by checking the validations
    def save(requested_by)
      return false unless valid?

      save_messages(requested_by)
    end

    # Initialises a new message with the correct default attributes.
    #
    # This is used for creating a new message, whether it's a reply or just creating a new message.
    #
    # @param id [String] is the id related to the origin_id message that it came from if it is a reply message,
    #   if this param value is nil then that means the message initialised is a new message, if not then it's a
    #   reply message which would have some data carried over to some fields.
    # @return [Object] this returns an instance of Message with the some of the attributes filled in.
    def self.initialise_message(requested_by, id = nil, reference = nil)
      # @note reference is being passed on here, currently being used for the all_returns page
      #   when the "Message" link is clicked - should fill in the reference for New message page
      message = Message.new(reference: reference)
      # current_user.username gets the name as it is needed and not the User object
      message.created_by = requested_by.username
      message.party_refno = requested_by.party_refno # @account.company_name
      message.from = "#{message.party_refno} (#{message.sent_by})"
      unless id.nil? || !reference.nil?
        message = Message.find(id, requested_by)
        message.body = ''
      end
      message
    end

    # Finds a specific message linked to the party_refno of the user and updates the read to 'Y'.
    # This method is mainly used for when the user is viewing a specific message.
    # @param id [String] The id of the message to be shown
    # @param requested_by [String] The user who made a find request that the messages are linked to
    # @return [Object] an instance of a Message object with the correct matching message_id
    def self.find(id, requested_by) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      message = ''
      success = call_ok?(:get_secure_message_details, request_secure_message_details(requested_by, id)) do |response|
        break if response.blank?

        message = Message.new_from_fl(response)
        message.id = message.smsg_refno
        #        message.created_date = DateFormatting.to_display_datetime_format(message.created_date)
        message.has_attachment = boolean_to_yesno(message.has_attachment)
        message.read_indicator = if message.direction == 'I'
                                   I18n.t('.sent', scope: [i18n_scope, model_name.i18n_key])
                                 else
                                   boolean_to_yesno(message.read_indicator)
                                 end
      end
      message if success
    end

    # @!method self.list_messages(requested_by, pagination, filter)
    # Lists the messages that are related to the party_refno of the user that is logged in.
    # To get all the messages, there shouldn't be an origin_id passed as param value. This is used
    # to show all the messages in the index page of messages.
    #
    # To get all the messages that have the same origin_id then it must be passed as param value.
    # This is used to show all the messages related to the message that is shown in full details
    # of the specific message currently being viewed.
    #
    # @param requested_by [Object] the user who requests to get the list of their messages
    # @return [Hash] a hash of messages in this format {"1"=>#<Message...>, "2"=>#<Message...>, ...}.
    #   So it's in the format of { id : <Message>, ... }
    private_class_method def self.list_messages(requested_by, pagination, filter)
      secure_messages, pagination_secure_message = {}
      success = call_ok?(:list_secure_messages,
                         request_list_secure_messages(requested_by, pagination, filter)) do |response|
        break if response.blank?

        pagination_secure_message = response[:pagination]
        ServiceClient.iterate_element(response[:secure_messages]) do |secure_message|
          secure_messages[secure_message[:smsg_refno]] = modify_attributes(secure_message, filter)
        end
      end
      [pagination_secure_message, secure_messages] if success
    end

    # Do the save processing for secure messages
    def save_messages(requested_by)
      msg_refno = ''
      success = call_ok?(:secure_message_create, request_save(requested_by)) do |response|
        break if response.blank?

        msg_refno = response[:msg_refno]
      end
      [success, msg_refno]
    end

    # store individual document to backoffice
    def add_attachment(requested_by, document, smsg_refno)
      doc_refno = ''
      success = call_ok?(:add_attachment, request_add_attachment(requested_by, document, smsg_refno)) do |response|
        break if response.blank?

        doc_refno = response[:doc_refno]
      end
      [success, doc_refno]
    end

    # delete document from backoffice
    # @param requested_by [Object] the user who requested to get access for the specific set of data.
    # @param doc_refno [String] document reference number to be delete from backoffice
    # @return [Boolean] true if document delete successfully from backoffice else false
    def delete_attachment(requested_by, doc_refno)
      success = call_ok?(:delete_attachment, request_delete_attachment(requested_by, doc_refno))
      success
    end

    # retrieve document from backoffice
    # @param requested_by [Object] the user who requested to get access for the specific set of data.
    # @param attachment_refno [String] document reference number
    # @param attachment_type [String] document type
    # @return [Boolean] [Object] return file in binary format if success is true
    def self.retrieve_file_attachment(requested_by, attachment_refno, attachment_type)
      attachment = ''
      success = call_ok?(:get_attachment, request_get_attachment(requested_by, attachment_refno,
                                                                 attachment_type)) do |response|
        break if response.blank?

        attachment = response
      end
      [success, attachment]
    end

    # @!method self.secure_message_details_request(requested_by, id)
    # request to send backoffice to get secure message details
    # @return [Object] a hash suitable for use in a list secure messages request to the back office
    private_class_method def self.request_secure_message_details(requested_by, id)
      request_user(requested_by).merge!(SmsgRefno: id)
    end

    # @!method self.request_list_secure_messages(requested_by, pagination, message_filter, smsg_original_refno)
    # @return a hash suitable for use in a list secure messages request to the back office
    private_class_method def self.request_list_secure_messages(requested_by, pagination, message_filter)
      request = request_user(requested_by).merge!(WrkRefno: 1, SRVCode: 'SYS')
      request[:Pagination] = { 'ins1:StartRow' => pagination.start_row, 'ins1:NumRows' => pagination.num_rows }
      return request if message_filter.nil?

      request.merge!(request_list_secure_messages_filter(message_filter))
    end

    # @!method self.request_list_secure_messages_filter(message_filter)
    # @return a hash suitable for use in a list secure messages filter
    private_class_method def self.request_list_secure_messages_filter(message_filter)
      { SmsgOriginalRefno: message_filter.smsg_original_refno.to_s,
        SubjectCode: message_filter.subject_code.to_s,
        SearchUserName: message_filter.sent_by.to_s,
        Reference: message_filter.reference.to_s,
        Direction: translate_direction_code(message_filter.direction_code.to_s),
        UnreadOnly: message_filter.unread_only.to_s }.merge(request_date_filter(message_filter))
    end

    # @!method self.request_date_filter(message_filter)
    # @return a hash containing date values suitable for use in a list secure messages filter
    private_class_method def self.request_date_filter(message_filter)
      { FromDate: DateFormatting.to_xml_date_format(message_filter.from_datetime),
        ToDate: DateFormatting.to_xml_date_format(message_filter.to_datetime) }
    end

    # @!method self.translate_direction_code
    # @return a hash suitable for use in a list secure messages filter
    private_class_method def self.translate_direction_code(code)
      if code.to_s == 'I'
        'Inbound'
      elsif code.to_s == 'O'
        'Outbound'
      end
    end

    # @return a hash suitable for use in all message request
    # this is create specific for class where Username case is different
    private_class_method def self.request_user(requested_by)
      { ParRefno: requested_by.party_refno, Username: requested_by.username }
    end

    # @return a hash suitable for use in all message request
    def request_user_instance(requested_by)
      { ParRefno: requested_by.party_refno, UserName: requested_by.username }
    end

    # @return a hash suitable for use in store document request to the back office
    def request_document_create(document)
      { 'ins1:FileName': document.original_filename,
        'ins1:FileType': document.content_type,
        'ins1:Description': document.description,
        'ins1:BinaryData': Base64.encode64(document.data) }
    end

    # @return a hash suitable for use in a save request to the back office
    def request_save(requested_by)
      secure_message_create_request = { OriginalRefno: @original_smsg_refno,
                                        MsgSubject: { 'ins1:Subject': @subject_code,
                                                      'ins1:FrdDomain': 'MESSAGE_SUBJECT',
                                                      'ins1:WrkRefno': 1, 'ins1:SrvCode': 'SYS' },
                                        Title: @title, Body: @body, Reference: @reference }
      secure_message_create_request = request_user_instance(requested_by).merge!(secure_message_create_request)
      return secure_message_create_request if @attachment.nil?

      document_para = { Document: request_document_create(@attachment) }
      secure_message_create_request.merge!(document_para)
    end

    # @return a hash suitable for use in a add attachment to the back office
    def request_add_attachment(requested_by, document, smsg_refno)
      add_attachment_request = { SmsgRefno: smsg_refno }
      add_attachment_request = request_user_instance(requested_by).merge!(add_attachment_request)
      add_attachment_request.merge!(request_document_create(document))
    end

    # @return a hash suitable for use in a delete attachment to the back office
    def request_delete_attachment(requested_by, doc_refno)
      request_user_instance(requested_by).merge!(DocRefno: doc_refno.to_i)
    end

    # @return a hash suitable for use in a get attachment to the back office
    private_class_method def self.request_get_attachment(requested_by, attachment_ref_no, attachment_type)
      request_user(requested_by).merge!(AttachmentRefno: attachment_ref_no, AttachmentType: attachment_type)
    end

    private :request_add_attachment, :request_delete_attachment
  end
end
