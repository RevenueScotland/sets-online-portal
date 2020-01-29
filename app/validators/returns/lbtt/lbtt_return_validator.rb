# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Validation model for the LBTT return
    # This class is to validate complete lbtt model before submitting and to show general common error message
    # for wizard section instead of showing field specfic error on summary page
    # eg rather than showing "First name cannot be empty" it would show something like
    #    "Contact details for agent has missing information"
    class LbttReturnValidator < AbstractReturnValidator
      # validate complete lbtt_return model with child elements
      # Note the design pattern of passing the list of errors around outside of the model.errors list.  This is
      # because every time we call model.valid? it calls model.errors.clear so we would end up saying validation
      # passed when there errors.
      # @param lbtt_return [LbttReturn] the model to validate
      def validate(lbtt_return)
        # validate if required object is present or not
        save_validation(lbtt_return)
        # return if there is validation failed for required object
        return unless lbtt_return.errors.blank?

        # list to store error messages to be added to the model at the end (so it doesn't get cleared
        # by calls to model.valid?)
        errors = []
        validate_agent_section(lbtt_return, errors) if lbtt_return.is_public == false
        validate_conveyance_parties(lbtt_return, errors)
        validate_lease_parties(lbtt_return, errors)
        validate_transaction_section(lbtt_return, errors)
        validate_tax_model(lbtt_return, errors)

        build_model_errors(lbtt_return, errors)
      end

      # validating agent against child specific attribute list whether all required and valid details are provided.
      # also in Party model, it is validating on condition if: :individual? which checking party_type is 'AGENT'
      def validate_agent_section(lbtt_return, errors)
        # attribute list for agent
        # to check agent section specific error separated list of agent attributes from Party model
        agent_attr_list = %i[
          title surname firstname agent_reference agent_dx_number telephone email_address agent_address
        ]

        return if lbtt_return.agent.valid? agent_attr_list

        add_error(errors, (I18n.t '.returns.lbtt.summary.add_agent_description'), lbtt_return.agent)
      end

      # validate transaction section
      def validate_transaction_section(lbtt_return, errors)
        # Already showing validation on this condition( @see LbttReturn model) to fill details in this section
        # if it is completely blank
        return if lbtt_return.effective_date.blank?

        # only check the attributes involved in the transaction section
        trans_attr_list = %i[
          contingents_event_ind deferral_agreed_ind deferral_reference previous_option_ind exchange_ind uk_ind
          linked_consideration non_chargeable remaining_chargeable annual_rent linked_ind link_transactions total_vat
          premium_paid lease_premium linked_lease_premium property_type relevant_rent non_ads_reliefclaim_option_ind
          non_ads_relief_claims rent_for_all_years yearly_rents business_ind sale_include_option total_consideration
        ]

        add_error(errors, (I18n.t '.transaction'), lbtt_return) unless lbtt_return.valid? trans_attr_list
      end

      # Checks if any of the child objects have validation errors
      def validate_conveyance_parties(lbtt_return, errors)
        validate_child(Property.attribute_list, lbtt_return.properties, (I18n.t '.property'), errors)
        validate_child(Party.attribute_list, lbtt_return.buyers, (I18n.t '.buyer'), errors)
        validate_child(Party.attribute_list, lbtt_return.sellers, (I18n.t '.seller'), errors)
      end

      # Checks if any of the lease party child objects have validation errors
      def validate_lease_parties(lbtt_return, errors)
        validate_child(Party.attribute_list, lbtt_return.tenants, (I18n.t '.tenant'), errors)
        validate_child(Party.attribute_list, lbtt_return.landlords, (I18n.t '.landlord'), errors)
        validate_child(Party.attribute_list, lbtt_return.new_tenants, (I18n.t '.new_tenant'), errors)
      end

      # Passes list of objects and check all objects in the list are valid, add error if not valid
      # eg. list of tenants,list of buyers in the lbtt_return model
      # @param validation_context [list] List of attributes against which to validate
      # @param list [Array] array of objects to check for validity
      # @param field_to_blame [symbol] displayable name of the field the error originates from
      # @param errors [ActiveModel::Errors] the errors object being passed around
      def validate_child(validation_context, list, field_to_blame, errors)
        return if list.blank?

        # Check individual object from the list and added index to each object for identification
        list.values.each_with_index do |object, index|
          next if object.valid? validation_context

          # Concatenate key information about attribute eg Contact details for agent
          error_attr = field_to_blame + ' ' + (index + 1).to_s + ' ' + object.key_info

          # add error if child is not valid
          add_error(errors, error_attr, object)
        end
      end

      # Validate all the tax (sub-model) attributes except amount_already_paid which may be skipped for this validation
      # (ie they're allowed to submit without setting it at the moment)
      def validate_tax_model(lbtt_return, errors)
        attribute_contexts = Tax.attribute_list - [:amount_already_paid]
        Rails.logger.debug "Validating #{attribute_contexts}"
        return if lbtt_return.tax.valid? attribute_contexts

        add_error(errors, (I18n.t '.returns.lbtt.summary.edit_calculation'), lbtt_return.tax)
      end

      # Check if the return is valid for saving to the back office - adds errors any found.
      def save_validation(model)
        # clear previous error
        model.errors.clear
        save_common_validation(model)
        save_convey_validation(model) if model.flbt_type == 'CONVEY'
        save_lease_validation(model) if %w[LEASERET LEASEREV ASSIGN TERMINATE].include? model.flbt_type
      end

      # Save validation common to all LBTT return types
      def save_common_validation(model)
        model.errors.add(:base, :missing_properties_entries, link_id: 'add_property') if model.properties.blank?
        transaction_validation(model)
        return unless model.is_public == false && model.agent.blank?

        model.errors.add(:base, :missing_agent_details, link_id: 'amend_details')
      end

      # validation specific to conveyance LBTT returns
      def save_convey_validation(model)
        model.errors.add(:base, :missing_buyer_entries, link_id: 'add_buyer') if model.buyers.blank?
        model.errors.add(:base, :missing_seller_entries, link_id: 'add_seller') if model.sellers.blank?
        ads_summary_validation(model)
      end

      # validation specific to transaction
      def transaction_validation(model)
        return unless model.effective_date.blank?

        model.errors.add(:base, :missing_about_the_transaction, link_id: 'add_transaction')
      end

      # validation specific to ads
      def ads_summary_validation(model)
        return if model.properties.blank?

        return unless model.show_ads? && model.ads.ads_consideration_yes_no.blank?

        model.errors.add(:base, :missing_ads, link_id: 'add_ads')
      end

      # validation specific to lease LBTT returns
      def save_lease_validation(model)
        model.errors.add(:base, :missing_tenant_entries, link_id: 'add_tenant') if model.tenants.blank?
        case model.flbt_type
        when 'LEASERET'
          model.errors.add(:base, :missing_landlord_entries, link_id: 'add_landlord') if model.landlords.blank?
        when 'ASSIGN'
          model.errors.add(:base, :missing_new_tenant_entries, link_id: 'add_new_tenant') if model.new_tenants.blank?
        end
      end
    end
  end
end
