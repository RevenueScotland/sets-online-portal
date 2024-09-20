# frozen_string_literal: true

# Helper for the main Wizard methods concern handling companies as a special case
module WizardCompanyHelper
  extend ActiveSupport::Concern
  include CompanyHelper

  # Provides a method for the common code for using the company search system as a wizard step.
  #
  # There are 3 parts to an company wizard step with submits in between and after them :
  #    1) loading the page 2) searching for a company number 3) storing the chosen company.
  #
  # Like wizard_step, this method is designed to be pretty much the only thing the controller action does for managing
  # the navigation etc.  If you find yourself putting it in an if statement, you're almost certainly doing it wrong.
  #
  # Standard overrides are listed below but it can also take overrides used by the main wizard step
  #
  # This relies on code @see CompanyHelper that handles company searches outside of a wizard
  #
  # @param steps [Object] if it's an array then it's the list of steps follow otherwise it _is_ the next step
  # @param overrides [Hash] hash of optional overrides with the following keys :
  #  :company_attribute  - The attribute as a symbol used store the company if it isn't called company on the object
  #  :cache_index     - if cache_index is not the default controller you can override it
  #
  # @example Controller action has
  #   wizard_company_step(STEPS, company_attribute: :my_non_standard_company)
  #
  #
  def wizard_company_step(steps, overrides = {})
    # non standard names used to avoid a line length issue further down
    cached_object, page_object = wizard_setup_step(overrides)

    if request.get?
      wizard_company_get(page_object, overrides)
    elsif company_search?
      wizard_company_search(cached_object, page_object, overrides)
    elsif wizard_store_company(cached_object, page_object, overrides)
      wizard_navigation_step(steps, overrides, wizard_page_objects_size(cached_object, overrides))
    else
      # Error on company
      render(status: :unprocessable_entity)
    end
  end

  private

  # Processing for a get request on a page with a company search
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param overrides [Hash] an array of overrides see @wizard_company_step
  def wizard_company_get(wizard_page_object, overrides)
    wizard_handle_clear_cache(overrides)
    wizard_load_company(wizard_page_object, overrides)
  end

  # processing for the company search
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param overrides [Hash] an array of overrides see @wizard_company_step
  def wizard_company_search(wizard_cached_object, wizard_page_object, overrides)
    # Special POST and GET - Find Company
    search_for_companies if wizard_company_pre_search(wizard_cached_object, wizard_page_object, overrides, false)
    # Force a redirect back to the current page
    render(status: :unprocessable_entity)
  end

  # Standard store company code to handle storing company in the current object
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param overrides [Hash] an array of overrides see @wizard_company_step
  # @return [Boolean] was the save successful or was there an error
  def wizard_store_company(wizard_cached_object, wizard_page_object, overrides)
    # we may also have main object parameters so store these and validate them first
    # the standard company search does the save
    object_valid = wizard_company_pre_search(wizard_cached_object, wizard_page_object, overrides, true)

    company = Company.new(company_detail_params)

    # @note order is important as we want to validate the company even if the main object isn't valid
    if company.valid?(%i[company_number company_selected]) && object_valid
      wizard_save_company(wizard_cached_object, wizard_page_object, company, overrides)
    else
      Rails.logger.debug { "Validation on company failed object_valid: #{object_valid}" }
      # @see company_helper
      initialize_company_variables(company)
      false
    end
  end

  # This is the standard company pre-search. Primarily it saves any non company fields
  # prior to the search option so they are not lost on the object
  # it can optionally validate the object
  # it is also used @see standard_company_store_company to store parameters prior to company validation
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param overrides [Hash] uses the :sub_object_attribute to deal with things related to the sub-object
  # @param validate [Boolean] do we need to validate the parent object as part of the process
  def wizard_company_pre_search(wizard_cached_object, wizard_page_object, overrides, validate)
    wizard_params = resolve_params(overrides)
    unless wizard_params.nil?
      merge_params_with_object(wizard_page_object, wizard_params)

      return true unless validate

      return wizard_valid?(wizard_cached_object, wizard_params, overrides)
    end
    true
  end

  # This is the standard company load. Primarily it populates the company detail from the object
  # @param wizard_page_object [Object] the parent object being processed
  # @param overrides [Hash] an array of overrides see @wizard_company_step
  def wizard_load_company(wizard_page_object, overrides)
    company = wizard_page_object.send(overrides[:company_attribute] || :company)
    initialize_company_variables(company)
  end

  # Actually saves the company in the object at either the company attribute or the attribute given in the override
  # @param wizard_cached_object [Object] the object being cached
  # @param wizard_page_object [Object] the object on the page, a child or the same as the cached object
  # @param company [Object] the company being processed
  # @param overrides [Hash] an array of overrides see @wizard_company_step
  def wizard_save_company(wizard_cached_object, wizard_page_object, company, overrides)
    company_attribute = overrides[:company_attribute] || :company

    Rails.logger.debug { "Storing company in object at #{wizard_page_object.class.name}##{company_attribute}" }
    wizard_page_object.send(:"#{company_attribute}=", company)

    wizard_save(wizard_cached_object, overrides[:cache_index])
    true
  end

  # Runs the company search
  def search_for_companies
    populate_company_data
    company_search
  end
end
