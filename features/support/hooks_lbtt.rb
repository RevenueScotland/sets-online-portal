# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock calls associated with the lbtt returns
def load_lbtt_convey
  message = { 'ins1:TareRefno': '251', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
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

  lbtt = { :'ins1:FlbtType' => 'CONVEY', :'ins1:PropertyType' => nil,
           :'ins1:EffectiveDate' => nil, :'ins1:RelevantDate' => nil,
           :'ins1:ContractDate' => nil, :'ins1:PreviousOptionInd' => nil,
           :'ins1:ExchangeInd' => nil, :'ins1:UKInd' => nil,
           'ins1:Parties' => { 'ins1:Party': [mock_party1, mock_party2, mock_agent] },
           'ins1:LinkedConsideration' => 0, 'ins1:BusinessInd' => nil, 'ins1:TotalConsideration' => nil,
           'ins1:TotalVat' => nil, 'ins1:NonChargeable' => nil, 'ins1:RemainingChargeable' => nil,
           'ins1:Reliefs' => { 'ins1:Relief': [] }, 'ins1:Calculated' => nil, 'ins1:AdsDue' => nil,
           'ins1:DueBeforeReliefs' => '0.0', 'ins1:TotalReliefs' => nil,
           'ins1:TotalADSReliefs' => nil, 'ins1:TaxDue' => '0', 'ins1:OrigCalculated' => nil, 'ins1:OrigAdsDue' => nil,
           'ins1:OrigDueBeforeReliefs' => '0.0', 'ins1:OrigTotalReliefs' => nil, 'ins1:OrigTaxDue' => '0',
           'ins1:OrigNetPresentValue' => nil, 'ins1:OrigTotalADSReliefs' => nil, 'ins1:OrigPremiumTaxDue' => nil,
           'ins1:AdsDueInd' => 'no', 'ins1:ContingentsEventInd' => nil }

  msg = { FormType: 'D', Version: '1', Username: 'VALID.USER', ParRefno: '117',
          'ins1:LBTTReturnDetails': lbtt }
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
  message = { 'ins1:TareRefno': '251', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
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
  { :'ins1:PartyType' => 'PER', 'ins1:LpltType' => 'PRIVATE', 'ins1:FlptType' => 'BUYER',
    'ins1:PersonName' => { 'ins1:Title': '', 'ins1:Forename': 'Albert', 'ins1:Surname': 'Buyer' },
    'ins1:Address' => { :'ins0:AddressLine1' => 'Royal Mail', 'ins0:AddressLine2' => 'Luton Delivery Office 9-11',
                        'ins0:AddressLine3' => 'Dunstable Road', 'ins0:AddressTownOrCity' => 'LUTON',
                        'ins0:AddressPostcodeOrZip' => 'LU1 1AA', 'ins0:AddressCountryCode' => 'EN',
                        'ins0:QASMoniker' => '14174279' },
    'ins1:AuthorityInd' => 'no', 'ins1:TelNo' => '0123456789', 'ins1:EmailAddress' => 'noreply@northgateps.com',
    'ins1:ParPerNiNo' => 'AB123456C', 'ins1:AlternateReference' => { 'ins1:AlrtType': '',
                                                                     'ins1:RefCountry': '', 'ins1:Reference': '' },
    'ins1:BuyerSellerLinkedInd' => 'no', 'ins1:BuyerSellerLinkedDesc' => '', 'ins1:ActingAsTrusteeInd' => 'no' }
end

# party 1 for the mock_address_identifier_details
def mock_party2
  { :'ins1:PartyType' => 'PER', 'ins1:LpltType' => 'PRIVATE', 'ins1:FlptType' => 'BUYER',
    'ins1:PersonName' => { 'ins1:Title': '', 'ins1:Forename': 'Bert', 'ins1:Surname': 'Buyer' },
    'ins1:Address' => { :'ins0:AddressLine1' => 'Royal Mail', 'ins0:AddressLine2' => 'Luton Delivery Office 9-11',
                        'ins0:AddressLine3' => 'Dunstable Road', 'ins0:AddressTownOrCity' => 'LUTON',
                        'ins0:AddressPostcodeOrZip' => 'LU1 1AA', 'ins0:AddressCountryCode' => 'EN' },
    'ins1:AuthorityInd' => 'no', 'ins1:TelNo' => '0123456780', 'ins1:EmailAddress' => 'noreply2@northgateps.com',
    'ins1:ParPerNiNo' => 'NP123456D', 'ins1:AlternateReference' => { 'ins1:AlrtType': '',
                                                                     'ins1:RefCountry': '', 'ins1:Reference': '' },
    'ins1:BuyerSellerLinkedInd' => 'no', 'ins1:BuyerSellerLinkedDesc' => '', 'ins1:ActingAsTrusteeInd' => 'no' }
end

# Agent for the mock_address_identifier_details
def mock_agent
  { :'ins1:PartyType' => 'PER', 'ins1:LpltType' => 'PRIVATE', 'ins1:FlptType' => 'AGENT',
    'ins1:PersonName' => { 'ins1:Title': nil, 'ins1:Forename': 'Valid', 'ins1:Surname': 'User' },
    'ins1:AuthorityInd' => 'no', 'ins1:EmailAddress' => 'valid.user@northgateps.com',
    'ins1:BuyerSellerLinkedInd' => nil, 'ins1:BuyerSellerLinkedDesc' => '', 'ins1:ActingAsTrusteeInd' => nil }
end
