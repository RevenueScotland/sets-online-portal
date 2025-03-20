# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock calls associated with Sat

# Mock loading an Sat return for submission (ie a draft one)
# And to validate the dd warning for amendement
Before('@mock_sat_load_return_draft') do
  start_mock
  mock_valid_sat_signin

  message = { 'ins0:TareRefno': '1338', Version: '1', Username: 'VALID.USER', ParRefno: '3752',
              'ins0:EnrmRefno': '142', 'ins0:EnrmRegistrationRef': 'SAT1000000TVTV' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/sat_load_draft.xml")
  @savon.expects(:get_sat_return_wsdl).with(message: message).returns(fixture)

  mock_agg_rates
  mock_return_periods
  mock_calc
  mock_party

  sat_return_message = {}
  sat_return_fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/sat_return.xml")
  @savon.expects(:sat_return_wsdl).with(message: sat_return_message).returns(sat_return_fixture)

  message = { 'ins0:TareRefno': '1338', Version: '2', Username: 'VALID.USER', ParRefno: '3752',
              'ins0:EnrmRefno': '142', 'ins0:EnrmRegistrationRef': 'SAT1000000TVTV' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/sat_load_amend.xml")
  @savon.expects(:get_sat_return_wsdl).with(message: message).returns(fixture)

  mock_agg_rates
  mock_return_periods
  mock_calc
  mock_party

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock loading an Sat return for amendment (ie a submitted one)
Before('@mock_sat_load_return_final') do
  start_mock
  mock_valid_sat_signin

  message = { 'ins0:TareRefno': '1339', Version: '2', Username: 'VALID.USER', ParRefno: '3752',
              'ins0:EnrmRefno': '142', 'ins0:EnrmRegistrationRef': 'SAT1000000TVTV' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/sat_load_final.xml")
  @savon.expects(:get_sat_return_wsdl).with(message: message).returns(fixture)

  mock_agg_rates
  mock_return_periods
  mock_calc
  mock_party

  sat_return_message = {}
  sat_return_fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/sat_return_version2.xml")
  @savon.expects(:sat_return_wsdl).with(message: sat_return_message).returns(sat_return_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

def mock_agg_rates
  agg_rates_message = {}
  agg_rates_fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/sat_agg_rates.xml")
  @savon.expects(:get_aggregate_type_rates_wsdl).with(message: agg_rates_message).returns(agg_rates_fixture)
  @savon.expects(:get_aggregate_type_rates_wsdl).with(message: agg_rates_message).returns(agg_rates_fixture)
end

def mock_calc
  calc_message = {}
  calc_fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/sat_calculate.xml")
  @savon.expects(:sat_calc_wsdl).with(message: calc_message).returns(calc_fixture)
end

def mock_party
  party_message = {}
  party_fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/party_details.xml")
  @savon.expects(:get_party_details_wsdl).with(message: party_message).returns(party_fixture)
end

def mock_return_periods
  return_periods_message = {}
  rp_fixture = File.read("#{FIXTURES_MOCK_ROOT}sat/sat_return_periods.xml")
  @savon.expects(:get_return_periods_and_sites_wsdl).with(message: return_periods_message).returns(rp_fixture)
end
