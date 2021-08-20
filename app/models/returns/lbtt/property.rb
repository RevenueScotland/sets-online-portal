# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for the property
    class Property < FLApplicationRecord
      include PrintData

      # Attributes for this class in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[
          property_id lau_code address ads_due_ind flbt_type
          title_code title_number parent_title_code parent_title_number
        ]
      end

      # unique reference from the back office this is simply round tripped but is not accessible externally
      attr_accessor :pro_refno

      attribute_list.each { |attr| attr_accessor attr }

      # Overrides the param value passed into the id of the path when the instance of the object is used
      # as the parameter value of a path.
      # For example returns_lbtt_property_address_path(object) where object is an instance of this.
      def to_param
        @property_id
      end

      # override string output to help with debugging.
      def to_s
        "#{property_id} #{title_number} #{lau_code} #{address}"
      end

      validates :lau_code, presence: true, on: :lau_code
      validates :title_number, length: { maximum: 40 }, on: :lau_code
      validates :parent_title_number, length: { maximum: 40 }, on: :lau_code

      validates :ads_due_ind, presence: true, on: :ads_due_ind, if: proc { |s| s.flbt_type == 'CONVEY' }

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { lau_code: comp_key('LAU', 'SYS', 'RSTU'), title_code: comp_key('PROPERTYTITLEPREFIX', 'SYS', 'RSTU'),
          parent_title_code: comp_key('PROPERTYTITLEPREFIX', 'SYS', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes not cached in this model
      # long lists or special yes no case
      def uncached_ref_data_codes
        { ads_due_ind: YESNO_COMP_KEY }
      end

      # @return the title code + the title number
      def full_title_number
        "#{title_code} #{title_number}"
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :property_details, # section code
           divider: true, # should we have a section divider
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_properties about_the_property], # scope for the title translation
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :lau_code, lookup: true },
                        { code: :title_code, lookup: true, key_scope: %i[returns lbtt_properties about_the_property] },
                        { code: :title_number, nolabel: true },
                        { code: :parent_title_code, lookup: true,
                          key_scope: %i[returns lbtt_properties about_the_property] },
                        { code: :parent_title_number, nolabel: true },
                        { code: :ads_due_ind, lookup: true, when: :flbt_type, is: ['CONVEY'] }] },
         { code: :address,
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_properties property_address], # scope for the title translation
           type: :object }]
      end

      # Layout to print the receipt data in this model
      def print_layout_receipt
        [{ code: :property_details, # section code
           divider: true, # should we have a section divider
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_properties about_the_property], # scope for the title translation
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           list_items: [{ code: :full_title_number, key_scope: %i[return submit lbtt] },
                        { code: :full_address, key_scope: %i[return submit lbtt] }] }]
      end

      # Key information to display section error.(see @LbttReturnValidator)
      def key_info
        address.to_s
      end

      # provide full address of property
      delegate :full_address, to: :address

      # @return a hash suitable for use in a save request to the back office
      def request_save
        (@pro_refno.blank? ? {} : { 'ins1:ProRefno': @pro_refno }).merge(
          'ins1:LauCode': @lau_code,
          'ins1:Address': @address.format_to_back_office_address,
          'ins1:FtpfCode': @title_code, # title_prefix
          'ins1:TitleNumber': @title_number,
          'ins1:ParentFtpfCode': @parent_title_code, # parent_title_prefix
          'ins1:ParentTitleNumber': @parent_title_number,
          'ins1:AdsDueInd': convert_to_backoffice_yes_no_value(@ads_due_ind)
        )
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      # @param p_hash [Hash] the hash from the back office for an individual property
      # @param flbt_type [String] the return type needs to be copied down from the main return
      def self.convert_back_office_hash(p_hash, flbt_type)
        p_hash[:flbt_type] = flbt_type
        p_hash[:title_code] = p_hash.delete(:ftpf_code)
        p_hash[:parent_title_code] = p_hash.delete(:parent_ftpf_code)

        p_hash[:address] = Address.convert_hash_to_address(p_hash[:address]) unless p_hash[:address].nil?

        # Allocate an internal reference to track this property
        p_hash[:property_id] = SecureRandom.uuid

        # AdsDueInd is returned as Y/N rather than the expected yes/no which means we don't need to convert it here

        # Create new instance
        Property.new_from_fl(p_hash)
      end
    end
  end
end
