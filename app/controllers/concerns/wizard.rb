# frozen_string_literal: true

# Wizard methods concern, for wizard controllers to include.
#
# A Wizard is a multi-page form.  This concern helps us build them by saving the data from the forms in the
# wizard cache (ie Redis, under a certain index that this code manages for you (and saves in the session cookie),
# Wizard data is kept until it expires or is explititly cleared, so a user can navigate away and return to a
# wizard (which should make saving and restoring data nice and easy).
# The index is based on the controller name, so each controller has it's own wizard cache, and also on the user's
# session, so wizard data is not shared between users.
#
# A simple wizard is one where the data is stored in one model object, where the user visits the pages, in order,
# from start to finish.
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
#      wizard_step(STEPS) { { params: :filter_params } }
#    end
#
# The routes file must have an entry for each step in the wizard.  Each step needs both a GET and a POST
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
#     where @your_model and @post_path are set both set up in a setup_step method (@see SlftController#setup_step)
#     @your_model must be returned from setup_step.
#  2) Prefix all controller actions in a wizard with a common word so its obvious in the controller and routes
#     files which ones are grouped together (ie it's possible to have multiple wizards per controller if they
#     can share the same setup_step method, so want an easy way to organise them)
#  3) Define the model's non-sensitive attributes in a list which is then re-used by a controller method to limit
#     the parameters to just those accepted by the model - ie Don't Repeat Yourself (@see SlftController#filter_params)
#     This will mean that all attributes are accepted by all forms, so for sensitive attributes, consider leaving
#     them out of this list and including them specifically for the forms that allow it (so user's can't attempt to
#     change data they're not supposed to).
#  4) Give the submit button the name "submitted" so the Wizard code knows to merge and save the data rather than
#     just display the form @example
#        <%= f.button 'next', { :name => 'submitted' }  %>
#
# Common gotchas :
#   1) When some behaviour is only needed after submit is pressed, it's tempting to write something that
#      conditionally calls the wizard_step method.  This is against the design since the wizard_step method
#      does both with and without submit being called (ie does both halves).  Use the after_merge or next_step
#      options as appropriate instead (@see #wizard_step) or even don't use wizard_step at all for that case.
#   2) When some behaviour is only needed on the view part ie before submit is pressed, it's tempting to add it
#      before the wizard_step method.  This means it will run twice.  Consider if you should be using wizard_step
#      or if you should implement a custom version (eg @see SlftSitesWasteController#waste_description)
#   3) "wizard_step is going straight to the submitted part, it never shows my page!"  This happens because the
#      preceeding page is wrongly including a button with the name "submitted".  Usually you'll find the preceeding
#      page should itself be turned into a wizard step like @see LbttPartiesHelper#about_the_party or should use a
#      normal link (GET) rather than a submit (POST).
#   4) "wizard_step(method)" doesn't work because #method can't find @variable setup in setup_step.  This is because
#      #method is resolved before #wizard_step is called, so you can't rely on anything in setup_step.  Instead,
#      use the :next_step override option.
#
# FAQ :
#   @example - Just get the wizard data
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

  # Performs a step in a simple wizard.
  # There are two halves to a step, the first sets up the model for the view, with the same name as the controller
  # action method, to be called.  The second part validates then stores the submitted parameters in the wizard cache
  # model (provided by the #setup_step method) for later use, and moves to the next step.  If validation fails then the
  # view is shown again.
  #
  # NB You need to provide a setup_step method for this method and it needs to return the model used for the form_for
  # part of the view.
  #
  # A yield accepts a hash allowing optional overrides with the following keys :
  # :params -      pointer to method to run to get the parameters to be saved (defaults to the params rails method)
  #                this is normally set to be the filtered list of parameters for the model
  # :cache_index - overrides the cache key used when saving data (defaults to the current controller name)
  #                useful when you want two controllers to work on the same wizard cached data.
  # :after_merge - pointer to method to run after the merge has happened (can be used to insert data into somewhere
  #                else on the last step of the wizard for example)
  # :next_step -   pointer to method [to run after the merge has happened] which returns the next page.  This allows
  #                just-in-time conditional navigation
  # :clear_cache - Clear the wizard cache at _start_ of the first step ie before #setup_step is called.
  #                If 'true', the current wizard cache will be called, if a controller name is provided then that
  #                controller's cache will be cleared.
  #                eg :clear_cache: LbttController will clear the LbttController wizard cache.
  #
  # This method is designed to be pretty much the only thing the controller action calls.  If you find yourself putting
  # it in an if statement, you're probably doing it wrong.
  #
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  def wizard_step(steps)
    # yield allows various items to be overridden
    overrides = yield

    # First half of the step, optionally clear the wizard cache, then finish (so page can display)
    unless params[:submitted]
      # allow "clear_cache: true"
      overrides[:clear_cache] = self.class.name if overrides[:clear_cache] == true

      wizard_end(overrides[:clear_cache]) if overrides[:clear_cache]

      # sets up _AFTER_ allowing cache to be cleared
      setup_step
      return
    end

    # Second half - when step is submitted
    wizard_step_submitted(steps, overrides)
  end

  # Provides a method for the common code for using the address search system as a wizard step.
  #
  # There are 3 parts to an address wizard step with submits in between and after them :
  #    1) loading the page 2) searching for a postcode 3) storing the chosen address.
  #
  # Calls setup_step to get the model (ie the form_for attribute in the view/the object being developed in the wizard
  # cache) in every part since it's usually needed for the view and for storing the address.
  #
  # Like wizard_step, this method is designed to be pretty much the only thing the controller action does for managing
  # the navigation etc.  If you find yourself putting it in an if statement, you're almost certianly doing it wrong.
  #
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  #                       NB don't put a method call in the steps param, it will be resolved asap which is usually
  #                       before the data is merged which is usually not what you want.
  # @param store_address [Method] pointer to method to call to store the address data (see example below)
  #                               This is the method which puts your address into somewhere useful eg wizard_cache.
  # @param overrides [Hash] hash of optional overrides with the following keys :
  #  :load_address  - pointer to method to run to initially load any existing address data for the wizard page
  #  :pre_search    - pointer to method to run before the address search is done eg so you don't lose other fields
  #                   on the same page as the address search or so you can set UI options so the address search
  #                   remains visible
  #  :next_step     - pointer to method [to run after the merge has happened] which returns the next page.  This allows
  #                   just-in-time conditional navigation
  #
  # @example Controller action has
  #   wizard_address_step(STEPS, :store_address, pre_search: :pre_search_example_method)
  #
  # @example store_address method
  #    def store_address
  #      @lbtt_Return.ads_main_address = Address.new(address_params)
  #      wizard_save(@lbtt_return)
  #    end
  #
  # @example pre_search_example_method (you could do wizard merging/saving instead)
  #   def pre_search_example_method
  #     @lbtt_return.ads_apply_yes_no = yes_no unless @lbtt_return.nil? # ie some logic that's needed
  #   end
  #
  def wizard_address_step(steps, store_address, overrides = {})
    setup_step

    if params[:submitted]
      wizard_navigation_step(steps, overrides) if send(store_address)
    elsif address_search?
      send(overrides[:pre_search]) if overrides[:pre_search]

      search_for_addresses
    elsif overrides[:load_address]
      send(overrides[:load_address])
    end
  end

  # Provides a method for the common code for using the company search system as a wizard step.
  #
  # There are 3 parts to an company wizard step with submits in between and after them :
  #    1) loading the page 2) searching for a company number 3) storing the chosen company.
  # On the first two parts the setup_step method is called.
  #
  # Like wizard_step, this method is designed to be pretty much the only thing the controller action does for managing
  # the navigation etc.  If you find yourself putting it in an if statement, you're almost certainly doing it wrong.
  #
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param store_company [Method] pointer to method to call to store the company data (see example below)
  # @param overrides [Hash] hash of optional overrides with the following keys :
  #  :load_company  - pointer to method to run to initially load any existing company data for the wizard page
  #  :pre_search    - pointer to method to run before the company search is done eg so you don't lose other fields
  #                   on the same page as the company search or so you can set UI options so the company search
  #                   remains visible
  #  :next_step     - pointer to method [to run after the merge has happened] which returns the next page.  This allows
  #                   just-in-time conditional navigation
  #
  # @example Controller action has
  #   wizard_company_step(@lbtt_return, STEPS, :store_company, pre_search: :example_method)
  #
  # @example store_company method
  #    def store_company
  #      wizard_save(company_params)
  #      true
  #    end
  #
  # @example example_method (you could do wizard merging/saving instead)
  #   def example_method
  #     @lbtt_return.ads_apply_yes_no = 'Y' # ensures it's selected
  #   end
  #
  def wizard_company_step(steps, store_company, overrides = {})
    model = setup_step
    if params[:submitted]
      wizard_navigation_step(steps, overrides) if send(store_company)
    elsif company_search?
      send(overrides[:pre_search]) if overrides[:pre_search]
      search_for_companies(model)
    elsif overrides[:load_company]
      send(overrides[:load_company])
    end
  end

  # Retrieves wizard data from the cache.
  # @param controller_name [String] optional name of the wizard controller (defaults to self.class.name)
  #        ie if you don't provide a name the current controller will be used.
  #        If you do provide a name it will get that controller's wizard data instead.
  def wizard_load(controller_name = self.class.name)
    key = wizard_cache_key(controller_name)
    Rails.logger.debug "Loading wizard data for #{key}"
    Rails.cache.read(key)
  end

  # Assign wizard_params method output to model and save it in the wizard cache.
  # Optionally yields to check validation.  No yield, no validation checks, just saves.  @see #wizard_valid?
  # @param model - the object to save in the wizard cache
  # @param wizard_params - usually the method providing the submitted form data, data will be merged into the model
  # @param controller_name [String] optional name of the wizard controller (defaults to self.class.name)
  # @return [Boolean] false if validation fails, else true
  def wizard_merge_and_save(model, wizard_params, controller_name = self.class.name)
    # allow nil to be passed as argument for controller_name but still use default in that case
    controller_name = self.class.name if controller_name.nil?

    raise Error::AppError.new('Wizard', "Params argument is empty (for #{controller_name})") if wizard_params.nil?

    # if you get an error here, usually means a parameter provided wasn't an attribute in the model (maybe
    # it's missing, or maybe the parameters weren't properly filtered)
    Rails.logger.debug("  Merging/assigning params #{wizard_params}")
    model.assign_attributes(wizard_params)
    # check validation if yield provided (else valid = true)
    valid = block_given? ? yield(model, wizard_params) : true
    Rails.logger.debug "  Validation overall result is #{valid}"

    # save if validation passes
    wizard_save(model, controller_name) if valid

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
  # @return [Boolean] true if valid else false
  def wizard_valid?(model, wizard_params)
    validation_contexts = wizard_params.keys.map(&:to_sym)
    output = model.valid?(validation_contexts)
    Rails.logger.debug "  Validation for #{validation_contexts} is #{output}"

    model.errors.blank?
  end

  # _Overwrite_ the wizard cache object.  Use with caution.
  # @param master_object - the object to store in the cache
  # @param controller_name [String] optional name of the wizard controller (defaults to self.class.name)
  def wizard_save(master_object, controller_name = self.class.name)
    master_object.initialize_ref_data if master_object.respond_to?(:initialize_ref_data)
    key = wizard_cache_key(controller_name)
    Rails.logger.debug "Saving wizard params for #{key}"
    Rails.cache.write(key, master_object, expires_in: wizard_cache_expiry_time)
  end

  # Cleans up wizard cache and session at the end to delete it/free up resources.
  # Fails safe, won't throw exceptions if the deletion is unsuccessful due to a StandardError.
  # @param controller_name [String] optional name of the wizard controller (defaults to self.class.name)
  def wizard_end(controller_name = self.class.name)
    session_key = wizard_session_key(controller_name)
    cache_key = wizard_cache_key(controller_name)
    Rails.logger.debug "Ending wizard #{cache_key}"
    Rails.cache.delete(cache_key)
    session.delete(session_key) { |key| Rails.logger.warn "session #{key} not deleted, not found" }
  rescue StandardError => ex
    Rails.logger.warn("wizard_end failing safe, not throwing exception #{ex.message}")
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
    #     wizard_step(<steps_list>) { { params: :filter_params } }
    #   end
    #
    # If you want a custom version of this method, copy it and add "self." to the method signature
    # or copy it including the class_methods section into another concern.
    # @param steps_list [Array] the STEPS list to use for the generated wizard_step method
    # @param actions_list [Array] symbol list of action (method) names to generate
    # @param overrides [Hash] the overrides to set, defaults to params: :filter_params if nothing is set
    def standard_wizard_step_actions(steps_list, actions_list, overrides = { params: :filter_params })
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

  # The second half of wizard_step, separated out because it's getting too big.
  # Calls setup_step to get the model we're working on. @see #wizard_step for more details.
  # @param steps [List] @see #wizard_step
  # @param overrides [Hash] @see #wizard_step
  def wizard_step_submitted(steps, overrides)
    model = setup_step

    # get the parameters submitted
    wizard_params = resolve_params(overrides)

    # add submitted params to the cached object and save if validation passes
    # if validation fails then returns without doing the navigation
    return unless wizard_merge_and_save(model, wizard_params, overrides[:cache_index]) do
      wizard_valid?(model, wizard_params)
    end

    # custom method to run after successful merge
    send(overrides[:after_merge]) if overrides[:after_merge]

    # redirect to the next step unless there were errors added by the after_merge section (in which case we
    # fall out the bottom of the wizard process to re-display the current view)
    wizard_navigation_step(steps, overrides) unless model.errors.any?
  end

  # Gets the parameters submitted by calling the override[:params] method if exists or else the rails params method
  def resolve_params(overrides)
    return send(overrides[:params]) if overrides.key?(:params)

    params
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

  # Runs the company search
  # @param form_object [Object] your form's object, receives any errors that occur during company search
  def search_for_companies(form_object)
    populate_company_data
    company_search(form_object)
  end

  # Runs the address search
  def search_for_addresses
    populate_address_data
    address_search
  end

  # Provides the key to access this wizard's cache key in the user's _session_ [cookie] (@see #wizard_cache_key).
  # @param controller_name [String] the name of the wizard controller
  def wizard_session_key(controller_name)
    "WIZARD_#{controller_name}"
  end

  # Provides the wizard cache key for the relevant controller and user.
  #
  # Gets the cache key from the session [cookie]. Creates it in the session if it doesn't already exist.
  #
  # The cache key will contain a UUID so that each persons' wizard entries are unique.
  #
  # @param controller_name [String] the name of the wizard controller
  # @return [String] the wizard cache key
  def wizard_cache_key(controller_name)
    validate_wizard_cache_name(controller_name)
    session_key = wizard_session_key(controller_name)

    # if the session key doesn't exist, generate a new one including the session key itself (to help with debugging)
    # and a UUID to make it unique to the session
    session[session_key] = "#{session_key}_#{SecureRandom.uuid}" unless session.key?(session_key)

    session[session_key]
  end

  # Check assumption that self.class.name is available and valid (ie not "class" and contains "Controller")
  # to check it hasn't been redefined.
  # @param controller_name [String] the name of the wizard controller
  def validate_wizard_cache_name(controller_name)
    return unless controller_name.nil? && controller_name.casecmp('class') && controller_name.include?('Controller')
  rescue StandardError
    raise Error::AppError.new('wizard', "'#{controller_name}' is not a controller class")
  end

  # How long the wizard data will last for if @see #wizard_end isn't called.
  # @return the session max lifetime from system parameters or 10.hours if that doesn't exist for some reason
  def wizard_cache_expiry_time
    begin
      max = ReferenceData::SystemParameter.lookup('PWS', 'SYS', 'RSTU')['MAX_SESS_MINS']&.value&.to_i
    rescue StandardError
      Rails.logger.warn('System parameter PWS.SYS.RSTU did not include MAX_SESS_MINS, returning arbitrary expiry')
      return 10.hours
    end

    max.minutes
  end
end
