# frozen_string_literal: true

module Dashboard
  # MessageController handles all the messaging stuff
  class MessagesController < ApplicationController
    include FileUploadHandler
    include DownloadHelper

    authorise route: :index, requires: AuthorisationHelper::VIEW_MESSAGES
    authorise route: :new, requires: AuthorisationHelper::CREATE_MESSAGE
    authorise route: :show, requires: AuthorisationHelper::VIEW_MESSAGE_DETAIL
    authorise route: :retrieve_file_attachment, requires: AuthorisationHelper::DOWNLOAD_ATTACHMENT

    # This processes what messages to list down in the index page.
    # It shows all of the messages that are linked to logged in account
    # of the message chain.
    def index
      @message_filter = MessageFilter.new(MessageFilter.params(params))
      @messages, @pagination_collection =
        Message.list_paginated_messages(current_user, params[:page], @message_filter)
      # Determines when the find functionality is executed in index page of messages
      @on_filter_find = !params[:dashboard_message_filter].nil?
    end

    # This processes the message to find that was chosen from the list of messages from the index page
    # and a list of messages that are related to it, by looking at their origin_id.
    def show
      @message = Message.find(params[:smsg_refno], current_user)
      Rails.logger.debug { "Calling show method of (class) #{params[:smsg_refno]} with #{current_user}" }
      @message_filter = show_message_filter
      @messages, @pagination_collection =
        Message.list_paginated_messages(current_user, params[:page], @message_filter)
    end

    # Processes what happens when the send button for the new page, which is the page related to sending a message
    def create
      @message = Message.new(message_params)
      # Only handle a file upload if they can attach
      if can?(AuthorisationHelper::CREATE_ATTACHMENT)
        return if handle_file_upload('new')

        @message.attachment = @resource_items[0] unless @resource_items.nil?
      end
      success, msg_refno = @message.save(current_user)
      # need to call return
      return render_confirmation_page(msg_refno) if success

      render 'new'
    end

    # Handle confirmation related message
    def confirmation
      @message = Message.new(message_params)
      # Only handle a file upload if they can attach
      if can?(AuthorisationHelper::CREATE_ATTACHMENT)
        handle_file_upload('confirmation',
                           before_add: :add_document,
                           before_delete: :delete_document)

        return unless params[:finish]
      end
      # clear cache
      clear_resource_items
      redirect_to dashboard_messages_path
    end

    # Call delete attachment method of message to delete document from backoffice
    # @param doc_refno [String] document reference number to be delete from backoffice
    # @return [Boolean] true if document delete successfully from backoffice else false
    def delete_document(doc_refno)
      @message.delete_attachment(current_user, doc_refno)
    end

    # Send document to back office
    # @return [Boolean] true if document stored successfully in the back office else false and
    # @return [String] the documents reference
    def add_document(resource_item)
      @message.add_attachment(current_user, resource_item, @message.smsg_refno)
    end

    # Retrieve file from backoffice
    def retrieve_file_attachment
      return unless params[:attachment_ref_no] || params[:attachment_type]

      success, attachments = retrieve_file_details_from_backoffice

      return unless success

      send_file_from_attachment(attachments[:attachment])
    end

    # Processes some data to initially load up for the sending a message page.
    # If it is a reply then carry over the :subject, :origin_id, :title and :reference.
    def new
      @message = Message.initialise_message(current_user, params[:smsg_refno], params[:reference])
      handle_file_upload(nil, clear_cache: true)
    end

    private

    # which file types are allowed to be uploaded.
    def content_type_allowlist
      Rails.configuration.x.file_upload_content_type_allowlist.split(/\s*,\s*/)
    end

    # Retrieve download file details
    def retrieve_file_details_from_backoffice
      Message.retrieve_file_attachment(current_user, params[:attachment_ref_no], params[:attachment_type])
    end

    # Permits the access to the data passed on the .permit of :message objects
    def message_params
      params.require(:dashboard_message).permit(:original_smsg_refno,
                                                :subject_code, :subject_full_key_code,
                                                :reference, :title, :body, :attachment, :additional_file, :smsg_refno)
    end

    # Used specifically for show method to filter message
    def show_message_filter
      MessageFilter.new(selected_message_smsg_refno: @message.smsg_refno,
                        smsg_original_refno: @message.original_smsg_refno)
    end

    # This method will render the confirmation page if the message is successfully
    # sent to back-office
    def render_confirmation_page(msg_refno)
      @message.smsg_refno = msg_refno
      # Need to clear the resource items for the initial submission
      clear_resource_items
      render 'confirmation', id: msg_refno
    end
  end
end
