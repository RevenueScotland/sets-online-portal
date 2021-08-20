# frozen_string_literal: true

# Module to hold the Applications structure
module Applications
  # Module to hold the SLFT structure
  module Slft
    # Holds details of individual waste lines for application types
    #   landfill operator - water discount
    #   restoration agreement
    class Wastes < FLApplicationRecord
      include PrintData

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[application_type type_of_waste
           final_destination use
           estimated_tonnage]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      strip_attributes :estimated_tonnage

      # application_type
      #   WP-WD : waste producer - water discount
      #   LO-WD : landfill operator - water discount,
      #   LO-RA : landfill operator - restoration agreement
      #   LO-ND : landfill operator - non disposal
      #   LO-WB : landfill operator - weighbridge
      validates :application_type, presence: true
      validates :type_of_waste, presence: true, length: { maximum: 255 }
      # Below are only for landfill operator - water discount
      validates :final_destination, presence: true, length: { maximum: 255 },
                                    if: :landfill_operator_water_discount?
      validates :use, presence: true, length: { maximum: 255 },
                      if: :landfill_operator_water_discount?

      # Below are only for restoration agreement
      validates :estimated_tonnage, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                    allow_blank: true }, presence: true,
                                    if: :restoration_agreement?

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { application_type: comp_key('APPLICATION', 'SLFT', 'RSTU') }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [{ code: :wastes, # section code
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :type_of_waste },
                        { code: :final_destination, when: :landfill_operator_water_discount?, is: [true] },
                        { code: :use, when: :landfill_operator_water_discount?, is: [true] },
                        { code: :estimated_tonnage, when: :restoration_agreement?, is: [true] }] }]
      end

      # is this a landfill operator water discount application
      def landfill_operator_water_discount?
        (application_type == 'LO-WD')
      end

      # is this a restoration agreement application
      def restoration_agreement?
        (application_type == 'LO-RA')
      end

      # Key information to display section error.(see CompleteModelValidationHelper)
      def key_info
        type_of_waste
      end
    end
  end
end
