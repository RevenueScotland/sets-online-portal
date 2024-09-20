# frozen_string_literal: true

# Revenue Scotland Specific UI code
module RS
  # Renders a company search component works with the @see WizardCompanyHelper
  class CompanySearchComponent < ViewComponent::Base
    include DS::ComponentHelpers
    include DS::FieldsFor

    attr_reader :company, :autofocus, :readonly

    # @param company [Company] The company object
    # @param autofocus [Boolean] Autofocus on the company search button (overridden if there are errors)
    def initialize(company:, autofocus: false, readonly: false)
      super()

      @company = company
      @autofocus = autofocus
      @readonly = readonly
    end
  end
end
