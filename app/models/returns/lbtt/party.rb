# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # A party represents someone associated with particular land property transaction.
    # They may include buyer seller or agent.
    # Every tax return should have information about all the involved party members.
    class Party < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData

      # Attributes for this class in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[
          party_id title surname firstname telephone email_address nino alrt_type ref_country return_reference
          charity_number party_type type address is_contact_address_different contact_address
          alrt_reference buyer_seller_linked_ind buyer_seller_linked_desc
          company_number country_registered_company_outside_uk address_outside_uk contact_par_ref_no
          org_name job_title company org_type other_type_description
          contact_surname contact_firstname org_contact_address is_acting_as_trustee agent_dx_number
          contact_email contact_tel_no com_jurisdiction agent_reference same_address
          party_refno authority_date hash_for_nino used_address_list pre_populated
        ]
      end

      attribute_list.each { |attr| attr_accessor attr }

      validates :type, presence: true, on: :type
      validates :title, InReferenceValues: true, if: :individual?
      validates :surname, presence: true, length: { maximum: 100 }, on: :surname, if: :individual?
      validates :firstname, presence: true, length: { maximum: 50 }, on: :firstname, if: :individual?
      validates :agent_dx_number, length: { maximum: 100 }, on: %i[title]
      validates :agent_reference, length: { maximum: 30 }, on: %i[title]

      # For a party not on a claim both email address and telephone number are mandatory for individuals
      # Unless they are the seller type
      validates :email_address, presence: true, on: :email_address,
                                if: :individual_but_not_claim_seller_landlord_newtenant?
      validates :telephone, presence: true, on: :telephone,
                            if: :individual_but_not_claim_seller_landlord_newtenant?
      # For a claim one must be provided
      validate :contact_details_present, on: :email_address, if: :claim?
      # format must always be correct
      validates :email_address, email_address: true, on: :email_address,
                                if: :individual_but_not_seller_landlord_newtenant?
      validates :telephone, phone_number: true, on: :telephone, if: :individual_but_not_seller_landlord_newtenant?

      validates :buyer_seller_linked_ind, presence: true, on: :buyer_seller_linked_ind,
                                          if: proc { |p| %w[SELLER LANDLORD].exclude?(p.party_type) }
      validates :buyer_seller_linked_desc, presence: true, length: { maximum: 255 }, on: :buyer_seller_linked_ind,
                                           if: :buyer_seller_linked_desc_required?
      validates :is_contact_address_different, presence: true, on: :is_contact_address_different,
                                               if: :individual_but_not_seller_landlord?
      validates :org_type, presence: true, on: :org_type, if: proc { |p| p.type == 'OTHERORG' }
      validates :other_type_description, presence: true, length: { maximum: 255 },
                                         on: :org_type, if: proc { |w| w.org_type == 'OTHER' }
      validates :com_jurisdiction, presence: true, InReferenceValues: true, length: { maximum: 255 }, on: :org_name,
                                   if: proc { |p| p.type == 'OTHERORG' }
      # The party is used in both lbtt party and also in claim. The org_name is required in lbtt party but it is
      # optional in the claim flow. So this should only trigger for the lbtt party flow.
      validates :org_name, presence: true, on: :org_name, if: proc { |p| p.type == 'OTHERORG' }
      # This is the common validation for botht he lbtt and claim flow.
      validates :org_name, length: { maximum: 200 }, on: :org_name, if: proc { |p| p.type == 'OTHERORG' || p.claim? }
      validates :charity_number, presence: true, length: { maximum: 100 },
                                 on: :org_name, if: proc { |w| w.org_type == 'CHARITY' }

      validates :job_title, presence: true, length: { maximum: 255 },
                            on: :contact_firstname, if: :not_private_and_not_seller_landlord?
      validates :contact_firstname, presence: true, length: { maximum: 50 },
                                    on: :contact_firstname,
                                    if: :not_private_and_not_seller_landlord?
      validates :contact_surname, presence: true, length: { maximum: 100 },
                                  on: :contact_firstname,
                                  if: :not_private_and_not_seller_landlord?
      validates :contact_tel_no, presence: true,
                                 on: :contact_firstname,
                                 if: :not_private_and_not_seller_landlord?
      validates :contact_email, presence: true, email_address: true, on: :contact_firstname,
                                if: :not_private_and_not_seller_landlord?
      validates :contact_tel_no, on: :contact_firstname, phone_number: true, if: :not_private_and_not_seller_landlord?

      validates :is_acting_as_trustee, presence: true, on: :is_acting_as_trustee,
                                       if: proc { |p| %w[SELLER LANDLORD].exclude?(p.party_type) }
      # National insurance number and alternate related validation
      validate :nino_or_alternate_is_present, on: :nino, if: :individual_but_not_seller_landlord_newtenant?
      validate :both_nino_and_alternate_are_present, on: :nino
      validates :nino, nino: true, on: :nino, if: :individual_but_not_seller_landlord_newtenant?
      validates :alrt_type, :ref_country, presence: true, InReferenceValues: true, on: :alrt_type,
                                          if: :incomplete_alternate?
      validates :alrt_reference, presence: true, length: { maximum: 30 }, on: :alrt_type, if: :incomplete_alternate?

      # HACK: The conditions here are copying the #request_save method - they should use the same methods
      validates :contact_address, presence: true, on: :contact_address,
                                  if: proc { |p|
                                    p.lplt_type == 'PRIVATE' && p.party_type != 'AGENT' && p.contact_address_different?
                                  }
      validates :org_contact_address, presence: true, on: :org_contact_address,
                                      if: proc { |p|
                                        p.lplt_type != 'PRIVATE' && %w[LANDLORD SELLER].exclude?(p.party_type)
                                      }
      validate :validation_for_duplicate_nino, on: :nino, if: :individual_but_not_seller_landlord_newtenant?
      validates :same_address, presence: true, on: :same_address, if: :claim?

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { alrt_type: comp_key('PARALTREFTYPES', 'LBTT', 'RSTU'), ref_country: comp_key('COUNTRIES', 'SYS', 'RSTU'),
          title: comp_key('TITLES', 'SYS', 'RSTU'), type: comp_key('BUYER TYPES', 'SYS', 'RSTU'),
          org_type: comp_key('ORGANISATION TYPE', 'SYS', 'RSTU'),
          com_jurisdiction: comp_key('COUNTRIES', 'SYS', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes not cached in this model
      # long lists or special yes no case
      def uncached_ref_data_codes
        { is_contact_address_different: YESNO_COMP_KEY,
          buyer_seller_linked_ind: YESNO_COMP_KEY,
          is_acting_as_trustee: YESNO_COMP_KEY,
          same_address: YESNO_COMP_KEY }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable  Metrics/MethodLength
        [{ code: :agent_details, # section code
           parent_codes: [:agent],
           divider: true, # should we have a section divider
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_agent agent_details], # scope for the title translation
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :title, lookup: true },
                        { code: :firstname },
                        { code: :surname },
                        { code: :agent_reference },
                        { code: :agent_dx_number },
                        { code: :telephone },
                        { code: :email_address }] },
         { code: :address,
           parent_codes: [:agent],
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_agent agent_address], # scope for the title translation
           type: :object },
         { code: :company,
           parent_codes: %i[buyers sellers tenants landlords new_tenants],
           when: :type,
           is: ['REG_COM'],
           key_value: :party_type,
           key: '#key_value#_title', # key for the title translation
           key_scope: %i[returns lbtt_parties about_the_party], # scope for the title translation
           name: { code: :type, lookup: true },
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :object },
         { code: :organisation_type_details,
           parent_codes: %i[buyers sellers tenants landlords new_tenants],
           when: :type,
           is: ['OTHERORG'],
           key_value: :party_type,
           key: '#key_value#_title', # key for the title translation
           key_scope: %i[returns lbtt_parties about_the_party], # scope for the title translation
           name: { code: :type, lookup: true },
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :org_type, lookup: true },
                        { code: :other_type_description, when: :org_type, is: ['OTHER'] }] },
         { code: :organisation_details,
           parent_codes: %i[buyers sellers tenants landlords new_tenants],
           when: :type,
           is: ['OTHERORG'],
           key_value: :org_type,
           key: '#key_value#_title', # key for the title translation
           key_scope: %i[returns lbtt_parties organisation_details], # scope for the title translation
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :org_name },
                        { code: :charity_number, when: :org_type, is: ['CHARITY'] },
                        { code: :com_jurisdiction, lookup: true }] },
         # organisation address
         { code: :address,
           parent_codes: %i[buyers sellers tenants landlords new_tenants],
           when: :type,
           is: ['OTHERORG'],
           type: :object },
         { code: :representative_contact_details,
           parent_codes: %i[buyers sellers tenants landlords new_tenants],
           when: :type,
           is: %w[OTHERORG REG_COM],
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_parties representative_contact_details], # scope for the title translation
           display_title: false, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :contact_firstname },
                        { code: :contact_surname },
                        { code: :job_title },
                        { code: :contact_email },
                        { code: :contact_tel_no }] },
         # representative contact address
         { code: :org_contact_address,
           parent_codes: %i[buyers sellers tenants landlords new_tenants],
           when: :type,
           is: %w[OTHERORG REG_COM],
           type: :object },
         print_layout_taxpayer_details,
         print_layout_taxpayer_alternate_address,
         print_layout_taxpayer_address,
         { code: :buyer_details,
           parent_codes: %i[buyers sellers tenants landlords new_tenants taxpayers],
           when: :type,
           is: ['PRIVATE'],
           key_value: :party_type,
           key: '#key_value#_title', # key for the title translation
           key_scope: %i[returns lbtt_parties about_the_party], # scope for the title translation
           name: { code: :type, lookup: true },
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :title, lookup: true },
                        { code: :firstname },
                        { code: :surname },
                        { code: :telephone, when: :party_type, is_not: %w[LANDLORD SELLER] },
                        { code: :email_address, when: :party_type, is_not: %w[LANDLORD SELLER] },
                        { code: :nino, when: :party_type, is_not: %w[LANDLORD SELLER] },
                        { code: :alrt_type, lookup: true, when: :party_type, is_not: %w[LANDLORD SELLER] },
                        { code: :ref_country, lookup: true, when: :party_type, is_not: %w[LANDLORD SELLER] },
                        { code: :alrt_reference, when: :party_type, is_not: %w[LANDLORD SELLER] }] },
         { code: :address,
           parent_codes: %i[buyers sellers tenants landlords new_tenants],
           when: :type,
           is: ['PRIVATE'],
           key_value: :party_type,
           key: '#key_value#_title', # key for the title translation
           key_scope: %i[returns lbtt_parties party_address], # scope for the title translation
           type: :object },
         { code: :buyer_alternate_address,
           parent_codes: %i[buyers tenants],
           when: :type,
           is: ['PRIVATE'],
           key_value: :party_type,
           key: '#key_value#_title', # key for the title translation
           key_scope: %i[returns lbtt_parties party_alternate_address], # scope for the title translation
           type: :list,
           list_items: [{ code: :is_contact_address_different, lookup: true }] },
         { code: :contact_address,
           parent_codes: %i[buyers tenants],
           when: :is_contact_address_different,
           is: ['Y'],
           type: :object },
         { code: :buyer_relation,
           parent_codes: %i[buyers tenants],
           key_value: :party_type,
           key: '#key_value#_title', # key for the title translation
           key_scope: %i[returns lbtt_parties parties_relation], # scope for the title translation
           display_title: false, # Is the title to be displayed
           type: :list,
           list_items: [{ code: :buyer_seller_linked_ind, lookup: true },
                        { code: :buyer_seller_linked_desc, when: :buyer_seller_linked_desc_required?, is: [true] },
                        { code: :is_acting_as_trustee, lookup: true }] }]
      end

      # layout for the taxpayer details of the print data of claim
      def print_layout_taxpayer_details
        { code: :taxpayer_details,
          parent_codes: %i[taxpayers],
          key_value: :party_type,
          key: '#key_value#_title',
          key_scope: %i[claim claim_payments taxpayer_details],
          divider: true, # should we have a section divider
          display_title: true, # Is the title to be displayed
          type: :list,
          list_items: print_layout_taxpayer_details_list_item }
      end

      # fields for the taxpayer details
      def print_layout_taxpayer_details_list_item
        [{ code: :firstname },
         { code: :surname },
         { code: :telephone },
         { code: :email_address }]
      end

      # layout for the taxpayer alternate address of the print data of claim
      def print_layout_taxpayer_alternate_address
        { code: :taxpayer_alternate_address,
          parent_codes: %i[taxpayers],
          key_value: :party_type,
          key: '#key_value#_title',
          key_scope: %i[claim claim_payments taxpayer_address], # scope for the title translation
          type: :list,
          list_items: [{ code: :same_address, lookup: true, when: :object_index, is_not: [0] }] }
      end

      # layout for the taxpayer address of the print data of claim
      def print_layout_taxpayer_address
        { code: :address,
          parent_codes: %i[taxpayers],
          key_value: :party_type,
          key: '#key_value#_title',
          key_scope: %i[claim claim_payments taxpayer_address], # scope for the title translation
          type: :object }
      end

      # Layout to print the receipt data in this model
      def print_layout_receipt
        [{ code: :party_details,
           divider: true, # should we have a section divider
           display_title: false, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :full_name, when: :party_type, is_not: ['AGENT'] },
                        { code: :agent_reference, when: :party_type, is: ['AGENT'],
                          action_name: :receipt }] }]
      end

      # National insurance number and alternate related validation
      # No nino or alternate data is provided.
      def nino_or_alternate_is_present
        return unless nino.blank? && alrt_type.blank? && ref_country.blank? && alrt_reference.blank?

        errors.add(:nino, :no_nino_or_alternate)
      end

      # National insurance number and alternate related validation
      # No nino or alternate data is provided.
      def both_nino_and_alternate_are_present
        return unless nino.present? && (alrt_type.present? || ref_country.present? || alrt_reference.present?)

        errors.add(:nino, :both_nino_and_alternate)
      end

      # Validation for NINO if same NINO used more than once.
      def validation_for_duplicate_nino
        return if nino.blank? || hash_for_nino.blank?

        nino_items = hash_for_nino.select { |u| u == nino }
        # we get the party_name at the index[1] & get the party_id at the index[0]
        errors.add(:nino, :duplicate_nino, party_name: nino_items.values[0][1]) if nino_items.present?
      end

      # Validate that at least one of the contact details is supplied.
      def contact_details_present
        return if email_address.present? || telephone.present?

        errors.add(:telephone, :no_contact_details)
      end

      # If the key alternate data has been started but not completed.
      # Only used for validating the nino and it's alternate related fields.
      def incomplete_alternate?
        # This converts to !alrt_type.blank? || !alrt_reference.blank? || !ref_country.blank?
        !(alrt_type.blank? && alrt_reference.blank? && ref_country.blank?) &&
          lplt_type == 'PRIVATE' && @party_type != 'AGENT'
      end

      # return true if contact address is different
      def contact_address_different?
        @is_contact_address_different == 'Y'
      end

      # return true if party type is agent or type is private individual and not seller or landlord
      def individual_but_not_seller_landlord?
        individual? && %w[SELLER LANDLORD].exclude?(party_type)
      end

      # return true if party type is agent or type is private individual and not seller or landlord or NEWTENANT
      def individual_but_not_seller_landlord_newtenant?
        individual? && %w[SELLER LANDLORD NEWTENANT].exclude?(party_type)
      end

      # return true if party type is agent or type is private individual and not seller or landlord or NEWTENANT
      def individual_but_not_claim_seller_landlord_newtenant?
        return false if claim?

        individual_but_not_seller_landlord_newtenant?
      end

      # validation method
      def not_private_and_not_seller_landlord?
        type != 'PRIVATE' && %w[SELLER LANDLORD].exclude?(party_type)
      end

      # return true if party is private individual or agent or party added while filling Claim
      def individual?
        type == 'PRIVATE' || party_type == 'AGENT' || claim?
      end

      # return true if party added while filling Claim
      def claim?
        %w[CLAIMANT UNAUTH_CLAIMANT].include?(party_type)
      end

      # validate the buyer_seller_linked_desc
      def buyer_seller_linked_desc_required?
        @buyer_seller_linked_ind == 'Y'
      end

      # Retrieve agent details from account to prepoulate on summary page
      # Note the party type needs to be set before calling this routine
      # this is not the account type from the back office as we are always creating an agent for the return
      def populate_from_account(account)
        # retrieve user personal details from account
        user = account.current_user
        @firstname = user.forename
        @surname = user.surname
        @email_address = user.email_address
        @telephone = account.contact_number

        # retrieve address from account
        @address = account.address
      end

      # Overrides the param value passed into the id of the path when the instance of the object is used
      # as the parameter value of a path.
      # This will be the :party_id of the returns_lbtt_about_the_party_path or returns_lbtt_party_delete_path.
      def to_param
        @party_id
      end

      # Remove any spaces from the provided nino value
      def nino=(value)
        @nino = value&.delete(' ')
      end

      # @return [String] the formatted name of the party.
      def full_name
        # @note the .strip method removes all leading and trailing whitespaces
        return [lookup_ref_data_value(:title), firstname, surname].join(' ').strip if individual?
        return company.company_name if type == 'REG_COM'

        org_name
      end

      # Custom getter to return the agent reference or text saying not provided
      # @return [String] the formatted name of the party.
      def agent_reference_or_not_provided
        return @agent_reference if @agent_reference.present?

        I18n.t('.none_provided')
      end

      # return unique information about party while displaying error for section
      # see @LbttReturnValidator
      def key_info
        full_name.to_s
      end

      # @return [String] the type of the party as a displayable string
      def display_type
        return lookup_ref_data_value(:org_type) if type == 'OTHERORG'

        lookup_ref_data_value(:type)
      end

      # @return [String] the address of the party as a displayable string
      def display_address
        return company.short_address if type == 'REG_COM'

        address&.short_address
      end

      # @return [String] the location of this party type in the lbtt return
      def lbtt_return_attribute
        "#{@party_type.downcase}s" == 'newtenants' ? 'new_tenants' : "#{@party_type.downcase}s"
      end

      # Returns a translation attribute where a given attribute may have more than one name based on e.g. a type
      # it also allows for a different attribute name for the error region for e.g. long labels
      # @param attribute [Symbol] the name of the attribute to translate
      # @param _translation_options [Object] extra information passed from the page or the print layout
      # @return [Symbol] the name of the translation attribute
      def translation_attribute(attribute, _translation_options = nil)
        return :registered_company_name if attribute == :org_name && type == 'REG_COM'

        return translation_attribute_full_name if attribute == :full_name

        return translation_for_claim(attribute) if claim?

        return translation_attribute_for_party_type(attribute) if translate_party_type?(attribute)

        attribute
      end

      # @return [Boolean] to decide whether to invoke translation_attribute_for_party_type method or not
      def translate_party_type?(attribute)
        %i[is_acting_as_trustee type buyer_seller_linked_ind].include?(attribute) && !party_type.nil?
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save(authority_ind) # rubocop:disable  Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        output = { 'ins0:PartyType': lplt_type == 'PRIVATE' ? 'PER' : 'ORG' }
        output['ins0:LpltType'] = lplt_type # Buyer Type
        output['ins0:OtherTypeDescription'] = other_type_description if other_type_description.present?
        output['ins0:FlptType'] = flpt_type # Party Type
        output['ins0:ParRefno'] = @party_refno if @party_refno.present?
        if individual?
          output['ins0:PersonName'] = { 'ins0:Title': @title,
                                        'ins0:Forename': @firstname,
                                        'ins0:Surname': @surname }
        elsif type == 'REG_COM'
          # currently back-office wsdl not having fields to send company details separately
          # e.g  "company"=>{"company_number"=>"03390089", "company_name"=>"COMPANY NUMBER 03390089 LTD",
          # "address_line1"=>"First Floor", "address_line2"=>"73-75 High Street", "locality"=>"Stevenage",
          # "county"=>"Hertfordshire", "postcode"=>"SG1 3HR", "country"=>"GB"}
          # so spliting company details into fields company name, address, company number
          output['ins0:ComCompanyName'] = @company.company_name if @company.company_name.present?
          output['ins0:ComRegno'] = @company.company_number if @company.company_number.present?

          output['ins0:Address'] = @company.company_address.format_to_back_office_address
        else
          output['ins0:ComCompanyName'] = @org_name if @org_name.present?
          output['ins0:ComJurisdiction'] = @com_jurisdiction if @com_jurisdiction.present?
        end
        output['ins0:Address'] = @address.format_to_back_office_address if @address.present?

        output['ins0:AgentDxNumber'] = @agent_dx_number if @agent_dx_number.present?
        output['ins0:AuthorityInd'] = @party_type == 'AGENT' && authority_ind == 'Y' ? 'yes' : 'no'
        output['ins0:TelNo'] = @telephone if @telephone.present?
        output['ins0:EmailAddress'] = @email_address if @email_address.present?

        output['ins0:CharityNumber'] = @charity_number if @org_type == 'CHARITY'
        if lplt_type == 'PRIVATE'
          output['ins0:ParPerNiNo'] = @nino if @nino.present?
          unless @party_type == 'AGENT'
            output['ins0:AlternateReference'] = { 'ins0:AlrtType': @alrt_type,
                                                  'ins0:RefCountry': @ref_country,
                                                  'ins0:Reference': @alrt_reference }.compact

            output.delete('ins0:AlternateReference') if output['ins0:AlternateReference'].blank?
            output['ins0:ContactAddress'] = @contact_address.format_to_back_office_address if contact_address_different?
          end
        else
          output['ins0:ContactTelNo'] = @telephone if output['ins0:ContactTelNo'].present?
          output['ins0:ContactEmailAddress'] = @email_address if output['ins0:ContactEmailAddress'].present?

          unless %w[LANDLORD SELLER].include? @party_type
            output['ins0:OrganisationContact'] = {
              'ins0:ContactParRefno': @contact_par_ref_no,
              'ins0:ContactJobTitle': @job_title,
              'ins0:ContactForename': @contact_firstname,
              'ins0:ContactSurname': @contact_surname,
              'ins0:ContactAddress': @org_contact_address&.format_to_back_office_address,
              'ins0:ContactTelNo': @contact_tel_no,
              'ins0:ContactEmailAddress': @contact_email
            }.compact
          end
        end
        output['ins0:BuyerSellerLinkedInd'] = convert_to_backoffice_yes_no_value(@buyer_seller_linked_ind)
        output['ins0:BuyerSellerLinkedDesc'] = @buyer_seller_linked_desc if @buyer_seller_linked_ind == 'Y'
        output['ins0:ActingAsTrusteeInd'] = convert_to_backoffice_yes_no_value(@is_acting_as_trustee)
        output['ins0:Prepopulated'] = convert_to_backoffice_yes_no_value(@pre_populated) if pre_populated?
        output
      end

      # returns true if the party has been pre populated
      def pre_populated?
        @pre_populated == 'Y'
      end

      # converts buyer type into wsdl acceptable format
      def lplt_type
        if individual?
          'PRIVATE'
        elsif type == 'REG_COM'
          'REG_COM'
        else
          @org_type
        end
      end

      # In case of lease return back_office expecting flpt type as buyer and seller
      def flpt_type
        case @party_type
        when 'TENANT'
          'BUYER'
        when 'LANDLORD'
          'SELLER'
        else
          @party_type
        end
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(raw_hash, lbtt_return_type, agent_ref) # rubocop:disable  Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        convert_lplt_type(raw_hash)
        raw_hash.delete(:party_type)

        raw_hash[:party_type] = convert_flpt_type(raw_hash[:flpt_type], lbtt_return_type)
        raw_hash[:party_refno] = raw_hash.delete(:par_refno)

        if raw_hash.key?(:person_name)
          raw_hash[:title] = raw_hash[:person_name][:title]
          raw_hash[:firstname] = raw_hash[:person_name][:forename]
          raw_hash[:surname] = raw_hash[:person_name][:surname]
          unless raw_hash[:contact_address].nil?
            raw_hash[:contact_address] = Address.convert_hash_to_address(raw_hash[:contact_address])
          end
        end
        raw_hash[:agent_reference] = agent_ref if raw_hash[:party_type] == 'AGENT' && agent_ref.present?
        raw_hash[:org_name] = raw_hash.delete(:com_company_name) if raw_hash.key?(:com_company_name)

        raw_hash[:address] = Address.convert_hash_to_address(raw_hash[:address]) unless raw_hash[:address].nil?

        raw_hash[:company] = Company.convert_hash_to_company(raw_hash) if raw_hash[:type] == 'REG_COM'

        raw_hash[:telephone] = raw_hash.delete(:tel_no)

        raw_hash[:nino] = raw_hash.delete(:par_per_ni_no) if raw_hash.key?(:par_per_ni_no)

        if raw_hash.key?(:alternate_reference)
          raw_hash[:alrt_type] = raw_hash[:alternate_reference][:alrt_type]
          raw_hash[:ref_country] = raw_hash[:alternate_reference][:ref_country]
          raw_hash[:alrt_reference] = raw_hash[:alternate_reference][:reference]
        end

        raw_hash[:telephone] = raw_hash.delete(:contact_tel_no) if raw_hash.key?(:contact_tel_no)
        raw_hash[:email_address] = raw_hash.delete(:contact_email_address) if raw_hash.key?(:contact_email_address)

        if raw_hash.key?(:organisation_contact)
          raw_hash[:contact_par_ref_no] = raw_hash[:organisation_contact][:contact_par_ref_no]
          raw_hash[:job_title] = raw_hash[:organisation_contact][:contact_job_title]
          raw_hash[:contact_firstname] = raw_hash[:organisation_contact][:contact_forename]
          raw_hash[:contact_surname] = raw_hash[:organisation_contact][:contact_surname]
          if raw_hash[:organisation_contact][:contact_address].present?
            address_raw_hash = raw_hash[:organisation_contact][:contact_address]
            raw_hash[:org_contact_address] = Address.convert_hash_to_address(address_raw_hash)
          end
          raw_hash[:contact_tel_no] = raw_hash[:organisation_contact][:contact_tel_no]
          raw_hash[:contact_email] = raw_hash[:organisation_contact][:contact_email_address]
        end

        raw_hash[:is_acting_as_trustee] = raw_hash.delete(:acting_as_trustee_ind)
        raw_hash[:pre_populated] = raw_hash.delete(:prepopulated)

        # strip out attributes we don't want yet
        delete = %i[lplt_type flpt_type person_name alternate_reference authority_ind organisation_contact]
        delete.each { |key| raw_hash.delete(key) }

        # convert back office yes/no to Y/N
        yes_nos_to_yns(raw_hash, %i[buyer_seller_linked_ind is_acting_as_trustee pre_populated])

        # derive yes no based on the data now that we've finished moving it around
        derive_yes_nos_in(raw_hash)

        raw_hash[:party_id] = SecureRandom.uuid

        # Create new instance
        Party.new_from_fl(raw_hash)
      end

      # Set attributes which depend on some other attributes received from back-office
      private_class_method def self.derive_yes_nos_in(party)
        party[:is_contact_address_different] = derive_yes_no(value: party[:contact_address])
      end

      # convert to proper type like PRIVATE,CHARITY etc
      def self.convert_lplt_type(output)
        if output[:party_type] == 'PER' || output[:lplt_type] == 'REG_COM'
          output[:type] = output[:lplt_type]
        else
          output[:type] = 'OTHERORG'
          output[:org_type] = output[:lplt_type]
        end
        output
      end

      # Convert if return type is lease return flpt type from BUYER, SELLER to TENANT,LANDLORD
      def self.convert_flpt_type(flpt_type, lbtt_return_type)
        if lbtt_return_type != 'CONVEY' && flpt_type == 'BUYER'
          'TENANT'
        elsif lbtt_return_type != 'CONVEY' && flpt_type == 'SELLER'
          'LANDLORD'
        else
          flpt_type
        end
      end

      private

      # Convert the full name to get translation
      def translation_attribute_full_name
        :"#{party_type}_full_name"
      end

      # handle the translations based on party type which may be nil
      def translation_attribute_for_party_type(attribute)
        return :"type_#{party_type}" if attribute == :type
        return :"is_acting_as_trustee_#{party_type}" if attribute == :is_acting_as_trustee
        return :"#{party_type}_buyer_seller_linked_ind" if attribute == :buyer_seller_linked_ind

        attribute
      end

      # Dynamically returns the translation key based on the translation_options provided by the page if it exists
      # @param attribute [Symbol] the name of the attribute to translate
      def translation_for_claim(attribute)
        acc_type = (party_type == 'UNAUTH_CLAIMANT' ? 'UNAUTHENTICATED' : 'AUTHENTICATED')
        return :"#{acc_type}_#{attribute}" if %i[telephone email_address same_address].include?(attribute)

        return :claim_org_name if attribute == :org_name

        attribute
      end
    end
  end
end
