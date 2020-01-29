# frozen_string_literal: true

# Wizard methods concern, for wizard controllers to include.
#
# A Wizard is a multi-page form.  This concern helps us build them by saving the data from the forms in the
# wizard cache (ie Redis, under a certain index that this code manages for you (and saves in the session cookie)).
# Wizard data is kept until it expires or is explicitly cleared, so a user can navigate away and return to a
# wizard (which make back links and saving and restoring data nice and easy).
# The index is based on the controller name, so each controller has it's own wizard cache, and also on the user's
# session, so wizard data is not shared between users.
#
# A simple wizard is one where the data is stored in one model object, where the user visits the pages (aka steps),
# in order, from start to finish.
# A complex wizard is one where the result needs to be copied into some other wizard cache's model at the end and/or
# the pages' order may vary based on user input.
#
# @example including wizard code into a controller
#   include Wizard
#
# @example defining the steps in the wizard (each is a controller action (ie matches controller method & view name))
#    # wizard steps in order; to end a wizard go to the summary page which isn't a wizard_step
#    STEPS = %w[credit_environmental credit_bad_debt credit_site_specific summary].freeze
#
# @example typical simple wizard controller action (ie method) (@see #standard_wizard_step_actions to generate lots)
#    def credit_environmental
#      wizard_step(STEPS)
#    end
#
# The routes file must have an entry for each page/step in the wizard.  Each step needs both a GET and a POST
# entry - ie the wizard_step method organises the form and processes it in the same controller action before
# sending the user to the next page in the wizard.
# This means we have just one place where each step is handled, rather than having two (or more).
# This also means we can easily define validation per step or reorganise the steps as needed without lots of
# refactoring due to coupling between methods.
#
# @example wizard step entry in routes.rb
#   match 'slft/credit_bad_debt',                 to: 'slft#credit_bad_debt',                 via: %i[get post]
#
# Conventions :
#  1) @example view excerpt
#       <%= form_for @your_model, url: @post_path, method: :post, local: true do |f| %>
#     where @your_model and @post_path are set both set up by a common controller method called by the wizard code
#     usually called load_step (the default) or setup_step for the 1st step which will create objects (that way
#     starting a wizard part way through will fail @see #wizard_load_or_redirect).
#     @your_model must be returned from the setup method.
#  2) Prefix all controller actions in a wizard with a common word so its obvious in the controller and routes
#     files which ones are grouped together (ie it's possible to have multiple wizards per controller, so we want an
#     easy way to organise them)
#  3) Define the model's non-sensitive attributes in a list which is then re-used by a controller method to limit
#     the parameters to just those accepted by the model - ie Don't Repeat Yourself (@see SlftController#filter_params)
#     This will mean that all attributes are accepted by all forms, so for sensitive attributes, consider leaving
#     them out of this list  (so user's can't attempt to change data they're not supposed to).
#  4) Give the submit button the name "submitted" so the Wizard code knows to merge and save the data rather than
#     just display the form @example
#        <%= f.button 'next', { :name => 'submitted' }  %>
#  5) Provide two setup methods, setup_step for the first step which will create the model if it doesn't already
#     exist, and load_step which won't create the model, but will load it or else redirect somewhere appropriate
#     if it doesn't exist.  This will help prevent users entering a wizard part way through and encountering errors
#     later on.
#     Put the methods at the bottom of the private section of the controller.
#     Extra setup for specific pages should go in its own setup method unless it's trivial.
#
# Common issues :
#   1) When some behaviour is only needed after submit is pressed, it's tempting to write something that
#      conditionally calls the wizard_step method.  This is against the design since the wizard_step method
#      deals both with and without submit being called (ie does both halves).  Use the after_merge or next_step
#      options as appropriate instead (@see #wizard_step) or even don't use wizard_step at all for that case.
#   2) When some behaviour is only needed on the view part ie before submit is pressed, it's tempting to add it
#      before the wizard_step method.  This means it will run twice.  Consider if you should be using wizard_step
#      or if you should implement a custom version (eg @see SlftSitesWasteController#waste_description)
#   3) "wizard_step is going straight to the submitted part, it never shows my page!"  This happens because the
#      preceding page is wrongly including a button with the name "submitted".  Usually you'll find the preceding
#      page should itself be turned into a wizard step like @see LbttPartiesHelper#about_the_party_next_steps or
#      should use a normal link (GET) rather than a submit (POST).
#   4) "wizard_step(custom_steps_method) doesn't work as #custom_steps_method can't find @variable that is created in
#      load_step".
#      This is because #custom_steps_method is resolved before #wizard_step is called, so you can't rely on anything in
#      the setup method being available.  Instead, use the :next_step override option.
#
# FAQ :
#   @example - Just get the wizard data (hits Redis ie performance hit with each use)
#     @your_model = wizard_load
#
#   @example - Merge data from current wizard into another, parent, wizard
#     @parent_data = wizard_load(OtherController)
#     @parent_data.child = wizard_load
#     wizard_save(@parent_data, OtherController)
#
#   @example - explicitly clearing out wizard data
#     wizard_end # @see Wizard#wizard_end
#
#   @example - conditional navigation (keep in mind the STEPS lists are stateless so can just jump to another one)
#     wizard_step(NORMAL_STEPS) { { next_step: :my_conditional_navigation_method_that_returns_next_step } }
#
module Wizard # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include SessionCacheHandler

  # Performs a step in a simple wizard.
  # There are two halves to a step, the first sets up the model for the view, with the same name as the controller
  # action method, to be called.  The second part validates then stores the submitted parameters in the wizard cache
  # model (provided by the setup method) for later use, and redirects to the next step.  If validation
  # fails then the view is shown again rather than being saved.
  #
  # A yield accepts a hash allowing optional overrides with the following keys :
  # :params -      pointer to method to run to get the parameters to be saved (defaults to #filter_params)
  #                this is normally set to be the filtered list of parameters for the model
  # :cache_index - overrides the cache key used when saving data (defaults to the current controller name)
  #                useful when you want two controllers to work on the same wizard cached data.
  # :after_merge - pointer to method to run after the merge and save has happened (can be used to insert data into
  #                somewhere else on the last step of the wizard for example) - a call to #wizard_save may be needed
  #                in this method if you want to persist the data in the wizard cache.
  # :next_step -   pointer to method [to run after the merge has happened] which returns the next page.  This allows
  #                just-in-time conditional navigation
  # :clear_cache - Clear the wizard cache at _start_ of the first step ie before #overrides[:setup_step] is called.
  #                If 'true', the current wizard cache will be called, if a controller name is provided then that
  #                controller's cache will be cleared.
  #                eg :clear_cache: LbttController will clear the LbttController wizard cache.
  # :setup_step -  Changes the setup method called.  Specify this for the first step in a wizard (eg to point to
  #                :setup_step) or if the step needs custom setup (eg @my_list = complex_setup_just_for_one_step).
  # :validates  -  List of extra validation contexts.  By default submitted params will be validated if a validation
  #                context exists on the model for that name.  This option allows us to add others, eg to provide
  #                page/step/action -based validation eg to check for un-checked check boxes on declaration pages.
  #
  # This method is designed to be pretty much the only thing the controller action calls.  If you find yourself putting
  # it in an if statement, you're probably doing it wrong.
  #
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  def wizard_step(steps)
    # yield allows various items to be overridden
    overrides = block_given? ? yield : {}

    # First half of the step, optionally clear the wizard cache, then finish (so page can display)
    unless params[:submitted]
      wizard_handle_clear_cache(overrides)

      # sets up _AFTER_ allowing cache to be cleared
      wizard_setup_step(overrides)
      return
    end

    # Second half - when step is submitted
    wizard_step_submitted(steps, overrides)
  end

  # Clears the cache iff the overrides[:clear_cache] says so.  @see #wizard_step for more information.
  def wizard_handle_clear_cache(overrides)
    # allow "clear_cache: true"
    overrides[:clear_cache] = self.class.name if overrides[:clear_cache] == true

    wizard_end(overrides[:clear_cache]) if overrides[:clear_cache]
  end

  # Retrieves wizard data from the cache.  Optionally redirects on failure.
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  #        ie if you don't provide a name the current controller will be used.
  #        If you do provide a name it will get that controller's wizard data instead.
  def wizard_load(cache_index = self.class.name)
    session_key = wizard_session_key(cache_index)
    session_cache_data_load(session_key, cache_index)
  end

  # Calls @see #wizard_load but if it fails, redirects to the given URL
  # @param redirect_url [String] the URL to redirect to
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  # @example wizard_load_or_redirect(returns_slft_site_waste_summary_url)
  # @raise WizardRedirectError to stop execution of this action, log it happened and redirect
  def wizard_load_or_redirect(redirect_url, cache_index = self.class.name)
    output = wizard_load(cache_index)
    return output unless output.nil?

    raise Error::WizardRedirectError, redirect_url
  end

  # Assign wizard_params method output to model and save it in the wizard cache.
  # Optionally yields to check validation.  No yield, no validation checks, just saves.  @see #wizard_valid?
  # @param model - the object to save in the wizard cache
  # @param wizard_params - usually the method providing the submitted form data, data will be merged into the model
  # @param after_merge [Symbol] the routine to run if the validation is successful
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  # @return [Boolean] false if validation fails or the after merge fails, else true
  def wizard_merge_and_save(model, wizard_params, after_merge = nil, cache_index = self.class.name)
    # nothing in params is usually a page containing only an un-checked checkbox, so don't attempt merge
    unless wizard_params.nil?
      Rails.logger.debug("  Merging/assigning params #{wizard_params}")
      # errors on this line usually mean the parameter doesn't match a model attribute or incorrect filter_params
      model.assign_attributes(wizard_params)
    end

    # check validation via yield
    valid = yield(model, wizard_params)
    Rails.logger.debug "  Validation overall result is #{valid}"

    # custom method to run after successful merge and save
    valid = send(after_merge) if after_merge && valid
    Rails.logger.debug "  After merge call to #{after_merge} failed with #{valid.inspect}" unless valid

    wizard_save(model, cache_index) if valid
    valid
  end

  # Validate the model based on the submitted parameters.
  # Builds up a list of validation contexts based on the parameters, so if you want validation for an attribute,
  # define it in the model with a validation context with the same name as the attribute.
  # @example validation in model
  #   validates :year, presence: true, on: :year
  #
  # This allows the validation to be run based on what's submitted (ie submitted for that wizard step) without us ever
  # having to specify or update the relationship between wizard step and validation.
  # @param model - the model to validate
  # @param wizard_params - params submitted eg on a form the keys of which will be the validation contexts to check
  # @param overrides - checks for the validates option to add contexts @see #wizard_step for more details
  # @return [Boolean] true if valid else false
  def wizard_valid?(model, wizard_params, overrides)
    # check it's not empty
    wizard_params ||= {}

    # extract validation contexts from the keys
    validation_contexts = add_validation_contexts(wizard_params.keys.map(&:to_sym), overrides)

    # do validation
    output = model.valid?(validation_contexts)
    Rails.logger.debug "  Validation for #{validation_contexts} is #{output}"
    output
  end

  # _Overwrite_ the wizard cache object.  Use with caution.
  # @param master_object - the object to store in the cache
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  def wizard_save(master_object, cache_index = self.class.name)
    # allow blank to be passed as argument for cache_index but still use default in that case
    cache_index = self.class.name if cache_index.nil?
    session_key = wizard_session_key(cache_index)
    session_cache_data_save(master_object, session_key, cache_index)
  end

  # Cleans up wizard cache and session at the end to delete it/free up resources.
  # Fails safe, won't throw exceptions if the deletion is unsuccessful due to a StandardError.
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  def wizard_end(cache_index = self.class.name)
    session_key = wizard_session_key(cache_index)
    clear_session_cache(session_key, cache_index)
  end

  # When the wizard form should submit to the same action that created it, returns the action attribute.
  # If you find this does not return the right value, check if you've got your namespaces and routing correct.
  # @param [String] controller_name optional override to provide path based on another controller (defaults to self)
  # @return [String] the url for the form's post action, calculated from the wizard controller class and current action
  def wizard_post_path(controller_name = self.class.name)
    controller_name.underscore.tr!('/', '_').sub('controller', action_name).to_sym
  end

  # Methods added to the including class as self.<method> which is the context that #standard_wizard_step_actions
  # is run in. See https://stackoverflow.com/questions/33326257/what-does-class-methods-do-in-concerns for more info.
  class_methods do
    # Dynamically creates multiple typical simple wizard_step controller actions (ie methods) to save copying and
    # pasting.  @example Output looks like :
    #   def <action name>
    #     wizard_step(<steps_list>)
    #   end
    #
    # If you want a custom version of this method, copy it and add "self." to the method signature
    # or copy it including the class_methods section into another concern.
    # @param steps_list [Array] the STEPS list to use for the generated wizard_step method
    # @param actions_list [Array] symbol list of action (method) names to generate
    # @param overrides [Hash] the overrides to set, defaults to  if nothing is set
    def standard_wizard_step_actions(steps_list, actions_list, overrides = {})
      actions_list.each do |action|
        define_method(action) do
          wizard_step(steps_list) { overrides }
        end
      end
    end
  end

  # Given a list of steps, finds the current action in the list and returns the next one.
  # @param steps_list [Array] list of STEPS.
  # @return [String] the next step
  def next_step_in_list(steps_list)
    current_step = steps_list.index(action_name)
    raise Error::AppError.new('Wizard', "Missing step #{action_name} in steps list #{steps_list}") if current_step.nil?

    steps_list[current_step + 1]
  end

  private

  # Aids code re-use by calling the right setup_step method to return the model.
  # By default, calls load_step to load the model but can be overriden by providing the :setup_step override
  # to create objects for the first step or do a custom step setup.
  # @param overrides [Hash] @see #wizard_step
  # @return the wizard cache model returned by the setup step method called
  def wizard_setup_step(overrides)
    overrides.key?(:setup_step) ? send(overrides[:setup_step]) : load_step
  end

  # The second half of wizard_step, separated out because it's getting too big. Manages merging, validation and saving.
  # Calls wizard_setup_step to get the model we're working on.
  # @see #wizard_step for more details.
  # @param steps [List] @see #wizard_step
  # @param overrides [Hash] @see #wizard_step
  def wizard_step_submitted(steps, overrides = {})
    model = wizard_setup_step(overrides)

    # get the parameters submitted
    wizard_params = resolve_params(overrides)

    # add submitted params to the cached object and save if validation passes
    # if validation fails then returns without doing the navigation
    return unless wizard_merge_and_save(model, wizard_params, overrides[:after_merge], overrides[:cache_index]) do
      # validate model (@note this is a block called by #wizard_merge_and_save)
      wizard_valid?(model, wizard_params, overrides)
    end

    # redirect to the next step unless there were errors added by the after_merge section
    # if the merge fails then we would have returned above
    # (in which case we fall out the bottom of the wizard process to re-display the current view)
    wizard_navigation_step(steps, overrides) unless model.errors.any?
  end

  # Adds any additional contexts from the overrides onto the passed validation context
  #
  # @param validation_contexts - the existing validation contexts which may be added to
  # @param overrides - checks for the :validates option to add contexts @see #wizard_step for more details
  # @return [Array] - The revised list of validation contexts
  def add_validation_contexts(validation_contexts, overrides)
    new_validation_contexts = validation_contexts
    # add optional extra validation contexts
    if overrides.key?(:validates)
      validations = overrides[:validates]

      # turn it into an array if it's not already
      validations = [validations] unless validations.is_a? Array

      # add to the list of validation contexts
      validations.each { |v| new_validation_contexts << v }
    end

    new_validation_contexts
  end

  # Gets the parameters submitted by calling the override[:params] method if exists
  # or else assumes a method filter_params exists and defaults to that.
  def resolve_params(overrides)
    return send(overrides[:params]) if overrides.key?(:params)

    filter_params
  end

  # Decides what the next step is and redirects to that page.
  # @see #wizard_step and the :next_step optional override
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @see http://localhost:3000/rails/info/routes but consider if it'd be better todo something like :
  #      ['current_action', STEPS.first] which is another option.
  def wizard_navigation_step(steps, overrides)
    # custom method to run which sets the next_step override
    steps = send(overrides[:next_step]) if overrides[:next_step]

    # normal case - find next step in list and redirect to that action (on current controller)
    if steps.is_a?(Array)
      calculated_next_step = next_step_in_list(steps)
      Rails.logger.debug "Redirecting to next step/action: #{calculated_next_step}"
      redirect_to action: calculated_next_step
      return
    end

    # redirect to a specific path eg returns_slft_declaration_repayment_path
    calculated_next_step = steps
    Rails.logger.debug "Redirecting to specific location: #{calculated_next_step}"
    redirect_to calculated_next_step
  end

  # Provides the key to access this wizard's cache key in the user's _session_ [cookie] (@see #wizard_cache_key).
  # @param cache_index [String] the identifier for the cache index
  def wizard_session_key(cache_index)
    "WIZARD_#{cache_index}"
  end

  # Provides the wizard cache key for the relevant controller and user.
  #
  # Gets the cache key from the session [cookie]. Creates it in the session if it doesn't already exist.
  #
  # The cache key will contain a UUID so that each persons' wizard entries are unique.
  #
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  # @return [String] the wizard cache key
  def wizard_cache_key(cache_index)
    session_key = wizard_session_key(cache_index)
    session_cache_key(cache_index, session_key)
  end

  # How long the wizard data will last for if @see #wizard_end isn't called.
  # @return the session max lifetime from system parameters or 10.hours if that doesn't exist for some reason
  def wizard_cache_expiry_time
    session_cache_data_expiry_time
  end
end
