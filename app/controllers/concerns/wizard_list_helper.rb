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
# @example @lbtt_return.ads_relief_claims ||= Array.new(3) { Lbtt::ReliefClaim.new }
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
#              {:class => 'scot-rev-button_link manual_link govuk-details__summary-text', :name => 'add_row'} %>
#  Controller change
#  wizard_list_step(nil, params: :filter_params,
#                        next_step: :calculate_next_step, cache_index: LbttController,
#                        merge_list: :merge_linked_transactions, add_row_handler: :add_linked_transactions_row)
module WizardListHelper
  extend ActiveSupport::Concern

  # Edge-case wizard-step to merge data as normal in a model but also merge in a list of another class.
  # Requires implementing classes have a setup_step method which returns the model (ie normal Wizard stuff).
  #
  # You need to override "add_row_handler" to handle add row functionality on page.
  # and override "delete_row_handler" to handle delete row functionality on page.
  # Limitations - at present, only validation contexts gleaned from filter_params can be used.  That usually
  # won't include your list!  (But it will include anything else on your form, eg a yes-no radio button.)
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param overrides [Hash] @see Wizard#wizard_step
  def wizard_list_step(steps, overrides)
    # first half
    model = setup_step

    handle_add_delete_rows(overrides)

    return unless params[:submitted]

    handle_submit_method(steps, model, overrides)
  end

  private

  # Method handle sequence of action after submittion
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param overrides [Hash] @see Wizard#wizard_step
  def handle_submit_method(steps, model, overrides)
    # second half
    # merge normal fields - won't include the list (ignore message saying they're unpermitted)
    wizard_params = resolve_params(overrides)
    model.assign_attributes(wizard_params)

    # call the override method to merge the list _before_ validate & save
    send(overrides[:merge_list]) if overrides[:merge_list]

    # validate and save if valid
    wizard_save(model, overrides[:cache_index]) if wizard_valid?(model, wizard_params)

    # custom method to run after successful merge
    send(overrides[:after_merge]) if overrides[:after_merge]

    # navigate to the next page if validation passed
    wizard_navigation_step(steps, overrides) unless model.errors.any?
  end

  # Adds or removes a row when the user presses the add or delete button
  # Implmenting classes need to have an :add_row_handler and a :delete_row_handler method specified in the overrides.
  # @param overrides [Hash] @see Wizard#wizard_step
  def handle_add_delete_rows(overrides)
    # handle add row functionality of array object
    send(overrides[:add_row_handler]) if overrides[:add_row_handler] && params[:add_row]

    # handle delete row functionality of array object
    send(overrides[:delete_row_handler], params[:delete_row].to_i) if overrides[:delete_row_handler] &&
                                                                      params[:delete_row]
  end
end
