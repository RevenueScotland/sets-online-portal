# frozen_string_literal: true

# Helper for the main Wizard methods concern handling addresses as a special case
module WizardAddressHelper
  extend ActiveSupport::Concern
  include AddressHelper

  # Provides a method for the common code for using the address search system as a wizard step.
  #
  # There are 3 parts to an address wizard step with submits in between and after them :
  #    1) loading the page 2) searching for a postcode 3) storing the chosen address.
  #
  # Calls #wizard_setup_step to get the model (ie the form_for attribute in the view/the object being developed in
  # the wizard cache) in every part since it's usually needed for the view and for storing the address.
  #
  # Like wizard_step, this method is designed to be pretty much the only thing the controller action does for managing
  # the navigation etc.  If you find yourself putting it in an if statement, you're almost certainly doing it wrong.
  #
  # It provides default processing to handle most scenarios to load the address from the parent model and save
  # it back at the appropriate point. it does this via three standard routines to load the address, store the
  # address or to make sure other fields on the parent model are saved. You can override each of these if needed
  # but if you are overriding them check first as you are probably doing it wrong
  #
  # Standard overrides are listed below but it can also take overrides used by the main wizard step
  #
  # This relies on code @see AddressHelper that handles address searches outside of a wizard
  #
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  #                       NB don't put a method call in the steps param, it will be resolved asap which is usually
  #                       before the data is merged which is usually not what you want.
  # @param overrides [Hash] hash of optional overrides with the following keys :
  #  :address_attribute  - The attribute as a symbol used store the address if it isn't called address on the model
  #  :address_required - Another attribute which may determine if the address is required e.g. contact_address_ind
  #  :address_not_required - Another attribute which may determine if the address is not required the reverse sense of
  #                         the above, only one of these can be supplied
  #  :cache_index     - if cache_index is not the default controller you can override it
  #  :default_country - This is used to set the default country on an address object being created if it isn't GB
  #
  # @example Controller action has
  #   wizard_address_step(STEPS, address_attribute: :my_address, address_required: :my_address_yes_no )
  #
  #
  def wizard_address_step(steps, overrides = {})
    wizard_handle_clear_cache(overrides)
    model = wizard_setup_step(overrides)
    model, sub_object = model if model.is_a?(Array)

    # POST
    if params[:continue]
      return unless wizard_store_address(model, sub_object, overrides)

      return wizard_navigation_step(steps, overrides, collection_of_sub_object_size(model, overrides))
    end

    # special POST and GET
    # The standard pre-search makes sure any non address items are saved in the model before the search
    # for the address. Then sets global variables about the address used for the rendered address layout
    return wizard_address_pre_search(model, sub_object, overrides, false) && search_for_addresses if address_search?

    # GET
    wizard_load_address(model, sub_object, overrides)
  end

  private

  # Standard store address code to handle storing address in the current mode
  # @param model [Object] the parent model being processed
  # @param sub_object [Object|NilClass] a sub-object of the model that the wizard page is currently referring to,
  #   if it's nil then there's no such object.
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # returns [Boolean] true if the model was valid and saved, false otherwise
  def wizard_store_address(model, sub_object, overrides)
    # we may also have main model parameters so store these and validate them first
    # the standard address search does the save
    model_valid = wizard_address_pre_search(model, sub_object, overrides, true)

    # check the address required flags
    address_required = wizard_address_required?(model, sub_object, overrides)

    # if the model is valid and an address isn't required then exit now
    return true if model_valid && !address_required

    address = Address.new(address_params.merge!(default_country: overrides[:default_country]))

    # exit with false if the save failed
    unless wizard_address_save_or_initialise([model, sub_object], address, address_required, model_valid, overrides)
      return false
    end

    success = run_after_merge(overrides)
    # save the model if all successful
    wizard_save(model, overrides[:cache_index]) if success
    success
  end

  # saves the address in the model on the parent or initialises as required
  # @param wizard_objects [Array] two objects: first one is the parent model being processed, and second is
  #   the sub-object of the parent model which should be nil if it doesn't exist.
  # @param address [Object] the actual address we are trying to save
  # @param address_required [Boolean] Is an address required on this page
  # @param model_valid [Boolean] is the parent model valid
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # returns [Boolean] true if the model was valid and saved, false otherwise
  def wizard_address_save_or_initialise(wizard_objects, address, address_required, model_valid, overrides)
    # @note order is important as we want to validate the address even if the main model isn't valid
    # we use address required to stop it validating an address that isn't required atm
    success = false
    if address_required && address.valid?(add_validation_contexts(address_validation_contexts, overrides)) &&
       model_valid
      success = wizard_save_address_in_model(wizard_objects[0], wizard_objects[1], address, overrides)
    end

    Rails.logger.debug("Validation on address: #{success}, required: #{address_required}, model_valid: #{model_valid}")

    initialize_address_variables(address, search_postcode) unless success
    success
  end

  # This is the standard address pre-search. Primarily it saves fields prior to the search option so they are not lost
  # on the model. It can optionally validate the model
  # It is also used @see standard_store_address to store parameters prior to address validation
  # @param model [Object] the parent model being processed
  # @param sub_object [Object|NilClass] a sub-object of the model that the wizard page is currently referring to,
  #   if it's nil then there's no such object.
  # @param validate [Boolean] do we need to validate the parent model as part of the process
  def wizard_address_pre_search(model, sub_object, overrides, validate)
    page_params = resolve_params(overrides)
    unless page_params.nil?
      wizard_page_object = overrides[:sub_object_attribute].present? ? sub_object : model
      merge_params_with_object(wizard_page_object, page_params)

      return true unless validate

      valid = validate_model_after_sub_object_merge(model, sub_object, overrides, true)
      return wizard_page_object.valid?(page_params.keys.map(&:to_sym)) && valid
    end
    true
  end

  # In some models an address may not be required depending on another item in the model. This routine this checks the
  # flag. The flag can either be a required flag (Y if an address is required), or a not required flag
  # (N if an address is not required) only one of these can be provided
  # @example LBTT Party requires an additional contact address if the user says that Yes their address will change
  # @example A company has a flag that asks if the registered address is also the contact address so if the user says
  #   No they need another address
  # If an address isn't required then save the model (see @save_address_if_not_required)
  # @param model [Object] the parent model being processed
  # @param sub_object [Object|NilClass] a sub-object of the model that the wizard page is currently referring to,
  #   if it's nil then there's no such object.
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # @return [Boolean] is an address required
  def wizard_address_required?(model, sub_object, overrides)
    address_required = overrides[:address_required]
    address_not_required = overrides[:address_not_required]
    return true if address_required.nil? && address_not_required.nil?

    # Depending on the object we're using on current wizard page, we'll use that to check if the address
    # is required or not required.
    wizard_page_object = sub_object || model
    value = wizard_page_object.send(address_required || address_not_required)
    check = (address_required.nil? ? 'Y' : 'N')

    save_address_if_not_required(model, value, check, overrides)
  end

  # see @wizard_address_required
  # Saves the address if the required/not required flag is set to the check value
  # The flag not being set is always considered to be that an address is not required (as this means the flag hasn't
  # been set)
  # @param model [Object] the parent model being processed
  # @param flag_value [Object] the flag_value being checked
  # @param required_value [Object] the value the flag is checked against (Y or N)
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # @return [Boolean] true if an address is required, false otherwise
  def save_address_if_not_required(model, flag_value, required_value, overrides)
    if flag_value.blank? || (flag_value == required_value)
      wizard_save(model, overrides[:cache_index])
      return false
    end
    true
  end

  # This is the standard address load. Primarily it populates the address detail from  the model
  # @param model [Object] the parent model being processed
  # @param sub_object [Object|NilClass] a sub-object of the model that the wizard page is currently referring to,
  #   if it's nil then there's no such object.
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  def wizard_load_address(model, sub_object, overrides)
    address = (sub_object || model).send(overrides[:address_attribute] || :address)
    initialize_address_variables(address, search_postcode, overrides[:default_country])
  end

  # Populated the model with the address it doesn't save in the cache as later stages may error
  # @param model [Object] The model where the address will be stored at an address attribute or the attribute
  #   provided in the override
  # @param sub_object [Object|NilClass] a sub-object of the model that the wizard page is currently referring to,
  #   if it's nil then there's no such object. So if this is present then the address will be stored in an attribute
  #   of it, then that sub-object will be merged back to the model.
  # @param address [Object] the address being processed
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # @return [Boolean] always returns true
  def wizard_save_address_in_model(model, sub_object, address, overrides)
    address_attribute = overrides[:address_attribute] || :address
    wizard_page_object = sub_object || model

    Rails.logger.debug "Storing address in object #{wizard_page_object.class.name}##{address_attribute}"

    wizard_page_object.send((address_attribute.to_s + '=').to_sym, address)
    # revalidate the parent model to allow for any cross address validation
    valid = wizard_valid?(wizard_page_object, resolve_params(overrides), overrides)
    valid = validate_model_after_sub_object_merge(model, sub_object, overrides, valid)

    return false unless valid

    true
  end

  # Runs the after merge if one was specified
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # @return [Boolean] true if the merge call succeeded or there wasn't one false if a call fails
  def run_after_merge(overrides)
    # custom method to run after successful merge and save
    after_merge = overrides[:after_merge]
    return true unless after_merge

    success = send(after_merge)
    Rails.logger.debug "After merge call failed: #{after_merge}" unless success
    success
  end

  # Runs the address search
  def search_for_addresses
    populate_address_data
    address_search
  end
end
