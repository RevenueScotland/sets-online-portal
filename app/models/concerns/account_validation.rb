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

    send(attribute).valid?(filtered_context)
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
    current_user.valid?(:save) && valid?(:create) && address_valid?(:save)
  end

  # Validation for taxes, user must have selected only one non-blank service
  def one_tax_is_choosen
    errors.add(:taxes, :one_must_be_chosen) if taxes.compact_blank.size != 1
  end

  # Validation for names, if it's not a company
  def names_are_valid
    return nil unless AccountType.individual?(account_type)

    errors.add(:forename, :cant_be_blank) if forename.to_s.empty?
    errors.add(:surname, :cant_be_blank) if surname.to_s.empty?
    names_length_are_valid
  end

  # Extra validation for names that checks for the length
  def names_length_are_valid
    errors.add(:forename, :too_long, count: 50) if forename.length > 50
    errors.add(:surname, :too_long, count: 100) if surname.length > 100
  end

  # Checks if the address is valid. For registered companies without a separate contract address
  # this can be nil, otherwise it must be supplied, and is validated by the address object
  # @param validation_contexts[String] validation contexts to validate address object
  # @return [Boolean] true if the address valid, or doesn't need validation otherwise false
  def address_valid?(validation_contexts)
    return true if address.nil?
    return true unless reg_company_contact_address_yes_no == 'N' || reg_company_contact_address_yes_no.to_s.empty?

    address.valid?(validation_contexts)
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
