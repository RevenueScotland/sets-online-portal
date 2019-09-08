# frozen_string_literal: true

# Model for yearly rent records
class AccountType
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Translation

  # Attributes for this class, in list so can re-use as permitted params list in the controller
  def self.attribute_list
    %i[registration_type]
  end

  validates :registration_type, presence: true, on: :registration_type

  attribute_list.each { |attr| attr_accessor attr }

  # return true if registration type is empty
  def empty?
    registration_type.to_s.empty?
  end

  # returns a list of registrations types
  def self.registration_types
    %i[registered_organisation other_organisation individual]
  end

  # note: disabling Style/ClassVars as we *do* only want one copy of these
  @@registered_organisation = # rubocop:disable Style/ClassVars
    AccountType.new(registration_type: :registered_organisation)
  @@other_organisation = # rubocop:disable Style/ClassVars
    AccountType.new(registration_type: :other_organisation)
  @@individual = # rubocop:disable Style/ClassVars
    AccountType.new(registration_type: :individual)

  # return an account type of registered organisation
  # @return AccountType for registered organisation
  def self.registered_organisation
    @@registered_organisation
  end

  # return an account type of other organisation
  # @return AccountType for other organisation
  def self.other_organisation
    @@other_organisation
  end

  # return an account type of individual
  # @return AccountType for individual
  def self.individual
    @@individual
  end

  # return a list of account registration types
  def self.list
    AccountType.registration_types
               .map { |s| ReferenceData::ReferenceValue.new(code: s, value: I18n.t(s.to_s)) }
  end

  # Returns true if the supplied registration_type represents an individual
  def self.individual?(registration_type)
    registration_type = registration_type.registration_type if registration_type.respond_to? :registration_type
    registration_type.to_sym == :individual
  end

  # Returns true if the supplied registration_type represents an registered_organisation
  def self.registered_organisation?(registration_type)
    registration_type = registration_type.registration_type if registration_type.respond_to? :registration_type
    registration_type.to_sym == :registered_organisation
  end

  # Returns true if the supplied registration_type represents an other_organisation
  def self.other_organisation?(registration_type)
    registration_type = registration_type.registration_type if registration_type.respond_to? :registration_type
    registration_type.to_sym == :other_organisation
  end

  # Calculate the account type based on the details of the account. Based on these rules
  #   company.company_number not empty then registered organisation
  #   company.company_name   not empty then other organisation
  #                          otherwise      individual
  # @param account [Account] the account to check the account type for
  # @return [AccountType] the type of account
  def self.from_account(account)
    raise Error::AppError.new('AccountType::from_account', 'Account argument must be non-nil') if account.nil?

    unless account.company.nil?
      return @@registered_organisation if account.company.company_number?
      return @@other_organisation if account.company.company_name?
    end
    @@individual
  end
end
