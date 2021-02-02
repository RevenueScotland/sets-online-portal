# frozen_string_literal: true

# Module to hold the SLFT Applications structure
module Applications
  # Module to hold the SLFT Applications structure
  module Slft
    # Holds details of the waste producer or the landfill operator
    # waste producers are only needed on the waster discounts (both types)
    class Applicants < FLApplicationRecord
      include PrintData

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[organisation_name slft_registration_number telephone_number email_address address]
      end

      attribute_list.each { |attr| attr_accessor attr }

      validates :organisation_name, presence: true, length: { maximum: 200 }, on: :organisation_name
      validates :slft_registration_number, presence: true, length: { maximum: 30 }, on: :slft_registration_number
      validates :telephone_number, presence: true, phone_number: true, on: :telephone_number
      validates :email_address, presence: true, email_address: true, on: :email_address
      validates :address, presence: true, on: :address

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        if slft_registration_number.nil?
          [print_layout_waste_producer_details, print_layout_waste_producer_address]
        else
          [print_layout_landfill_operator_details, print_layout_landfill_operator_address]
        end
      end

      private

      # layout for the landfill_operator details
      def print_layout_landfill_operator_details
        { code: :applicant_details, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft applicant_details], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: print_layout_landfill_operator_list_items }
      end

      # fields for the landfill_operator details
      def print_layout_landfill_operator_list_items
        [{ code: :organisation_name },
         { code: :slft_registration_number },
         { code: :telephone_number },
         { code: :email_address }]
      end

      # layout for the landfill_operator address
      def print_layout_landfill_operator_address
        { code: :address, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft applicant_address], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :object }
      end

      # layout for the waste_producer details
      def print_layout_waste_producer_details
        { code: :waste_producer_details, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft waste_producer_details], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :organisation_name },
                       { code: :telephone_number },
                       { code: :email_address }] }
      end

      # layout for the waste_producer address
      def print_layout_waste_producer_address
        { code: :address, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft waste_producer_address], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :object }
      end
    end
  end
end
