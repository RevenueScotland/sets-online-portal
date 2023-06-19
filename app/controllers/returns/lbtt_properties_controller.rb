# frozen_string_literal: true

# Sub-directory to organise the different tax returns.
module Returns
  # Controller for LBTT properties management
  # It maintains all information about the properties related to LBTT return
  class LbttPropertiesController < ApplicationController
    include Wizard
    include WizardAddressHelper
    include LbttTaxHelper

    authorise requires: RS::AuthorisationHelper::LBTT_SUMMARY, allow_if: :public
    # Allow unauthenticated/public access to properties actions
    skip_before_action :require_user

    # Navigation page flow for property wizard
    # @see #about_the_property_next_step which skips the last step unless return type is CONVEY
    STEPS = %w[property_address about_the_property property_ads_applies].freeze

    # First property wizard step.  Clears the cache at start so can't mix up data from old wizards.
    # Enabling country code field for Property Model.
    def property_address
      # Call clear_cache whenever params[:property_id]==new
      clear_cache = params[:property_id] == 'new'
      Rails.logger.debug('New property') if clear_cache

      # Set country code to false as property must be in scotland so don't ask the user for it
      @country_code_required = false
      wizard_address_step(STEPS, setup_step: :setup_step, clear_cache: clear_cache,
                                 validates: :scotland_postcode_selected,
                                 default_country: 'SCO')
    end

    # Property wizard step
    def about_the_property
      wizard_step(nil) { { next_step: :about_the_property_next_step } }
    end

    # Last property wizard step, on submit, merges property data into return data @see #dump_property_into_lbtt_wizard
    def property_ads_applies
      wizard_step(returns_lbtt_summary_path) { { after_merge: :dump_property_into_lbtt_wizard } }
    end

    # Delete the property entry entry specified by params[:property_id]
    def destroy
      lbtt_return = load_return
      look_for_property(params[:property_id], lbtt_return, delete: true)
      redirect_to(returns_lbtt_summary_path, status: :see_other)
    end

    private

    # Loads the parent return
    def load_return
      wizard_load_or_redirect(returns_lbtt_summary_url, nil, Returns::LbttController)
    end

    # We only want to show the property_ads_applies page if return type is CONVEY.  If it's not, show the summary
    # page after calling @see #dump_property_into_lbtt_wizard
    def about_the_property_next_step
      return STEPS if @property.flbt_type == 'CONVEY'

      dump_property_into_lbtt_wizard

      returns_lbtt_summary_path
    end

    # Searches the LBTT wizard for a property
    # @param property_id [String] the property_id to look for
    # @param delete [Boolean] option to delete the party if found, defaults to false
    def look_for_property(property_id, lbtt_return, delete: false)
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

    # Puts the new property data into the right place in LbttReturn
    def dump_property_into_lbtt_wizard
      @lbtt_return = load_return
      @lbtt_return.properties = {} if @lbtt_return.properties.nil?
      @lbtt_return.properties[@property.property_id] = @property

      @lbtt_return.synchronising_ads_due_on_reliefs!

      # if ADS applies to this property, update the tax calculations to take ADS into consideration
      update_tax_calculations if @property.ads_due_ind

      wizard_save(@lbtt_return, Returns::LbttController)
      wizard_end # clear the property from the cache
    end

    # Sets up wizard model if it doesn't already exist in the cache
    # Properties are index by UUID so we don't get the wrong one when editing or deleteing them.
    # Follows the a similar pattern to @see LbttPartiesController#setup_step
    # @note This method is very similar to the setup_step method of lbtt_parties_controller.rb
    # @raise [Error:AppError] if the property_id is missing (provided as a param)
    # @return [Property] the model for wizard saving
    def setup_step
      @post_path = wizard_post_path

      # load existing or setup new property on first entering the step
      if params[:property_id]
        @property = setup_by_property_id(params[:property_id])
        Rails.logger.debug { "Loaded (and cached) property #{@property.property_id}" }
      end

      # normal load now if it didn't get setup above
      @property ||= wizard_load

      @property
    end

    # If property_id is new then creates a new Property object with a UUID, otherwise calls @see #look_for_property.
    # returns the property.
    # @param lbtt_return [Object] The return being processed
    # @param property_id [String] the property_id to look for
    # @return [Property] object
    def create_or_get_property(lbtt_return, property_id)
      # new property case - assign a UUID
      if property_id == 'new'
        property = Lbtt::Property.new(property_id: SecureRandom.uuid, flbt_type: lbtt_return.flbt_type,
                                      ads_due_ind: default_ads_due_ind(lbtt_return))
      else

        # or lookup the existing property by it's ID (which is a UUID)
        property ||= look_for_property(property_id, lbtt_return)
      end

      property
    end

    # defaults the ads_due ind
    # @param lbtt_return [Object] The return being processed
    # @return Y or nil
    def default_ads_due_ind(lbtt_return)
      if lbtt_return.non_individual_buyer? && (lbtt_return.flbt_type == 'CONVEY') && (lbtt_return.property_type == '1')
        'Y'
      end
    end

    # Passes the property_id to the check if the property is new or not
    # @param property_id [String] the property_id to look for
    # @raise [Error::AppError] if the property cannot be found
    # @return [Property] object
    def setup_by_property_id(property_id)
      lbtt_return = load_return

      property = create_or_get_property(lbtt_return, property_id)

      # @property with ID should exist now
      raise Error::AppError.new('Property', 'Missing property_id') if property&.property_id.nil?

      # save the newly loaded property into this wizard's cache ready for the next step
      wizard_save(property)

      property
    end

    # Loads existing wizard models from the wizard cache or redirects to the summary page
    # @return [Property] the model for wizard saving
    def load_step(_sub_object_attribute = nil)
      @post_path = wizard_post_path
      @property = wizard_load_or_redirect(returns_lbtt_summary_url)
      @property
    end

    # Return the parameter list filtered for the attributes of the LbttReturn model.
    def filter_params(_sub_object_attribute = nil)
      required = :returns_lbtt_property
      attribute_list = Lbtt::Property.attribute_list
      params.require(required).permit(attribute_list) if params[required]
    end
  end
end
