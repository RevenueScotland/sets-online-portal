# frozen_string_literal: true

# set up the savon mocks each mock should be given a descriptive tag name
require 'savon/mock/spec_helper'

def start_mock
  @savon ||= Savon::SpecHelper::Interface.new
  @savon.mock!
  Rails.logger.debug { "Mocking started :  #{@savon.inspect}" }
end

def mock_dashboard_calls
  # Mock Caching call to get account details
  mock_get_account_details('117', 'VALID.USER', 'get_account_details')
  mock_list_user
  # Mock the move to the dashboard page
  mock_list_secure_messages('117', 'VALID.USER')
  mock_all_returns('117', 'VALID.USER')
  mock_all_returns('117', 'VALID.USER')
end

def mock_valid_signin
  message = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/normal_login/valid_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_dashboard_calls
end

def mock_two_factor_signin(token_value, two_factor_response)
  message = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/two_factor/valid_signin_2factor.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  message = { Username: 'VALID.USER', Token: token_value }
  fixture = File.read(File.join('test/fixtures/files/two_factor', two_factor_response))
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)

  mock_dashboard_calls
end

def mock_valid_two_factor_signin
  mock_two_factor_signin 'valid.token', 'valid_signin_token.xml'
end

def mock_invalid_two_factor_signin
  mock_two_factor_signin 'invalid.token', 'invalid_token.xml'
end

def mock_expired_two_factor_signin
  mock_two_factor_signin 'expired.token', 'expired_token.xml'
end

def mock_not_activated_two_factor_signin
  mock_two_factor_signin 'valid.token', 'not_activated_user_signin.xml'
end

def mock_password_expired_two_factor_signin
  mock_two_factor_signin 'valid.token', 'expired_password_signin.xml'
end

def mock_force_password_change_two_factor_signin
  mock_two_factor_signin 'valid.token', 'forced_password_change_signin.xml'
end

def mock_confirm_tc_two_factor_signin
  mock_two_factor_signin 'valid.token', 'confirm_tcs.xml'
end

# ViewAllReturns
def mock_all_returns(party_ref, requestor)
  fixture = File.read('test/fixtures/files/list_all_returns.xml')
  message = { ParRefno: party_ref, Username: requestor }
  @savon.expects(:view_all_returns_wsdl).with(message: message).returns(fixture)
end

def mock_list_financial_transactions(party_ref, requestor)
  fixture = File.read('test/fixtures/files/list_transactions.xml')
  message = { ParRefno: party_ref, RequestUser: requestor }
  @savon.expects(:get_transactions_wsdl).with(message: message).returns(fixture)
end

# list of secure message
def mock_list_secure_messages(party_ref, requestor)
  fixture = File.read('test/fixtures/files/list_secure_messages.xml')
  message = { ParRefno: party_ref, Username: requestor,
              WrkRefno: 1, SRVCode: 'SYS', SmsgOriginalRefno: '',
              Pagination: { 'ins1:StartRow' => 1, 'ins1:NumRows' => 3 } }
  @savon.expects(:list_secure_messages_wsdl).with(message: message).returns(fixture)
end

def mock_list_user
  fixture = File.read('test/fixtures/files/list_users.xml')
  @savon.expects(:maintain_user_wsdl).with(message: :any).returns(fixture)
end

def mock_get_account_details(party_ref, requestor, filename)
  fixture = File.read('test/fixtures/files/' + filename + '.xml')
  message = { PartyRef: party_ref, 'ins1:Requestor': requestor }
  @savon.expects(:get_party_details_wsdl).with(message: message).returns(fixture)
end

def mock_address_details
  fixture = File.read('test/fixtures/files/address_details.xml')
  message = { Address: { 'ins1:AddressIdentifier' => '14174279        ' } }
  @savon.expects(:nas_address_detail_wsdl).with(message: message).returns(fixture)
end

def mock_address_search
  fixture = File.read('test/fixtures/files/address_search.xml')
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
  fixture = File.read('test/fixtures/files/address_alt_details.xml')
  message = { Address: { 'ins1:AddressIdentifier' => '14174279        ' } }
  @savon.expects(:nas_address_detail_wsdl).with(message: message).returns(fixture)
end

