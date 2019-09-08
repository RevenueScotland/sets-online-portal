# frozen_string_literal: true

require 'test_helper'
require 'models/reference_data/memory_cache_helper'

module Returns
  module Lbtt
    # Tests Returns::Lbtt::ReliefClaim validation
    class ReliefClaimTest < ActiveSupport::TestCase
      test 'validation status' do
        # neither type or amount
        r = ReliefClaim.new
        assert_equal(:empty, r.validation_status)

        # missing amount
        r.relief_type = 'hello'
        assert_equal(:missing, r.validation_status)

        # amount fails validation
        r.relief_amount = 'world'
        assert_equal(:bad, r.validation_status)

        # happy path
        r.relief_amount = '3.14'
        assert_equal(:good, r.validation_status)

        # missing type
        r.relief_type = ''
        assert_equal(:missing, r.validation_status)
      end
    end
  end
end
