# frozen_string_literal: true

require 'savon/mock/spec_helper'

# set up the Savon mocks each mock should be given a descriptive tag name
# This file contains procedures to mock the dashboard pages
def mock_dashboard_calls(party_ref, requestor, filename)
  # Mock Caching call to get account details
  mock_get_account_details(party_ref, requestor, filename)
  mock_list_user
  # Mock the move to the dashboard page
  mock_list_secure_messages(party_ref, requestor)
  mock_all_returns(party_ref, requestor)
  mock_all_returns(party_ref, requestor)
end

def mock_all_returns(party_ref, requestor)
  fixture = File.read(FIXTURES_MOCK_ROOT + 'dashboard/list_all_returns.xml')
  message = { ParRefno: party_ref, Username: requestor }
  @savon.expects(:view_all_returns_wsdl).with(message: message).returns(fixture)
end

def mock_list_financial_transactions(party_ref, requestor)
  fixture = File.read(FIXTURES_MOCK_ROOT + 'dashboard/list_transactions.xml')
  message = { ParRefno: party_ref, RequestUser: requestor }
  @savon.expects(:get_transactions_wsdl).with(message: message).returns(fixture)
end

# list of secure message
def mock_list_secure_messages(party_ref, requestor)
  fixture = File.read(FIXTURES_MOCK_ROOT + 'dashboard/list_secure_messages.xml')
  message = { ParRefno: party_ref, Username: requestor,
              WrkRefno: 1, SRVCode: nil, SmsgOriginalRefno: '',
              Pagination: { 'ins1:StartRow' => 1, 'ins1:NumRows' => 3 } }
  @savon.expects(:list_secure_messages_wsdl).with(message: message).returns(fixture)
end

def mock_list_user
  fixture = File.read(FIXTURES_MOCK_ROOT + 'dashboard/list_users.xml')
  @savon.expects(:maintain_user_wsdl).with(message: :any).returns(fixture)
end

def mock_get_account_details(party_ref, requestor, filename)
  fixture = File.read(FIXTURES_MOCK_ROOT + 'dashboard/' + filename + '.xml')
  message = { PartyRef: party_ref, 'ins1:Requestor': requestor }
  @savon.expects(:get_party_details_wsdl).with(message: message).returns(fixture)
end
