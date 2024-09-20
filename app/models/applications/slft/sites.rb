# frozen_string_literal: true

# Module to hold the Applications structure
module Applications
  # Module to hold the SLFT structure
  module Slft
    # Holds details broken down by site
    class Sites < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include CompleteModelValidationHelper
      include PrintData

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[application_type existing_agreement sepa_license_number site_id site_name address
           landfill_operator slft_registration_number operator_separate_mailing_address operator_mailing_address
           estimated_tonnage
           full_or_part
           wastes
           further_treatment
           intended_use start_date
           estimated_timescale
           type_of_waste_text]
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
      # application type and existing_agreement copied down from slft application
      # validates :application_type, presence: true
      # validates :existing_agreement, presence: true
      validates :sepa_license_number, presence: true, length: { maximum: 30 }, on: :sepa_license_number
      validates :site_name, presence: true, length: { maximum: 255 }, on: :site_name
      validates :address, presence: true, on: :address
      # Below are only for waste producer - water discount
      # The landfill operator/slft registration number are for the operator of the landfill site when the form is being
      # completed by the waste producer, otherwise the landfill operator is Applicant on the slft application
      validates :landfill_operator, presence: true, length: { maximum: 200 }, on: :landfill_operator,
                                    if: :waste_producer_water_discount?
      validates :slft_registration_number, presence: true, length: { maximum: 30 }, on: :slft_registration_number,
                                           if: :waste_producer_water_discount?
      validates :operator_separate_mailing_address, presence: true, on: :operator_separate_mailing_address,
                                                    if: :waste_producer_water_discount?
      validates :operator_mailing_address, presence: true, on: :operator_mailing_address,
                                           if: :operator_separate_mailing_address?
      validates :estimated_tonnage, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                    allow_blank: true }, presence: true, on: :estimated_tonnage,
                                    if: :waste_producer_water_discount?

      # Below are only for restoration agreement
      validates :full_or_part, presence: true, on: :full_or_part, if: :restoration_agreement?

      # Below are only for landfill operator - water discount and restoration agreement
      # Array of Waste objects (note has application type copied down)
      validates :wastes, presence: true, on: :wastes, if: :wastes_required?
      validate :validate_wastes, on: :wastes, if: :wastes_required?
      # Below are only for landfill operator - water discount
      validates :further_treatment, presence: true, length: { maximum: 2000 }, on: :further_treatment,
                                    if: :landfill_operator_water_discount?

      # Below are only for non disposal
      validates :intended_use, presence: true, length: { maximum: 255 }, on: :intended_use, if: :non_disposal?
      validates :start_date, presence: true, on: :start_date,
                             if: :start_date_required?

      # Below are only for non disposal and restoration agreement
      validates :estimated_timescale, presence: true, length: { maximum: 255 }, on: :estimated_timescale,
                                      if: :estimated_timescale_required?

      # Below for non disposal and waste producer - water discount
      validates :type_of_waste_text, presence: true, length: { maximum: 2000 }, on: :type_of_waste_text,
                                     if: :type_of_waste_text_required?

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { application_type: comp_key('APPLICATION', 'SLFT', 'RSTU'),
          full_or_part: comp_key('RESTORATION-TYPE', 'SLFT', 'RSTU') }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [print_layout_site_details, print_layout_site_address,
         print_layout_non_disposal_details, print_layout_waste_details, print_layout_waste,
         print_layout_alternate_address, print_layout_operator_address,
         print_layout_site_waste_details]
      end

      # Define the ref data codes associated with the attributes not to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { existing_agreement: YESNO_COMP_KEY,
          operator_separate_mailing_address: YESNO_COMP_KEY }
      end

      # This routine validates wastes by ensuring wastes attribute is not empty and all wastes are valid
      def validate_wastes
        validate_sub_objects(wastes, '') unless wastes.nil?
      end

      # Key information to display section error.(see CompleteModelValidationHelper)
      def key_info
        "site #{site_name}"
      end

      # is this a waste producer water discount
      def waste_producer_water_discount?
        (application_type == 'WP-WD')
      end

      # have they said the operator has a separate mailing address
      def operator_separate_mailing_address?
        (operator_separate_mailing_address == 'Y')
      end

      # Do we need to collect the list of wastes for this site
      def wastes_required?
        (application_type == 'LO-RA') || (application_type == 'LO-WD')
      end

      # is the start date required
      def start_date_required?
        (application_type == 'LO-ND') && (existing_agreement == 'N')
      end

      # Are estimated timescales required
      def estimated_timescale_required?
        (application_type == 'LO-ND') || (application_type == 'LO-RA')
      end

      # is this a waste producer water discount
      def type_of_waste_text_required?
        (application_type == 'WP-WD') || (application_type == 'LO-ND')
      end

      # Is this a restoration agreement application
      def restoration_agreement?
        (application_type == 'LO-RA')
      end

      # is this a landfill operator water discount application
      def landfill_operator_water_discount?
        (application_type == 'LO-WD')
      end

      # Is this a non disposal application
      def non_disposal?
        (application_type == 'LO-ND')
      end

      # Dynamically returns the translation key based on the translation_options provided by the page if it exists
      # @param attribute [Symbol] the name of the attribute to translate
      # @return [Symbol] "attribute_" + extra information to make the translation key
      def translation_attribute(attribute, _translation_options = nil)
        return :"#{attribute}_#{application_type}" if %i[estimated_timescale
                                                         type_of_waste_text wastes].include?(attribute)

        attribute
      end

      private

      # layout for the landfill site details
      def print_layout_site_details
        { code: :details, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications sites details], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :site_name },
                       { code: :sepa_license_number },
                       { code: :landfill_operator, when: :waste_producer_water_discount?, is: [true] },
                       { code: :slft_registration_number, when: :waste_producer_water_discount?, is: [true] }] }
      end

      # layout for the landfill site address
      def print_layout_site_address
        { code: :address, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications sites address], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :object }
      end

      # layout for the non_disposal area details
      def print_layout_non_disposal_details
        return unless non_disposal?

        { code: :non_disposal_details, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications sites non_disposal_details], # scope for the title translation
          divider: false, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: print_layout_non_disposal_list_items }
      end

      # fields for the non disposal details
      def print_layout_non_disposal_list_items
        [{ code: :intended_use },
         { code: :estimated_timescale },
         { code: :type_of_waste_text },
         { code: :start_date, format: :date, when: :start_date_required?, is: [true] }]
      end

      # layout for the waste details
      def print_layout_waste_details
        return unless wastes_required?

        { code: :wastes, # section code
          key_value: :application_type,
          key: 'title_#key_value#', # key for the title translation
          key_scope: %i[applications sites wastes], # scope for the title translation
          divider: false, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: print_layout_waste_list_items }
      end

      # layout for the waste details items
      def print_layout_waste_list_items
        [
          { code: :full_or_part, lookup: true, when: :restoration_agreement?, is: [true] },
          { code: :estimated_timescale, when: :estimated_timescale_required?, is: [true] },
          { code: :further_treatment, when: :landfill_operator_water_discount?, is: [true] }
        ]
      end

      # layout to add type of waste information for R
      def print_layout_waste
        return unless wastes_required?

        { code: :wastes,
          type: :object }
      end

      # layout for the taxpayer alternate address of the print data of claim
      def print_layout_alternate_address
        return unless waste_producer_water_discount?

        { code: :separate_mailing_address,
          parent_codes: %i[sites],
          key: :title,
          key_scope: %i[applications sites separate_mailing_address], # scope for the title translation
          type: :list,
          list_items: [{ code: :operator_separate_mailing_address, lookup: true }] }
      end

      # layout for the taxpayer address of the print data of claim
      def print_layout_operator_address
        return unless waste_producer_water_discount?

        { code: :address,
          parent_codes: %i[sites],
          key: :title,
          key_scope: %i[applications sites separate_mailing_address], # scope for the title translation
          type: :object }
      end

      # layout about the site waste details
      def print_layout_site_waste_details
        return unless waste_producer_water_discount?

        { code: :type_of_waste, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications sites type_of_waste], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :type_of_waste_text },
                       { code: :estimated_tonnage }] }
      end
    end
  end
end
