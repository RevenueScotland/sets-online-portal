# frozen_string_literal: true

# Validators for various common fields.
module CommonValidation
  include DateFormatting
  # Regex for email address validation
  EMAIL_ADDRESS_REGEX = /\A[a-zA-Z0-9_!#$%&’*+=?`{|}~^.-]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}\z/i.freeze

  # Regex for UK mobile number validation
  MOBILE_REGEX = /\A(\+44\s?7\d{3}|\(?07\d{3}\)?)\s?\d{3}\s?\d{3}\z/i.freeze

  # Regex for Uk telephone number validation
  # eg. 02079460654, +442079460654, 02079460654 #2789
  long_regex_pt1 = '\A(((\+|00)?44|0)([123578]{1}))(((\d{1}\s?\d{4}|\d{2}\s?\d{3})\s?\d{4})|(\d{3}\s?\d{2,3}\s?\d{3})|'
  long_regex_pt2 = '(\d{4}\s?\d{4,5}))(\s?(#|[xX]|[eE][xX][tT])(\d{4}|\d{3}))?\z'

  # Telephone regex is long, hence split it and combine
  TELEPHONE_REGEX = Regexp.new(long_regex_pt1 + long_regex_pt2)

  # Regex for international telephone number
  # Also allow Spanish telephone number (0034629629629 or +34629629629)
  INT_TELEPHONE_REGEX = /\A(?:00|\+)(?:[0-9] ?){6,14}[0-9]\z/i.freeze

  # Regex for National Insurance Number validation
  NINO_REGEX = /\A(?!BG|GB|NK|KN|TN|NT|ZZ)[A-CEGHJ-PR-TW-Z][A-CEGHJ-NPR-TW-Z](?:\s*\d{2}){3}\s*[A-D]\z/i.freeze

  # Regular Expression for 2DP decimals
  TWO_DP_PATTERN = /\A\d+(?:\.\d{0,2})?\z/.freeze

  # Regex for Scotland Postcode Validation
  SCOTLAND_POSTCODE_REGEX = /\A((BT|ZE|KW|IV|HS|PH|AB|DD|PA|FK|G|KY|KA|EH|ML|TD|\DG)[0-9])/i.freeze

  # Regex for Sort Code validation
  SORT_CODE = /\A(?!(?:0{6}))(?:\d\d-\d\d-\d\d)\z/i.freeze

  # Validation for telephone number
  def phone_format_valid?
    errors.add(:telephone, :cant_be_blank) && return if telephone.to_s.empty?

    phone_number_format_valid? :telephone
  end

  # Validation for telephone number
  # it should check against Uk phone number and also international number
  # @param attribute [Symbol] the name of the attribute to check for validation
  def phone_number_format_valid?(attribute)
    return if send(attribute)&.match?(TELEPHONE_REGEX) || send(attribute)&.match?(INT_TELEPHONE_REGEX)

    errors.add(attribute, :is_invalid)
  end

  # Validation for email address
  def valid_email_address?
    email_address_valid? :email_address
  end

  # Validation for email addresses
  # @param attribute [Symbol] the name of the attribute to check for validation
  def email_address_valid?(attribute)
    errors.add(attribute, :cant_be_blank) && return if send(attribute).to_s.empty?

    errors.add(attribute, :is_invalid) && return unless send(attribute)&.match?(EMAIL_ADDRESS_REGEX)
  end

  # Validation for mobile number
  def mobile_format_valid?
    return if contact_number&.match?(MOBILE_REGEX) || contact_number.to_s.empty?

    errors.add(:contact_number, :is_invalid)
  end

  # Validation for NINO - checks if the format is valid
  # @param attribute [Symbol] the name of the attribute to check for validation
  def national_insurance_number_valid?(attribute)
    # Don't have to do the validation as attribute is empty
    return if send(attribute).to_s.empty?

    errors.add(attribute, :is_invalid) && return unless send(attribute)&.match?(NINO_REGEX)
  end

  # Validation for NINO - checks if empty
  # @param attribute [Symbol] the name of the attribute to check for validation
  def national_insurance_number_empty?(attribute)
    errors.add(attribute, :cant_be_blank) && return if send(attribute).to_s.empty?
  end

  # Validation for existing references
  def valid_reference?(reference)
    reference&.match?(Rails.configuration.x.app_ref.validation_pattern)
  end

  # Validate a date, a date is valid if the string can be parsed into a date
  # @example here are some string examples of date format that can be parsed into the date
  #   '25-12-2018'
  #   '25/12/2018'
  #   '2018/12/25'
  #   '2018-12-25'
  # @param attribute [Symbol] the name of the attribute of an object to be checked for validation
  # @see DateFormatting::date_parsable? to see how it is handling the checker of a parsable date
  def date_format_valid?(attribute)
    # Check the date is parsable
    errors.add(attribute, :is_invalid) && return unless date_parsable?(send(attribute))

    # Checks the year has 4 digits
    return if Date.parse(send(attribute)).year.to_s.length <= 4

    errors.add(attribute, :is_invalid)
  end

  # Validates a range of date where the start date should be before the end date
  # @param start_attr [Symbol] the name of the attribute of the object to be checked for validation
  #   which is the start date
  # @param end_attr [Symbol] the name of the attribute of the object to be checked for validation
  #   which is the end date
  def date_start_before_end?(start_attr, end_attr)
    start_date = send(start_attr)
    end_date = send(end_attr)
    return unless date_parsable?(end_date) && date_parsable?(start_date)
    return unless Date.parse(end_date) < Date.parse(start_date)

    errors.add(start_attr, :before_date_error)
    errors.add(end_attr, :after_date_error)
  end

  # Validation for Repayment bank sort code
  # verifies the given bank sort code is in 99-99-99 format
  def repay_bank_sort_code_valid?
    errors.add(:branch_code, :cant_be_blank) && return if branch_code.to_s.empty?

    repay_bank_sort_code_format_valid? :branch_code
  end

  # Validation for Sort code
  # @param attribute [Symbol] the name of the attribute to check for validation
  def repay_bank_sort_code_format_valid?(attribute)
    return if send(attribute)&.match?(SORT_CODE)

    errors.add(attribute, :is_invalid)
  end

  # Validation for checking format of postcode,whether it is of Scotland.
  def scotland_postcode_format_valid?(postcode)
    postcode.match?(SCOTLAND_POSTCODE_REGEX)
  end

  # Logic to check if country code is of Scotland.
  def scotland_country_code_valid(country)
    country == Rails.configuration.x.allowed_country_code
  end
end