def mock_alt_address_search
  fixture = File.read('test/fixtures/files/address_alt_search.xml')
  message = { RequestParameters: {},
              SearchParameters: { 'ins1:Postcode' => 'RG30 6XT' },
              SelectionOptions: { 'ins1:MaximumNumberOfRows' => 200,
                                  'ins1:IncludeNonGeographicAddresses' => false,
                                  'ins1:IncludeBFPOAddresses' => false,
                                  'ins1:IncludeMultiResidenceAddresses' => false,
                                  'ins1:IncludeNIAddresses' => true } }
  @savon.expects(:nas_address_search_wsdl).with(message: message).returns(fixture)
end

# Mock a locked user sign in
Before('@mock_locked_user') do
  start_mock
  message = { Username: 'LOCKED.USER', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/normal_login/locked_user_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a non activated user sign in
Before('@mock_not_actived_user') do
  start_mock
  message = { Username: 'NOT.ACTIVATED.USER', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/normal_login/not_activated_user_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a activating account to complete registration
Before('@mock_activate_account') do
  start_mock
  message = { Action: 'CompleteRegistration', RegistrationToken: 'valid.registation.token' }
  fixture = File.read('test/fixtures/files/activate_account.xml')
  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a forced password change user sign in
Before('@mock_forced_password_change') do
  start_mock
  message = { Username: 'FORCED.PASSWORD.CHANGE.USER', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/normal_login/forced_password_change_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_get_account_details('189', 'FORCED.PASSWORD.CHANGE.USER', 'get_account_details')
  mock_list_user
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a forced password change user and confirming terms and conditions for a user with limited
# permissions
Before('@mock_force_password_change_and_tc_limited_permissions') do
  start_mock
  message = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/limited_perms/forced_password_change_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_get_account_details('189', 'VALID.USER', 'get_account_details')
  mock_list_user

  message_pwd = { Username: 'VALID.USER', Requestor: 'VALID.USER', Action: 'ChangePassword',
                  OldPassword: 'valid.password', NewPassword: 'New.password1', ServiceCode: 'SYS' }
  fixture_pwd = File.read('test/fixtures/files/change_password.xml')
  @savon.expects(:maintain_user_wsdl).with(message: message_pwd).returns(fixture_pwd)

  message_logoff = { Username: 'VALID.USER' }
  fixture_logoff = File.read('test/fixtures/files/limited_perms/logoff.xml')
  @savon.expects(:log_off_user_wsdl).with(message: message_logoff).returns(fixture_logoff)

  message_tc = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture_tc = File.read('test/fixtures/files/limited_perms/confirm_tcs.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message_tc).returns(fixture_tc)
  mock_get_account_details('189', 'VALID.USER', 'get_account_details')
  mock_list_user

  message = { Username: 'VALID.USER', Action: 'TaCsSignUp' }
  fixture = File.read('test/fixtures/files/update_confirm_tcs.xml')
  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)

  mock_list_secure_messages('189', 'VALID.USER')
  mock_all_returns('189', 'VALID.USER')
  mock_all_returns('189', 'VALID.USER')
end

# Mock a user whose password will expire after 4 days
Before('@mock_due_password') do
  start_mock
  message = { Username: 'DUE.PASSWORD', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/normal_login/due_password_signin.xml')

  # To run this test successfully,replaces expiry_date to 4 days future date
  fixture.sub!(/\d{4}-\d{2}-\d{2}/, (Date.today + 4).to_s)

  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_get_account_details('189', 'DUE.PASSWORD', 'get_due_password_account_details')
  mock_list_user
  mock_list_secure_messages('189', 'DUE.PASSWORD')
  mock_all_returns('189', 'DUE.PASSWORD')
  mock_all_returns('189', 'DUE.PASSWORD')
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock a user that needs to confirm the t&cs
Before('@mock_confirm_tcs') do
  start_mock
  message = { Username: 'VALID.USER', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/normal_login/confirm_tcs.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)

  mock_get_account_details('117', 'VALID.USER', 'get_account_details')
  mock_list_user

  message = { Username: 'VALID.USER', Action: 'TaCsSignUp' }
  fixture = File.read('test/fixtures/files/update_confirm_tcs.xml')
  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)

  mock_list_secure_messages('117', 'VALID.USER')
  mock_all_returns('117', 'VALID.USER')
  mock_all_returns('117', 'VALID.USER')
end

# Mock an expired user signin
Before('@mock_expired_password') do
  start_mock
  message = { Username: 'EXPIRED.PASSWORD', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/normal_login/expired_password_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
  mock_get_account_details('189', 'EXPIRED.PASSWORD', 'get_account_details')
  mock_list_user
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock for change password
Before('@mock_change_password') do
  start_mock
  mock_valid_signin
  message = { Username: 'VALID.USER', Requestor: 'VALID.USER', Action: 'ChangePassword',
              OldPassword: 'valid.password', NewPassword: 'New.password1', ServiceCode: 'SYS' }
  fixture = File.read('test/fixtures/files/change_password.xml')
  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

Before('@mock_two_factor_login') do
  start_mock
  mock_valid_two_factor_signin
end

Before('@mock_two_factor_login_invalid_token') do
  start_mock
  mock_invalid_two_factor_signin
end

Before('@mock_two_factor_login_expired_token') do
  start_mock
  mock_expired_two_factor_signin
end

Before('@mock_two_factor_login_user_locked') do
  start_mock
  message = { Username: 'LOCKED.USER', Password: 'valid.password' }
  fixture = File.read('test/fixtures/files/two_factor/locked_user_signin.xml')
  @savon.expects(:authenticate_user_wsdl).with(message: message).returns(fixture)
end

Before('@mock_two_factor_login_user_not_activated') do
  start_mock
  mock_not_activated_two_factor_signin
end

Before('@mock_two_factor_login_expired_password') do
  start_mock
  mock_password_expired_two_factor_signin
  mock_list_user
end

Before('@mock_two_factor_login_force_password_change') do
  start_mock
  mock_force_password_change_two_factor_signin
  mock_list_user
end

Before('@mock_two_factor_confirm_tcs') do
  start_mock
  mock_confirm_tc_two_factor_signin
end

# Mock for new user registration
Before('@mock_new_user_registration') do
  start_mock
  mock_address_search
  mock_address_details
  message = { Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS',
              Username: 'NEW.USER.REGISTRATION', Password: 'Password001', ForcePasswordChange: 'N', UserIsCurrent: 'N',
              Forename: 'forename', Surname: 'surname', EmailAddress: 'test@example.com', EmailDataIndicator: 'Y',
              ConfirmEmailAddress: 'test@example.com', AddressLine1: 'Royal Mail', PartyNINO: 'AB123456D',
              AddressLine2: 'Luton Delivery Office 9-11', AddressTownOrCity: 'LUTON', AddressCountryCode: 'GB',
              AddressPostcodeOrZip: 'LU1 1AA', PartyAccountType: 'TAXPAYER',
              UserServices: { 'ins2:UserService' => ['LBTT'] } }
  fixture = File.read('test/fixtures/files/register_user.xml')

  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

Before('@mock_new_other_company_registration') do
  start_mock
  mock_address_search
  mock_address_details
  mock_alt_address_search
  mock_alt_address_details
  message = { Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS', UserPhoneNumber: '01234567890',
              Username: 'NEW.USER.REGISTRATION', Password: 'Password001', ForcePasswordChange: 'N', UserIsCurrent: 'N',
              Forename: 'forename', Surname: 'surname', EmailAddress: 'test@example.com', EmailDataIndicator: 'Y',
              ConfirmEmailAddress: 'test@example.com', AddressLine1: '10 Rydal Avenue', PartyNINO: 'AB123456D',
              AddressLine2: 'Tilehurst', AddressTownOrCity: 'READING', AddressCountyOrRegion: '',
              AddressCountryCode: 'GB', AddressPostcodeOrZip: 'RG30 6XT', PartyAccountType: 'TAXPAYER',
              PartyPhoneNumber: '01234567891', PartyEmailAddress: 'noreply@northgateps.com',
              PartyContactName: 'Mr Wobble', UserServices: { 'ins2:UserService' => ['LBTT'] },
              CompanyName: 'Other Company',
              RegisteredAddress: { 'ins1:AddressLine1' => 'Royal Mail',
                                   'ins1:AddressLine2' => 'Luton Delivery Office 9-11',
                                   'ins1:AddressTownOrCity' => 'LUTON',
                                   'ins1:AddressCountyOrRegion' => '',
                                   'ins1:AddressPostcodeOrZip' => 'LU1 1AA', 'ins1:AddressCountryCode' => 'GB' } }
  fixture = File.read('test/fixtures/files/register_user.xml')

  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

Before('@mock_new_company_no_address_registration') do
  start_mock
  message = { Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS', UserPhoneNumber: '01234567890',
              Username: 'NEW.USER.REGISTRATION', Password: 'Password001', ForcePasswordChange: 'N', UserIsCurrent: 'N',
              Forename: 'forename', Surname: 'surname', EmailAddress: 'test@example.com', EmailDataIndicator: 'Y',
              ConfirmEmailAddress: 'test@example.com', AddressLine1: 'Peoplebuilding 2 Peoplebuilding Estate',
              AddressLine2: 'Maylands Avenue', AddressTownOrCity: 'Hemel Hempstead',
              AddressCountryCode: 'GB', AddressPostcodeOrZip: 'HP2 4NW', PartyAccountType: 'TAXPAYER',
              PartyPhoneNumber: '01234567891', PartyEmailAddress: 'noreply@northgateps.com',
              PartyContactName: 'Mr Wobble', UserServices: { 'ins2:UserService' => ['LBTT'] },
              CompanyName: 'NORTHGATE PUBLIC SERVICES LIMITED', RegistrationNumber: '09338960',
              RegisteredAddress: { 'ins1:AddressLine1' => 'Peoplebuilding 2 Peoplebuilding Estate',
                                   'ins1:AddressLine2' => 'Maylands Avenue',
                                   'ins1:AddressTownOrCity' => 'Hemel Hempstead',
                                   'ins1:AddressCountyOrRegion' => 'Hertfordshire',
                                   'ins1:AddressPostcodeOrZip' => 'HP2 4NW', 'ins1:AddressCountryCode' => 'GB' } }
  fixture = File.read('test/fixtures/files/register_user.xml')

  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

Before('@mock_new_company_registration') do
  start_mock
  mock_address_search
  mock_address_details
  message = { Action: 'CREATE', WorkplaceCode: '3', ServiceCode: 'SYS', UserPhoneNumber: '01234567890',
              Username: 'NEW.USER.REGISTRATION', Password: 'Password001', ForcePasswordChange: 'N', UserIsCurrent: 'N',
              Forename: 'forename', Surname: 'surname', EmailAddress: 'test@example.com',
              ConfirmEmailAddress: 'test@example.com', AddressLine1: 'Royal Mail', EmailDataIndicator: 'Y',
              AddressLine2: 'Luton Delivery Office 9-11', AddressTownOrCity: 'LUTON', AddressCountryCode: 'GB',
              AddressPostcodeOrZip: 'LU1 1AA', PartyAccountType: 'TAXPAYER', PartyPhoneNumber: '01234567891',
              PartyEmailAddress: 'noreply@northgateps.com', PartyContactName: 'Mr Wobble',
              UserServices: { 'ins2:UserService' => ['LBTT'] }, CompanyName: 'NORTHGATE PUBLIC SERVICES LIMITED',
              RegistrationNumber: '09338960',
              RegisteredAddress: { 'ins1:AddressLine1' => 'Peoplebuilding 2 Peoplebuilding Estate',
                                   'ins1:AddressLine2' => 'Maylands Avenue',
                                   'ins1:AddressTownOrCity' => 'Hemel Hempstead',
                                   'ins1:AddressCountyOrRegion' => 'Hertfordshire',
                                   'ins1:AddressPostcodeOrZip' => 'HP2 4NW', 'ins1:AddressCountryCode' => 'GB' } }
  fixture = File.read('test/fixtures/files/register_user.xml')

  @savon.expects(:maintain_user_wsdl).with(message: message).returns(fixture)
  Rails.logger.debug { "Mocking configured :  #{@savon.inspect}" }
end

# Mock loading an SLfT return for amendment (ie a submitted one)
Before('@mock_slft_load_amend') do
  start_mock
  mock_valid_signin
  message = { "ins1:TareRefno": '960', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read('test/fixtures/files/slft_load_amend.xml')
  @savon.expects(:slft_tax_return_wsdl).with(message: message).returns(fixture)

  calc_message = {}
  calc_fixture = File.read('test/fixtures/files/slft_calculate.xml')
  @savon.expects(:slft_calc_wsdl).with(message: calc_message).returns(calc_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock loading an SLfT return with missing sites to check we're fault tolerant
Before('@mock_slft_load_no_sites_details') do
  start_mock
  mock_valid_signin
  message = { "ins1:TareRefno": '960', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read('test/fixtures/files/slft_load_no_sites.xml')
  @savon.expects(:slft_tax_return_wsdl).with(message: message).returns(fixture)

  calc_message = {}
  calc_fixture = File.read('test/fixtures/files/slft_calculate.xml')
  @savon.expects(:slft_calc_wsdl).with(message: calc_message).returns(calc_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock loading an SLfT return with only one site (ie sites list is not an array)
Before('@mock_slft_load_one_site_details') do
  start_mock
  mock_valid_signin
  message = { "ins1:TareRefno": '960', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read('test/fixtures/files/slft_load_one_site.xml')
  @savon.expects(:slft_tax_return_wsdl).with(message: message).returns(fixture)

  calc_message = {}
  calc_fixture = File.read('test/fixtures/files/slft_calculate.xml')
  @savon.expects(:slft_calc_wsdl).with(message: calc_message).returns(calc_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock calculate an SLfT return tax liability
Before('@mock_slft_calculate') do
  start_mock
  mock_valid_signin
  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock Amend SLfT draft return and mock submit
Before('@mock_slft_load_submit_draft') do
  start_mock
  mock_valid_signin
  message = { "ins1:TareRefno": '960', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read('test/fixtures/files/slft_load.xml')
  @savon.expects(:slft_tax_return_wsdl).with(message: message).returns(fixture)

  # saving draft twice
  fixture = File.read('test/fixtures/files/slft_draft_saved.xml')
  @savon.expects(:slft_tax_return_wsdl).with(message: {}).returns(fixture)
  fixture = File.read('test/fixtures/files/slft_draft_saved.xml')
  @savon.expects(:slft_tax_return_wsdl).with(message: {}).returns(fixture)
  fixture = File.read('test/fixtures/files/slft_draft_saved.xml')
  @savon.expects(:slft_tax_return_wsdl).with(message: {}).returns(fixture)

  calc_fixture = File.read('test/fixtures/files/slft_calculate.xml')
  @savon.expects(:slft_calc_wsdl).with(message: {}).returns(calc_fixture)

  slft_update_fixture = File.read('test/fixtures/files/slft_update.xml')
  @savon.expects(:slft_tax_return_wsdl).with(message: {}).returns(slft_update_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Sets the savon expectation that will load an LBTT conveyance return
def load_lbtt_convey
  message = { "ins1:TareRefno": '251', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read('test/fixtures/files/lbtt_load_convey.xml')
  @savon.expects(:lbtt_tax_return_wsdl).with(message: message).returns(fixture)
end

# Mock loading an LBTT return
Before('@mock_load_lbtt_convey_details_with_tax_calc') do
  start_mock
  mock_valid_signin
  load_lbtt_convey

  calc_message = {}
  calc_fixture = File.read('test/fixtures/files/lbtt_tax_calc.xml')
  @savon.expects(:get_lbtt_calc_wsdl).with(message: calc_message).returns(calc_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock loading an LBTT return and responses for the amend tests
Before('@mock_load_lbtt_convey_details_for_amend') do
  start_mock
  mock_valid_signin
  load_lbtt_convey

  mock_address_search
  mock_address_details
  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock updating an LBTT return
Before('@mock_update_lbtt_details') do
  start_mock
  mock_valid_signin
  load_lbtt_convey

  calc_fixture = File.read('test/fixtures/files/lbtt_tax_calc.xml')
  @savon.expects(:get_lbtt_calc_wsdl).with(message: {}).returns(calc_fixture)

  lbtt_update_fixture = File.read('test/fixtures/files/lbtt_update.xml')
  @savon.expects(:lbtt_tax_return_wsdl).with(message: {}).returns(lbtt_update_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Clear the mocks after each scenario
After do
  @savon&.unmock!
  Rails.logger.debug { "Mocking ended :  #{@savon&.inspect}" }
end
