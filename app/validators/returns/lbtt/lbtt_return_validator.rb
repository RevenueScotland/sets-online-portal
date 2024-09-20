# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Validation model for the LBTT return
    # This class is to validate complete lbtt model before submitting and to show general common error message
    # for wizard section instead of showing field specific error on summary page
    # eg rather than showing "First name cannot be empty" it would show something like
    #    "Contact details for agent has missing information"
    class LbttReturnValidator < AbstractReturnValidator # rubocop:disable Metrics/ClassLength
      # validate complete lbtt_return model with child elements
      # Note the design pattern of passing the list of errors around outside of the model.errors list.  This is
      # because every time we call model.valid? it calls model.errors.clear so we would end up saying validation
      # passed when there errors.
      # @param lbtt_return [LbttReturn] the model to validate
      def validate(lbtt_return)
        # validate if required object is present or not
        save_validation(lbtt_return)
        # return if there is validation failed for required object
        return if lbtt_return.errors.present?

        # list to store error messages to be added to the model at the end (so it doesn't get cleared
        # by calls to model.valid?)
        errors = []
        validate_agent_section(lbtt_return, errors) if lbtt_return.user_account_type != 'PUBLIC'
        validate_child_hash(lbtt_return.properties, (I18n.t '.property'), errors)
        validate_parties(lbtt_return, errors)
        validate_transaction_section(lbtt_return, errors)
        validate_reliefs_section(lbtt_return, errors)
        validate_tax_model(lbtt_return, errors)

        build_model_errors(lbtt_return, errors)
      end

      private

      # validating agent against child specific attribute list whether all required and valid details are provided.
      # also in Party model, it is validating on condition if: :individual? which checking party_type is 'AGENT'
      def validate_agent_section(lbtt_return, errors)
        # attribute list for agent
        # to check agent section specific error separated list of agent attributes from Party model
        attr_list = %i[title surname firstname agent_reference agent_dx_number telephone email_address agent_address]

        return if lbtt_return.agent.valid?(attr_list)

        add_error(errors, (I18n.t '.returns.lbtt.summary.add_agent_description'), lbtt_return.agent)
      end

      # only check the attributes involved in the transaction section
      def transaction_attribute_list
        %i[ contingents_event_ind deferral_agreed_ind deferral_reference previous_option_ind exchange_ind uk_ind
            linked_consideration non_chargeable remaining_chargeable annual_rent linked_ind link_transactions total_vat
            premium_paid lease_premium linked_lease_premium property_type relevant_rent
            rent_for_all_years yearly_rents business_ind sale_include_option total_consideration]
      end

      # Validates the individual fields in the transaction section
      def validate_transaction_section(lbtt_return, errors)
        # Validation for a blank section is in #save_validation
        return if lbtt_return.effective_date.blank?

        add_error(errors, (I18n.t '.transaction'), lbtt_return) unless lbtt_return.valid?(transaction_attribute_list)
      end

      # Validates the individual reliefs
      def validate_reliefs_section(lbtt_return, errors)
        # Validation for a blank section is in 'save_validation
        return if lbtt_return.relief_claims.blank?

        # log error
        region_name = (I18n.t '.returns.lbtt.summary.add_relief_description')
        add_error(errors, region_name, lbtt_return) unless validate_child_array(lbtt_return.relief_claims)
        # Trigger the uniqueness check on the parent return
        add_error(errors, region_name, lbtt_return) unless lbtt_return.valid?(:relief_claims)
      end

      # Validates all elements in an array are valid
      # @param list [Array] array of objects to check for validity
      def validate_child_array(list)
        valid = list.all? { |o| o.valid?(o.class.attribute_list) }

        # Clearing the errors on array objects as we don't want these reported
        # @see fl_application_record.error_objects
        list.each { |o| o.errors.clear } if valid == false
        valid
      end

      # Checks if any of the parties have validation errors
      def validate_parties(lbtt_return, errors)
        translation_path = 'returns.lbtt_parties.about_the_party'
        validate_child_hash(lbtt_return.buyers, (I18n.t "#{translation_path}.BUYER_title"), errors)
        validate_child_hash(lbtt_return.sellers, (I18n.t "#{translation_path}.SELLER_title"), errors)
        validate_child_hash(lbtt_return.tenants, (I18n.t "#{translation_path}.TENANT_title"), errors)
        validate_child_hash(lbtt_return.landlords, (I18n.t "#{translation_path}.LANDLORD_title"), errors)
        validate_child_hash(lbtt_return.new_tenants, (I18n.t "#{translation_path}.NEWTENANT_title"), errors)
      end

      # Passes list of objects and check all objects in the list are valid, add error if not valid
      # eg. list of tenants,list of buyers in the lbtt_return model
      # @param list [Hash] Hash of objects where the value is checked for validity
      # @param field_to_blame [symbol] displayable name of the field the error originates from
      # @param errors [ActiveModel::Errors] the errors object being passed around
      def validate_child_hash(list, field_to_blame, errors)
        return if list.blank?

        # Check individual object from the list and added index to each object for identification
        list.values.each_with_index do |object, index|
          next if object.valid?(object.class.attribute_list)

          # add error if child is not valid
          # Concatenate key information about attribute eg Contact details for agent
          # @Note: We do not need to clear errors on the hash as the fl_application_record.error_objects does
          # not extract errors from a hash structure
          add_error(errors, "#{field_to_blame} #{index + 1} #{object.key_info}", object)
        end
      end

      # Validate all the tax (sub-model) attributes except amount_already_paid which may be skipped for this validation
      # (ie they're allowed to submit without setting it at the moment)
      def validate_tax_model(lbtt_return, errors)
        attribute_contexts = Tax.attribute_list - [:amount_already_paid]
        Rails.logger.debug { "Validating #{attribute_contexts}" }
        return if lbtt_return.tax.valid? attribute_contexts

        add_error(errors, (I18n.t '.returns.lbtt.summary.about_calculation'), lbtt_return.tax)
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
        model.errors.add(:base, :missing_properties_entries, link_id: 'add_a_property') if model.properties.blank?
        transaction_validation(model)
        # Since we do not prepopulate the relevant date details
        validate_relevant_date(model) if %w[ASSIGN TERMINATE LEASEREV].include? model.flbt_type

        return unless model.user_account_type != 'PUBLIC' && model.agent.blank?

        model.errors.add(:base, :missing_agent_details, link_id: 'edit_agent_details')
      end

      # validation specific to conveyance LBTT returns
      def save_convey_validation(model)
        model.errors.add(:base, :missing_buyer_entries, link_id: 'add_a_buyer') if model.buyers.blank?
        model.errors.add(:base, :missing_seller_entries, link_id: 'add_a_seller') if model.sellers.blank?
        missing_ads_non_individual_validation(model)
        ads_summary_validation(model)
        non_residential_validation(model) if model.property_type == '3'
      end

      # validation specific to transaction
      def transaction_validation(model)
        model.errors.add(:base, :recalc_return, link_id: 'edit_transaction_details') if model.recalc_required == 'Y'
        return if model.effective_date.present?

        model.errors.add(:base, :missing_about_the_transaction, link_id: 'add_transaction_details')
      end

      # Validates if the relevant date is not blank
      def validate_relevant_date(model)
        return if model.relevant_date.present?

        model.errors.add(:relevant_date, :cant_be_blank, link_id: 'edit_transaction_details')
      end

      # If there is at least one non individual buyer then ads is due on
      # all the properties
      def missing_ads_non_individual_validation(model)
        # Property type 1 = residential
        return if model.properties.blank? || !model.non_individual_buyer? || model.property_type != '1'

        return if model.properties.values.all? { |p| p.ads_due_ind == 'Y' }

        model.errors.add(:base, :non_individual_no_ads, link_id: 'add_a_property')
      end

      # validation specific to ads
      def ads_summary_validation(model)
        return if model.properties.blank?

        return unless model.show_ads? && model.ads.ads_consideration_yes_no.blank?

        model.errors.add(:base, :missing_ads, link_id: 'add_ads')
      end

      # validation when the property type is non-residential and return type is CONVEY
      def non_residential_validation(model)
        return if model.non_residential_reason.present?

        model.errors.add(:non_residential_reason, :reason_must_be_provided, link_id: 'edit_transaction_details')
      end

      # validation specific to lease LBTT returns
      def save_lease_validation(model)
        model.errors.add(:base, :missing_tenant_entries, link_id: 'add_a_tenant') if model.tenants.blank?
        case model.flbt_type
        when 'LEASERET'
          model.errors.add(:base, :missing_landlord_entries, link_id: 'add_a_landlord') if model.landlords.blank?
        when 'ASSIGN'
          model.errors.add(:base, :missing_new_tenant_entries, link_id: 'add_a_new_tenant') if model.new_tenants.blank?
        end
      end
    end
  end
end
