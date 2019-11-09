# frozen_string_literal: true

# Provides common code for account validation
module AccountValidation
  extend ActiveSupport::Concern

  # Override the valid? method. When called from the registration wizard the contexts will be an array of
  # validation contexts, and in this case, we should also check any child objects for validation errors.
  # When called from other methods, e.g. updating, the contexts will be a simple symbol or string, and
  # the default behaviour of valid? is called
  # @param contexts [Array/Symbol/String] validation context or array of contexts
  # @return [Boolean] returns true if the model is valid, otherwise false
  def valid?(contexts)
    return super unless contexts.is_a?(Array)

    result = super filter_attributes(contexts, Account.attribute_list)
    result &= child_valid?(contexts, User, :current_user)
    result &= child_valid?(contexts, Company, :company)
    result &= child_valid?(contexts, AccountType, :account_type)
    result &= child_valid?(contexts, Address, :address)
    remove_duplicate_errors
    result
  end

  private

  # Checks if child objects are valid
  # @param context [Array] array of validation contexts
  # @param model [Class] the class of the sub object
  # @param attribute [symbol] the name of the class variable to check for validity
  # @return [Boolean] returns true if the child is valid, otherwise false
  def child_valid?(context, model, attribute)
    filtered_context = filter_attributes(context, model.send(:attribute_list))
    return true if send(attribute).nil? || filtered_context.nil? || filtered_context.empty?

    valid = send(attribute).valid?(filtered_context)
    errors.merge!(send(attribute).errors)
    valid
  end

  # Removes duplicate errors from any model errors. This can occur as account and user
  # has overlapping attributes.
  def remove_duplicate_errors
    return if errors.nil? || errors.empty?

    remove_duplicate_error_part(errors.messages)
    remove_duplicate_error_part(errors.details)
  end

  # Removes duplicate errors from any model errors. This can occur as account and user
  # has overlapping attributes.
  # @param collection [Hash] the collection to remove duplicates from
  def remove_duplicate_error_part(collection)
    collection.each { |k, m| collection[k] = m.uniq }
  end

  # Checks if any of the child objects have validation errors, and returns false if that do
  # @return [Boolean] false if any child objects have validation messages
  def check_for_child_validation_errors
    result = true
    result &= check_for_child_validation_error(:current_user)
    result &= check_for_child_validation_error(:company)
    result &= check_for_child_validation_error(:account_type)
    result &= check_for_child_validation_error(:address)
    result
  end

  # Checks if the child object have validation errors, and returns false if that do
  # @param attribute [symbol] the name of the class variable to check for errors
  # @return [Boolean] false if any child objects have validation messages
  def check_for_child_validation_error(attribute)
    return true if send(attribute).nil? || send(attribute).errors.nil?

    send(attribute).errors.empty?
  end

  # perform validation on current_user, the main account object, and the address
  def validate_all
    current_user.valid?(:save) && valid?(:create) && address_valid?
  end

  # Validation for taxes, user must have selected only one non-blank service
  def taxes_valid?
    errors.add(:taxes, :one_must_be_chosen) if taxes.reject(&:empty?).size != 1
  end

  # Validation for NINO. Only required when the account type is for other organisation
  # or individual
  def nino_valid?
    return nil if AccountType.registered_organisation?(account_type)

    national_insurance_number_empty? :nino
    national_insurance_number_valid? :nino
  end

  # Validation for names, if it's not a company
  def names_valid?
    return nil unless AccountType.individual?(account_type)

    errors.add(:forename, :cant_be_blank) if forename.to_s.empty?
    errors.add(:surname, :cant_be_blank) if surname.to_s.empty?
  end

  # Checks if the address is valid. For registered companies without a separate contract address
  # this can be nil, otherwise it must be supplied, and is validated by the address object
  def address_valid?
    return true if address.nil?
    return true unless reg_company_contact_address_yes_no == 'N' || reg_company_contact_address_yes_no.to_s.empty?

    address.valid?(:save)
  end

  # Checks if the company is valid.
  # @return [Boolean] true if the company valid, or doesn't need validation otherwise false
  def company_valid?
    return true if AccountType.individual?(account_type) || company.nil?

    company.valid?(account_type.registration_type.to_sym)
  end

  # Checks if company details are valid for basic account updating. In this case the company
  # is checked only if the account type is for other organisation
  # @return [Boolean] true if the company valid, or doesn't need validation otherwise false
  def basic_company_details_valid?
    return true unless AccountType.other_organisation?(account_type)

    company.valid?(account_type.registration_type.to_sym)
  end
end