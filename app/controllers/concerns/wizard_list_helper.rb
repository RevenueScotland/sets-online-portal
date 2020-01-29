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
  # @param overrides [Hash] @see Wizard#wizard_step
  def wizard_list_step(steps, overrides)
    # first half
    wizard_handle_clear_cache(overrides)
    model = wizard_setup_step(overrides)

    # Handle the main model to make sure it is up to date
    wizard_params = resolve_params(overrides)
    model.assign_attributes(wizard_params) unless wizard_params.nil?
    return unless wizard_valid?(model, wizard_params, overrides)

    handle_add_delete_rows(overrides)

    return unless params[:submitted]

    handle_submit_method(steps, model, overrides)
  end

  private

  # Method handle sequence of action after submitting
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param overrides [Hash] @see Wizard#wizard_step
  def handle_submit_method(steps, model, overrides)
    # merges in the child object and validates it
    # The merge list procedure returns true or false if it fails e.g. validation error
    # at which point return and don't move off the page
    # The below is saying if there is an override call it and then if it fails exit this routine
    return if overrides[:merge_list] && !send(overrides[:merge_list])

    success = run_after_merge(overrides)

    # if the after merge fails then also stay on the page and don't save
    return if model.errors.any? || success == false

    wizard_save(model, overrides[:cache_index])
    wizard_navigation_step(steps, overrides)
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

  # Adds or removes a row when the user presses the add or delete button
  # Implementing classes need to have an :add_row_handler and a :delete_row_handler method specified in the overrides.
  # @param overrides [Hash] @see Wizard#wizard_step
  def handle_add_delete_rows(overrides)
    # handle add row functionality of array object
    send(overrides[:add_row_handler]) if overrides[:add_row_handler] && params[:add_row]

    # handle delete row functionality of array object
    send(overrides[:delete_row_handler], params[:delete_row].to_i) if overrides[:delete_row_handler] &&
                                                                      params[:delete_row]
  end
end
