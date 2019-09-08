# frozen_string_literal: true

require 'test_helper'

module Returns
  # Tests for Returns::AbstractReturn
  class AbstractReturnTest < ActiveSupport::TestCase
    test 'amendment? logic' do
      ar = AbstractReturn.new
      ar.version = 1
      ar.form_type = 'D'
      assert_equal(false, ar.amendment?)

      ar.form_type = 'F'
      assert_equal(true, ar.amendment?)

      ar.form_type = 'ignore'
      ar.version = 2
      assert_equal(true, ar.amendment?)
    end
  end
end
