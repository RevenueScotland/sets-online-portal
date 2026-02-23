# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise LBTT return models
  module Lbtt
    extend ActiveSupport::Concern

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

        return if lbtt_return.valid?(transaction_attribute_list)

        add_error(errors, (I18n.t '.returns.lbtt.summary.add_transaction_description'), lbtt_return)
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
      def save_validation(model) # rubocop:disable Metrics/AbcSize
        # clear previous error
        model.errors.clear
        # Return shouldn't be submitted if
        # 1. ADS is applicable
        # 2. FIRSTTIME relief is added
        # 3. It is a conveyance return
        if model.convey? && model.show_ads? && model.first_time_relief_added?
          model.errors.add(:base,
                           :non_submittable_ads_ftb_relief,
                           link_id:
                           "#{model.ads.ads_consideration_yes_no.blank? ? 'add_ads' : 'edit_ads'}") # rubocop:disable Style/RedundantInterpolation
        end
        save_common_validation(model)
        save_convey_validation(model) if model.flbt_type == 'CONVEY'
        save_lease_validation(model) if %w[LEASERET LEASEREV ASSIGN TERMINATE].include? model.flbt_type
      end

      # cleans the data
      # removes any non A-Z, a-z or 0-9 characters
      # and downcases the result
      # @param variable [String] the elements to be compared
      # @return [String] a cleaned downcase version of the passed in value
      def remove_special_charas(variable)
        variable&.gsub(/[^A-Za-z0-9]/i, '')&.downcase
      end

      # generic method to compare two the non address variables in the model
      # returns true if the values are the same (after being cleaned)
      # @param model [model] the model
      # @param party_type1 [String] the first party type for the elements to be compared
      # @param party_type2 [String] the second party type for the elements to be compared
      # @param variable [String] the elements to be compared
      # @return [boolean]
      def check_non_address_variables?(model, party_type1, party_type2, variable)
        @account = Account.find(model.current_user)
        model.send(party_type1).values.detect do |x|
          party_type2 = party_type2.to_s
          remove_special_charas(x.send(variable)) ==
            remove_special_charas(if party_type2 == 'user'
                                    @account.send(variable)
                                  else
                                    model.send(party_type2).send(variable)
                                  end)
        end.present?
      end

      # generic method to get all the address variables in the model for that party
      # @param model [model] the model
      # @return [array] array of addresses for that party
      def get_party_address(model, party)
        send(:"get_#{party}_addresses", model)
      end

      # generic method to compare two the address variables in the model
      # merges the two arrays duplicate values only
      # returns true if the values are the same (after being cleaned)
      # @param model [model] the model
      # @param party_type1 [String] the first party type for the elements to be compared
      # @param party_type2 [String] the second party type for the elements to be compared
      # @return [boolean]
      def check_address_variables?(model, party_type1, party_type2)
        party1_addresses = get_party_address(model, party_type1)
        party2_addresses = get_party_address(model, party_type2)

        party1_addresses.map! { |address| remove_special_charas(address) }
        party2_addresses.map! { |address| remove_special_charas(address) }

        party1_addresses.intersect?(party2_addresses)
      end

      # checks if the party type has data for that variable
      def check_if_nil?(model, party_type2, variable)
        return true if party_type2 != 'user' && model.send(party_type2).send(variable).blank?

        return true if party_type2 == 'user' && @account&.send(variable).blank?

        false
      end

      # generic method to compare two variables in the model
      # returns true if the values are the same (after being cleaned)
      # @param model [model] the model
      # @param party_type1 [String] the first party type for the elements to be compared
      # @param party_type2 [String] the second party type for the elements to be compared
      # @param variable [String] the elements to be compared
      # @return [boolean]
      def check_model_values_are_same?(model, party_type1, party_type2, variable)
        return false if check_if_nil?(model, party_type2, variable)

        if variable.to_s == 'address'
          return true if check_address_variables?(model, party_type1, party_type2)
        elsif check_non_address_variables?(model, party_type1, party_type2, variable)
          return true
        else
          return false
        end

        false
      end

      # checks what party type is populated and returns that party type
      # can only ever have either a buyer(s) or tenant(s) never both at the same time
      # @param model [model] the model
      # @return [string] buyers or tenants
      def get_party_type(model)
        if model.buyers.present?
          'buyers'
        elsif model.tenants.present?
          'tenants'
        end
      end

      # Determines what model elements should be compared, if the comparison is true then
      # Stops the comparison at the first hit it finds
      # when both values are the same.
      # @param model [model] the model
      # @param expl_party_type [expl_party_type] : explicitly pass party type (used for tenants, new_tenants diff)
      # @return [boolean]
      def validate_buyer_agent_not_same(model, expl_party_type = '')
        return unless Account.find(model.current_user).party_account_type == 'AGENT'

        party = expl_party_type.present? ? expl_party_type : get_party_type(model) # rubocop:disable Rails/Presence
        %i[fullname cleaned_telephone email address].each do |x|
          return true if check_model_values_are_same?(model, party, 'agent', x)

          return true if check_model_values_are_same?(model, party, 'user', x)
        end
        false
      end

      # Call the code to check if the data is the same for the agent and the buyer/tennant
      # @param model [model] the model
      # return [error] if the data is the same else returns blank
      # TODO : fix rubocop
      def add_error_same_details(model) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        if model.buyers.present? && model.agent.present? && validate_buyer_agent_not_same(model)
          model.errors.add(:base, :buyer_agent_same, link_id: 'add_a_buyer')
        elsif model.tenants.present? && model.agent.present? && validate_buyer_agent_not_same(model)
          model.errors.add(:base, :tenant_agent_same, link_id: 'add_a_tenant')
        elsif model.new_tenants.present? && model.agent.present? && validate_buyer_agent_not_same(model, 'new_tenants')
          model.errors.add(:base, :tenant_agent_same, link_id: 'add_a_new_tenant')
        end
      end

      # Save validation common to all LBTT return types
      def save_common_validation(model)
        add_error_same_details(model) if model.validate_buyer_agent_details == 'Y'
        model.errors.add(:base, :missing_properties_entries, link_id: 'add_a_property') if model.properties.blank?
        transaction_validation(model)
        # Since we do not prepopulated the relevant date details
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
        return validate_effective_date(model) if model.effective_date.present?

        model.errors.add(:base, :missing_about_the_transaction, link_id: 'add_transaction_details')
      end

      def date_crossed_submit_limit?(model, comp_date)
        # the submission time is measured in months
        max_return_submission_time = model.return_time_limit
        return false if comp_date.nil? && (max_return_submission_time.nil? || max_return_submission_time.blank?)

        parsed_limit = max_return_submission_time.to_i
        if parsed_limit.positive?
          future_date = Time.zone.today + parsed_limit.months
          comp_date > future_date
        else
          false
        end
      end

      # Validates if effective date is valid
      def validate_effective_date(model)
        return unless %w[CONVEY LEASERET].include? model.flbt_type

        validate_date_cross_submission_limit(model, model.effective_date,
                                             'effective_date')
      end

      # Validates if the relevant date is not blank
      def validate_relevant_date(model)
        if model.relevant_date.present?
          return validate_date_cross_submission_limit(model, model.relevant_date,
                                                      'relevant_date')
        end

        model.errors.add(:relevant_date, :cant_be_blank, link_id: 'edit_transaction_details')
      end

      # Validates if the passed date(cmp_date) crosses the max submission time limit
      # If it's crossed, adds a error to base. A dynamic locale_key is generated
      # by the passed key_name interpolation
      def validate_date_cross_submission_limit(model, cmp_date, key_name)
        locale_key = :"non_submitabble_#{key_name}"
        model.errors.add(:base, locale_key, time_limit: model.return_time_limit) if date_crossed_submit_limit?(
          model, cmp_date
        )
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

      # @param model [model] the model
      # @return [array] array of addresses for the buyers except for records with company_number
      def get_buyers_addresses(model)
        model.send(:buyers).values.map do |x|
          next if x.company&.company_number.present?

          [x&.full_address, x&.full_contact_address, x&.full_org_contact_address_address]
        end.flatten.compact_blank
      end

      # @param model [model] the model
      # @return [array] array of addresses for the tenants except for records with company_number
      def get_tenants_addresses(model)
        model.send(:tenants).values.map do |x|
          next if x.company&.company_number.present?

          [x&.full_address, x&.full_contact_address, x&.full_org_contact_address_address]
        end.flatten.compact_blank
      end

      # @param model [model] the model
      # @return [array] array of addresses for the tenants
      def get_new_tenants_addresses(model)
        model.send(:new_tenants).values.map do |x|
          [x&.full_address, x&.full_contact_address, x&.full_org_contact_address_address]
        end.flatten.compact_blank
      end

      # @param model [model] the model
      # @return [array] array of addresses for the agent
      def get_agent_addresses(model)
        [model.agent&.full_address]
      end

      # @param model [model] the model
      # @return [array] array of addresses for the user
      def get_user_addresses(model)
        [Account.find(model.current_user).full_address] << Account.find(model.current_user)&.org_address_humanised
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
