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
  #  :company_attribute  - The attribute as a symbol used store the company if it isn't called company on the model
  #  :cache_index     - if cache_index is not the default controller you can override it
  #
  # @example Controller action has
  #   wizard_company_step(STEPS, company_attribute: :my_non_standard_company)
  #
  #
  def wizard_company_step(steps, overrides = {})
    model = wizard_setup_step(overrides)

    if params[:submitted]
      wizard_navigation_step(steps, overrides) if wizard_store_company(model, overrides)
    elsif company_search?
      wizard_company_pre_search(model, false)
      search_for_companies
    else
      wizard_load_company(model, overrides)
    end
  end

  private

  # Standard store company code to handle storing company in the current model
  # @param model [Object] the model being processed
  # @param overrides [Hash] an array of overrides see @wizard_address_step
  def wizard_store_company(model, overrides)
    # we may also have main model parameters so store these and validate them first
    # the standard company search does the save
    model_valid = wizard_company_pre_search(model, true)

    company = Company.new(company_detail_params)

    # @note order is important as we want to validate the company even if the main model isn't valid
    if company.valid?(%i[company_number company_selected]) && model_valid
      wizard_save_company(model, company, overrides)
    else
      Rails.logger.debug "Validation on company failed model_valid: #{model_valid}"
      # @see company_helper
      initialize_company_variables(company)
      false
    end
  end

  # This is the standard company pre-search. Primarily it saves any non company fields
  # prior to the search option so they are not lost on the model
  # it can optionally validate the model
  # it is also used @see standard_company_store_company to store parameters prior to company validation
  # @param model [Object] the parent model being processed
  # @param validate [Boolean] do we need to validate the parent model as part of the process
  def wizard_company_pre_search(model, validate)
    unless filter_params.nil?
      model.assign_attributes(filter_params)
      return true unless validate

      return model.valid?(filter_params.keys.map(&:to_sym))
    end
    true
  end

  # This is the standard company load. Primarily it populates the company detail from the model
  # @param model [Object] the parent model being processed
  # @param overrides [Hash] an array of overrides see @wizard_company_step
  def wizard_load_company(model, overrides)
    company = model.send(overrides[:company_attribute] || :company)
    initialize_company_variables(company)
  end

  # Actually saves the company in the model at either the company attribute or the attribute given in the override
  # @param model [Object] the parent model being processed
  # @param company [Object] the company being processed
  # @param overrides [Hash] an array of overrides see @wizard_company_step
  def wizard_save_company(model, company, overrides)
    company_attribute = overrides[:company_attribute] || :company
    Rails.logger.debug "Storing company in model at #{model.class.name}##{company_attribute}"
    model.send((company_attribute.to_s + '=').to_sym, company)
    wizard_save(model, overrides[:cache_index])
    true
  end

  # Runs the company search
  def search_for_companies
    populate_company_data
    company_search
  end
end
