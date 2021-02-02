# frozen_string_literal: true

# Provides common code for account persistence
module AccountPersistence
  extend ActiveSupport::Concern

  # Activate this account
  def activate
    return false unless valid?(:process_activate_account)

    call_ok?(:maintain_user_registration, save_activate_account_request)
  end

  # Save a new account.
  # Validates this account and then the new user (in field current_user) then creates them in the back office.
  def save
    # populates account validation errors
    valid?(:create)
    # NOTE: that we return false straight away if the current_user
    # or address details validation fails, hence needing the line above
    # for account validation error messages
    return false unless validate_all

    updated_address = contact_address(company, address, reg_company_contact_address_yes_no)
    # current_user is the field eg self.current_user, not the logged in/controller accessible/warden security user
    call_ok?(:maintain_user_registration,
             register_account_request(current_user, updated_address, taxes, company))
  end

  # Updates basic details (email, other company name, forename, surname, mobile number), but based on the
  # account type
  # @param account_params [Hash] changes to the account data
  # @param requested_by [User] the user requesting the changes
  # @return [Boolean] true if the account changes where saved in the back office, otherwise false
  def update_basic(account_params, requested_by)
    assign_attributes(account_params)
    # not sure why I need check_for_child_validation_errors, as basic_company_details_valid? returns
    # false and populates the company object with validation errors, but somehow that false gets lost
    # and the result ends up true if there are no other validation errors on the page
    return false unless valid?(:update_basic) && check_for_child_validation_errors

    save_or_update(requested_by)
  end

  # Updates address details on an account
  # @param address_params [Hash] changes to the address data
  # @param requested_by [User] the user requesting the changes
  # @param validation_contexts[String] validation contexts to validate address object
  # @return [Boolean] true if the address changes where saved in the back office, otherwise false
  def update_address(address_params, requested_by, validation_contexts)
    self.address = Address.new(address_params)
    return false unless address_valid?(validation_contexts)

    save_or_update(requested_by)
  end

  # Hash to translate back office logical data item into an attribute
  def back_office_attributes
    { PASSWORD: { attribute: :new_password, model: :current_user },
      REGISTRATION_TOKEN: { attribute: :registration_token } }
  end

  private

  # call to maintain party details service
  def save_or_update(requested_by)
    success = call_ok?(:maintain_party_details, save_request(requested_by))
    Account.refresh_cache!(requested_by) if success
    success
  end

  # parameters to be passed while requesting update user account details
  def save_request(requested_by)
    updated_address = contact_address(company, address, reg_company_contact_address_yes_no)
    address_details_list(updated_address).merge(account_details_list(requested_by))
                                         .merge(register_account_request_company(company, :update))
  end

  # Creates back office request update account details
  def account_details_list(requested_by)
    { Forename: forename, Surname: surname, EmailAddress: email_address, PhoneNumber: contact_number,
      PartyNINO: nino,
      'ins2:Update': { 'ins2:PartyRef': requested_by.party_refno }, 'ins1:Requestor': requested_by.username }
  end

  # Creates back office request update address details
  def address_details_list(address)
    return {} if address.nil?

    country_code = address.country || 'GB'
    { Address: { 'ins1:AddressLine1': address.address_line1, 'ins1:AddressLine2': address.address_line2,
                 'ins1:AddressLine3': address.address_line3, 'ins1:AddressLine4': address.address_line4,
                 'ins1:AddressTownOrCity': address.town, 'ins1:AddressCountyOrRegion': address.county,
                 'ins1:AddressPostcodeOrZip': address.postcode, 'ins1:AddressCountryCode': country_code } }
  end

  # Creates back office request to register a new account
  # @param user [User] the user details to save
  # @param address [Address] the address details to save
  # @param taxes [Array] list of taxes (taxes) to save
  # @param company [Company] the company details to save
  def register_account_request(user, address, taxes, company)
    register_account_request_user(user).merge(register_account_request_address(address))
                                       .merge(register_account_request_other(taxes))
                                       .merge(register_account_request_company(company))
                                       .merge(register_account_request_non_company_contact_details(company))
                                       .merge(register_account_request_company_contact_details(company))
  end

  # Creates back office request
  def save_activate_account_request
    # Not strip the token to handle dodgy cut and paste
    { Action: 'CompleteRegistration', RegistrationToken: registration_token.strip, ServiceCode: 'SYS' }
  end

  # Create a partial back office request for a user. Also sets various static fields
  # @param user [User] the user to map onto the request to the back office
  # @return hash map
  def register_account_request_user(user)
    { Requestor: user.new_username, Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS',
      Username: user.new_username, Password: user.new_password, ForcePasswordChange: 'N', UserIsCurrent: 'N',
      UserPhoneNumber: contact_number, Forename: user.forename, Surname: user.surname, EmailAddress: email_address,
      ConfirmEmailAddress: email_address_confirmation, PartyAccountType: party_account_type, PartyNINO: nino,
      EmailDataIndicator: email_data_ind }
  end

  # Create a partial back office request for an address
  # @param address [Address] the address to map onto the request to the back office
  # @return hash map
  def register_account_request_address(address)
    country_code = address.country || 'GB'
    { AddressLine1: address.address_line1, AddressLine2: address.address_line2,
      AddressLine3: address.address_line3, AddressLine4: address.address_line4,
      AddressTownOrCity: address.town, AddressCountyOrRegion: address.county, AddressCountryCode: country_code,
      AddressPostcodeOrZip: address.postcode }
  end

  # Create a partial back office request for a company
  # @param company [Company] the company to map onto the request to the back office
  # @return hash map
  def register_account_request_company(company, _type = :register)
    return {} if company&.company_name.nil?

    namespace = 'ins1' # both request types use ins1 at the moment, but may change so keeping the logic
    { CompanyName: company.company_name, RegistrationNumber: company.company_number, RegisteredAddress:
      { "#{namespace}:AddressLine1" => company.address_line1, "#{namespace}:AddressLine2" => company.address_line2,
        "#{namespace}:AddressTownOrCity" => company.locality, "#{namespace}:AddressCountyOrRegion" => company.county,
        "#{namespace}:AddressPostcodeOrZip" => company.postcode, "#{namespace}:AddressCountryCode" => company.country },
      PartyContactName: company.main_rep_name }
  end

  # Create a partial back office request for company contact details
  # @param company [Company] the company to map onto the request to the back office
  # @return hash map
  def register_account_request_company_contact_details(company)
    return {} if company&.company_name.nil?

    { PartyEmailAddress: company.org_email_address, PartyPhoneNumber: company.org_telephone }
  end

  # Create a partial back office request for company contact details
  # @param company [Company] the company to map onto the request to the back office
  # @return hash map
  def register_account_request_non_company_contact_details(company)
    return {} unless company&.company_name.nil?

    { PartyEmailAddress: email_address, PartyPhoneNumber: contact_number }
  end

  # Create a partial back office request for other parts of the call, in this case just taxes
  # @param taxes [hash of strings] the taxes to map onto the request to the back office
  # @return hash map
  def register_account_request_other(taxes)
    { UserServices: { 'ins2:UserService' => taxes.reject(&:empty?) } }
  end

  # Return the contact address. If it's a registered company without a specific contact address
  # then return the companies, address, otherwise just return the supplied address
  def contact_address(company, address, reg_company_contact_address_yes_no)
    return address unless reg_company_contact_address_yes_no == 'Y'

    Address.new(address_line1: company.address_line1, address_line2: company.address_line2, town: company.locality,
                county: company.county, country: company.country, postcode: company.postcode)
  end
end
