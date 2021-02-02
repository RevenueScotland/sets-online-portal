# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock calls associated with registration and account activation

def mock_address_details
  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/address_details.xml")
  message = { Address: { 'ins1:AddressIdentifier' => '14174279        ' } }
  @savon.expects(:nas_address_detail_wsdl).with(message: message).returns(fixture)
end

def mock_address_search
  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/address_search.xml")
  message = { RequestParameters: {},
              SearchParameters: { 'ins1:Postcode' => 'LU1 1AA' },
              SelectionOptions: { 'ins1:MaximumNumberOfRows' => 200,
                                  'ins1:IncludeNonGeographicAddresses' => false,
                                  'ins1:IncludeBFPOAddresses' => false,
                                  'ins1:IncludeMultiResidenceAddresses' => false,
                                  'ins1:IncludeNIAddresses' => true } }
  @savon.expects(:nas_address_search_wsdl).with(message: message).returns(fixture)
end

def mock_alt_address_details
  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/address_alt_details.xml")
  message = { Address: { 'ins1:AddressIdentifier' => '14174279        ' } }
  @savon.expects(:nas_address_detail_wsdl).with(message: message).returns(fixture)
end

def mock_alt_address_search
  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/address_alt_search.xml")
  message = { RequestParameters: {},
              SearchParameters: { 'ins1:Postcode' => 'RG30 6XT' },
              SelectionOptions: { 'ins1:MaximumNumberOfRows' => 200,
                                  'ins1:IncludeNonGeographicAddresses' => false,
                                  'ins1:IncludeBFPOAddresses' => false,
                                  'ins1:IncludeMultiResidenceAddresses' => false,
                                  'ins1:IncludeNIAddresses' => true } }
  @savon.expects(:nas_address_search_wsdl).with(message: message).returns(fixture)
end

