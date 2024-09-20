# frozen_string_literal: true

module Dashboard
  # MessageController handles all the messaging stuff
  class MessagesController < ApplicationController
    include FileUploadHandler
    include DownloadHelper

    authorise route: :index, requires: RS::AuthorisationHelper::VIEW_MESSAGES
    authorise route: :new, requires: RS::AuthorisationHelper::CREATE_MESSAGE
    authorise route: :show, requires: RS::AuthorisationHelper::VIEW_MESSAGE_DETAIL
    authorise route: :retrieve_file_attachment, requires: RS::AuthorisationHelper::DOWNLOAD_ATTACHMENT

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
      @message = Message.find(params[:smsg_refno], current_user, params[:mark_as_read])
      @message_filter = show_message_filter
      @messages, @pagination_collection =
        Message.list_paginated_messages(current_user, params[:page], @message_filter)
      # Don't show related messages if there is only one
      @messages = nil if @messages.count < 2
    end

    # Processes some data to initially load up for the sending a message page.
    # If it is a reply then carry over the :subject, :origin_id, :title and :reference.
    def new
      @message = Message.initialise_message(current_user, params[:smsg_refno], params[:reference])
      handle_file_upload(clear_cache: true)
    end

    # Processes what happens when the send button for the new page, which is the page related to sending a message
    def create
      @message = Message.new(message_params)
      # Only handle a file upload if they can attach
      if can?(RS::AuthorisationHelper::CREATE_ATTACHMENT)
        render('new', status: :unprocessable_entity) && return if handle_file_upload(parent_param: :dashboard_message)

        @message.attachment = @resource_items[0] unless @resource_items.nil?
      end
      success, msg_refno = @message.save(current_user)
      # need to call return
      return redirect_to_confirmation_page(msg_refno) if success

      render('new', status: :unprocessable_entity)
    end

    # Handle confirmation related message
    def confirmation
      @message = Message.find(params[:smsg_refno], current_user)
      # Only handle a file upload if they can attach
      if can?(RS::AuthorisationHelper::CREATE_ATTACHMENT) &&
         handle_file_upload(parent_param: :dashboard_message, before_add: :add_document,
                            before_delete: :delete_document)
        render(status: :unprocessable_entity)
      else
        return unless params[:finish]

        # clear cache
        clear_resource_items
        redirect_to dashboard_messages_path('dashboard_message_filter[sort_by]': 'MostRecent')
      end
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
      return unless params[:doc_refno] || params[:type]

      success, attachments = retrieve_file_details_from_backoffice

      return unless success

      send_file_from_attachment(attachments[:attachment])
    end

    # Toggles message read status
    def toggle_read_status
      Message.toggle_read_status(params[:smsg_refno], current_user)
      redirect_to dashboard_message_path
    end

    private

    # which file types are allowed to be uploaded.
    def content_type_allowlist
      Rails.configuration.x.file_upload_content_type_allowlist.split(/\s*,\s*/)
    end

    # Retrieve download file details
    def retrieve_file_details_from_backoffice
      Message.retrieve_file_attachment(current_user, params[:doc_refno], params[:type])
    end

    # Permits the access to the data passed on the .permit of :message objects
    def message_params
      params.require(:dashboard_message).except(:resource_item)
            .permit(:original_smsg_refno, :subject_code, :subject_full_key_code, :reference, :title, :body,
                    :attachment, :smsg_refno)
    end

    # Used specifically for show method to filter message
    def show_message_filter
      MessageFilter.new(selected_message_smsg_refno: @message.smsg_refno,
                        smsg_original_refno: @message.original_smsg_refno)
    end

    # This method will render the confirmation page if the message is successfully
    # sent to back-office
    def redirect_to_confirmation_page(msg_refno)
      @message.smsg_refno = msg_refno
      # Need to clear the resource items for the initial submission
      clear_resource_items
      redirect_to confirmation_dashboard_message_path(smsg_refno: msg_refno)
    end
  end
end
