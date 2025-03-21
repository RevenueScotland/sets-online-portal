# frozen_string_literal: true

# User validation methods.
# Split out into a separate class to keep User class small/keep Rubocop happy.
module UserValidation
  extend ActiveSupport::Concern

  included do
    validates :username, length: { maximum: 30 }, presence: true, on: %i[update update_password login two_factor]
    validates :new_username, length: { minimum: 5, maximum: 30 }, on: %i[save new_username]

    validates :password, presence: true, length: { maximum: 200 }, on: :login
    validates :old_password, presence: true, length: { maximum: 200 }, on: :update_password
    validates :new_password, presence: true, length: { maximum: 200 }, on: %i[save update_password new_password]
    validates :new_password, confirmation: true

    validates :token, presence: true, length: { maximum: 100 }, on: :two_factor

    validates :email_address, presence: true, email_address: true, on: %i[save update email_check]
    validates :email_address, confirmation: true, on: %i[save update email_check]
    validates :phone_number, phone_number: true, on: %i[save update]
    validates :forename, presence: true, length: { maximum: 50 }, on: %i[save update forename]
    validates :surname, presence: true, length: { maximum: 100 }, on: %i[save update surname]

    validates :user_is_current, presence: true, format: /\A(Y|N)\z/i, on: %i[save update]

    validates :user_is_signed_ta_cs, acceptance: { accept: ['Y'] }, on: :confirm_tcs
    validates :portal_object_index, presence: true, on: :select_portal_object
  end

  # Check password is expired or not
  def check_password_expired?
    !days_to_password_expiry.nil? && days_to_password_expiry <= 0
  end

  # If password_change_required parameter from back-office is true or password is expired
  # then the user needs to reset password to access the application
  def check_password_change_required?
    password_change_required || check_password_expired?
  end

  # Check if the user needs to read the terms and conditions again
  def check_tcs_required?
    user_is_signed_ta_cs != 'Y'
  end

  # Check if the user needs to select the enrolment objects
  def check_object_needed?
    return false if portal_objects_access.nil?

    true
  end

  # Return number of days remaining for password to expire
  def days_to_password_expiry
    no_of_days_remaining = (password_expiry_date.to_date - Time.zone.today).to_i
    no_of_days_remaining.to_i unless no_of_days_remaining >= Rails.configuration.x.authentication.password_due_period
  end
end
