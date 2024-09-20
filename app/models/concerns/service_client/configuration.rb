# frozen_string_literal: true

module ServiceClient
  # Service Clients configuration for the back office and pre-loader method used as part of initialisation
  class Configuration # rubocop:disable Metrics/ClassLength
    # Firstly, service endpoint details
    fl_endpoint = { root: Rails.configuration.x.fl_endpoint.root, username: Rails.configuration.x.fl_endpoint.uid,
                    password: Rails.configuration.x.fl_endpoint.pwd, wsdl_root: 'fl',
                    timeout: Rails.configuration.x.fl_endpoint.timeout }
    nadr_endpoint = { root: Rails.configuration.x.nadr_endpoint.root, username: Rails.configuration.x.nadr_endpoint.uid,
                      password: Rails.configuration.x.nadr_endpoint.pwd, wsdl_root: 'nas',
                      timeout: Rails.configuration.x.nadr_endpoint.timeout,
                      proxy: Rails.configuration.x.nadr_endpoint.proxy }

    # Secondly, service details (in alphabetical order)
    # :savon_log can be set to false so that both the SOAP request and response would not be logged for it.
    add_attachment = { service: fl_endpoint, wsdl: 'AddAttachment.wsdl', endpoint: '/addAttachment',
                       operation: :add_attachment_wsdl, response: :add_attachment_response }
    add_document = { service: fl_endpoint, wsdl: 'AddDocument.wsdl', endpoint: '/AddDocument',
                     operation: :add_document_wsdl, response: :add_document_response }
    address_detail = { service: nadr_endpoint, wsdl: 'NASAddressDetail.wsdl', endpoint: '/GetAddressDetail',
                       operation: :nas_address_detail_wsdl, response: :address_detail_response }
    address_search = { service: nadr_endpoint, wsdl: 'NASAddressSearch.wsdl', endpoint: '/AddressSearch',
                       operation: :nas_address_search_wsdl, response: :address_search_response }
    authenticate_user = { service: fl_endpoint, wsdl: 'FLAuthenticateUser.wsdl', endpoint: '/authenticateUser',
                          operation: :authenticate_user_wsdl, response: :authenticate_user_response }
    claim_repayment_details = { service: fl_endpoint, wsdl: 'ClaimRepaymentDetails.wsdl',
                                endpoint: '/ClaimRepaymentDetails', operation: :claim_repayment_details_wsdl,
                                response: :claim_repayment_details_response }
    delete_attachment = { service: fl_endpoint, wsdl: 'DeleteAttachment.wsdl', endpoint: '/deleteAttachment',
                          operation: :delete_attachment_wsdl, response: :delete_attachment_response }
    delete_document = { service: fl_endpoint, wsdl: 'DeleteDocument.wsdl', endpoint: '/DeleteDocument',
                        operation: :delete_document_wsdl, response: :delete_document_response }
    delete_draft_tax_return = { service: fl_endpoint, wsdl: 'DeleteDraftTaxReturn.wsdl',
                                endpoint: '/deleteDraftTaxReturn',
                                operation: :delete_draft_tax_return_wsdl, response: :delete_draft_tax_return_response }
    get_attachment = { service: fl_endpoint, wsdl: 'GetAttachment.wsdl', endpoint: '/getAttachment',
                       operation: :get_attachment_wsdl, response: :get_attachment_response }
    get_party_details = { service: fl_endpoint, wsdl: 'FLGetPartyDetails.wsdl',
                          endpoint: '/getPartyDetailsRequest', operation: :get_party_details_wsdl,
                          response: :get_party_details_response }
    get_pws_text = { service: fl_endpoint, wsdl: 'PublicWebsiteText.wsdl', endpoint: '/getPWSText',
                     operation: :public_website_text_wsdl, response: :get_pws_text_response, savon_log: false }
    get_reference_values = { service: fl_endpoint, wsdl: 'GetReferenceValues.wsdl', endpoint: '/getReferenceValues',
                             operation: :get_reference_values_wsdl, response: :get_reference_values_response,
                             savon_log: false }
    get_role_actions = { service: fl_endpoint, wsdl: 'GetRoleActions.wsdl',
                         endpoint: '/getRoleActions', operation: :get_role_action_wsdl,
                         response: :get_role_actions_response }
    get_secure_message_details = { service: fl_endpoint, wsdl: 'GetSecureMessages.wsdl',
                                   endpoint: '/GetSecureMessageDetails', operation: :get_secure_messages_wsdl,
                                   response: :get_secure_message_response }
    get_sites = { service: fl_endpoint, wsdl: 'SLFTSites.wsdl', endpoint: '/SLFTPartySites',
                  operation: :slft_sites_wsdl, response: :slft_sites_response }
    get_system_parameters = { service: fl_endpoint, wsdl: 'GetSystemParameters.wsdl', endpoint: '/getSystemParameters',
                              operation: :get_system_parameters_wsdl, response: :get_system_parameters_response,
                              savon_log: false }
    get_tax_relief_types = { service: fl_endpoint, wsdl: 'GetTaxReliefTypes.wsdl',
                             endpoint: '/GetTaxReliefTypes',
                             operation: :get_tax_relief_types_wsdl, response: :get_tax_relief_types_response,
                             savon_log: false }
    get_transactions = { service: fl_endpoint, wsdl: 'GetTransactions.wsdl', endpoint: '/getTransactions',
                         operation: :get_transactions_wsdl, response: :get_transactions_response }
    lbtt_calc = { service: fl_endpoint, wsdl: 'LBTTCalc.wsdl', endpoint: '/GetLBTTCalc',
                  operation: :get_lbtt_calc_wsdl, response: :lbtt_calc_response }
    lbtt_tax_return = { service: fl_endpoint, wsdl: 'LBTTTaxReturn.wsdl', endpoint: '/createLBTTReturn',
                        operation: :lbtt_tax_return_wsdl, response: :lbtt_tax_return_response }
    lbtt_tax_return_details = { service: fl_endpoint, wsdl: 'LBTTTaxReturnDetails.wsdl',
                                endpoint: '/LBTTTaxReturnDetails', operation: :lbtt_tax_return_wsdl,
                                response: :lbtt_tax_return_response }
    lbtt_update = { service: fl_endpoint, wsdl: 'LBTTTaxReturnUpdate.wsdl', endpoint: '/updateLBTTTaxReturn',
                    operation: :lbtt_tax_return_wsdl, response: :lbtt_tax_return_response }
    list_secure_messages = { service: fl_endpoint, wsdl: 'ListSecureMessages.wsdl',
                             endpoint: '/getListSecureMessages', operation: :list_secure_messages_wsdl,
                             response: :list_secure_messages_response }
    list_system_notices = { service: fl_endpoint, wsdl: 'ListSystemNotices.wsdl',
                            endpoint: '/getSystemNotices', operation: :list_system_notices_wsdl,
                            response: :list_system_notices_response, savon_log: false }
    log_off_user = { service: fl_endpoint, wsdl: 'FLLogOffUser.wsdl', endpoint: '/LogOffUser',
                     operation: :log_off_user_wsdl, response: :log_off_user_response }
    maintain_party_details = { service: fl_endpoint, wsdl: 'FLMaintainPartyDetails.wsdl',
                               endpoint: '/maintainPartyDetails', operation: :maintain_party_details_wsdl,
                               response: :maintain_party_details_response }
    maintain_user = { service: fl_endpoint, wsdl: 'FLMaintainUser.wsdl', endpoint: '/MaintainUser',
                      operation: :maintain_user_wsdl, response: :maintain_user_response }
    maintain_user_registration = { service: fl_endpoint, wsdl: 'FLMaintainRegistrationUser.wsdl',
                                   endpoint: '/MaintainUserRegistration', operation: :maintain_user_wsdl,
                                   response: :maintain_user_response }
    secure_message_create = { service: fl_endpoint, wsdl: 'SecureMessageCreate.wsdl',
                              endpoint: '/CreateSecureMessage', operation: :secure_message_create_wsdl,
                              response: :secure_message_create_response }
    secure_message_update = { service: fl_endpoint, wsdl: 'SecureMessageUpdate.wsdl',
                              endpoint: '/UpdateSecureMessage', operation: :secure_message_update_wsdl,
                              response: :secure_message_update_response }
    slft_application = { service: fl_endpoint, wsdl: 'SLFTApplication.wsdl',
                         endpoint: '/SLFTApplication', operation: :slft_application_wsdl,
                         response: :slft_application_response }
    slft_calc = { service: fl_endpoint, wsdl: 'SLFTCalc.wsdl', endpoint: '/getSlftCalculation',
                  operation: :slft_calc_wsdl, response: :slft_calc_response }
    slft_tax_return = { service: fl_endpoint, wsdl: 'SLFTTaxReturn.wsdl', endpoint: '/createSLFTReturn',
                        operation: :slft_tax_return_wsdl, response: :slft_tax_return_response }
    slft_tax_return_details = { service: fl_endpoint, wsdl: 'SLFTTaxReturnDetails.wsdl',
                                endpoint: '/SLFTTaxReturnDetails', operation: :slft_tax_return_wsdl,
                                response: :slft_tax_return_response }
    slft_update = { service: fl_endpoint, wsdl: 'SLFTTaxReturnUpdate.wsdl', endpoint: '/updateSLFTTaxReturn',
                    operation: :slft_tax_return_wsdl, response: :slft_tax_return_response }
    validate_return_reference = { service: fl_endpoint, wsdl: 'ValidateReturnReference.wsdl',
                                  endpoint: '/ValidateReturnReference',
                                  operation: :validate_return_reference_wsdl,
                                  response: :validate_return_reference_response }
    view_all_returns = { service: fl_endpoint, wsdl: 'ViewAllReturns.wsdl',
                         endpoint: '/ViewAllReturns', operation: :view_all_returns_wsdl,
                         response: :view_returns_response }
    view_case_pdf = { service: fl_endpoint, wsdl: 'ViewCasePDF.wsdl', endpoint: '/ViewCasePDF',
                      operation: :view_case_pdfwsdl, response: :view_case_pdf_response }
    view_claim_pdf = { service: fl_endpoint, wsdl: 'ViewClaimPDF.wsdl', endpoint: '/ViewClaimPDF',
                       operation: :view_claim_pdfwsdl, response: :view_claim_pdf_response }
    view_document =  { service: fl_endpoint, wsdl: 'ViewDocument.wsdl', endpoint: '/ViewDocument',
                       operation: :view_document_wsdl, response: :view_document_response }
    view_return_pdf = { service: fl_endpoint, wsdl: 'ViewReturnPDF.wsdl', endpoint: '/getViewReturnPDF',
                        operation: :view_return_pdf, response: :view_return_pdf_response }

    # Finally, map of all services used by this application
    @configuration = { add_attachment: add_attachment, add_document: add_document, address_detail: address_detail,
                       address_search: address_search, authenticate_user: authenticate_user,
                       claim_repayment_details: claim_repayment_details,
                       delete_attachment: delete_attachment, delete_document: delete_document,
                       delete_draft_tax_return: delete_draft_tax_return,
                       get_attachment: get_attachment, get_party_details: get_party_details, get_pws_text: get_pws_text,
                       get_reference_values: get_reference_values, get_role_actions: get_role_actions,
                       get_secure_message_details: get_secure_message_details, get_sites: get_sites,
                       get_system_parameters: get_system_parameters, get_tax_relief_types: get_tax_relief_types,
                       get_transactions: get_transactions,
                       lbtt_calc: lbtt_calc, lbtt_tax_return: lbtt_tax_return,
                       lbtt_tax_return_details: lbtt_tax_return_details, lbtt_update: lbtt_update,
                       list_secure_messages: list_secure_messages, list_system_notices: list_system_notices,
                       log_off_user: log_off_user, maintain_party_details: maintain_party_details,
                       maintain_user: maintain_user, maintain_user_registration: maintain_user_registration,
                       secure_message_create: secure_message_create, secure_message_update: secure_message_update,
                       slft_application: slft_application,
                       slft_calc: slft_calc, slft_tax_return: slft_tax_return,
                       slft_tax_return_details: slft_tax_return_details, slft_update: slft_update,
                       validate_return_reference: validate_return_reference,
                       view_all_returns: view_all_returns, view_case_pdf: view_case_pdf,
                       view_claim_pdf: view_claim_pdf, view_document: view_document,
                       view_return_pdf: view_return_pdf }

    class << self
      attr_reader :configuration

      # Preload all the currently configured clients in the ServiceClient class
      def preload
        @configuration.reject { |_, v| v[:service][:root].nil? }
                      .each { |_, v| ServiceClient.get_client(v[:wsdl], v[:endpoint], v[:service], v[:savon_log]) }
      end
    end
  end
end
