# frozen_string_literal: true

# Module to hold the SLFT Applications structure
module Applications
  # Module to hold the SLFT Applications structure
  module Slft
    # Main model for SLFT Applications
    class Applications < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include CompleteModelValidationHelper
      include PrintData

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[ applicant_type application_type
            existing_agreement previous_case_reference landfill_operator sites
            supporting_document_list supporting_document_other_description declaration change_declaration
            declaration_name declaration_position declaration_telephone_number declaration_email_address
            waste_producer
            renewal_or_review why_water_present not_banned_waste
            type_of_waste_text how_produced how_added waste_percentage added_water_percentage
            naturally_occurring naturally_occurring_percentage treatment reason_for_no_treatment start_date
            case_references case_ref_nos]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # For each of the numeric fields create a setter, don't do this if there is already a setter
      strip_attributes :waste_percentage, :added_water_percentage, :naturally_occurring_percentage

      # applicant_type
      #   WP : waste producer
      #   LO : landfill operator
      validates :applicant_type, presence: true, on: :applicant_type
      # application_type
      #   WP-WD : waste producer - water discount
      #   LO-WD : landfill operator - water discount,
      #   LO-RA : landfill operator - restoration agreement
      #   LO-ND : landfill operator - non disposal
      #   LO-WB : landfill operator - weighbridge
      validates :application_type, presence: true, on: :application_type
      # This is the question is this an existing agreement
      # For landfill operator this is the 'is this a review' question
      # For waste producer this is the 'is there an existing water discount' question
      validates :existing_agreement, presence: true, on: :existing_agreement
      validates :previous_case_reference, presence: true, length: { maximum: 30 }, on: :previous_case_reference,
                                          if: :existing_agreement?
      # Waste producer for water discount (for waste producer - water discount and landfill operator - water discount)
      # both the below are Applicants objects
      validates :waste_producer, presence: true, on: :waste_producer, if: :water_discount?
      validates :landfill_operator, presence: true, on: :landfill_operator, if: :not_waste_producer_water_discount?
      # Array of site objects (note has application type and renewal or review copied down)
      validate :validate_sites, on: :added_sites
      validates :supporting_document_other_description, presence: true, length: { maximum: 200 },
                                                        on: :supporting_document_other_description,
                                                        if: :supporting_document_other?
      validates :declaration, acceptance: { accept: ['Y'] }, on: :declaration
      validates :change_declaration, acceptance: { accept: ['Y'] }, on: :declaration,
                                     if: :change_declaration_required?

      validates :declaration_name, presence: true, length: { maximum: 255 }, on: :declaration_name
      validates :declaration_position, presence: true, length: { maximum: 255 }, on: :declaration_position
      validates :declaration_telephone_number, presence: true, phone_number: true, on: :declaration_telephone_number
      validates :declaration_email_address, presence: true, email_address: true, on: :declaration_email_address
      # below are specific to waste producer - water discount
      # renewal or review is a coding list with two options Renewal or Review
      validates :renewal_or_review, presence: true, on: :renewal_or_review, if: :renewal_or_review_mandatory?
      validates :why_water_present, presence: true, on: :why_water_present, if: :waste_producer_water_discount?
      validates :not_banned_waste, acceptance: { accept: ['Y'] }, on: :not_banned_waste,
                                   if: :waste_producer_water_discount?
      # Note this is also asked in some applications at the site level, held in the site model
      validates :type_of_waste_text, presence: true, length: { maximum: 2000 }, on: :type_of_waste_text,
                                     if: :waste_producer_water_discount?
      validates :how_produced, presence: true, length: { maximum: 2000 }, on: :how_produced,
                               if: :waste_producer_water_discount?
      validates :how_added, presence: true, length: { maximum: 2000 }, on: :how_added,
                            if: :waste_producer_water_discount?
      validates :naturally_occurring, presence: true, on: :naturally_occurring, if: :waste_producer_water_discount?
      validates :naturally_occurring_percentage, numericality: { greater_than: 0, less_than: 100,
                                                                 allow_blank: true }, presence: true,
                                                 on: :naturally_occurring_percentage, if: :naturally_occurring?
      validates :waste_percentage, numericality: { greater_than: 0, less_than: 100,
                                                   allow_blank: true }, presence: true, on: :waste_percentage,
                                   if: :waste_producer_water_discount?
      validates :added_water_percentage, numericality: { greater_than: 0, less_than: 100,
                                                         allow_blank: true }, presence: true,
                                         on: :added_water_percentage,
                                         if: :waste_producer_water_discount?
      validates :treatment, presence: true, length: { maximum: 2000 }, on: :treatment,
                            if: :treatment_required?
      validates :reason_for_no_treatment, presence: true, length: { maximum: 2000 }, on: :reason_for_no_treatment,
                                          if: :reason_for_no_treatment_required?
      validates :start_date, presence: true, on: :start_date, if: :start_date_required?

      validate :mandatory_supporting_document_option_selected, on: :supporting_document_list,
                                                               if: :waste_producer_water_discount?

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { applicant_type: comp_key('APPLICANT-TYPE', 'SLFT', 'RSTU'),
          application_type: comp_key('APPLICATION', 'SLFT', 'RSTU'),
          supporting_document_list: comp_key("DOCUMENTS-#{application_type}", 'SLFT', 'RSTU'),
          renewal_or_review: comp_key('RENEWALORREVIEW', 'SYS', 'RSTU'),
          why_water_present: comp_key('WHY-WATER', 'SLFT', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes not to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { existing_agreement: YESNO_COMP_KEY,
          declaration: YESNO_COMP_KEY,
          change_declaration: YESNO_COMP_KEY,
          not_banned_waste: YESNO_COMP_KEY,
          naturally_occurring: YESNO_COMP_KEY }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [print_layout_application,
         print_layout_landfill_operator, print_layout_waste_producer,
         print_layout_waste_water_details, print_layout_banned_from_landfill,
         print_layout_about_the_waste, print_layout_about_water_content, print_layout_water_treatment,
         print_layout_start_date,
         { code: :sites,
           type: :object },
         print_layout_supporting_document,
         print_layout_declaration]
      end

      # is there a previous agreement, and it is WP-WD variant that means
      #     renewal_or_review selection is mandatory
      def renewal_or_review_mandatory?
        existing_agreement? && waste_producer_water_discount?
      end

      # is there naturally occurring water & it's WP-WD variant means that, naturally occurring percentage is required
      def naturally_occurring?
        (naturally_occurring == 'Y' && waste_producer_water_discount?)
      end

      # is there a previous agreement, means that case reference is required
      def existing_agreement?
        (existing_agreement == 'Y')
      end

      # is this a water discount means that a waste producer is required
      def water_discount?
        (application_type == 'LO-WD') || (application_type == 'WP-WD')
      end

      # is this a water producer water discount application
      def waste_producer_water_discount?
        (application_type == 'WP-WD')
      end

      # is this not the water producer water discount application
      def not_waste_producer_water_discount?
        (application_type != 'WP-WD')
      end

      # Is a change declaration also required
      def change_declaration_required?
        (application_type != 'LO-WD')
      end

      # is the supporting document other description required
      def supporting_document_other?
        supporting_document_list.include?('OTHER')
      end

      # Is the start date required
      def start_date_required?
        (application_type == 'WP-WD') && (existing_agreement == 'N' || renewal_or_review == 'REVIEW')
      end

      # This routine validates sites by ensuring sites attribute is not empty and all sites are valid
      def validate_sites
        return errors.add(:base, :missing_sites_entries, link_id: 'add_site') if sites.blank?

        validate_sub_objects(sites, 'edit')
      end

      # This routine validates supporting_document_list first option is accepted for WP-WD variant
      def mandatory_supporting_document_option_selected
        errors.add(:base, :required_for_WP_WD) unless supporting_document_list.include?('DOC1')
      end

      # Does the treatment need to be validated.
      # @return [Boolean] true if reason_for_no_treatment or treatment is filled
      def treatment_required?
        (treatment.present? || reason_for_no_treatment.blank?) && waste_producer_water_discount?
      end

      # Does the reason_for_no_treatment need to be validated
      # @return [Boolean] true if reason_for_no_treatment or treatment is filled
      def reason_for_no_treatment_required?
        (treatment.blank? || reason_for_no_treatment.present?) && waste_producer_water_discount?
      end

      # @return [Array] list of application types excluding 'WP-WD' for landfill operator variant
      def application_type_list
        list_ref_data(:application_type).delete_if { |r| r.code == 'WP-WD' } if @applicant_type == 'LO'
      end

      # Builds and returns the selected supporting_document_list to show on last page
      # @return [Array] the list of selected supporting_documents to upload
      def display_supporting_document_list
        return if application_type == 'LO-WD'

        @display_supporting_document_list = []
        documents_ref_hash = ReferenceData::ReferenceValue.lookup("DOCUMENTS-#{application_type}", 'SLFT', 'RSTU')
        @supporting_document_list.each_with_index do |checked_code, index|
          # @supporting_document_list always contains 0th element '' so ignore 0th element
          next if checked_code == ''

          documents_ref_hash[checked_code].code = index
          documents_ref_hash[checked_code].value = @supporting_document_other_description if checked_code == 'OTHER'

          @display_supporting_document_list << documents_ref_hash[checked_code]
        end
        @display_supporting_document_list
      end

      # store individual document to back office
      def add_supporting_document(supporting_document)
        doc_refno = ''
        success = call_ok?(:add_document, request_supporting_document_elements(supporting_document)) do |response|
          break if response.blank?

          doc_refno = response[:doc_refno]
        end
        [success, doc_refno]
      end

      # delete support document from back-office
      # @param doc_refno [String] support document reference number to be delete from back-office
      # @return [Boolean] true if support document delete successfully from back-office else false
      def delete_supporting_document(doc_refno)
        call_ok?(:delete_document, request_delete_supporting_document_elements(doc_refno))
      end

      # Gets the all the data regarding the version and CaseRefno and CaseReference of a application,
      #  which will be used for downloading as a pdf file.
      # @return [Array] consists of [Boolean, Hash] the Boolean value is used to check if the call was successful and
      #   the Hash consists of data regarding the pdf to be downloaded.
      def back_office_pdf_data
        pdf_response = ''
        success = call_ok?(:view_case_pdf, request_pdf_elements) do |body|
          break if body.blank?

          pdf_response = body
        end

        [success, pdf_response]
      end

      # Checks whether a save can be done by checking the validations
      def save
        call_ok?(:slft_application, request_save) do |body|
          convert_back_office_hash(body)
        end
      end

      # Gets the all cases from the back office and
      # @return [Hash] a hash of all case_references and case_ref_nos from the back office
      def convert_back_office_hash(body)
        @case_references = []
        @case_ref_nos = []
        ServiceClient.iterate_element(body[:application_cases]) do |cases|
          @case_references.push(cases[:case_reference])
          @case_ref_nos.push(cases[:case_refno])
        end
      end

      # Dynamically returns the translation key based on the translation_options provided by the page if it exists
      # @param attribute [Symbol] the name of the attribute to translate
      # @return [Symbol] "attribute_" + extra information to make the translation key
      def translation_attribute(attribute, _translation_options = nil)
        return "#{attribute}_#{applicant_type}".to_sym if %i[existing_agreement
                                                             previous_case_reference].include?(attribute)

        return "#{attribute}_#{application_type}".to_sym if attribute == :declaration

        attribute
      end

      private

      # @return [Hash] elements used to specify what data we want to send to the back office
      def request_save
        output = { Role: @applicant_type,
                   Form: @application_type }

        # Assume new if blank
        output[:Type] = type_element
        output[:PreAgreementNumber] = @previous_case_reference if existing_agreement?

        output[:WPDetails] = request_waste_producer

        output.merge!(request_sites)

        output[:LandfillOp] = request_landfill_operator

        output[:Declaration] = request_declaration
        output[:Application] = { 'ins1:PrintData': print_data(:print_layout) }

        output
      end

      # Derive the value for the type element sent to the back office
      # This is new or review, waste producer water discount may also return renewal
      # @return [String] New/Review/Renewal as appropriated
      def type_element
        # Always new unless there is an existing agreement
        return 'New' unless existing_agreement?

        # Always review if there is an existing agreement except for a waste producer water discount
        return lookup_ref_data_value(:renewal_or_review, 'REVIEW') if not_waste_producer_water_discount?

        # Return the renewal or review flag for the waste producer water discount
        lookup_ref_data_value(:renewal_or_review)
      end

      # @return a hash suitable for use in a add supporting_document to the back office
      def request_supporting_document_elements(supporting_document)
        add_attachment_request = request_user_instance
        add_attachment_request.merge!('ins1:FileName': supporting_document.original_filename,
                                      'ins1:FileType': supporting_document.content_type,
                                      'ins1:Description': supporting_document.description,
                                      'ins1:BinaryData': Base64.encode64(supporting_document.file_data))
      end

      # @return a hash suitable for use in all message request
      def request_user_instance
        # We record documents against the first case reference returned even if there are multiples
        { 'ins1:Authenticated': 'no', 'ins1:ObjectRefno': @case_references.join(','), 'ins1:ObjectType': 'CASE',
          'ins1:DocumentType': 'APPDOC' }
      end

      # @return a hash suitable for use in a delete support document to the back office
      def request_delete_supporting_document_elements(doc_refno)
        request_user_instance.merge!('ins1:DocRefNo': doc_refno.to_i)
      end

      # @return a hash suitable for use in download pdf request to the back office
      def request_pdf_elements
        # One submission may create more than one case but the PDF is the same for all so just pick the first one
        { Authenticated: 'no', 'ins1:CaseRefno': @case_ref_nos[0], 'ins1:CaseReference': @case_references[0] }
      end

      # @return [Hash] of waste producer details
      def request_waste_producer
        return if waste_producer.nil?

        { 'ins1:OrganisationName': waste_producer.organisation_name,
          'ins1:TelephoneNumber': waste_producer.telephone_number,
          'ins1:EmailAddress': waste_producer.email_address,
          'ins1:ContactAddress': waste_producer.address.format_to_back_office_address }
      end

      # @return [Hash] of added all sites and their details
      def request_sites
        { Sites: { 'ins1:Site':
          sites.map { |site| request_site(site) } } }
      end

      # @return [Hash] of added individual site details
      def request_site(site)
        { 'ins1:SEPALicenseNumber': site.sepa_license_number,
          'ins1:SiteName': site.site_name,
          'ins1:LandfillOpName': site.landfill_operator,
          'ins1:LandfillOpRegNumber': site.slft_registration_number,
          'ins1:SiteAddress': site.address.format_to_back_office_address }
      end

      # @return [Hash] of landfill operator details
      def request_landfill_operator
        return if landfill_operator.nil?

        { 'ins1:LandfillOpName': landfill_operator.organisation_name,
          'ins1:LandfillOpRegNumber': landfill_operator.slft_registration_number,
          'ins1:LandfillOpPhoneNumber': landfill_operator.telephone_number,
          'ins1:LandfillOpEmail': landfill_operator.email_address,
          'ins1:LandfillOpAddress': landfill_operator.address.format_to_back_office_address }
      end

      # @return [Hash] elements used to specify the declaration details data we want to send to the back office
      def request_declaration
        { 'ins1:Agreed': (declaration == 'Y'),
          'ins1:Name': declaration_name,
          'ins1:Position': declaration_position,
          'ins1:Telephone': declaration_telephone_number,
          'ins1:EmailAddress': declaration_email_address }
      end

      # layout for the application type
      def print_layout_application
        { code: :application_type, # section code
          key: :pdf_title, # key for the title translation
          key_scope: %i[applications slft application_type], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: print_layout_application_type_list_items }
      end

      # layout for the existing agreement
      def print_layout_application_type_list_items
        [{ code: :case_reference, placeholder: '<%CASE_REFERENCE%>' },
         { code: :applicant_type, lookup: true },
         { code: :application_type, lookup: true },
         { code: :existing_agreement, lookup: true },
         { code: :renewal_or_review, lookup: true, when: :renewal_or_review_mandatory?, is: [true] },
         { code: :previous_case_reference, when: :existing_agreement?, is: [true] }]
      end

      # layout for the landfill_operator details
      def print_layout_landfill_operator
        return if waste_producer_water_discount?

        { code: :landfill_operator,
          type: :object }
      end

      # layout for the waste_producer details
      def print_layout_waste_producer
        return unless water_discount?

        { code: :waste_producer,
          type: :object }
      end

      # layout for the supporting document
      def print_layout_supporting_document
        return if application_type == 'LO-WD'

        { code: :supporting_documents, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft supporting_documents], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :supporting_document_list, lookup: true, format: :list }] }
      end

      # layout about waste water details
      def print_layout_waste_water_details
        return if not_waste_producer_water_discount?

        { code: :about_waste_water, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft about_waste_water], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :why_water_present, lookup: true }] }
      end

      # layout for the banned from landfill details
      def print_layout_banned_from_landfill
        return if not_waste_producer_water_discount?

        { code: :banned_from_landfill, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft banned_from_landfill], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :not_banned_waste, lookup: true }] }
      end

      # layout about the waste details
      def print_layout_about_the_waste
        return if not_waste_producer_water_discount?

        { code: :about_the_waste, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft about_the_waste], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :type_of_waste_text },
                       { code: :how_produced },
                       { code: :how_added }] }
      end

      # layout about the waste details
      def print_layout_about_water_content
        return if not_waste_producer_water_discount?

        { code: :about_water_content, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft about_water_content], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: print_layout_water_content_list_items }
      end

      # fields for the water content
      def print_layout_water_content_list_items
        [{ code: :naturally_occurring, lookup: true },
         { code: :naturally_occurring_percentage, when: :naturally_occurring?, is: [true] },
         { code: :waste_percentage },
         { code: :added_water_percentage }]
      end

      # layout about the water treatment
      def print_layout_water_treatment
        return if not_waste_producer_water_discount?

        { code: :water_treatment, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft water_treatment], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :treatment },
                       { code: :reason_for_no_treatment }] }
      end

      # layout about the date details
      def print_layout_start_date
        return if not_waste_producer_water_discount?

        { code: :start_date, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft start_date], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: [{ code: :start_date, format: :date }] }
      end

      # layout for the declaration
      def print_layout_declaration
        { code: :declaration, # section code
          key: :title, # key for the title translation
          key_scope: %i[applications slft declaration], # scope for the title translation
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list, # type list = the list of attributes to follow
          list_items: print_layout_declaration_list_items }
      end

      # fields for the declaration
      def print_layout_declaration_list_items
        [{ code: :declaration, lookup: true },
         { code: :change_declaration, lookup: true },
         { code: :declaration_name },
         { code: :declaration_position },
         { code: :declaration_telephone_number },
         { code: :declaration_email_address }]
      end
    end
  end
end
