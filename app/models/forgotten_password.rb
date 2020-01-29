# frozen_string_literal: true

# Model for the forgotten password functionality
class ForgottenPassword < FLApplicationRecord
  attr_accessor :email_address, :new_password, :new_password_confirmation
  attr_reader :username

  validates :username, presence: true, length: { minimum: 3, maximum: 30 }
  validates :email_address, presence: true, email_address: true
  validates :new_password, length: { maximum: 200 }, presence: true
  validates :new_password, confirmation: true

  # Custom override setter for username to make sure it is stored upper case as the back office requires it
  # @param [String] value the value to set the username to
  def username=(value)
    @username = (value.nil? ? value : value.upcase)
  end

  # Send forgotten password request to the back office
  def save
    return false unless valid?

    call_ok?(:maintain_user, forgot_password_request)
  end

  private

  # @return [Array] the save element list for forgotten password
  def forgot_password_request
    {
      Username: username,
      Requestor: username,
      Action: 'ForgottenPassword',
      EmailAddress: email_address,
      NewPassword: new_password,
      ServiceCode: 'SYS'
    }
  end

  # Hash to translate back office logical data item into an attribute
  def back_office_attributes
    { PASSWORD: { attribute: :new_password } }
  end
end
