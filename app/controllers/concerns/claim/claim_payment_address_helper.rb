# frozen_string_literal: true

# claim payment address helper which contains extra methods required for address wizard
module Claim
  # Helpful address methods common to Claims controllers
  module ClaimPaymentAddressHelper
    extend ActiveSupport::Concern

    # Load previously entered address
    def load_previous_address
      if @claim_payment.address.nil?
        initialize_address_variables
      else
        initialize_address_variables(@claim_payment.address)
      end
    end

    # stores address in the wizard cache
    def store_address
      @claim_payment.address = Address.new(address_params)
      unless @claim_payment.address.valid?(address_validation_context)
        # setup page to show error
        initialize_address_variables(@claim_payment.address, search_postcode)
        return false
      end
      wizard_save(@claim_payment)
      true
    end

    # Load previously entered address
    def tax_load_previous_address
      if @claim_payment.tax_address.nil?
        initialize_address_variables
      else
        initialize_address_variables(@claim_payment.tax_address)
      end
    end

    # stores address in the wizard cache
    def tax_store_address
      @claim_payment.tax_address = Address.new(address_params)
      unless @claim_payment.tax_address.valid?(address_validation_context)
        initialize_address_variables(@claim_payment.tax_address, search_postcode)
        return false
      end
      wizard_save(@claim_payment)
      true
    end
  end
end