# Mock a activating account to complete registration
Before('@mock_activate_account') do
  start_mock
  message = { Action: 'CompleteRegistration', RegistrationToken: 'valid.registation.token' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/activate_account.xml")
  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock for change password
Before('@mock_change_password') do
  start_mock
  mock_valid_signin
  message = { Username: 'VALID.USER', Requestor: 'VALID.USER', Action: 'ChangePassword',
              OldPassword: 'valid.password', NewPassword: 'New.password1', ServiceCode: 'SYS' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/change_password.xml")
  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock for new user registration
Before('@mock_new_user_registration') do
  start_mock
  mock_address_search
  mock_address_details

  message = { Requestor: 'NEW.USER.REGISTRATION', Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS',
              Username: 'NEW.USER.REGISTRATION', Password: 'Password001', ForcePasswordChange: 'N', UserIsCurrent: 'N',
              UserPhoneNumber: '07700 900123', Forename: 'forename', Surname: 'surname',
              EmailAddress: 'test@example.com', ConfirmEmailAddress: 'test@example.com', PartyAccountType: 'TAXPAYER',
              PartyNINO: 'AB123456D', EmailDataIndicator: 'Y', AddressLine1: 'Royal Mail',
              AddressLine2: 'Luton Delivery Office 9-11', AddressLine3: 'Dunstable Road', AddressLine4: '',
              AddressTownOrCity: 'LUTON', AddressCountyOrRegion: '', AddressCountryCode: 'EN',
              AddressPostcodeOrZip: 'LU1 1AA', UserServices: { 'ins2:UserService' => ['LBTT'] },
              PartyEmailAddress: 'test@example.com', PartyPhoneNumber: '07700 900123' }

  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/register_user.xml")

  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

Before('@mock_new_other_company_registration') do
  start_mock
  mock_address_search
  mock_address_details
  mock_alt_address_search
  mock_alt_address_details
  message = { Requestor: 'NEW.USER.REGISTRATION', Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS',
              Username: 'NEW.USER.REGISTRATION', Password: 'Password001', ForcePasswordChange: 'N', UserIsCurrent: 'N',
              UserPhoneNumber: '01234567890', Forename: 'forename', Surname: 'surname',
              EmailAddress: 'test@example.com', ConfirmEmailAddress: 'test@example.com',
              PartyAccountType: 'TAXPAYER', PartyNINO: 'AB123456D',
              EmailDataIndicator: 'Y', AddressLine1: '10 Rydal Avenue', AddressLine2: 'Tilehurst', AddressLine3: '',
              AddressLine4: '', AddressTownOrCity: 'READING', AddressCountyOrRegion: '', AddressCountryCode: 'EN',
              AddressPostcodeOrZip: 'RG30 6XT', UserServices: { 'ins2:UserService' => ['LBTT'] },
              CompanyName: 'Other Company', RegistrationNumber: nil,
              RegisteredAddress: { 'ins1:AddressLine1' => 'Royal Mail',
                                   'ins1:AddressLine2' => 'Luton Delivery Office 9-11',
                                   'ins1:AddressTownOrCity' => 'LUTON',
                                   'ins1:AddressCountyOrRegion' => '',
                                   'ins1:AddressPostcodeOrZip' => 'LU1 1AA',
                                   'ins1:AddressCountryCode' => 'EN' },
              PartyContactName: 'Mr Wobble', PartyEmailAddress: 'noreply@northgateps.com',
              PartyPhoneNumber: '01234567891' }

  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/register_user.xml")

  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

Before('@mock_new_company_no_address_registration') do
  start_mock
  message = { Requestor: 'NEW.USER.REGISTRATION', Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS',
              Username: 'NEW.USER.REGISTRATION', Password: 'Password001', ForcePasswordChange: 'N', UserIsCurrent: 'N',
              UserPhoneNumber: '01234567890', Forename: 'forename', Surname: 'surname',
              EmailAddress: 'test@example.com', ConfirmEmailAddress: 'test@example.com', PartyAccountType: 'TAXPAYER',
              PartyNINO: nil, EmailDataIndicator: 'Y',
              AddressLine1: 'Peoplebuilding 2 Peoplebuilding Estate', AddressLine2: 'Maylands Avenue',
              AddressLine3: nil, AddressLine4: nil, AddressTownOrCity: 'Hemel Hempstead',
              AddressCountyOrRegion: 'Hertfordshire', AddressCountryCode: 'GB', AddressPostcodeOrZip: 'HP2 4NW',
              UserServices: { 'ins2:UserService' => ['LBTT'] },
              CompanyName: 'NORTHGATE PUBLIC SERVICES LIMITED', RegistrationNumber: '09338960',
              RegisteredAddress: { 'ins1:AddressLine1' => 'Peoplebuilding 2 Peoplebuilding Estate',
                                   'ins1:AddressLine2' => 'Maylands Avenue',
                                   'ins1:AddressTownOrCity' => 'Hemel Hempstead',
                                   'ins1:AddressCountyOrRegion' => 'Hertfordshire',
                                   'ins1:AddressPostcodeOrZip' => 'HP2 4NW',
                                   'ins1:AddressCountryCode' => 'GB' },
              PartyContactName: 'Mr Wobble', PartyEmailAddress: 'noreply@northgateps.com',
              PartyPhoneNumber: '01234567891' }

  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/register_user.xml")

  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

Before('@mock_new_company_registration') do
  start_mock
  mock_address_search
  mock_address_details

  message = { Requestor: 'NEW.USER.REGISTRATION', Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS',
              Username: 'NEW.USER.REGISTRATION', Password: 'Password001', ForcePasswordChange: 'N', UserIsCurrent: 'N',
              UserPhoneNumber: '01234567890', Forename: 'forename', Surname: 'surname',
              EmailAddress: 'test@example.com', ConfirmEmailAddress: 'test@example.com',
              PartyAccountType: 'TAXPAYER', PartyNINO: nil,
              EmailDataIndicator: 'Y', AddressLine1: 'Royal Mail', AddressLine2: 'Luton Delivery Office 9-11',
              AddressLine3: 'Dunstable Road', AddressLine4: '', AddressTownOrCity: 'LUTON', AddressCountyOrRegion: '',
              AddressCountryCode: 'EN', AddressPostcodeOrZip: 'LU1 1AA',
              UserServices: { 'ins2:UserService' => ['LBTT'] },
              CompanyName: 'NORTHGATE PUBLIC SERVICES LIMITED', RegistrationNumber: '09338960',
              RegisteredAddress: { 'ins1:AddressLine1' => 'Peoplebuilding 2 Peoplebuilding Estate',
                                   'ins1:AddressLine2' => 'Maylands Avenue',
                                   'ins1:AddressTownOrCity' => 'Hemel Hempstead',
                                   'ins1:AddressCountyOrRegion' => 'Hertfordshire',
                                   'ins1:AddressPostcodeOrZip' => 'HP2 4NW',
                                   'ins1:AddressCountryCode' => 'GB' },
              PartyContactName: 'Mr Wobble', PartyEmailAddress: 'noreply@northgateps.com',
              PartyPhoneNumber: '01234567891' }

  fixture = File.read("#{FIXTURES_MOCK_ROOT}registration/register_user.xml")

  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end
