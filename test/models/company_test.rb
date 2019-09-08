# frozen_string_literal: true

require 'test_helper'

# Tests Company model
class CompanyTest < ActiveSupport::TestCase
  test 'company number validation' do
    company = Company.new

    validate_company_number(company, nil, false)
    validate_company_number(company, '', false)
    validate_company_number(company, 'abc', false)
    validate_company_number(company, '-1', false)
    validate_company_number(company, 'abcdef', false)
    validate_company_number(company, 'abcdefgh', false)
    validate_company_number(company, '123', false)
    validate_company_number(company, '123456', false)
    validate_company_number(company, 'N123456', false)
    validate_company_number(company, 'SCO123456', false)

    validate_company_number(company, 'ni123456', true)
    validate_company_number(company, 'sc123456', true)
    validate_company_number(company, 'SC123456', true)
    validate_company_number(company, '12345678', true)
  end

  # Sets the input as company number on company then checks the validation produces the expectation as result.
  def validate_company_number(company, input, expectation)
    company.company_number = input
    assert_equal(expectation, company.valid?(:company_number), "Checking company number #{input}")
  end
end
