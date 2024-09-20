# frozen_string_literal: true

# Wizard methods concern, for wizard controllers to include.
#
# A Wizard is a multi-page form.  This concern helps us build them by saving the data from the forms in the
# wizard cache (ie Redis, under a certain index that this code manages for you (and saves in the session cookie)).
# Wizard data is kept until it expires or is explicitly cleared, so a user can navigate away and return to a
# wizard (which make back links and saving and restoring data nice and easy).
# The index is based on the controller name, so each controller has it's own wizard cache, and also on the user's
# session, so wizard data is not shared between users.
# Note: This does mean that each session can only have on instance of a wizard open at a time (i.e. I can't create
# two lbtt_returns at the same time, the code is not tab safe)
#
# A simple wizard is one where the data is stored in one object, where the user visits the pages (aka steps),
# in order, from start to finish.
# A complex wizard is one where the result needs to be copied into some other wizard object at the end and/or
# the pages' order may vary based on user input or you have a nested object within a parent object
#
# Although this is transparent when you using this method conceptually this code deals with two objects
# The cached object is the object that is stored in the cache
# The page object is the object that is being edited on the page, this may be the same as the cached object
# or if the :sub_object_attribute is provided a sub object of the main object
#
# There are also specialist wizard steps where the page does an address search, a company search or maintains
# a table of date @see WizardAddressHelper @see WizardCompanySearch @see WizardListHelper
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
#    resource :slft, controller: :slft
#      member do
#        get 'public_landing'
#        post 'public_landing'
#
# Conventions :
#  1) @example view excerpt
#       <%= old_form_for @your_object, url: @post_path, method: :post, local: true do |f| %>
#     where @your_object and @post_path are set both set up by a common controller method called by the wizard code
#     usually called load_step (the default) or setup_step for the 1st step which will create objects (that way
#     starting a wizard part way through will fail @see #wizard_load_or_redirect).
#     @your_object must be returned from the setup method and load method
#     For a more complex situation you may end up returning the chain of objects from the parent cached object
#     down to the actual object on the page
#  2) Prefix all controller actions in a wizard with a common word so its obvious in the controller and routes
#     files which ones are grouped together (ie it's possible to have multiple wizards per controller, so we want an
#     easy way to organise them)
#  3) Define the object's non-sensitive attributes in a list which is then re-used by a controller method to limit
#     the parameters to just those accepted by the object - ie Don't Repeat Yourself (@see SlftController#filter_params)
#     This will mean that all attributes are accepted by all forms, so for sensitive attributes, consider leaving
#     them out of this list  (so user's can't attempt to change data they're not supposed to).
#  4) Give the submit button the name "continue" so the Wizard code knows to merge and save the data rather than
#     just display the form @example.
#        <%= f.button 'continue', { :name => 'continue' }  %>
#      this is the default so the below works
#        <%= f.button %>
#  5) Provide two setup methods, setup_step for the first step which will create the object if it doesn't already
#     exist, and load_step which won't create the object, but will load the object (or objects) or else redirect
#     somewhere appropriate if it doesn't exist.  This will help prevent users entering a wizard part way through
#     and encountering errors later on.
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
#      preceding page is wrongly including a button with the name "continue".  Usually you'll find the preceding
#      page should itself be turned into a wizard step like @see LbttPartiesHelper#about_the_party_next_steps or
#      should use a normal link (GET) rather than a submit (POST).
#   4) "wizard_step(custom_steps_method) doesn't work as #custom_steps_method can't find @variable that is created in
#      load_step".
#      This is because #custom_steps_method is resolved before #wizard_step is called, so you can't rely on anything in
#      the setup method being available.  Instead, use the :next_step override option.
#
# FAQ :
#   @example - Just get the wizard data (hits Redis ie performance hit with each use)
#     @your_object = wizard_load
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
  # There are two halves to a step, the first sets up the page object for the view, with the same name as the controller
  # action method, to be called.  The second part validates then stores the submitted parameters in the wizard cache
  # object (provided by the setup method) for later use, and redirects to the next step.  If validation
  # fails then the view is shown again rather than being saved.
  #
  # A yield accepts a hash allowing optional overrides with the following keys :
  # :params -      pointer to method to run to get the parameters to be saved (defaults to #filter_params)
  #                this is normally set to be the filtered list of parameters for the object
  # :cache_index - overrides the cache key used when saving data (defaults to the current controller name)
  #                useful when you want two controllers to work on the same wizard cached data.
  # :after_merge - pointer to method to run after the merge and save has happened (can be used to insert data into
  #                somewhere else on the last step of the wizard for example) Any data in the main object is saved
  #                following this step. If you want to take the current wizard object and add it into a parent object
  #                then you will need to load and save the parent object e.g. when merging a party back to the main
  #                return object
  #                NOTE: The method found from this needs to return a boolean value true if validation passes, but
  #                false if it fails.
  # :next_step -   pointer to method [to run after the merge has happened] which returns the next page.  This allows
  #                just-in-time conditional navigation
  # :clear_cache - Clear the wizard cache at _start_ of the first step ie before #overrides[:setup_step] is called.
  #                If 'true', the current wizard cache will be called, if a controller name is provided then that
  #                controller's cache will be cleared.
  #                eg :clear_cache: LbttController will clear the LbttController wizard cache.
  # :setup_step -  Changes the setup method called.  Specify this for the first step in a wizard (eg to point to
  #                :setup_step) or if the step needs custom setup (eg @my_list = complex_setup_just_for_one_step).
  # :validates  -  List of extra validation contexts.  By default submitted params will be validated if a validation
  #                context exists on the object for that name.  This option allows us to add others, eg to provide
  #                page/step/action -based validation eg to check for un-checked check boxes on declaration pages.
  # :does_not_validate  -  List of extra validation contexts that are not validated on this step.
  #                This allows us to remove fields that we don't want to validate on this page to avoid the user
  #                getting in trap by the validation.
  # :loop       -  this is used for wizard page(s) that needs to loop around a (set of) page(s).
  #                If you are using the loop functionality then the route must end with /(:sub_object_index)
  #                There are three specific values it only accepts
  #                1. :start_next_step - putting this on a wizard page means that the next page it goes to is the
  #                                      start of the looping/indexing feature for the wizard pages.
  #                2. :continue - this must be added if the page is either the first page or any page in between
  #                               the first and last page of the loop. This means that the current page is part of
  #                               wizard page.
  #                3. :<page-name> - this should be added to the last page of the looping/indexing feature, as this
  #                                  means that it will go back to that page to loop around when there's still more
  #                                  objects in the list.
  # :sub_object_attribute - this contains the attribute(s) in the object where the sub-object(s) is/are stored.
  #                The attributes must be symbols. The contents can be an array of sub-objects.
  #                This is used to extract and save objects
  #
  # This method is designed to be pretty much the only thing the controller action calls.  If you find yourself putting
  # it in an if statement, you're probably doing it wrong.
  #
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  def wizard_step(steps)
    # yield allows various items to be overridden
    overrides = block_given? ? yield : {}

    # First half of the step, optionally clear the wizard cache, then finish (so page can display)
    if request.get?
      wizard_handle_clear_cache(overrides)

      # sets up _AFTER_ allowing cache to be cleared
      wizard_setup_step(overrides)
      return
    end

    # Second half - when step is submitted
    return if wizard_step_submitted(steps, overrides)

    render(status: :unprocessable_entity)
  end

  # Clears the cache and ends the wizard as per the overrides
  # @see #wizard_step for more information.
  # @param overrides [Hash] the keys used in this method :
  #   - :clear_cache to indicate that cache should be cleared
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
    cached_object = session_cache_data_load(session_key, cache_index)
    return if cached_object.nil?

    # it is possible that the object was saved with errors
    # normally we should not save an object with errors but in the event of a submit error we
    # need to clear the submitted flag and save the object and this will have errors
    # Note we can't clear when we save as that clears the errors before we show them to the user
    cached_object.errors.clear
    cached_object
  end

  # Calls @see #wizard_load and if it fails, redirects to the given URL
  # This will return either one object (the cached object), or if :sub_object_attribute is provided in the overrides,
  # it will return an array of nested sub objects in the cached object in the order given by the sub object attributes
  # Note that the order given in the sub_object_attributes must be in the correct nesting order
  # i.e. cached_object->sub_object->sub_sub_object etc
  # You can disregard those objects returned that aren't needed on the page (you may only need the last sub object)
  # @param redirect_url [String] the URL to redirect to
  # @param sub_object_attribute [Symbol|Array] A single symbol or an array of symbols
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  # @return [Object|Array] The object or array of nested objects
  # @example wizard_load_or_redirect(returns_slft_site_waste_summary_url)
  # @raise WizardRedirectError to stop execution of this action, log it happened and redirect
  def wizard_load_or_redirect(redirect_url, sub_object_attribute = nil, cache_index = self.class.name)
    wizard_cached_object = wizard_load(cache_index)
    raise Error::WizardRedirectError, redirect_url if wizard_cached_object.nil?

    # if there are no sub object attributes the calling code is just expecting a single object
    return wizard_cached_object if sub_object_attribute.nil?

    # We pass down the sub object_override as an override to this routine
    wizard_all_objects_array(wizard_cached_object, { sub_object_attribute: sub_object_attribute })
  end

  # Assign wizard_params method output to a page object and save it in the wizard cache.
  # Optionally yields to check validation.  No yield, no validation checks, just saves.  @see #wizard_valid?
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param wizard_params [Hash] The method providing the submitted form data which will be merged into the page object
  # @param overrides [Hash] the keys used in this method and it's child-methods:
  #   - :after_merge [Symbol] the routine to run if the validation is successful
  #   - :cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  #   - :loop [Symbol] used for determining if the params should be assigned to the sub-object
  #   - :sub_object_attribute [Symbol] this is the attribute(s) of the cached object which contains the sub-object
  # @return [Boolean] false if validation fails or the after merge fails, else true
  def wizard_merge_and_save(wizard_cached_object, wizard_page_object, wizard_params, overrides = {})
    merge_params_with_object(wizard_page_object, wizard_params)

    # check validation via yield
    valid = yield(wizard_page_object, wizard_params)

    valid = save_cached_object_to_cache(wizard_cached_object, overrides) if valid
    valid
  end

  # Merges the wizard params with the object in the wizard page
  # @note The wizard page object is actually a pointer to the object within the cached object. So updating it
  #  will also update the cached object 'version'
  def merge_params_with_object(wizard_page_object, wizard_params)
    # nothing in params is usually a page containing only an un-checked check box, so don't attempt merge
    return if wizard_params.nil?

    Rails.logger.debug { "  Merging/assigning params #{wizard_params}" }
    # errors on this line usually mean the parameter doesn't match an object attribute or incorrect filter_params
    wizard_page_object.assign_attributes(wizard_params)
  end

  # Validate the cached and page object based on the linking attributes and the submitted parameters.
  # Note that as per standard load processing the page object is the last object extracted from the cached object
  #
  # The list of validation contexts based on the parameters and the linking attribute, so if you want
  # validation for an attribute, define it in the class with a validation context with the same name as the attribute.
  # @example validation in class
  #   validates :year, presence: true, on: :year
  #
  # This allows the validation to be run based on what's submitted (ie submitted for that wizard step) without us ever
  # having to specify or update the relationship between wizard step and validation.
  # @param wizard_cached_object [Object] the object to validate
  # @param wizard_params [Hash] params submitted eg on a form the keys of which will be the validation contexts to check
  # @param overrides [Hash] the keys used in this method and it's child-methods:
  #   - :validates [Symbol] extra validation contexts to be used
  #   - :does_not_validate [Symbol] List of extra validation contexts that are not validated on this step.
  #   - :sub_object_attribute [Symbol] this is the attribute(s) of the cached object which contains the sub-object
  # @return [Boolean] true if valid else false
  def wizard_valid?(wizard_cached_object, wizard_params, overrides)
    # Set up the values for validation
    all_objects = wizard_all_objects_array(wizard_cached_object, overrides)
    sub_object_attributes = wizard_sub_object_attributes(overrides)
    page_object_contexts = add_validation_contexts((wizard_params || {}).keys.map(&:to_sym), overrides)
    valid = true

    # Do validation prior to the page object
    # at this stage all objects is [cached_object sub_object(*) page_object]
    # attributes is [sub_object_attribute(*) page_object_attribute]
    all_objects.each_with_index do |o, i|
      validation_context = (i < sub_object_attributes.size ? sub_object_attributes[i] : page_object_contexts)
      valid &&= o.valid?(validation_context)
      Rails.logger.debug { "  Validation for #{validation_context} valid is now #{valid}" }
    end

    valid
  end

  # _Overwrite_ the wizard cache object.  Use with caution.
  # @param wizard_cached_object - the object to store in the cache
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  def wizard_save(wizard_cached_object, cache_index = self.class.name)
    # allow blank to be passed as argument for cache_index but still use default in that case
    cache_index = self.class.name if cache_index.nil?
    session_key = wizard_session_key(cache_index)
    session_cache_data_save(wizard_cached_object, session_key, cache_index)
  end

  # Cleans up wizard cache and session at the end to delete it/free up resources.
  # Fails safe, won't throw exceptions if the deletion is unsuccessful due to a StandardError.
  # @param cache_index [String] the identifier for the cache index, defaults to the class name (the controller)
  def wizard_end(cache_index = self.class.name)
    session_key = wizard_session_key(cache_index)
    clear_session_cache(session_key, cache_index)
  end

  # This returns the path to be used for posting the response to a wizard page.
  # This is basically the same as the URL for the current page
  # @return [String] the url for the form's post action
  def wizard_post_path
    request.path
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

  # Gets all levels of sub-objects. This also handles where the sub object is an array, the individual item in the array
  # is extracted. This uses index which are passed on the parameters and are totally handled within the wizard code
  # @param wizard_cached_object [Object] The object of the wizard.
  # @param overrides [Hash] the overrides from the wizard step
  #  - :sub_object_attribute [Symbol|Array] A single symbol or an array of symbols for the attributes for the sub object
  # @example wizard_all_objects_array(<LbttReturn...>, { sub_object_attribute: [buyers company] }) will return
  #   [<LbttReturn>, <Party>, <Company>]
  # @return [Array] the cached object and all the levels of the sub-objects, ordered from cached object to
  #   the lowest level sub-object).
  def wizard_all_objects_array(wizard_cached_object, overrides)
    all_objects = [wizard_cached_object]
    sub_object_attributes = wizard_sub_object_attributes(overrides)
    return all_objects if sub_object_attributes.blank?

    sub_object_attributes.each do |a|
      # Depending on the contents in the attribute, this could be an array of objects or just a single object
      objects_from_attribute = all_objects.last.send(a)
      # extract the sub object from the array if it is an array, we need to know if is the last attribute as that uses
      # the standard name for the index parameter name
      all_objects << extracted_sub_object(objects_from_attribute, sub_object_attributes.last == a)
    end
    all_objects
  end

  # Extracts the sub-object from the parent object attribute.
  # @param sub_objects [Object|Array] the contents of the attribute of the parent
  # @param last_attribute [Boolean] is the method being used on the last attribute within
  #   the attributes list?
  # @return [Object] the sub-object extracted from it's parent
  def extracted_sub_object(sub_objects, last_attribute)
    return sub_objects unless sub_objects.is_a?(Array)

    # On the last attribute wizard page index uses the default name, so don't pass down the class name
    class_name = sub_objects.first.class.name unless last_attribute
    index = wizard_object_index(class_name)

    sub_objects[index - 1]
  end

  # Aids code re-use by calling the right setup_step method to return the objects.
  # By default, calls load_step to load the objects but can be overridden by providing the :setup_step override
  # to create objects for the first step or do a custom step setup.
  # The load step/setup step provided may return one object or an array of objects if we are dealing with nested objects
  # this routine always returns two objects, the root cached object and the object on the page. These may be the same
  # The object on the page is always the lowest object sub_object_attribute list for this page
  # @param overrides [Hash] the keys used in this method and it's child-methods:
  #   - :setup_step [Symbol] The method to call to do the setup of the objects
  #   - :sub_object_attribute [Symbol] this is the attribute(s) of the cached object which contains the sub-object
  # @return [Array] The cached object and the page object.
  def wizard_setup_step(overrides)
    # This may return an array of the cached object and all sub-objects, or just the cached object.
    objects_from_setup = if overrides.key?(:setup_step)
                           send(overrides[:setup_step])
                         else
                           load_step(overrides[:sub_object_attribute])
                         end

    return [objects_from_setup.first, objects_from_setup.last] if objects_from_setup.is_a? Array

    # This is the standard scenario where we only have one object
    # This is actually returning two pointers to the same object, so in the calling routine changing
    # attributes on one changes both
    [objects_from_setup, objects_from_setup]
  end

  # The second half of wizard_step, separated out because it's getting too big. Manages merging, validation and saving.
  # Calls wizard_setup_step to get the objects we're working on.
  # @see #wizard_step for more details.
  # @param steps [List] @see #wizard_step
  # @param overrides [Hash] @see #wizard_step
  # @return [Boolean] true if the submission was successful
  def wizard_step_submitted(steps, overrides = {})
    wizard_cached_object, wizard_page_object = wizard_setup_step(overrides)

    # get the parameters submitted
    wizard_params = resolve_params(overrides)

    # add submitted params to the cached object and save if validation passes
    # if validation fails then returns without doing the navigation
    # # overrides[:after_merge], overrides[:cache_index]) do
    return false unless wizard_merge_and_save(wizard_cached_object, wizard_page_object, wizard_params, overrides) do
      # validate object (@note this is a block called by #wizard_merge_and_save)
      wizard_valid?(wizard_cached_object, wizard_params, overrides)
    end

    # We want to know if there is a collection of sub-objects that the page is traversing through.
    sub_object_size = wizard_page_objects_size(wizard_cached_object, overrides)

    # redirect to the next step unless there were errors added by the after_merge section
    # if the merge fails then we would have returned above
    # (in which case we fall out the bottom of the wizard process to re-display the current view)
    return false if wizard_page_object.errors.any?

    wizard_navigation_step(steps, overrides, sub_object_size)
  end

  # Counts the total size of the collection of sub-objects in the cached object, if the found collection turns out
  # to not be a collection, then it will return nil.
  # @see wizard_step_submitted as this is only to be used in that method.
  # @param wizard_cached_object [Object] The object of the wizard.
  # @param overrides [Hash] the overrides from the wizard step
  #    :sub_object_attribute [Symbol|Array] A single symbol or an array of symbols for the attributes for the sub object
  # @return [Integer|nil] Total size or nil if cached objects contents doesn't contain a collection.
  def wizard_page_objects_size(wizard_cached_object, overrides)
    sub_object_attributes = wizard_sub_object_attributes(overrides)
    return if sub_object_attributes.blank?

    all_objects = wizard_all_objects_array(wizard_cached_object, overrides)
    # As we are trying to get the list of sub-objects and not a specific one, we'll get it by looking at the
    # second last object and look at it's contents.
    collection_or_sub_object = all_objects[-2].send(sub_object_attributes.last)
    return unless collection_or_sub_object.is_a?(Array)

    collection_or_sub_object.size
  end

  # Runs the after merge method (if needed) and if that is successful saves the object to the cache
  # @see wizard_merge_and_save as this should only be used there, and this is done to split up the method.
  # @param wizard_cached_object [Object] The object of the wizard.
  # @param overrides [Hash] the overrides from the wizard step
  #    :after_merge [Symbol|Array] A pointer to the after merge method to run
  #    :cache_index [Symbol] The index to use to save the object
  # @return [Boolean] false if the after merge failed.
  def save_cached_object_to_cache(wizard_cached_object, overrides)
    after_merge = overrides[:after_merge]

    # custom method to run after successful merge and save
    valid = true
    valid = send(after_merge) if after_merge
    Rails.logger.debug { "  After merge call to #{after_merge} failed with #{valid.inspect}" } unless valid

    wizard_save(wizard_cached_object, overrides[:cache_index] || self.class.name) if valid
    valid
  end

  # Adds or removes any additional contexts from the overrides onto the passed validation context
  #
  # @param validation_contexts - the existing validation contexts which may be added to
  # @param overrides - checks for the :validates option to add contexts @see #wizard_step for more details
  #                  - checks for the :does_not_validate option to remove specific contexts
  # @return [Array] - The revised list of validation contexts
  def add_validation_contexts(validation_contexts, overrides)
    new_validation_contexts = validation_contexts
    # add optional extra validation contexts
    if overrides.key?(:validates)
      # add to the list of validation contexts
      new_validation_contexts += Array(overrides[:validates])
    end

    # remove optional extra validation contexts
    if overrides.key?(:does_not_validate)
      # delete from the list of validation contexts
      new_validation_contexts -= Array(overrides[:does_not_validate])
    end

    new_validation_contexts
  end

  # Gets the parameters submitted by calling the override[:params] method if exists
  # or else assumes a method filter_params exists and defaults to that.
  def resolve_params(overrides)
    return send(overrides[:params]) if overrides.key?(:params)

    filter_params(overrides[:sub_object_attribute])
  end

  # Decides what the next step is and redirects to that page.
  # @see #wizard_step and the :next_step optional override
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param overrides [Hash] contains the instruction to do the loop feature or overriding of the next_step
  #   - :loop [Symbol] mainly used for calculating the sub_object_index to be used for loading the new page
  #   - :next_step [Symbol|String] used for overriding the next step.
  # @param total_objects [Integer|nil] defaults to nil but may also contain nil. This is used for a type of wizard
  #   pages that has the feature to loop back to a starting page, it is used to determine if the looping cycle
  #   should continue or break.
  # @return [Boolean] true if the navigation is redirected
  # @see http://localhost:3000/rails/info/routes but consider if it'd be better todo something like :
  #      ['current_action', STEPS.first] which is another option.
  def wizard_navigation_step(steps, overrides, total_objects = nil)
    loop_instruction = overrides[:loop]
    # custom method to run which sets the next_step override
    steps = wizard_navigation_override_next_step(loop_instruction, overrides[:next_step]) || steps

    # normal case - find next step in list and redirect to that action (on current controller)
    if steps.is_a?(Array)
      # @see wizard_object_index to know how the :sub_object_index is being taken
      return wizard_navigation_from_list_next_step(steps, loop_instruction, wizard_object_index, total_objects)
    end

    # redirect to a specific path eg returns_slft_declaration_repayment_path
    calculated_next_step = steps
    Rails.logger.debug { "Redirecting to specific location: #{calculated_next_step}" }
    redirect_to calculated_next_step
    true
  end

  # Creates the next step according to the override value found in the next_step.
  # @see wizard_navigation_step as it should only be used there.
  def wizard_navigation_override_next_step(loop_instruction, next_step)
    return if next_step.nil?

    next_step = send(next_step)

    # Normally the next_step is the already-built path, however, when using it with the loop feature then
    # that path should be the symbol version of it. So that the index can be passed.
    if loop_instruction == :start_next_step && !next_step.is_a?(Array) && respond_to?(next_step)
      return send(next_step, 1)
    end

    next_step
  end

  # Navigates the wizard to redirect to a page by looking at the array of steps and figuring out which would the
  # next step be. This may also add an index according to the loop_instruction.
  # @return [Boolean] true if the navigation is redirected
  def wizard_navigation_from_list_next_step(steps, loop_instruction, current_index, total_objects)
    calculated_next_step = next_step_in_list(steps)
    action, index = build_action_and_index(calculated_next_step, loop_instruction, current_index, total_objects)
    # Next step with index, or the normal next step
    Rails.logger.debug { "Redirecting to next step/action: #{calculated_next_step} #{action} #{index}}" }
    index.present? ? redirect_to(action: action, sub_object_index: index) : redirect_to(action: action)
    true
  end

  # Builds the action and index for the next step, which is only used for the array of steps.
  # @see wizard_navigation_from_list_next_step as it should only be used there.
  # @return [Array] of two items which should be a String for the action and an Integer (or nil) for the index.
  def build_action_and_index(action, loop_instruction, current_index, total_objects)
    # index is related to the sub_object_index
    index = nil
    if loop_instruction.present?
      # If :continue is found in the loop_instruction, this means that we're on a page in between the start and last
      # A page with loop_instruction of :start_next_step means that the next page is the start of the looping
      # (indexing) wizard pages.
      index = { start_next_step: 1, continue: current_index }[loop_instruction]
      # Having no index with a loop_instruction present means that we're looping back to the start page
      if index.nil? && current_index < total_objects
        index = current_index + 1
        action = loop_instruction.to_s
      end
    end
    [action, index]
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

  # Where we are traversing an array on objects in an object. This returns the current index of the object from the
  # parameters
  # The default name of the index is sub_object_index which is always used for the last subject in the chain
  # (or if there is only one sub object in the chain). For other indexes it is based on the class name
  # This routine is also used for when calculating the index for the next page.
  # @param class_name [String] Class name of an object (<Object>.class.name), if this is the last object
  #   in the chain MUST be passed as nil
  # @return [Integer] The sub_object_index from the page. The sub_object_index starts the count
  #   from 1, so to use it on arrays don't forget to -1 it.
  def wizard_object_index(class_name = nil)
    key = :sub_object_index
    key = "#{class_name.demodulize.singularize.underscore}_#{key}".to_sym unless class_name.nil?
    return if params[key].nil?

    params[key].to_i
  end

  # Returns the array of sub object attributes from the override parameter, handling that it may be a single value
  # or an array. It always returns an array
  # @param overrides [Hash] the overrides from the wizard step
  #    :sub_object_attribute [Symbol|Array] A single symbol or an array of symbols for the attributes for the sub object
  # @return [Array] an array of symbols
  def wizard_sub_object_attributes(overrides)
    sub_object_attribute = (overrides || {})[:sub_object_attribute]
    return [] if sub_object_attribute.nil?

    (sub_object_attribute.is_a?(Array) ? sub_object_attribute : [sub_object_attribute])
  end
end
