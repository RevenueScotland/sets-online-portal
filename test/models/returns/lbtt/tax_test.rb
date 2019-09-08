# frozen_string_literal: true

require 'test_helper'

module Returns
  module Lbtt
    # Tests Returns::Lbtt::Tax
    class TaxTest < ActiveSupport::TestCase
      test 'rounding up/down tax_due_for_return' do
        t = Tax.new
        t.calculate_tax_due_for_return
        assert_equal(0, t.tax_due_for_return)

        t.tax_due = 880
        t.amount_already_paid = 13.56
        t.calculate_tax_due_for_return
        assert_equal(866, t.tax_due_for_return)

        t.amount_already_paid = 13.46
        t.calculate_tax_due_for_return
        assert_equal(866, t.tax_due_for_return)

        t.amount_already_paid = 980.11
        t.calculate_tax_due_for_return
        assert_equal(-100, t.tax_due_for_return)

        t.amount_already_paid = 980.99
        t.calculate_tax_due_for_return
        assert_equal(-100, t.tax_due_for_return)
      end
    end
  end
end
