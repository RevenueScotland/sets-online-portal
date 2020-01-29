# frozen_string_literal: true

# Company helpers for this application
# Included by controllers to help manage company search forms.
module CompanyHelper
  extend ActiveSupport::Concern

  private

  # Returns true if the account refers to a registered organisation, otherwise false if it
  # refers to an individual or a non-registered company.
  def registered_organisation?
    AccountType.registered_organisation?(@account.account_type)
  end

  # Returns true if the account refers to a non-registered company, otherwise false if it
  # refers to an individual or a registered company.
  def other_organisation?
    AccountType.other_organisation?(@account.account_type)
  end

  # Returns true if the account refers to a individual, otherwise false if it
  # refers company.
  def individual?
    AccountType.individual?(@account.account_type)
  end

  # Initialize company required variables for the company view to use.
  # @param company [Object] : parameter use to view exiting companies details on the company view
  def initialize_company_variables(company = nil)
    @company = company || Company.new
    @company_read_only = true
  end

  # Performs a company search based on the search parameters and displays the results (if any)
  # @param redirect_to [String/Symbol] page to redirect to if supplied
  def company_search(redirect_to = nil)
    return unless params[:company_search]

    @company = Company.new(company_search_params)
    @company.search
    # Used for focusing on the search button when company search has been made and then the page reloaded
    @on_company_search = true
    render redirect_to unless redirect_to.nil?
  end

  # re-populate company summary and company details data from request param
  def populate_company_data
    @company = Company.new
    return if params[:company].nil?

    @company = Company.new(company_search_params)
  end

  # Is the form submit for an company search?
  def company_search?
    params[:company_search]
  end

  # controls the permitted parameters to this controller to perform
  # a search
  def company_search_params
    params.require(:company).permit(:company_number)
  end

  # controls the permitted parameters to this controller to save company data
  def company_detail_params
    params.require(:company).permit(Company.attribute_list)
  end
end
