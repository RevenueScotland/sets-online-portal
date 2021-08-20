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
  # Calls #wizard_setup_step to get the cached object and the object on the page
  #
  # Like wizard_step, this method is designed to be pretty much the only thing the controller action does for managing
  # the navigation etc.  If you find yourself putting it in an if statement, you're almost certainly doing it wrong.
  #
  # It provides default processing to handle most scenarios to load the address from the parent object and save
  # it back at the appropriate point. it does this via three standard routines to load the address, store the
  # address or to make sure other fields on the parent object are saved. You can override each of these if needed
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
  #  :address_attribute  - The attribute as a symbol used store the address if it isn't called address on the object
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
    # non standard names used to avoid a line length issue further down
    cached_object, page_object = wizard_setup_step(overrides)

    # POST
    if params[:continue]
      return unless wizard_store_address(cached_object, page_object, overrides)

      return wizard_navigation_step(steps, overrides, wizard_page_objects_size(cached_object, overrides))
    end

    # special POST and GET
    # The standard pre-search makes sure any non address items are saved in the object before the search
    # for the address. Then sets global variables about the address used for the rendered address layout
    if address_search?
      return wizard_address_pre_search(cached_object, page_object, overrides, false) && search_for_addresses
    end

    # GET
    wizard_load_address(page_object, overrides)
  end

  private

  # Standard store address code to handle storing address in the current mode
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # returns [Boolean] true if the cached object was valid and saved, false otherwise
  def wizard_store_address(wizard_cached_object, wizard_page_object, overrides)
    # we may also have page object parameters so store these and validate them first
    # the standard address search does the save
    valid = wizard_address_pre_search(wizard_cached_object, wizard_page_object, overrides, true)

    # check the address required flags
    required = wizard_address_required?(wizard_cached_object, wizard_page_object, overrides)

    # if the model is valid and an address isn't required then exit now
    return true if valid && !required

    # exit with false if the save failed
    unless wizard_address_save_or_initialise(wizard_cached_object, wizard_page_object, required, valid, overrides)
      return false
    end

    success = wizard_address_run_after_merge(overrides)
    # save the object if all successful
    wizard_save(wizard_cached_object, overrides[:cache_index]) if success
    success
  end

  # saves the address in the node on the parent or initialises as required
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param required [Boolean] is the address required
  # @param object_valid [Boolean] is the cached object valid
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # returns [Boolean] true if the object was valid and saved, false otherwise
  def wizard_address_save_or_initialise(wizard_cached_object, wizard_page_object, required, object_valid, overrides)
    # @note order is important as we want to validate the address even if the parent object isn't valid
    # we use address required to stop it validating an address that isn't required atm
    address = Address.new(address_params.merge!(default_country: overrides[:default_country]))

    success = false
    if required && address.valid?(add_validation_contexts(address_validation_contexts, overrides)) && object_valid
      success = wizard_save_address_in_object(wizard_cached_object, wizard_page_object, address, overrides)
    end

    Rails.logger.debug { "Validation on address: #{success}, required: #{required}, object_valid: #{object_valid}" }

    # if the above didn't work then initialise the page address variables for the next iteration
    initialize_address_variables(address, search_postcode) unless success
    success
  end

  # This is the standard address pre-search. Primarily it saves fields prior to the search option so they are not lost
  # on the object. It can optionally validate the object
  # It is also used @see standard_store_address to store parameters prior to address validation
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param validate [Boolean] do we need to validate the parent object as part of the process
  def wizard_address_pre_search(wizard_cached_object, wizard_page_object, overrides, validate)
    wizard_params = resolve_params(overrides)
    unless wizard_params.nil?
      merge_params_with_object(wizard_page_object, wizard_params)

      return true unless validate

      return wizard_valid?(wizard_cached_object, wizard_params, overrides)
    end
    true
  end

  # In some objects an address may not be required depending on another item in the object. This routine this checks the
  # flag. The flag can either be a required flag (Y if an address is required), or a not required flag
  # (N if an address is not required) only one of these can be provided
  # @example LBTT Party requires an additional contact address if the user says that Yes their address will change
  # @example A company has a flag that asks if the registered address is also the contact address so if the user says
  #   No they need another address
  # If an address isn't required then save the object (see @save_address_if_not_required)
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # @return [Boolean] is an address required
  def wizard_address_required?(wizard_cached_object, wizard_page_object, overrides)
    address_required = overrides[:address_required]
    address_not_required = overrides[:address_not_required]
    return true if address_required.nil? && address_not_required.nil?

    # Depending on the object we're using on current wizard page, we'll use that to check if the address
    # is required or not required.
    value = wizard_page_object.send(address_required || address_not_required)
    check = (address_required.nil? ? 'Y' : 'N')

    required = save_address_if_not_required(wizard_cached_object, value, check, overrides)
    Rails.logger.debug { "Address required: #{required}" }
    required
  end

  # see @wizard_address_required
  # Saves the address if the required/not required flag is set to the check value
  # The flag not being set is always considered to be that an address is not required (as this means the flag hasn't
  # been set)
  # @param wizard_cached_object [Object] the object being cached
  # @param flag_value [Object] the flag_value being checked
  # @param required_value [Object] the value the flag is checked against (Y or N)
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # @return [Boolean] true if an address is required, false otherwise
  def save_address_if_not_required(wizard_cached_object, flag_value, required_value, overrides)
    if flag_value.blank? || (flag_value == required_value)
      wizard_save(wizard_cached_object, overrides[:cache_index])
      return false
    end
    true
  end

  # This is the standard address load. Primarily it populates the address detail from  the object
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  def wizard_load_address(wizard_page_object, overrides)
    address = wizard_page_object.send(overrides[:address_attribute] || :address)
    initialize_address_variables(address, search_postcode, overrides[:default_country])
  end

  # Populated the object with the address it doesn't save in the cache as later stages may error
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param address [Object] the address being processed
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # @return [Boolean] always returns true
  def wizard_save_address_in_object(wizard_cached_object, wizard_page_object, address, overrides)
    address_attribute = overrides[:address_attribute] || :address

    Rails.logger.debug { "Storing address in object #{wizard_page_object.class.name}##{address_attribute}" }

    wizard_page_object.send("#{address_attribute}=".to_sym, address)
    # revalidate the parent object to allow for any cross address validation
    wizard_valid?(wizard_cached_object, resolve_params(overrides), overrides)
  end

  # Runs the after merge if one was specified
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  # @return [Boolean] true if the merge call succeeded or there wasn't one false if a call fails
  def wizard_address_run_after_merge(overrides)
    # custom method to run after successful merge and save
    after_merge = overrides[:after_merge]
    return true unless after_merge

    success = send(after_merge)
    Rails.logger.debug { "After merge call failed: #{after_merge}" } unless success
    success
  end

  # Runs the address search
  def search_for_addresses
    populate_address_data
    address_search
  end
end
