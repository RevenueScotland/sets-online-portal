# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock calls associated with the lbtt returns
def load_lbtt_convey
  message = { 'ins0:TareRefno': '251', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}lbtt/lbtt_load_convey.xml")
  @savon.expects(:lbtt_tax_return_wsdl).with(message: message).returns(fixture)
end

# Mock updating an LBTT return
Before('@mock_update_lbtt_details') do
  start_mock
  mock_valid_signin
  load_lbtt_convey

  calc_fixture = File.read("#{FIXTURES_MOCK_ROOT}lbtt/lbtt_tax_calc.xml")
  @savon.expects(:get_lbtt_calc_wsdl).with(message: {}).returns(calc_fixture)
  @savon.expects(:get_lbtt_calc_wsdl).with(message: {}).returns(calc_fixture)

  lbtt_update_fixture = File.read("#{FIXTURES_MOCK_ROOT}lbtt/lbtt_update.xml")
  @savon.expects(:lbtt_tax_return_wsdl).with(message: {}).returns(lbtt_update_fixture)

  mock_get_secure_message_reference('117', 'VALID.USER', 'RS1000202XWQY')

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock updating an LBTT return
Before('@mock_address_identifier_details') do
  start_mock
  mock_valid_signin
  mock_address_search
  mock_address_details
  mock_address_search
  mock_address_details

  lbtt = { :'ins0:FlbtType' => 'CONVEY', :'ins0:PropertyType' => nil,
           'ins0:LBTTCalculationScheme' => nil,
           :'ins0:EffectiveDate' => nil, :'ins0:RelevantDate' => nil,
           :'ins0:ContractDate' => nil, :'ins0:PreviousOptionInd' => nil,
           :'ins0:ExchangeInd' => nil, :'ins0:UKInd' => nil,
           'ins0:Parties' => { 'ins0:Party': [mock_party1, mock_party2, mock_agent] },
           'ins0:LinkedConsideration' => 0, 'ins0:BusinessInd' => nil, 'ins0:TotalConsideration' => nil,
           'ins0:TotalVat' => nil, 'ins0:NonChargeable' => nil, 'ins0:RemainingChargeable' => nil,
           'ins0:Calculated' => nil, 'ins0:AdsDue' => nil,
           'ins0:DueBeforeReliefs' => '0.0', 'ins0:TotalReliefs' => nil,
           'ins0:TotalADSReliefs' => nil, 'ins0:TaxDue' => '0', 'ins0:OrigCalculated' => nil, 'ins0:OrigAdsDue' => nil,
           'ins0:OrigDueBeforeReliefs' => '0.0', 'ins0:OrigTotalReliefs' => nil, 'ins0:OrigTaxDue' => '0',
           'ins0:OrigNetPresentValue' => nil, 'ins0:OrigTotalADSReliefs' => nil, 'ins0:OrigPremiumTaxDue' => nil,
           'ins0:AdsDueInd' => 'no', 'ins0:ContingentsEventInd' => nil }

  msg = { FormType: 'D', Version: '1', Username: 'VALID.USER', ParRefno: '117',
          'ins0:LBTTReturnDetails': lbtt }
  lbtt_save_draft_fixture = File.read("#{FIXTURES_MOCK_ROOT}lbtt/lbtt_draft_saved.xml")
  @savon.expects(:lbtt_tax_return_wsdl).with(message: msg).returns(lbtt_save_draft_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock calling the back office and getting a success=false no messages error which should send the user to the
# error page with a back link on it
# This is only used for development testing # @see errors.feature
Before('@mock_lbtt_serious_back_office_error') do
  start_mock
  mock_valid_signin
  message = { 'ins0:TareRefno': '251', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}lbtt/lbtt_load_success_false_no_messages.xml")
  @savon.expects(:lbtt_tax_return_wsdl).with(message: message).returns(fixture)

  # back to the dashboard
  mock_list_secure_messages('117', 'VALID.USER')
  mock_all_returns('117', 'VALID.USER')
  mock_all_returns('117', 'VALID.USER')
  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# party 1 for the mock_address_identifier_details
def mock_party1
  { :'ins0:PartyType' => 'PER', 'ins0:LpltType' => 'PRIVATE', 'ins0:FlptType' => 'BUYER',
    'ins0:PersonName' => { 'ins0:Title': '', 'ins0:Forename': 'Albert', 'ins0:Surname': 'Buyer' },
    'ins0:Address' => { :'ns1:AddressLine1' => 'Royal Mail', 'ns1:AddressLine2' => 'Luton Delivery Office 9-11',
                        'ns1:AddressLine3' => 'Dunstable Road', 'ns1:AddressTownOrCity' => 'LUTON',
                        'ns1:AddressPostcodeOrZip' => 'LU1 1AA', 'ns1:AddressCountryCode' => 'EN',
                        'ns1:QASMoniker' => '14174279' },
    'ins0:AuthorityInd' => 'no', 'ins0:TelNo' => '0123456789', 'ins0:EmailAddress' => 'noreply@necsws.com',
    'ins0:ParPerNiNo' => 'AB123456C', 'ins0:AlternateReference' => { 'ins0:AlrtType': '',
                                                                     'ins0:RefCountry': '', 'ins0:Reference': '' },
    'ins0:BuyerSellerLinkedInd' => 'no', 'ins0:ActingAsTrusteeInd' => 'no' }
end

# party 1 for the mock_address_identifier_details
def mock_party2
  { :'ins0:PartyType' => 'PER', 'ins0:LpltType' => 'PRIVATE', 'ins0:FlptType' => 'BUYER',
    'ins0:PersonName' => { 'ins0:Title': '', 'ins0:Forename': 'Bert', 'ins0:Surname': 'Buyer' },
    'ins0:Address' => { :'ns1:AddressLine1' => 'Royal Mail', 'ns1:AddressLine2' => 'Luton Delivery Office 9-11',
                        'ns1:AddressLine3' => 'Dunstable Road', 'ns1:AddressTownOrCity' => 'LUTON',
                        'ns1:AddressPostcodeOrZip' => 'LU1 1AA', 'ns1:AddressCountryCode' => 'EN' },
    'ins0:AuthorityInd' => 'no', 'ins0:TelNo' => '0123456780', 'ins0:EmailAddress' => 'noreply2@necsws.com',
    'ins0:ParPerNiNo' => 'NP123456D', 'ins0:AlternateReference' => { 'ins0:AlrtType': '',
                                                                     'ins0:RefCountry': '', 'ins0:Reference': '' },
    'ins0:BuyerSellerLinkedInd' => 'no', 'ins0:ActingAsTrusteeInd' => 'no' }
end

# Agent for the mock_address_identifier_details
def mock_agent
  { :'ins0:PartyType' => 'PER', 'ins0:LpltType' => 'PRIVATE', 'ins0:FlptType' => 'AGENT',
    'ins0:PersonName' => { 'ins0:Title': nil, 'ins0:Forename': 'Valid', 'ins0:Surname': 'User' },
    'ins0:AuthorityInd' => 'no', 'ins0:EmailAddress' => 'valid.user@necsws.com',
    'ins0:BuyerSellerLinkedInd' => nil, 'ins0:ActingAsTrusteeInd' => nil }
end
