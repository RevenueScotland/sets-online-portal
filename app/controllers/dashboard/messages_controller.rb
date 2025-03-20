# frozen_string_literal: true

module Dashboard
  # MessageController handles all the messaging stuff
  class MessagesController < ApplicationController # rubocop:disable Metrics/ClassLength
    include Wizard
    include FileUploadHandler
    include DownloadHelper

    before_action :load_step, only: %i[upload_documents send_message]
    before_action :set_max_uploads_allowed, only: %i[upload_documents send_message]

    authorise route: :index, requires: RS::AuthorisationHelper::VIEW_MESSAGES
    authorise route: :new, requires: RS::AuthorisationHelper::CREATE_MESSAGE
    authorise route: :show, requires: RS::AuthorisationHelper::VIEW_MESSAGE_DETAIL
    authorise route: :retrieve_file_attachment, requires: RS::AuthorisationHelper::DOWNLOAD_ATTACHMENT
    authorise route: :download_view_all, requires: RS::AuthorisationHelper::VIEW_ALL_PDF

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
      if params[:step1] || params[:smsg_refno].present?
        Rails.logger.debug('Starting new Message')
        clear_caches
      end
      wizard_step(nil) do
        { setup_step: :setup_step, next_step: :upload_documents_dashboard_messages_path }
      end
      @reply_thread = params[:smsg_refno].present?
    end

    # Processes what happens when the send button for the new page, which is the page related to sending a message
    def create
      @message = Message.new(message_params)
      @reply_thread = @message.original_smsg_refno.present?
      wizard_save(@message) if @message.valid?
      if @message.valid?
        redirect_to upload_documents_dashboard_messages_path
      else
        render 'new', status: :unprocessable_entity unless @message.valid?
      end
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

    # The method used to retrieve the view all messages pdf
    # The "target: '_blank'" page used to download the pdf file of the return according
    # to its details.
    def download_view_all
      attachments = Message.back_office_pdf_data(params[:original_smsg_refno], current_user)
      return unless attachments

      # Download the file
      send_file_from_attachment(attachments[:attachment], 'inline')
    end

    # Toggles message read status
    def toggle_read_status
      Message.toggle_read_status(params[:smsg_refno], current_user)
      redirect_to dashboard_message_path
    end

    # Step 2 : message wizard
    def upload_documents
      @reply_thread = @message.original_smsg_refno.present?
      return redirect_to send_message_dashboard_messages_path if params[:continue].present?

      save_and_upload_file if can?(RS::AuthorisationHelper::CREATE_ATTACHMENT)
      # methods above could have updated the return so save it to give wizards access to the new data
      wizard_save(@message)
    end

    # Step 3 of the message wizard
    def send_message
      @reply_thread = @message.original_smsg_refno.present?
      # Save data if form submitted
      save_message_data if confirm_page_submitted?
      return unless can?(RS::AuthorisationHelper::CREATE_ATTACHMENT)

      if params[:delete_resource].present? &&
         handle_file_upload(parent_param: :dashboard_message)
        save_attachments_data
      else
        handle_file_upload(parent_param: :dashboard_message)
      end
    end

    private

    # returns the max files allowed limit
    def set_max_uploads_allowed
      @max_file_upload_limit = ReferenceData::SystemParameter.lookup('PWS', 'SYS',
                                                                     'RSTU', safe_lookup: true)['QTY_FILE_UPLOAD']
                                                             &.value.to_i
      @max_file_upload_limit = 10 if @max_file_upload_limit.zero?
      @max_file_upload_limit
    end

    # Checks if file is uploaded from wizard
    def extract_uploaded_from_wizard
      params.dig(:dashboard_message, :upload_from_wizard)
    end

    # check file data object
    def extract_fd_obj
      params.dig(:dashboard_message, :resource_item, :default, :file_data)
    end

    # check file desc object
    def extract_file_desc
      params.dig(:dashboard_message, :resource_item, :default, :description)
    end

    # Returns if file data is not present
    def upload_file_data_empty?
      extract_uploaded_from_wizard.present? && extract_fd_obj.nil? &&
        (extract_file_desc.nil? || extract_file_desc.blank?)
    end

    # Check if user only added description and didn't attach file
    # Scenario : User adds file description but doesn't attach a file while upload
    def validate_description_only_added
      if extract_file_desc.present? && (extract_uploaded_from_wizard.present? && extract_fd_obj.nil?)
        handle_file_upload(parent_param: :dashboard_message)
        render('upload_documents', status: :unprocessable_entity) && return
      end
      true
    end

    # on page load this method loads @resource_items
    # in case file is uploaded it validates and save file
    def save_and_upload_file
      handle_file_upload(parent_param: :dashboard_message) if extract_uploaded_from_wizard.nil?
      redirect_to send_message_dashboard_messages_path if upload_file_data_empty?
      validate_description_only_added

      validate_and_save_uploaded_file(extract_uploaded_from_wizard, extract_fd_obj)
    end

    # Validate and save uploaded file from step 2
    # This method accepts two parameters
    # uploaded_from_wizard -> indicates if file upload is triggered from wizard
    # fd_obj (file_data object) -> used to check if file_data object is present
    def validate_and_save_uploaded_file(uploaded_from_wizard, fd_obj)
      return unless uploaded_from_wizard.present? # rubocop:disable Rails/Blank

      process_uploaded_file(fd_obj)
    end

    # Process uploaded file using the fd_obj(file_data object)
    # Check if upload request is added. If yes, attach the document
    # If it is a delete request, remove the relevant attachment
    def process_uploaded_file(fd_obj)
      if fd_obj.present? && handle_file_upload(parent_param: :dashboard_message)
        validate_and_add_attachment
      elsif params[:delete_resource].present? &&
            handle_file_upload(parent_param: :dashboard_message)
        redirect_to send_message_dashboard_messages_path && return
      end
    end

    # This method is used from the last step of message wizard
    # Update message attachments
    def save_attachments_data
      no_files_attached = @resource_items.nil? || (@resource_items.is_a?(Array) && @resource_items.empty?)
      @message.attachments = nil if no_files_attached
      wizard_save(@message)
      render('send_message',
             status: :unprocessable_entity) && return
    end

    # Checks if added attachment is valid. This method is sub-function of upload_documents
    def validate_and_add_attachment
      invalid_file = @resource_items_hash[:default].errors.any?
      return render('upload_documents', status: :unprocessable_entity) if invalid_file

      @message.attachments = @resource_items unless @resource_items.nil?
      wizard_save(@message)
      redirect_to send_message_dashboard_messages_path
    end

    # Save @message data
    def save_message_data # rubocop:disable Metrics/MethodLength
      @message.assign_attributes(message_params.slice(:reference, :title, :body, :subject_code, :agent_reference))
      assign_msg_attachments
      if @message.valid?
        wizard_save(@message)
        success, msg_refno = @message.save(current_user)
        # need to call return
        return redirect_to_confirmation_page(msg_refno) if success
        render(status: :unprocessable_entity) && return unless success
      else
        handle_file_upload(parent_param: :dashboard_message)
        render(status: :unprocessable_entity) && return unless @message.valid?
      end
    end

    # Checks if the confirm message page is submitted (step3 of msg wizard)
    def confirm_page_submitted?
      params[:dashboard_message].present? && message_params.present? && !params[:delete_resource].present? # rubocop:disable Rails/Blank
    end

    # Update the attachments for @message
    def assign_msg_attachments
      handle_file_upload(parent_param: :dashboard_message)
      return if @resource_items&.empty?

      @message.attachments = @resource_items
      @message.has_attachment = true
    end

    # which file types are allowed to be uploaded.
    def content_type_allowlist
      Rails.configuration.x.file_upload_content_type_allowlist.split(/\s*,\s*/)
    end

    # max finename length allowed for upload
    def max_filename_length
      Rails.configuration.x.file_upload_file_name_limit
    end

    # Retrieve download file details
    def retrieve_file_details_from_backoffice
      Message.retrieve_file_attachment(current_user, params[:doc_refno], params[:type])
    end

    # Permits the access to the data passed on the .permit of :message objects
    def message_params
      params.require(:dashboard_message).except(:resource_item)
            .permit(:original_smsg_refno, :subject_code, :subject_full_key_code, :reference, :agent_reference, :title,
                    :body, :attachment, :smsg_refno, :subject_desc)
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

    # Sets up wizard model if it doesn't already exist in the cache
    # @return [Message] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path
      @message = wizard_load || Message.initialise_message(current_user, params[:smsg_refno], params[:reference],
                                                           account_service)

      @message
    end

    # Loads existing wizard models from the wizard cache or redirects to the summary page
    # @return [Message] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @message = wizard_load_or_redirect(new_dashboard_message_url)
      @post_path = wizard_post_path
      @message
    end

    # Calls @see #wizard_end for SAT and sub-objects
    def clear_caches
      Rails.logger.debug('Clearing Message caches')
      wizard_end
    end
  end
end
