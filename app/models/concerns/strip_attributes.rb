# frozen_string_literal: true

# Adds the ability to strip leading and trailing spaces from attributes
module StripAttributes
  extend ActiveSupport::Concern

  class_methods do
    # Adds the method to the class that allows you to specify the attributes you want the spaces stripped from
    # NOTE: This generates new setter methods so if there is already a setter method then amend that to strip do
    # not specify it on this method
    # @example
    #   strip_attributes :slcf_contribution, :slcf_credit_claimed, :bad_debt_credit
    # @params attributes [Array<Symbols>] The list of attributes
    def strip_attributes(*attributes)
      # For each of the provided attributes create a setter
      # If the value passed in is not a string then the try strip will fail with null, so default to the actual value
      attributes.each do |attribute|
        class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
            def #{attribute}=(value)                    # def bad_debt_credit=(value)
              @#{attribute} = value.try(:strip)||value  #   @bad_debt_credit=value.try(:strip)||value
            end                                         # end
        RUBY_EVAL
      end
    end
  end
end
