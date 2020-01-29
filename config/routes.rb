# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  root to: 'home#index'
  scope '(:locale)', Locale: /en|cy/ do # rubocop:disable Metrics/BlockLength
    get 'home/index'
    get 'home/error', to: 'home#error'
    get 'home/file-download-error', to: 'home#file_download_error'
    get 'home/forbidden', to: 'home#forbidden'

    # This is generic page to display public website text retrieve from back office
    # Depending on the code, text on the page changes
    # Passing the code as key parameter in the link
    # e.g http://localhost:3000/en/website_texts/REGTSANDCS
    resources :website_texts, param: :text_code, only: :show

    # use username as the key param and override constraint to allow non alpha characters.
    resources :users, param: :username, except: %i[show destroy], constraints: { username: %r{[^\/]+} }

    get 'user/change-password', to: 'users#change_password'
    post 'user/update-password', to: 'users#update_password'

    get 'user/update-tcs', to: 'users#update_tcs'
    post 'user/confirm-update-tcs', to: 'users#confirm_update_tcs'

    resource 'account', controller: :accounts, only: :show, as: :account do
      collection do
        get 'activate_account'
        get 'process-activate-account'
        post 'process-activate-account'
        get  'edit-basic'
        post 'update-basic'
        get  'edit-address'
        post 'update-address'
      end
    end

    get '/login',                     to: 'login#new'
    post '/login',                    to: 'login#create'
    get '/logout',                    to: 'login#destroy'
    get '/logout-session-expired',    to: 'login#session_expired'

    get '/forgotten-password',        to: 'forgotten_passwords#new'
    post '/forgotten-password',       to: 'forgotten_passwords#create'

    get  '/forgotten-username',       to: 'forgotten_usernames#new'
    post '/forgotten-username',       to: 'forgotten_usernames#create'

    get '/dashboard',                 to: 'dashboard/dashboard_home#index'

    namespace :dashboard do
      get 'messages/download-file',            to: 'messages#download_file'
      match 'messages/confirmation',           to: 'messages#confirmation', via: %i[get post]

      resources :messages, except: %i[destroy update edit], param: :smsg_refno do
        member do
          get 'retrieve-file-attachment'
        end
      end
      resources :financial_transactions, only: %i[index show]
      resources :dashboard_returns, only: %i[index destroy] do
        member do
          get 'download-receipt'
          get 'download-pdf'
          get 'download-waste'
          get 'load'
        end
      end
    end

    # Accounts
    namespace :accounts do
      match 'registration/account_details',    to: 'registration#account_details',    via: %i[get post]
      match 'registration/account_for',        to: 'registration#account_for',        via: %i[get post]
      match 'registration/company',            to: 'registration#company',            via: %i[get post]
      match 'registration/company_registered', to: 'registration#company_registered', via: %i[get post]
      match 'registration/org_contact',        to: 'registration#org_contact',        via: %i[get post]
      match 'registration/rep_address',        to: 'registration#rep_address',        via: %i[get post]
      match 'registration/address',            to: 'registration#address',            via: %i[get post]
      match 'registration/taxes',              to: 'registration#taxes',              via: %i[get post]
      match 'registration/user_details',       to: 'registration#user_details',       via: %i[get post]
      match 'registration/confirmation',       to: 'registration#confirmation',       via: %i[get]
    end

    # LBTT
    namespace :returns do # rubocop:disable Metrics/BlockLength
      match 'lbtt/summary',                        to: 'lbtt#summary',                                via: %i[get post]
      match 'lbtt/return_type',                    to: 'lbtt#return_type',                            via: %i[get post]
      match 'lbtt/return_reference_number',        to: 'lbtt#return_reference_number',                via: %i[get post]
      match 'lbtt/save_draft',                     to: 'lbtt#save_draft',                             via: :get
      match 'lbtt/declaration',                    to: 'lbtt#declaration',                            via: %i[get post]
      match 'lbtt/declaration_submitted',          to: 'lbtt#declaration_submitted',                  via: %i[get post]
      match 'lbtt/public_landing',                 to: 'lbtt#public_landing',                         via: %i[get]
      match 'lbtt/public_return_type',             to: 'lbtt#public_return_type',                     via: %i[get post]
      match 'lbtt/reliefs_calculation',            to: 'lbtt#reliefs_calculation',                    via: %i[get post]
      get 'lbtt/download-receipt',                 to: 'lbtt#download_receipt'

      match 'lbtt/about_the_party(/:party_id)',    to: 'lbtt_parties#about_the_party',
                                                   as: 'lbtt_about_the_party',                        via: %i[get post]
      match 'lbtt/organisation_type_details',      to: 'lbtt_parties#organisation_type_details',      via: %i[get post]
      match 'lbtt/organisation_details',           to: 'lbtt_parties#organisation_details',           via: %i[get post]
      match 'lbtt/representative_contact_details', to: 'lbtt_parties#representative_contact_details', via: %i[get post]
      match 'lbtt/party_details',                  to: 'lbtt_parties#party_details',                  via: %i[get post]
      match 'lbtt/party_address',                  to: 'lbtt_parties#party_address',                  via: %i[get post]
      match 'lbtt/party_alternate_address',        to: 'lbtt_parties#party_alternate_address',        via: %i[get post]
      match 'lbtt/parties-relation',               to: 'lbtt_parties#parties_relation',               via: %i[get post]
      match 'lbtt/acting-as-trustee',              to: 'lbtt_parties#acting_as_trustee',              via: %i[get post]
      match 'lbtt/registered_company',             to: 'lbtt_parties#registered_company',             via: %i[get post]
      match 'lbtt/company_number',                 to: 'lbtt_parties#company_number',                 via: %i[get post]
      match 'lbtt/organisation_contact_details',   to: 'lbtt_parties#organisation_contact_details',   via: %i[get post]
      resources :parties, only: %i[destroy], controller: :lbtt_parties, param: :party_id

      match 'lbtt/about_the_property', to: 'lbtt_properties#about_the_property', via: %i[get post]
      match 'lbtt/property_address(/:property_id)', to: 'lbtt_properties#property_address',
                                                    as: 'lbtt_property_address',                      via: %i[get post]
      match 'lbtt/property_ads_applies',           to: 'lbtt_properties#property_ads_applies',        via: %i[get post]
      resources :properties, only: %i[destroy], controller: :lbtt_properties, param: :property_id

      match 'lbtt/agent_details',                  to: 'lbtt_agent#agent_details',                    via: %i[get post]
      match 'lbtt/agent_address',                  to: 'lbtt_agent#agent_address',                    via: %i[get post]

      match 'lbtt/ads_dwellings',                  to: 'lbtt_ads#ads_dwellings',                      via: %i[get post]
      match 'lbtt/ads_amount',                     to: 'lbtt_ads#ads_amount',                         via: %i[get post]
      match 'lbtt/ads_intending_sell',             to: 'lbtt_ads#ads_intending_sell',                 via: %i[get post]
      match 'lbtt/ads_reliefs',                    to: 'lbtt_ads#ads_reliefs',                        via: %i[get post]

      match 'lbtt/ads_repay_reason',               to: 'lbtt_ads#ads_repay_reason',                   via: %i[get post]
      match 'lbtt/ads_repay_date',                 to: 'lbtt_ads#ads_repay_date',                     via: %i[get post]
      match 'lbtt/ads_repay_address',              to: 'lbtt_ads#ads_repay_address',                  via: %i[get post]
      match 'lbtt/ads_repay_details',              to: 'lbtt_ads#ads_repay_details',                  via: %i[get post]

      match 'lbtt/calculation',                    to: 'lbtt_tax#calculation', as: 'lbtt_tax_calculation',
                                                   via: %i[get post]
      match 'lbtt/calc_already_paid',              to: 'lbtt_tax#calc_already_paid', as: 'lbtt_tax_calc_already_paid',
                                                   via: %i[get post]
      match 'lbtt/npv',                            to: 'lbtt_tax#npv', as: 'lbtt_tax_npv',            via: %i[get post]

      match 'lbtt/repayment_claim',                to: 'lbtt_claim#repayment_claim',                  via: %i[get post]
      match 'lbtt/repayment_claim_amount',         to: 'lbtt_claim#repayment_claim_amount',           via: %i[get post]
      match 'lbtt/repayment_claim_bank_details',   to: 'lbtt_claim#repayment_claim_bank_details',     via: %i[get post]
      match 'lbtt/repayment_claim_declaration',    to: 'lbtt_claim#repayment_claim_declaration',      via: %i[get post]

      match 'lbtt/property-type',                  to: 'lbtt_transactions#property_type',             via: %i[get post]
      match 'lbtt/transaction-dates',              to: 'lbtt_transactions#transaction_dates',         via: %i[get post]
      match 'lbtt/sale-of-business',               to: 'lbtt_transactions#sale_of_business',          via: %i[get post]
      match 'lbtt/conveyance-values',              to: 'lbtt_transactions#conveyance_values',         via: %i[get post]
      match 'lbtt/tax-summary',                    to: 'lbtt_transactions#tax_summary',               via: %i[get post]
      match 'lbtt/about-the-calculation',          to: 'lbtt_transactions#about_the_calculation',     via: %i[get post]
      match 'lbtt/about-the-transaction',          to: 'lbtt_transactions#about_the_transaction',     via: %i[get post]
      match 'lbtt/linked-transactions',            to: 'lbtt_transactions#linked_transactions',       via: %i[get post]
      match 'lbtt/reliefs_on_transaction',         to: 'lbtt_transactions#reliefs_on_transaction',    via: %i[get post]
      match 'lbtt/lease_values',                   to: 'lbtt_transactions#lease_values',              via: %i[get post]
      match 'lbtt/rental_years',                   to: 'lbtt_transactions#rental_years',              via: %i[get post]
      match 'lbtt/premium_paid',                   to: 'lbtt_transactions#premium_paid',              via: %i[get post]
      match 'lbtt/relevant_rent',                  to: 'lbtt_transactions#relevant_rent',             via: %i[get post]
      match 'lbtt/tax_summary_lease',              to: 'lbtt_transactions#tax_summary_lease',         via: %i[get post]
    end

    # SLfT
    namespace :returns do
      match 'slft/summary',                         to: 'slft#summary',                         via: %i[get post]
      match 'slft/save_draft',                      to: 'slft#save_draft',                      via: %i[get post]
      get   'slft/download-receipt',                to: 'slft#download_receipt'

      match 'slft/credit_environmental',            to: 'slft#credit_environmental',            via: %i[get post]
      match 'slft/credit_bad_debt',                 to: 'slft#credit_bad_debt',                 via: %i[get post]
      match 'slft/credit_site_specific',            to: 'slft#credit_site_specific',            via: %i[get post]

      match 'slft/site_waste_summary(/:site)',      to: 'slft_sites_waste#site_waste_summary',
                                                    as: 'slft_site_waste_summary',              via: %i[get post]
      match 'slft/waste_description(/:waste)',      to: 'slft_sites_waste#waste_description',
                                                    as: 'slft_waste_description',               via: %i[get post]
      match 'slft/waste_exemption',                 to: 'slft_sites_waste#waste_exemption',     via: %i[get post]
      match 'slft/waste_tonnage',                   to: 'slft_sites_waste#waste_tonnage',       via: %i[get post]
      resources :wastes, only: %i[destroy], controller: :slft_sites_waste, param: :waste

      match 'slft/transaction_period',              to: 'slft#transaction_period',              via: %i[get post]
      match 'slft/transaction_new_non_disposal',    to: 'slft#transaction_new_non_disposal',    via: %i[get post]
      match 'slft/transaction_ceased_non_disposal', to: 'slft#transaction_ceased_non_disposal', via: %i[get post]

      match 'slft/repayment_bank_details',          to: 'slft#repayment_bank_details',          via: %i[get post]
      match 'slft/repayment_declaration',           to: 'slft#repayment_declaration',           via: %i[get post]
      match 'slft/repayment_submitted',             to: 'slft#repayment_submitted',             via: %i[get post]

      match 'slft/declaration_calculation',         to: 'slft#declaration_calculation',         via: %i[get post]
      match 'slft/declaration_repayment',           to: 'slft#declaration_repayment',           via: %i[get post]
      match 'slft/declaration',                     to: 'slft#declaration',                     via: %i[get post]
      match 'slft/declaration_submitted',           to: 'slft#declaration_submitted',           via: %i[get post]
    end

    # Claim_Payments
    namespace :claim do # rubocop:disable Metrics/BlockLength
      get '/download_claim',                             to: 'claim_payments#view_claim_pdf'
      get 'claim_payments/download-file',                to: 'claim_payments#download_file'
      match 'claim_payments/claim_reason',               to: 'claim_payments#claim_reason',         via: %i[get post]
      match 'claim_payments/date_of_sale',               to: 'claim_payments#date_of_sale',         via: %i[get post]
      match 'claim_payments/further_claim_info',         to: 'claim_payments#further_claim_info',   via: %i[get post]
      match 'claim_payments/claiming_amount',            to: 'claim_payments#claiming_amount',      via: %i[get post]
      match 'claim_payments/taxpayer_details',           to: 'claim_payments#taxpayer_details',     via: %i[get post]
      match 'claim_payments/taxpayer_address',           to: 'claim_payments#taxpayer_address', via: %i[get post]
      match 'claim_payments/claim_payment_bank_details', to: 'claim_payments#claim_payment_bank_details',
                                                         via: %i[get post]
      match 'claim_payments/main_residence_address',     to: 'claim_payments#main_residence_address',
                                                         via: %i[get post]
      match 'claim_payments/taxpayer_declaration',       to: 'claim_payments#taxpayer_declaration', via: %i[get post]
      match 'claim_payments/confirmation_of_payment',    to: 'claim_payments#confirmation_of_payment',
                                                         via: %i[get post]
      match 'claim_payments/second_tax_payer',           to: 'claim_payments#second_tax_payer',     via: %i[get post]
      match 'claim_payments/second_taxpayer_info',       to: 'claim_payments#second_taxpayer_info', via: %i[get post]
      match 'claim_payments/additional_tax_payer',       to: 'claim_payments#additional_tax_payer', via: %i[get post]
      match 'claim_payments/upload_evidence',            to: 'claim_payments#upload_evidence',      via: %i[get post]
      match 'claim_payments/more_uploads',               to: 'claim_payments#more_uploads',         via: %i[get post]
      match 'claim_payments/confirmation',               to: 'claim_payments#confirmation',         via: %i[get post]
      match 'claim_payments/public_claim_landing',          to: 'claim_payments#public_claim_landing', via: %i[get post]
      match 'claim_payments/return_reference_number',       to: 'claim_payments#return_reference_number',
                                                            via: %i[get post]
      match 'claim_payments/claimant_info',                 to: 'claim_payments#claimant_info',        via: %i[get post]
      match 'claim_payments/agent_info',                    to: 'claim_payments#agent_info',           via: %i[get post]
      match 'claim_payments/agent_address',                 to: 'claim_payments#agent_address',        via: %i[get post]
    end
  end
end
