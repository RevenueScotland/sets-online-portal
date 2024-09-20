# frozen_string_literal: true

require 'base64'
# The secure communication is part of the Dashboard.
module Dashboard
  # Models a user objects, not including authentication, see User Session for that.
  # @note the attribute :selected is for highlighting the row of data from the table whose :selected
  #   is set to true, which is used for determining if that message is currently being viewed.
  class Message < FLApplicationRecord # rubocop:disable Metrics/ClassLength
    include Pagination
    include AllMessageSubject

    # see AllMessageSubject for accessors for subject_code
    attr_accessor :created_datetime, :created_by,
                  :party_refno, :reference, :title, :body,
                  :selected,
                  :attachment, :document, :smsg_refno,
                  :original_smsg_refno, :direction, :wrk_refno, :created_date,
                  :srv_code, :read_indicator, :subject_domain, :has_attachment,
                  :read_datetime, :attachments, :forename, :surname, :status_update

    validates :reference, presence: true, length: { maximum: 30 }
    validates :title, presence: true, length: { maximum: 255 }
    validates :body, presence: true, length: { maximum: 4000 }
    validates :subject_code, presence: true

    # overrides the standard id parameters to smsg_refno
    def to_param
      @smsg_refno
    end

    # Getting the formatted full name of the user.
    # @return [String] the formatted full name of the user.
    def full_name
      [forename, surname].join(' ')
    end

    # The list of cached message codes
    def cached_ref_data_codes
      { subject_code: comp_key('MESSAGE_SUBJECT', @srv_code, 'RSTU'), direction: comp_key('DIRECTION', 'SYS', 'RSTU') }
    end

    # Uses the subject code to and translates it to the description of the subject
    def subject_description
      lookup_ref_data_value(:subject_code, @subject_code)
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

    # Checks whether a save can be done by checking the validations
    def save(requested_by)
      return false unless valid?

      save_messages(requested_by)
    end

    # Initialises a new message with the correct default attributes.
    #
    # This is used for creating a new message, whether it's a reply or just a new message.
    # If it's a reply then looks up some data from the original message.
    #
    # @param smsg_refno [String] is the smsg_refno related to the message that it came from if it is a reply message.
    #                    If this param value is nil then that means the message initialised is a new message
    # @param reference [String] If creating a new message the reference to be used
    # @return [Object] this returns an instance of Message with the some of the attributes filled in.
    def self.initialise_message(requested_by, smsg_refno = nil, reference = nil)
      if smsg_refno.nil?
        # @note reference is being passed on here, currently being used for the all_returns page
        #   when the "Message" link is clicked - should fill in the reference for New message page
        message = Message.new(reference: reference)
      else
        # Handle reply
        message = Message.find(smsg_refno, requested_by)
        message.body = ''
        message.new_record!(true)
      end
      # current_user.username gets the name as it is needed and not the User object
      message.created_by = requested_by.username
      message.party_refno = requested_by.party_refno
      message
    end

    # Finds a specific message linked to the party_refno of the user and updates the read to 'Y'
    # This method is mainly used for when the user is viewing a specific message.
    # @param smsg_refno [String] The internal reference of the message to be shown
    # @param requested_by [String] The user who made a find request that the messages are linked to
    # @return [Object] an instance of a Message object with the correct matching smsg_refno
    def self.find(smsg_refno, requested_by, mark_as_read = nil)
      message = ''
      success = call_ok?(:get_secure_message_details,
                         request_secure_message_details(requested_by, smsg_refno, mark_as_read)) do |response|
        break if response.blank?

        message = Message.new_from_fl(convert_back_office_hash(response.merge!(subject_domain: 'MESSAGE_SUBJECT')))
      end
      message if success
    end

    # @!method self.list_messages(requested_by, pagination, filter)
    # Lists the messages that are related to the party_refno of the user that is logged in.
    #
    # A filter can be passed that limits the messages to a subset of those
    #
    # @param requested_by [Object] the user who requests to get the list of their messages
    # @return [Hash] a hash of messages in this format {"1"=>#<Message...>, "2"=>#<Message...>, ...}.
    #   So it's in the format of { smsg_refno : <Message>, ... }
    private_class_method def self.list_messages(requested_by, pagination, filter)
      secure_messages, pagination_secure_message = {}
      success = call_ok?(:list_secure_messages,
                         request_list_secure_messages(requested_by, pagination, filter)) do |response|
        break if response.blank?

        pagination_secure_message = response[:pagination]
        ServiceClient.iterate_element(response[:secure_messages]) do |secure_message|
          secure_messages[secure_message[:smsg_refno]] = new_from_fl(convert_back_office_hash(secure_message, filter))
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

    # store individual document to back office
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
      call_ok?(:delete_attachment, request_delete_attachment(requested_by, doc_refno))
    end

    # sends the request to the bo to toggle the status of the message
    # @param smsg_refno [Number] the secure message refno
    # @param requested_by [String] who requested the status toggle
    def self.toggle_read_status(smsg_refno, requested_by)
      call_ok?(:secure_message_update, request_update_status(smsg_refno, requested_by))
    end

    # retrieve document from backoffice
    # @param requested_by [Object] the user who requested to get access for the specific set of data.
    # @param doc_refno [String] document reference number
    # @param type [String] document type
    # @return [Boolean] [Object] return file in binary format if success is true
    def self.retrieve_file_attachment(requested_by, doc_refno, type)
      attachment = ''
      success = call_ok?(:get_attachment, request_get_attachment(requested_by, doc_refno, type)) do |response|
        break if response.blank?

        attachment = response
      end
      [success, attachment]
    end

    # @!method self.secure_message_details_request(requested_by, id)
    # request to send backoffice to get secure message details
    # @return [Object] a hash suitable for use in a list secure messages request to the back office
    private_class_method def self.request_secure_message_details(requested_by, id, mark_as_read)
      output = request_user(requested_by)
      output['ins1:SmsgRefno'] = id
      output['ins1:MarkAsRead'] = mark_as_read

      output
    end

    # @!method self.request_list_secure_messages(requested_by, pagination, message_filter, smsg_original_refno)
    # @return a hash suitable for use in a list secure messages request to the back office
    private_class_method def self.request_list_secure_messages(requested_by, pagination, message_filter)
      request = request_user(requested_by).merge!(WrkRefno: 1)
      request[:Pagination] = { 'ins1:StartRow' => pagination.start_row, 'ins1:NumRows' => pagination.num_rows }
      return request if message_filter.nil?

      request.merge!(message_filter.request_list_secure_messages_filter)
    end

    # This is used for converting the boolean values of true or false to 'Yes' or 'No'.
    # @return [String] 'Yes' or 'No'
    private_class_method def self.boolean_to_yesno(bool)
      return 'Yes' if [true, 'true'].include?(bool)

      'No'
    end

    # @!method self.convert_back_office_hash
    # @return a hash where the back office values are converted to class values
    private_class_method def self.convert_back_office_hash(hash, filter = nil)
      hash[:has_attachment] = boolean_to_yesno(hash[:has_attachment])
      hash[:read_indicator] = set_read_indicator(hash[:direction], hash[:read_indicator])
      hash[:selected] = (hash[:smsg_refno] == filter.selected_message_smsg_refno) unless filter.nil?
      hash[:attachments] = convert_attachments(hash)
      hash
    end

    # @!method self.set_read_indicator
    # @param direction [String] The direction of the message
    # @param read_indicator [String] has the message been read
    # @return [String] the correct text to show on the page
    private_class_method def self.set_read_indicator(direction, read_indicator)
      if direction == 'I'
        I18n.t('.sent', scope: [i18n_scope, model_name.i18n_key])
      else
        boolean_to_yesno(read_indicator)
      end
    end

    # Convert the attachments data into resource item objects
    private_class_method def self.convert_attachments(hash)
      return if hash[:attachments].nil?

      output = []
      ServiceClient.iterate_element(hash.delete(:attachments)) do |resource_item_hash|
        resource_item = ResourceItem.convert_attachment_back_office_hash(resource_item_hash)
        output << resource_item
      end
      output
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
        'ins1:BinaryData': Base64.encode64(document.file_data) }
    end

    # @return a hash suitable for use in a save request to the back office
    def request_save(requested_by)
      secure_message_create_request = { OriginalRefno: @original_smsg_refno,
                                        MsgSubject: { 'ins1:Subject': @subject_code,
                                                      'ins1:FrdDomain': @subject_domain,
                                                      'ins1:WrkRefno': @wrk_refno, 'ins1:SrvCode': @srv_code },
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
    private_class_method def self.request_get_attachment(requested_by, doc_refno, type)
      request_user(requested_by).merge!(AttachmentRefno: doc_refno, AttachmentType: type)
    end

    # @return a hash suitable for use in updating the read status in the back office
    private_class_method def self.request_update_status(smsg_refno, requested_by)
      { 'ins1:ParRefno': requested_by.party_refno,
        'ins1:UserName': requested_by.username,
        'ins1:SmsgRegno': smsg_refno,
        'ins1:ToggleReadIndicator': 'Y' }
    end

    private :request_add_attachment, :request_delete_attachment
  end
end
