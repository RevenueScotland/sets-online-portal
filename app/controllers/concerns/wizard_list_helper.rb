# frozen_string_literal: true

# This handles the case where the wizard page has a a table of objects to include in the main object
# As we do for address and company search
# Note: unlike the address or company search we don't have a non wizard variant of this as that would
# be normal rails code
# Include this concern in the controller code alongside the Wizard module.
#
# You need to provide specific methods in your controller to provide some of the processing to
# create a new instance of the object and provide pointers to these methods in the overrides
#
# Your controller must also provide a filter_list_params function that filters the parameters
# to those that are relevant for the attribute being processed
#
# If you need to create an instance of your list object (normally you have would need an empty row)
# then override the setup step as per the standard wizard
#
# Validation for the added object is normally applied to the whole object (as you are normally saving
# a whole object in one go). This can be overridden if needed but question why you have specific contexts
# see @wizard_list_step for specific overrides for this concern
#
# @example
#     wizard_list_step(nil, setup_step: :setup_reliefs_on_transaction_step,
#                           next_step: :calculate_next_step, cache_index: LbttController,
#                           list_required: :non_ads_reliefclaim_option_ind,
#                           list_attribute: :non_ads_relief_claims,
#                           new_list_item_instance: :new_list_item_non_ads_relief_claims)
module WizardListHelper
  extend ActiveSupport::Concern

  # Requires implementing classes have specified a setup method which returns the object (ie normal Wizard stuff).
  #
  # You need to override "add_row_handler" to handle add row functionality on page.
  # and override "delete_row_handler" to handle delete row functionality on page.
  # Limitations - at present, only validation contexts gleaned from filter_params can be used.  That usually
  # won't include your list!  (But it will include anything else on your form, eg a yes-no radio button.)
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param overrides [Hash] the specific keys used are:
  #   - :list_required [Symbol] method name on the page object to check if the list is required (i.e method==Y)
  #   - :list_not_required [Symbol] method name on the page object to check if the list is not required (i.e method==N)
  #   - :new_list_item_instance [Symbol] method name on the controller to call to generate a new instance of the list
  #                                      object
  #   - :list_attribute [Symbol] is the attribute of the page object where the list is stored
  #   - :list_validation_context [Array] an array of symbols for a specific validation context, only needed in rare
  #                                      circumstances
  #   - also @see Wizard#wizard_step for more info about the other keys
  def wizard_list_step(steps, overrides)
    # Standard processing to initialise, used for both get and post processing
    wizard_handle_clear_cache(overrides)
    wizard_cached_object, wizard_page_object = wizard_setup_step(overrides)

    # Exit unless POST processing is required
    list_action, delete_row = wizard_list_action

    return unless list_action

    # Process the list items if we need to actually process them
    if wizard_list_required?(wizard_page_object, resolve_params(overrides), overrides)
      list_contents = wizard_merge_list(wizard_page_object, overrides)
    end

    navigate = wizard_list_validate_and_save(list_action, wizard_cached_object, list_contents, delete_row, overrides)
    return unless navigate

    wizard_navigation_step(steps, overrides, wizard_page_objects_size(wizard_cached_object, overrides))
  end

  private

  # determine the type of processing for the list
  # this will be one of continue, add_row or delete_row
  # if delete row then also returns the row number to delete as a string, it needs to be a string
  # as in places nil means not deleting
  # @ return type [Symbol], delete_row [String]
  def wizard_list_action
    if params[:continue]
      [:continue, nil]
    elsif params[:add_row]
      [:add_row, nil]
    elsif params[:delete_row]
      [:delete_row, params[:delete_row]]
    else
      [nil, nil]
    end
  end

  # Indicates we need to process the list items, also handles the assigning of attributes
  # We process the list if there is no required flag, or if there is a required flag that is 'Y'
  # or a not required flag that is N (only one of required and not required can be provided)
  # Note we don't validate the page object in this routine so it could be invalid that is handled
  # in the calling routine
  # @param wizard_page_object [Object] the object on the page that owns the list object
  # @param wizard_params [Hash] the parameters to process
  # @return [Boolean] if the list needs to be processed
  def wizard_list_required?(wizard_page_object, wizard_params, overrides)
    wizard_page_object.assign_attributes(wizard_params)
    required = overrides[:list_required]
    not_required = overrides[:list_not_required]

    # if there is no list required then default to true
    # otherwise return the flag
    list_required = if required.nil? && not_required.nil?
                      true
                    else
                      # This checks if required_method == 'Y' e.g. 'I want to provide a list' Y [list required] or N
                      # or not_required_method == 'N' e.g. 'There is no need for a list ' Y or N [list required]
                      wizard_page_object.send(required || not_required) == (required.nil? ? 'N' : 'Y')
                    end

    Rails.logger.debug { "  List required: #{list_required} " }
    list_required
  end

  # Merges the list parameters to create the list of objects.
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @return [Array] the list of objects created
  def wizard_merge_list(wizard_page_object, overrides)
    list_attribute = overrides[:list_attribute]
    list_contents = wizard_page_object.send(overrides[:list_attribute])
    # Call the routine on the controller to filter the parameters
    record_array = filter_list_params(list_attribute, overrides[:sub_object_attribute])

    record_array&.each_with_index do |record, i|
      list_item = wizard_list_create_and_validate_item(list_contents[i], record, overrides)
      list_contents[i] = list_item
    end
    wizard_page_object.send("#{list_attribute}=", list_contents)
    list_contents
  end

  # Validates the wizard and if valid saves it
  # signals back if the next navigation step should be carried out
  # @param list_action [Symbol] The type of wizard_list_processing
  # @param wizard_cached_object [Object] - the object to validate
  # @param list_contents [Array] - a list of pre-validated rails objects
  # @param delete_row [String] - a row about to be deleted [not checked for errors]
  # @param overrides - You can add extra contexts using the validates override @see #wizard_step for more details
  # @return [Boolean] true if navigation is required
  def wizard_list_validate_and_save(list_action, wizard_cached_object, list_contents, delete_row, overrides)
    # Do not navigate if the main object is not valid or any of the list contents have errors
    unless wizard_list_valid?(wizard_cached_object, resolve_params(overrides), list_contents, delete_row, overrides)
      return false
    end

    # Do not navigate if we are processing the submit and the after merge fails
    return unless wizard_list_run_after_merge(list_action, overrides)

    wizard_list_add_or_delete_row(list_action, list_contents, delete_row, overrides)

    # Finally save and if we are in continue navigate
    wizard_save(wizard_cached_object, overrides[:cache_index])
    (list_action == :continue)
  end

  # Validates the the cached object and the list objects are valid
  # It assumes the list objects have already been validated when they were
  # build so is really just a case of checking them
  # @param wizard_cached_object [Object] - the object to validate
  # @param wizard_params [hash] - params submitted on a form the keys of which will be the validation contexts to check
  # @param list_contents [Array] - a list of pre-validated rails objects
  # @param delete_row [String] - a row about to be deleted [not checked for errors]
  # @param overrides - You can add extra contexts using the validates override @see #wizard_step for more details
  # @return [Boolean] true if valid else false
  def wizard_list_valid?(wizard_cached_object, wizard_params, list_contents, delete_row, overrides)
    valid = wizard_valid?(wizard_cached_object, wizard_params, overrides)

    valid && !errors_in_list(list_contents, delete_row)
  end

  # Method handle after merge action after submitting
  # @param list_action [Symbol] The type of wizard_list_processing
  # @param overrides [Hash] @see Wizard#wizard_step
  def wizard_list_run_after_merge(list_action, overrides)
    return true unless list_action == :continue

    after_merge = overrides[:after_merge]
    return true unless after_merge

    success = send(after_merge)
    Rails.logger.debug { "After merge call failed: #{after_merge}" } unless success
    success
  end

  # create and validate a new item instance by calling the method on the controller
  # assigning the attributes and then validating
  # @param object [Object] the existing object at that index if one exists
  # @param attributes [Hash] hash of attributes
  # @param overrides [Hash] overrides for this step
  # @return [Object] a new populated and validated list item
  def wizard_list_create_and_validate_item(object, attributes, overrides)
    # list item is either the existing object or create a new one.
    list_item = (object.nil? ? send(overrides[:new_list_item_instance]) : object)
    list_item.assign_attributes(attributes)

    # if the validation needs to be done on specific key.
    list_item.valid?(overrides[:list_validation_context])
    list_item
  end

  # Adds or deletes a row depending on the type of processing
  # @param list_action [Symbol] Is this a delete or an add
  # @param list_contents [Array] The list of items
  # @param delete_row [String] the row to delete a string as needs to handle nil
  # @param overrides [Hash] the array of overrides for this step
  def wizard_list_add_or_delete_row(list_action, list_contents, delete_row, overrides)
    case list_action
    when :add_row
      wizard_list_add_row(list_contents, overrides)
    when :delete_row
      wizard_list_delete_row(list_contents, delete_row)
    end
  end

  # At the end of the list, adds a row to the list contents of the wizard page object.
  # @see wizard_merge_and_save_on_add_or_delete_row to know more about the parameter variables.
  def wizard_list_add_row(list_contents, overrides)
    list_contents.push(send(overrides[:new_list_item_instance]))
  end

  # Using an index, this deletes a row from the list contents of the wizard page object.
  # @param list_contents [Array] an array of rails model objects
  # @param delete_row [string] the array index to be excluded, string as if integer reads as 0
  # @return [Boolean] true if any errors exist
  def wizard_list_delete_row(list_contents, delete_row)
    # Exit if nothing to delete
    return unless list_contents && delete_row

    list_contents.delete_at(delete_row.to_i)
  end

  # This takes in a list of rails model objects and returns true if any of them have
  # errors in. It can optionally take in an index to exclude, for example when a row is about
  # to be deleted it is excluded from this test
  # @param list_contents [Array] an array of rails model objects
  # @param exclude_index [string] the array index to be excluded, string as if integer reads as 0
  # @return [Boolean] true if any errors exist
  def errors_in_list(list_contents, exclude_index = nil)
    # handle nil list
    return false unless list_contents

    local_list = list_contents.dup
    local_list.delete_at(exclude_index.to_i) unless exclude_index.nil?
    errors_in_list = local_list.any? { |obj| obj.errors.any? }
    Rails.logger.debug { "  Errors in list : #{errors_in_list}" }
    errors_in_list
  end
end
