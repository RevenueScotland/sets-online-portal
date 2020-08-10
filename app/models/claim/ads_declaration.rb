# frozen_string_literal: true

# Module for claim payments options.
module Claim
  # Model for the ADS Declarations
  # This holds the party reference, the description of the declaration and if the declaration was ticked
  class AdsDeclaration < FLApplicationRecord
    include PrintData

    # Attributes for this class, in list so can re-use as permitted params list in the controller
    def self.attribute_list
      %i[index text checked]
    end
    attribute_list.each { |attr| attr_accessor attr }

    # No specific validations as this is handled in the main claim module

    # Layout to print the data in this model
    # This defines the sections that are to be printed and the content and layout of those sections
    def print_layout
      [{ code: :unauthenticated_declarations, # section code
         type: :list, # type list = the list of attributes to follow
         list_items: [{ code: :checked, boolean_lookup: true, label: @text }] }]
    end
  end
end
