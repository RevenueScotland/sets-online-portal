# frozen_string_literal: true

# Edge case wizard step (so not included in the normal wizard code).
# Include this model in the controller code alongside the Wizard module.
#
# When we have a page (eg LBTT Reliefs) where there's inputs for a simple data item (eg a yes-no radio button)
# in the model (eg LbttReturn) and also a fixed size list of some other class of data (eg RefiefClaim),
# but there's not a page-specific model used for the form, then we have to do some custom work to integrate
# nicely with the normal wizard code (which is what this concern provides).
#
# The fixed list must be initialised in the setup_step method :
# @example @lbtt_return.ads.ads_relief_claims ||= Array.new(3) { Lbtt::ReliefClaim.new }
#
# You also need a #merge_list_data method which will take the list from the params and put
# it into the right place in your model.  If your list isn't a fixed size, you can probably still
# handle that in your #merge_list_data method.  @see LbttAdsController#merge_list_data for an example.
#
# If you want the ability to add more rows in Datatable(technically the upper limit is unbounded) .
# in this scenario you need to create button with name add_row and override the method add_row_handler
# @example
#  Html page change
# <%= f.button 'add_row',
#              { :class => 'scot-rev-button_link govuk-link', :name => 'add_row' } %>
#  Controller change
#  wizard_list_step(nil, next_step: :calculate_next_step, cache_index: LbttController,
#                        merge_list: :merge_linked_transactions, add_row_handler: :add_linked_transactions_row)
module WizardListHelper
  extend ActiveSupport::Concern

  # Edge-case wizard-step to merge data as normal in a model but also merge in a list of another class.
  # Requires implementing classes have specified a setup method which returns the model (ie normal Wizard stuff).
  #
  # You need to override "add_row_handler" to handle add row functionality on page.
  # and override "delete_row_handler" to handle delete row functionality on page.
  # Limitations - at present, only validation contexts gleaned from filter_params can be used.  That usually
  # won't include your list!  (But it will include anything else on your form, eg a yes-no radio button.)
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param overrides [Hash] the main keys used are:
  #   - :merge_list [Symbol] contains a method name to the processing of the merging of params to the model,
  #     the method must be defined in the controller
  #   - :list_attribute [Symbol] is the attribute of the object where the list is stored
  #   - :new_list_item_instance [Symbol] contains a method name to the instantiation of an object, the method
  #     must be defined in the controller
  #   - also @see Wizard#wizard_step for more info about the other keys
  def wizard_list_step(steps, overrides)
    # first half
    wizard_handle_clear_cache(overrides)
    model = wizard_setup_step(overrides)
    model, sub_object = model if model.is_a?(Array)

    # Handle the main model to make sure it is up to date
    return unless wizard_merge_and_validate_non_list_data(model, sub_object, overrides)

    if params[:continue]
      # Handles the merging and saving on cache when the form is submitted, by clicking the "Continue" button.
      wizard_merge_and_save_on_submit(steps, model, sub_object, overrides)
    else
      # Handles the merging and saving on cache when a "delete" or "add" button has been clicked.
      wizard_merge_and_save_on_add_or_delete_row(model, sub_object, overrides)
    end
  end

  private

  # Before doing the merge and save for the list-related data, this handles the merging and saving of the
  # non-list related data to the wizard page object.
  # @return [Boolean] are there NO ERRORS found while validating the object(s)?
  def wizard_merge_and_validate_non_list_data(model, sub_object, overrides)
    wizard_params = resolve_params(overrides)
    wizard_page_object = sub_object || model
    wizard_page_object.assign_attributes(wizard_params) unless wizard_params.nil?

    # Validates the current object (which is the model or the sub-object if it exists) on the wizard page
    valid = wizard_valid?(wizard_page_object, wizard_params, overrides)
    # Validates the model if there exists a sub-object
    validate_model_after_sub_object_merge(model, sub_object, overrides, valid)
  end

  # Method handle sequence of action after submitting
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param overrides [Hash] @see Wizard#wizard_step
  def wizard_merge_and_save_on_submit(steps, model, sub_object, overrides)
    # merges in the child object and validates it
    # The merge list procedure returns true or false if it fails e.g. validation error
    # at which point return and don't move off the page
    # The below is saying if there is an override call it and then if it fails exit this routine
    return if overrides[:merge_list] && !wizard_merge_and_validate_params_with_list(model, sub_object, overrides)

    success = run_after_merge(overrides)

    # if the after merge fails then also stay on the page and don't save
    return if model.errors.any? || success == false

    wizard_save(model, overrides[:cache_index])
    wizard_navigation_step(steps, overrides, collection_of_sub_object_size(model, overrides))
  end

  # Uses the overrides to do the merging of params with the model and then validates it in both the helper and the
  # controller.
  # Validations done in the controller is needed for objects with special rule(s).
  # @see merge_params_and_validate_with_list to learn about how the merging and initial validation is done, this is
  #   also yielded into the method (with key :merge_list in overrides) found in the controller where the
  #   wizard_list_helper is used.
  # @return [Boolean] true if there's any errors in any of the objects in the list, false if no errors found.
  def wizard_merge_and_validate_params_with_list(model, sub_object, overrides)
    send(overrides[:merge_list]) { merge_params_and_validate_with_list(model, sub_object, overrides) }
  end

  # Merges the params with the list and also validates each of them.
  # @note Ensure that the @list_item_validation_key is set if you need to add a key for the validation of each item
  # @note Also make sure that the method found in the new_list_item_instance is defined and returns an object
  # @return [Boolean] are there no errors in the list item objects?
  def merge_params_and_validate_with_list(model, sub_object, overrides)
    list_attribute = overrides[:list_attribute]
    list_contents = wizard_list_contents(model, sub_object, overrides)
    record_array = filter_list_params(list_attribute, overrides[:sub_object_attribute])

    record_array&.each_with_index do |record, i|
      # This stores the newly instantiated object with values from the record.
      list_item = send(overrides[:new_list_item_instance], record)

      # The global variable @list_item_validation_key must be set in the method which overrides[:merge_list] calls
      # if the validation needs to be done on specific key.
      list_item.valid?(@list_item_validation_key)
      list_contents[i] = list_item
    end

    # Storing the list contents back into the model (or sub-object) is needed for the attributes where we re-define
    # it to return new data that doesn't return a pointer to the storage, for example in the lbtt_return we have a
    # setter "relief_claims=" and the getter "relief_claim". The "relief_claim" is what the list_contents is
    # pointing to which does not return a pointer to the attribute contents itself.
    (sub_object || model).send("#{list_attribute}=", list_contents)

    # The list_contents is used to check if there is no error on any of the items in the list.
    # Then it validates the model if there exists a sub-object, if not then it will just return the checking
    # of errors on the list_contents.
    #
    # In short, it checks if all the related objects are valid.
    validate_model_after_sub_object_merge(model, sub_object, overrides, list_contents.all? { |obj| obj.errors.none? })
  end

  # Method handle after merge action after submitting
  # @param overrides [Hash] @see Wizard#wizard_step
  def run_after_merge(overrides)
    after_merge = overrides[:after_merge]
    return true unless after_merge

    success = send(after_merge)
    Rails.logger.debug "After merge call failed: #{after_merge}" unless success
    success
  end

  # Adds or removes a row when the user clicks on the add or delete button.
  # @param model [Object] the object that will be processed and used for the merging of params.
  # @param sub_object [Object|nil] a sub-object of the model, if it exists it will be used for the merging of params.
  # @param overrides [Hash] contains instructions @see Wizard#wizard_step
  def wizard_merge_and_save_on_add_or_delete_row(model, sub_object, overrides)
    delete_row = params[:delete_row]
    # If the "add row" or "delete row" has not been clicked then we don't have to do any merge and save
    return if params[:add_row].nil? && delete_row.nil?

    # Merge is needed for both the adding or deleting of a row
    merge_success = wizard_merge_and_validate_params_with_list(model, sub_object, overrides)
    list_contents = wizard_list_contents(model, sub_object, overrides)

    # As at the top the method is escaped when there's no add/delete row, then we only need to check one
    if delete_row.nil?
      list_add_row(list_contents, merge_success, overrides)
    else
      list_delete_row(list_contents, delete_row)
    end

    wizard_save(model, overrides[:cache_index])
  end

  # At the end of the list, adds a row to the list contents of the wizard page object.
  # @see wizard_merge_and_save_on_add_or_delete_row to know more about the parameter variables.
  def list_add_row(list_contents, merge_success, overrides)
    list_contents.push(send(overrides[:new_list_item_instance])) if merge_success
  end

  # Using an index, this deletes a row from the list contents of the wizard page object.
  # @see wizard_merge_and_save_on_add_or_delete_row to know more about the parameter variables.
  def list_delete_row(list_contents, delete_row)
    list_contents.delete_at(delete_row.to_i)
  end

  # Chooses between the model and the sub-object to get the list contents of the list-attribute
  def wizard_list_contents(model, sub_object, overrides)
    (sub_object || model).send(overrides[:list_attribute])
  end
end
