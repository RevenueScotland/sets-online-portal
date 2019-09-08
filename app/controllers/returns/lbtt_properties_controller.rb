# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for LBTT properties management
  # It maintains all information about the properties related to LBTT return
  class LbttPropertiesController < ApplicationController
    include AddressHelper
    include Wizard
    include LbttTaxHelper

    authorise requires: AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to properties actions
    skip_before_action :require_user

    # Navigation page flow for property wizard
    # @see #about_the_property_next_step which skips the last step unless return type is CONVEY
    STEPS = %w[property_address about_the_property property_ads_applies].freeze

    # First property wizard step.  Clears the cache at start so can't mix up data from old wizards.
    # Enabling country code field for Property Model.
    def property_address
      @country_code_required = true
      wizard_address_step(STEPS, :store_address, clear_cache: true, load_address: :load_address)
    end

    # Property wizard step
    def about_the_property
      wizard_step(nil) { { params: :filter_params_add_lau_value, next_step: :about_the_property_next_step } }
    end

    # Last property wizard step, on submit, merges property data into return data @see #dump_property_into_lbtt_wizard
    def property_ads_applies
      wizard_step(returns_lbtt_summary_path) do
        { params: :filter_params, after_merge: :dump_property_into_lbtt_wizard }
      end
    end

    # Delete the property entry entry specified by params[:property_id]
    def delete
      look_for_property(params[:property_id], delete: true)
      redirect_to returns_lbtt_summary_path
    end

    private

    # Sets up @property for this wizard/form to use (where to post the form to).
    # If property_id is provided in params then will load that property from the LBTT wizard and save in this wizard.
    # Otherwise it will load from the wizard (ie the current property)
    # Otherwise it's a new one, and will use property_id from the params and save it in this wizard.
    # @return [Property] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path(LbttController.name)
      load_property

      # @property should exist now
      Rails.logger.debug("Loaded property #{@property.property_id}")
      @property
    end

    # We only want to show the property_ads_applies page if return type is CONVEY.  If it's not, show the summary
    # page after calling @see #dump_property_into_lbtt_wizard
    def about_the_property_next_step
      return STEPS if @property.flbt_type == 'CONVEY'

      dump_property_into_lbtt_wizard

      returns_lbtt_summary_path
    end

    # Loads existing property into @property if available from the LBTT wizard cache and save in this wizard
    # Properties are indexed by UUID so we don't get the wrong one when editing or deleting them.
    def load_property
      if params[:property_id]

        # new property case - assign a UUID
        @property = Lbtt::Property.new(property_id: SecureRandom.uuid) if params[:property_id] == 'new'

        # or lookup the existing property by it's ID (which is a UUID)
        @property ||= look_for_property(params[:property_id])

        @property.flbt_type = wizard_load(Returns::LbttController).flbt_type

        # save the newly loaded property into this wizard's cache ready for the next step
        wizard_save(@property)
      else
        # existing data
        @property = wizard_load
      end
    end

    # Searches the LBTT wizard for a property
    # @param property_id [String] the property_id to look for
    # @param delete [Boolean] option to delete the party if found, defaults to false
    def look_for_property(property_id, delete = false)
      lbtt_return = wizard_load(Returns::LbttController)
      return if lbtt_return.properties.nil?

      return unless lbtt_return.properties.key? property_id

      if delete
        # delete property and save the return to make the deletion permanent
        Rails.logger.info("Deleting property #{property_id} from model")
        lbtt_return.properties.delete(property_id)
        wizard_save(lbtt_return, Returns::LbttController)
      else
        lbtt_return.properties.fetch(property_id)
      end
    end

    # Return the parameter list filtered for the attributes of the LbttReturn model.
    def filter_params
      required = :returns_lbtt_property
      attribute_list = Lbtt::Property.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end

    # The user selects a LAU code by the value but the submit sends the code.  Look up the value again
    # and insert it into the params so it seamlessly appears and we save another call to save @property.
    # (It would be possible to send both code and value from the select drop-down but this is less complex.)
    def filter_params_add_lau_value
      required = :returns_lbtt_property
      attribute_list = Lbtt::Property.attribute_list

      output = params.require(required).permit(attribute_list)
      restore_lau_value(output)
    end

    # Gets the LAU value for output[:lau_code] and populates output[:lau_value]
    # @param output [Parameters] @see #filter_params_add_lau_value
    def restore_lau_value(output)
      lau_code = output[:lau_code]
      ref_data_hash = ReferenceData::ReferenceValue.lookup('LAU', 'SYS', 'RSTU')
      unless lau_code.blank?
        lau_value = ref_data_hash[lau_code].value
        Rails.logger.debug("Adding LAU value back in #{lau_code} = #{lau_value}")
        output[:lau_value] = lau_value
      end
      output
    end

    # Puts the new property data into the right place in LbttReturn
    def dump_property_into_lbtt_wizard
      @lbtt_return = wizard_load(Returns::LbttController)
      @lbtt_return.properties = {} if @lbtt_return.properties.nil?
      @lbtt_return.properties[@property.property_id] = @property

      # if ADS applies to this property, update the tax calculations to take ADS into consideration
      update_tax_calculations if @property.ads_due_ind

      wizard_save(@lbtt_return, Returns::LbttController)
    end

    # Initialises address variables(@see #AddressHelper)
    def load_address
      initialize_address_variables(@property.address)
    end

    # store address in the wizard cache
    # This method also checks the value of the 'return_value'(Validation check result)got from the
    # model and returns the associated errors before saving in wizard.
    def store_address
      @property.address = Address.new(address_params)
      return merge_error unless @property.address.valid?(address_validation_context)

      return_value = @property.address.valid?(:scotland_postcode_selected)

      return merge_error if return_value == false

      wizard_save(@property)
      true
    end

    # Setup the view to show the address page with an error
    # @return false
    def merge_error
      initialize_address_variables(@property.address, search_postcode)
      false
    end
  end
end
