# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock calls associated with slft
# Mock loading an SLfT return for amendment (ie a submitted one)
Before('@mock_slft_load_amend') do
  start_mock
  mock_valid_signin
  message = { 'ins1:TareRefno': '960', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_load_amend.xml")
  @savon.expects(:slft_tax_return_wsdl).with(message: message).returns(fixture)

  message = { ParRefno: '117', Username: 'VALID.USER', Year: '2019', Quarter: 'Q1' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/standard_sites.xml")
  @savon.expects(:slft_sites_wsdl).with(message: message).returns(fixture)

  calc_message = {}
  calc_fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_calculate.xml")
  @savon.expects(:slft_calc_wsdl).with(message: calc_message).returns(calc_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end

# Mock loading an SLfT return with only one site (ie sites list is not an array)
Before('@mock_slft_load_one_site_details') do
  start_mock
  mock_valid_signin
  message = { 'ins1:TareRefno': '960', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_load_one_site.xml")
  @savon.expects(:slft_tax_return_wsdl).with(message: message).returns(fixture)

  message = { ParRefno: '117', Username: 'VALID.USER', Year: '2018', Quarter: 'Q1' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/one_site.xml")
  @savon.expects(:slft_sites_wsdl).with(message: message).returns(fixture)

  calc_message = {}
  calc_fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_calculate.xml")
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
  message = { 'ins1:TareRefno': '960', Version: '1', Username: 'VALID.USER', ParRefno: '117' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_load.xml")
  @savon.expects(:slft_tax_return_wsdl).with(message: message).returns(fixture)

  message = { ParRefno: '117', Username: 'VALID.USER', Year: '2015', Quarter: 'Q1' }
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/standard_sites.xml")
  @savon.expects(:slft_sites_wsdl).with(message: message).returns(fixture)

  # saving draft twice
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_draft_saved.xml")
  @savon.expects(:slft_tax_return_wsdl).with(message: {}).returns(fixture)
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_draft_saved.xml")
  @savon.expects(:slft_tax_return_wsdl).with(message: {}).returns(fixture)
  fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_draft_saved.xml")
  @savon.expects(:slft_tax_return_wsdl).with(message: {}).returns(fixture)

  calc_fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_calculate.xml")
  @savon.expects(:slft_calc_wsdl).with(message: {}).returns(calc_fixture)

  slft_update_fixture = File.read("#{FIXTURES_MOCK_ROOT}slft/slft_update.xml")
  @savon.expects(:slft_tax_return_wsdl).with(message: {}).returns(slft_update_fixture)

  Rails.logger.debug { "Mocking configured : #{@savon.inspect}" }
end
