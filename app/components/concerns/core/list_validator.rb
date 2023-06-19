# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Provides support to validate that a passed value is in a list
  module ListValidator
    extend ActiveSupport::Concern

    class_methods do
      # Utility function used for validating that a given value is in a list of allowed values
      # in development mode it will error if this is not true, otherwise returns the fallback value
      # @param allowed_values [Array] The list of allowed values
      # @param given_value [Object] The value to check in the list
      # @param fallback [Object] The value to return if the given value is not in the list
      # @return [Object] The value from the list or the fallback
      # @raise [ArgumentError] If the value isn't in the list in development mode
      def fetch_or_fallback(allowed_values, given_value, fallback)
        if allowed_values.include?(given_value)
          given_value
        elsif Rails.env.development?
          # :nocov: #
          raise ArgumentError, "[#{given_value}] is not in allowed values of #{allowed_values}"
        else
          fallback
          # :nocov: #
        end
      end
    end
  end
end
