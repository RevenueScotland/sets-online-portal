# frozen_string_literal: true

module Claim
  # claim payment controller which hold wizard steps for claiming payment for return
  # which is filled 12 months ago
  class ClaimPaymentsController < ApplicationController
    include Wizard
    include AddressHelper
    include ClaimPaymentAddressHelper

    authorise requires: AuthorisationHelper::CLAIM_REPAYMENT

    # SLFT_STEPS contains Wizard steps for slft return
    SLFT_STEPS = %w[payment_after_year claiming_amount claim_payment_bank_details taxpayer_declaration
                    confirmation_of_payment].freeze
    # ADS_STEPS contains Wizard steps for lbtt return when reason is selected as ADS
    ADS_STEPS = %w[payment_after_year date_of_sale main_residence_address further_claim_info claiming_amount
                   confirm_individual_details taxpayer_address claim_payment_bank_details taxpayer_declaration
                   confirmation_of_payment].freeze
    # NON_ADS_STEPS contains Wizard steps for lbtt return when reason is selected other than ADS
    NON_ADS_STEPS = %w[payment_after_year claiming_amount confirm_individual_details taxpayer_address
                       claim_payment_bank_details taxpayer_declaration confirmation_of_payment].freeze

    # claim/claim_payment/payment_after_year - step in the LBTT wizard
    def payment_after_year
      clear_cache = nil
      # This step is to start with new claim repayment. Hence need to clear cache to clear already
      # existing details. If we clear cache directly in step method, it also clears the data when we come
      # on this page after the back-button.
      # Radio buttons values on this page is displayed depending on reference value code which is  passed
      # in claim link on dashboard page (@see save_params method)
      if params[:new]
        Rails.logger.debug('New Claim Repayment')
        wizard_end
        clear_cache = true
      end
      wizard_step(nil) { { params: :filter_params, clear_cache: clear_cache, next_step: :calculate_next_step } }
    end

    # claim/claim_payment/date_of_sale - step in the LBTT wizard with ADS
    def date_of_sale
      wizard_step(ADS_STEPS) { { params: :filter_params } }
    end

    # claim/claim_payment/further_claim_info - step in the LBTT wizard with ADS
    def further_claim_info
      wizard_step(ADS_STEPS) { { params: :filter_params } }
    end

    # Calls @see #next_page_or_summary to save the data and skip to the summary for certain types of party
    def main_residence_address
      wizard_address_step(ADS_STEPS, :store_address, load_address: :load_previous_address)
    end

    # claim/claim_payment/claiming_amount - step in the LBTT wizard
    def claiming_amount
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step } }
    end

    # claim/claim_payment/slft_claim_amount - step in the LBTT wizard
    def confirm_individual_details
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step } }
    end

    # Calls @see #next_page_or_summary to save the data and skip to the summary for certain types of party
    def taxpayer_address
      wizard_address_step(ADS_STEPS, :tax_store_address, load_address: :tax_load_previous_address)
    end

    # claim/claim_payment/claim_payment_bank_details - step in the all wizard
    def claim_payment_bank_details
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step } }
    end

    # claim/claim_payment/taxpayer_declaration - step in the Taxpayer wizard
    def taxpayer_declaration
      wizard_step(nil) { { params: :filter_params, next_step: :calculate_next_step, cache_index: true } }
    end

    # claim/claim_payment/confirmation_of_payment - step in the Taxpayer wizard
    def confirmation_of_payment
      wizard_step(nil) { { params: :filter_params } }
      # Calling wsdl to send data to the back-office on last page of wizard
      @claim_payment.save_claim(current_user)
    end

    private

    # Sets up variables for the form to use based on the main Claim_payment controller
    def setup_step
      @post_path = wizard_post_path
      @claim_payment = wizard_load
      # specific setup for Payment_after_year method
      # save_params save data came from dashboard to claim_payment model
      save_params if action_name == 'payment_after_year' && @claim_payment.nil?

      @claim_payment
    end

    # Accepts the parameters passed from dashboard index with claim link and save them to @claim_payment model
    # Gets the data regarding the srv_code, version and tare_reference of a return, which will be send to Back-Office
    def save_params
      @claim_payment = ClaimPayment.new(srv_code: params[:srv_code], tare_reference: params[:reference],
                                        version: params[:version])
      wizard_save @claim_payment # save the initial set up
    end

    # Return the parameter list filtered for the attributes of the LbttReturn model
    def filter_params
      required = :claim_claim_payment
      output = {}
      output = params.require(required).permit(Claim::ClaimPayment.attribute_list) if params[required]
      output
    end

    # Calculates which wizard steps to be followed
    def calculate_next_step
      reason = @claim_payment.reason
      case reason
      when 'CLAIM'
        SLFT_STEPS
      when 'ADS'
        ADS_STEPS
      else
        NON_ADS_STEPS
      end
    end
  end
end
