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
          property_id lau_code lau_value address ads_due_ind flbt_type
          title_code title_number parent_title_code parent_title_number
        ]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # override string output to help with debugging.
      def to_s
        "#{property_id} #{title_number} #{lau_value} #{address}"
      end

      validates :lau_code, presence: true
      validates :title_number, length: { maximum: 37 }
      validates :parent_title_number, length: { maximum: 37 }

      validates :ads_due_ind, presence: true, on: :ads_due_ind, if: proc { |s| s.flbt_type == 'CONVEY' }

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { lau_code: 'LAU.SYS.RSTU', title_code: 'PROPERTYTITLEPREFIX.SYS.RSTU',
          parent_title_code: 'PROPERTYTITLEPREFIX.SYS.RSTU' }
      end

      # Define the ref data codes associated with the attributes not cached in this model
      # long lists or special yes no case
      def uncached_ref_data_codes
        { ads_due_ind: 'YESNO.SYS.RSTU' }
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

      # Key information to display section error.(see @LbttReturnValidator)
      def key_info
        address.to_s
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        {
          'ins1:LauCode': @lau_code,
          'ins1:Address': @address.format_to_back_office_address,
          'ins1:FtpfCode': @title_code, # title_prefix
          'ins1:TitleNumber': @title_number,
          'ins1:ParentFtpfCode': @parent_title_code, # parent_title_prefix
          'ins1:ParentTitleNumber': @parent_title_number,
          'ins1:AdsDueInd': @ads_due_ind == 'Y' ? 'yes' : 'no'
        }
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(p_hash)
        p_hash[:title_code] = p_hash.delete(:ftpf_code)
        p_hash[:parent_title_code] = p_hash.delete(:parent_ftpf_code)

        p_hash[:address] = Address.convert_hash_to_address(p_hash[:address]) unless p_hash[:address].nil?

        # derive local authority value to display on screen from code
        ref_data_hash = ReferenceData::ReferenceValue.lookup('LAU', 'SYS', 'RSTU')
        p_hash[:lau_value] = ref_data_hash[p_hash[:lau_code]].value
        p_hash[:property_id] = SecureRandom.uuid

        # AdsDueInd is returned as Y/N rather than the expected yes/no which means we don't need to convert it here

        # Create new instance
        Property.new_from_fl(p_hash)
      end
    end
  end
end
