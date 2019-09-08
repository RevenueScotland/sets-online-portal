# frozen_string_literal: true

# Model for the forgotten username functionality
class ForgottenUsername < FLApplicationRecord
  include CommonValidation

  attr_accessor :email_address

  validate :valid_email_address?

  # Save an existing record
  # it is using the method {#save_or_update} to do so.
  def save
    save_or_update
  end

  private

  # Do the save processing for either update or create
  # uses the new record to decide which one
  def save_or_update
    return false unless valid?

    call_ok?(:maintain_user, save_element_list)
  end

  # This is used on {#save_or_update} as the request value
  # @return [Hash] the save element list for forgotten username
  def save_element_list
    {
      Action: 'ForgottenUsername',
      EmailAddress: email_address
    }
  end
end
