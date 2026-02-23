# frozen_string_literal: true

# This controller is used to download documents
# The document can be a copy of return or a copy of registration
class DocumentsController < ApplicationController
  include Wizard
  include DownloadHelper

  # all public pages
  PUBLIC_PAGES = %I[access_document enter_passcode download_document download_attachment].freeze

  # Allow unauthenticated/public access to specific actions - NB do not put return_type here, want that
  # to require authentication so we don't mix the two up
  skip_before_action :require_user?, only: PUBLIC_PAGES

  # this can't be defined in authorise.rb, otherwise rails throws an error
  helper_method :public?

  # Page : Ask user to enter answers for secret questions while accessing lbtt document(if any)
  # if success, user will be redirected to enter_passcode page
  def access_document # rubocop:disable Metrics/AbcSize
    clear_caches
    setup_step
    @document.validate_token(params[:token_hash], session.id) if params[:token_hash]
    assign_qa_data
    if filter_params.present? || (params[:continue] && @document.token_verified)
      validate_and_redirect
    else
      wizard_save(@document)
    end
  end

  # Page to enter passcode
  def enter_passcode
    load_step
    redirect_if_invalid_token
    return if filter_controller_params.blank?

    @document.passcode = filter_controller_params[:passcode]
    @document.check_otp = true
    render(status: :unprocessable_content) && return unless @document.valid?

    validate_passcode_data
  end

  # page to download lbtt document
  def download_document
    load_step
    redirect_if_invalid_token
    return unless params[:download_attachment]

    download_attachment
  end

  # Send document as attachment
  def download_attachment
    render(status: :unprocessable_content) && return unless
                                              @document.update_download_status(params[:token_hash])

    wizard_save(@document)
    send_download_file
  end

  private

  # Returns data object for documents attachment data
  def send_download_file
    document = @document.documents[:document]
    document[:file_type] = 'application/pdf' if document[:file_type] == 'PDF'
    send_file_from_attachment(document)
  end

  # redirect to first page of flow if invalid token found
  def redirect_if_invalid_token
    return if params[:token_hash].blank?

    return unless @document&.hashed_token != params[:token_hash]

    redirect_to access_documents_url
  end

  # Calls @see #wizard_end for LBTT document detail
  def clear_caches
    Rails.logger.debug('Clearing LBTT document wizard caches')
    wizard_end
  end

  # Validate passcode data from BO
  def validate_passcode_data
    valid_passcode = @document.validate_passcode(params[:token_hash])
    wizard_save(@document) if valid_passcode
    render(status: :unprocessable_content) && return if @document.errors.present?

    redirect_to download_documents_path(params[:token_hash])
  end

  # Assign question answers data from filter_params
  def assign_qa_data
    return unless filter_params.present? && filter_params['question_answers'].present?

    @document.question_answers = filter_params['question_answers'].map(&:to_h)
  end

  # Validate data for the access-document page
  def validate_and_redirect
    render(status: :unprocessable_content) && return unless @document.valid?

    correct_answered = @document.validate_answers_data(params[:token_hash])
    wizard_save(@document) if correct_answered
    render(status: :unprocessable_content) && return if @document.errors.present?

    redirect_to enter_passcode_documents_path(params[:token_hash])
  end

  # Sets up wizard model if it doesn't already exist in the cache
  # @see #clean_on_new_type if you change this method, they need to match up
  # @return [LbttReturn] the model for wizard saving
  def setup_step
    @post_path = wizard_post_path
    @document = wizard_load || Document.new

    @document
  end

  # Return the parameter list filtered for the attributes of the SatReturn model.
  # Special case for the repayment declaration, since it's the only thing on the page we need to treat
  # its absence as a value of false.
  def filter_params(_sub_object_attribute = nil)
    required = :document
    output = {}
    dup_params = Document.attribute_list.dup
    dup_params.push(question_answers: %i[question_text question_code passcode])
    # Rubocop disable added as this breaks the functionality
    # https://github.com/rubocop/rubocop-rails/issues/1418
    output = params.require(required).permit(dup_params) if params[required] # rubocop:disable Rails/StrongParametersExpect

    output
  end

  # This method is useful when dynamic fields aren't there and ds fields are used
  def filter_controller_params(_sub_object_attribute = nil)
    required = :document
    output = {}
    dup_params = Document.attribute_list.dup
    dup_params.push(question_answers: %i[question_code passcode])
    # Rubocop disable added as this breaks the functionality
    # https://github.com/rubocop/rubocop-rails/issues/1418
    output = params.require(required).permit(dup_params) if params[required] # rubocop:disable Rails/StrongParametersExpect

    output
  end

  # Loads existing wizard models from the wizard cache or redirects to the summary page
  # @return [SatReturn] the model for wizard saving
  def load_step(_sub_object_attribute = nil)
    @document = wizard_load_or_redirect(access_documents_url)
    @post_path = wizard_post_path
    @document
  end
end
