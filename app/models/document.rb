# frozen_string_literal: true

# This class is used to store detail for downloading document
# The document can be a copy of return or a copy of registration
# Check RSTP-1826 for more details
class Document < FLApplicationRecord # rubocop:disable Metrics/ClassLength
  include NumberFormatting
  include PrintData

  # validates_with LbttReturnValidator, on: :submit
  validate :answers_added
  validate :validate_otp

  # Attributes for this class, in list so can re-use as permitted params list in the controller
  def self.attribute_list
    %i[session_id passcode questions_data email_addr token_is_valid question_answers token_verified
       passcode_verified token_validity object_refno document_description documents
       hashed_token link_status warning_text]
  end

  attribute_list.each { |attr| attr_accessor attr }

  attr_accessor :check_otp, :custom_errors

  def validate_token(security_token, session_key, validate_answers = false) # rubocop:disable Style/OptionalBooleanParameter
    return if security_token.blank? || session_key.blank?

    begin
      success = call_ok?(:communication_authentication,
                         generate_auth_params(security_token, session_key, validate_answers)) do |response|
        response.blank? ? reset_values : assign_and_set_token_data(response, security_token)
      end
      reset_values unless success
    rescue StandardError => e
      Rails.logger.warn("Unable to validate token : #{e.message}")
    end
  end

  # Validates if user enters correct answer from BO
  def validate_answers_data(security_token)
    success = call_ok?(:communication_authentication, # rubocop:disable Style/RedundantAssignment
                       generate_auth_params(security_token, session_id, true, 'VerifyandRequestOtp')) do |_response|
      @token_verified = true
    end
    success
  end

  # Validates passcode entered by user
  def validate_passcode(security_token)
    success = call_ok?(:communication_authentication, # rubocop:disable Style/RedundantAssignment
                       generate_auth_params(security_token, session_id, true, 'ValidateOtpAndGetDoc')) do |response|
      response.blank? ? @passcode_verified = false : assign_and_set_passcode_data(response)
    end
    success
  end

  # Calls BO to update the status to DOWNLOADED
  def update_download_status(security_token)
    success = call_ok?(:communication_authentication, # rubocop:disable Style/RedundantAssignment
                       generate_auth_params(security_token, session_id, true, 'DOWNLOAD')) do |response|
      @link_status = response[:cau_stage] if response.present?
    end
    success
  end

  # Validate if user enters OTP
  def validate_otp
    return if @token_verified.blank?

    errors.add(:passcode, :cannot_be_blank) if @passcode.blank? && check_otp
  end

  # Validate if answers are present
  def answers_added
    return if questions_data.blank?

    @custom_errors = {}
    question_answers.each do |x|
      if x[:passcode].blank? # rubocop:disable Style/Next
        errors.add(:base, :cannot_be_blank, que: x[:question_text])
        @custom_errors[x[:question_code].to_s] = I18n.t('answer.cannot_be_blank', que: x[:question_text],
                                                                                  scope: model_name.i18n_key)
      end
    end
  end

  # check if there are any dynamic field errors for question_answers field
  def check_ans_errors
    return [] unless errors.include?(:question_answers)

    errors[:question_answers]
  end

  # Returns custom errors if any for the que_code
  def cust_error_text(que_code)
    return check_ans_errors.join(', ') if check_ans_errors.present?
    return nil if @custom_errors.blank?

    @custom_errors[que_code]
  end

  # Returns answered data if already cached based on que_code
  def cached_answer(que_code)
    return '' if @question_answers.blank? || que_code.blank?

    ans = @question_answers.find { |k| k['question_code'] == que_code }
    ans['passcode'] || ''
  end

  # Returns documents name from @documents data
  def document_names
    return '' if documents.blank?

    documents.map { |_k, v| v[:file_name] }.join(', ')
  end

  # Returns the document_type
  def doc_type
    return '' if documents.blank?

    documents.map { |_k, v| v[:description] }.join(', ')
  end

  # Hash to translate back office logical data item into an attribute
  def back_office_attributes
    {
      question_answers: { attribute: :question_answers },
      passcode: { attribute: :passcode }
    }
  end

  def file_downloaded?
    @link_status == 'DOWNLOADED'
  end

  private

  # Assign data received from passcode verify request
  def assign_and_set_passcode_data(response)
    @token_validity = response[:secret_token_valid_till]
    @object_refno = response[:object_refno]
    @document_description = response[:object_description]
    @documents = response[:documents]
    @passcode_verified = true
    @link_status = response[:cau_stage]
    @warning_text = response[:warning_text]
  end

  # Assigns data after validating token
  def assign_and_set_token_data(response, sec_token)
    @hashed_token = sec_token
    @email_addr = response[:email_id]
    @questions_data = response[:secret_questions] if response[:is_authenticated] != 'Y'
    @session_id = response[:session_id]
    @token_is_valid = true
  end

  # reset values
  def reset_values
    @questions_data = nil
    @email_addr = nil
    @token_is_valid = false
    @token_verified = nil
    @hashed_token = nil
    reset_document_data
  end

  # reset data for document
  def reset_document_data
    @token_validity = nil
    @object_refno = nil
    @document_description = nil
    @documents = nil
    @passcode_verified = nil
    @warning_text = nil
  end

  # generate params hash for request
  def generate_auth_params(token, session_key, validate_answers = false, opt_action = '') # rubocop:disable Style/OptionalBooleanParameter
    auth_params = {
      Action: (opt_action.presence || 'VERIFY'), # rubocop:disable Style/RedundantParentheses
      SecretToken: token,
      SessionId: session_key
    }
    auth_params[:SecretQuestions] = request_answers_generate if validate_answers
    auth_params[:OTP] = @passcode if @passcode.present?
    auth_params
  end

  # generate data for question answers
  def request_answers_generate
    return [] if question_answers.blank?

    question_answers.map do |qa|
      { 'ins0:SecretQuestion': { 'ins0:QuestionCode': qa[:question_code], 'ins0:UserResponse': qa[:passcode] } }
    end
  end
end
