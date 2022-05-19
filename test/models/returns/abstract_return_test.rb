# frozen_string_literal: true

require 'test_helper'

module Returns
  # Tests for Returns::AbstractReturn
  class AbstractReturnTest < ActiveSupport::TestCase
    test 'amendment? logic' do
      ar = AbstractReturn.new
      # New return being saved as draft
      ar.version = nil
      ar.form_type = 'D'
      ar.previous_form_type = ''
      assert_equal(false, ar.amendment?)

      # Version 1 draft being saved as draft
      ar.version = 1
      ar.form_type = 'D'
      ar.previous_form_type = 'D'
      assert_equal(false, ar.amendment?)

      # Version 1 draft being saved as final
      ar.form_type = 'L'
      ar.previous_form_type = 'D'
      assert_equal(false, ar.amendment?)

      # version 1 being saved as version 2
      ar.form_type = 'L'
      ar.previous_form_type = 'F'
      assert_equal(true, ar.amendment?)

      # Any version 2 is amendment
      ar.form_type = 'ignore'
      ar.previous_form_type = 'ignore'
      ar.version = 2
      assert_equal(true, ar.amendment?)
    end
  end
end
