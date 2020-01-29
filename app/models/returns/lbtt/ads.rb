# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for Additional dwelling supplement(ADS) wizard
    # Split out from and used by LbttReturn which was getting too big.
    class Ads < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[ads_consideration_yes_no ads_amount_liable ads_sell_residence_ind ads_consideration ads_main_address
           ads_reliefclaim_option_ind ads_relief_claims rrep_ads_sold_date ads_sold_main_yes_no
           rrep_ads_sold_address ads_repay_amount_claimed]
      end
      attribute_list.each { |attr| attr_accessor attr }

      # Not including in the attribute_list so it can't be changed by the user
      attr_accessor :flbt_type # HACK: values copied from LbttReturn

      # ADS validation
      validates :ads_consideration_yes_no, presence: true, on: :ads_consideration_yes_no
      validates :ads_sell_residence_ind, presence: true, on: :ads_sell_residence_ind
      validates :ads_amount_liable, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000,
                                                    allow_blank: true }, presence: true,
                                    two_dp_pattern: true, on: :ads_amount_liable
      validates :ads_consideration, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000,
                                                    allow_blank: true }, presence: true,
                                    two_dp_pattern: true, on: :ads_amount_liable,
                                    if: :ads_consideration?
      validates :ads_reliefclaim_option_ind, presence: true, on: :ads_reliefclaim_option_ind
      validates :ads_relief_claims, relief_type_unique: true, on: :ads_reliefclaim_option_ind
      # ADS claim repayment validation
      validates :ads_sold_main_yes_no, presence: true, on: :ads_sold_main_yes_no
      validates :rrep_ads_sold_date, presence: true, on: :rrep_ads_sold_date, custom_date: true,
                                     if: :ads_repayment?
      # ads_repay_details
      validates :ads_repay_amount_claimed, numericality: { greater_than: 0, less_than: 1_000_000_000_000_000_000,
                                                           allow_blank: true }, presence: true,
                                           two_dp_pattern: true, on: :ads_repay_amount_claimed,
                                           if: :ads_repayment?

      # ADS validation method, returns true if ads_consideration_yes_no is 'Y'
      def ads_consideration?
        @ads_consideration_yes_no == 'Y'
      end

      # Validation method to check if ADS repayment is applicable.
      def ads_repayment?
        @ads_sold_main_yes_no == 'Y'
      end

      # Define the ref data codes associated with the attributes but which won't be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { ads_reliefclaim_option_ind: comp_key('YESNO', 'SYS', 'RSTU'),
          ads_consideration_yes_no: comp_key('YESNO', 'SYS', 'RSTU'),
          ads_sell_residence_ind: comp_key('YESNO', 'SYS', 'RSTU'),
          ads_sold_main_yes_no: comp_key('YESNO', 'SYS', 'RSTU') }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :ads_consideration, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_ads], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           when: :flbt_type,
           is: ['CONVEY'],
           list_items: [{ code: :ads_consideration_yes_no, lookup: true },
                        { code: :ads_amount_liable, format: :money },
                        { code: :ads_consideration, format: :money, when: :ads_consideration_yes_no, is: ['Y'] },
                        { code: :ads_sell_residence_ind, lookup: true }] },
         { code: :ads_main_address, # section code
           key: :address, # key for the title translation
           key_scope: %i[returns lbtt_ads ads_intending_sell], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :flbt_type,
           is: ['CONVEY'],
           type: :object },
         { code: :ads_relief_claim_ind, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_ads ads_reliefs], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           when: :flbt_type,
           is: ['CONVEY'],
           list_items: [{ code: :ads_reliefclaim_option_ind, lookup: true }] },
         { code: :ads_relief_claims, # section code
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           when: :ads_reliefclaim_option_ind,
           is: ['Y'],
           type: :object },
         { code: :ads_repayment, # section code
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_ads], # scope for the title translation
           divider: true, # should we have a section divider
           display_title: true, # Is the title to be displayed
           type: :list, # type list = the list of attributes to follow
           when: :ads_sold_main_yes_no,
           is: %w[Y N],
           list_items: [{ code: :ads_sold_main_yes_no, lookup: true },
                        { code: :rrep_ads_sold_date, format: :date, when: :ads_sold_main_yes_no, is: ['Y'] },
                        { code: :ads_repay_amount_claimed, format: :money, when: :ads_sold_main_yes_no, is: ['Y'] }] },
         { code: :rrep_ads_sold_address, # section code
           key: :rrep_ads_sold_address, # key for the title translation
           key_scope: %i[returns lbtt_ads ads_repay_address], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: true, # Is the title to be displayed
           when: :ads_sold_main_yes_no,
           is: ['Y'],
           type: :object }]
      end

      # Method to ensure the ADS sub-object is created and up to date with the values it needs copying into it.
      # Ideally the ADS model would have a reference to the LbttReturn model but for now, we're copying the required
      # values instead.
      # @see Tax which uses the same pattern
      # @param lbtt_return [LbttReturn] the parent model in which to create/refresh the model
      # @param force_clear [Boolean] force creation of a new model
      def self.setup_ads(lbtt_return, force_clear = false)
        lbtt_return.ads = Lbtt::Ads.new if force_clear

        # ensure the Ads model exists and the important values are updated from values
        lbtt_return.ads ||= Lbtt::Ads.new
        %i[flbt_type].each do |attr|
          lbtt_return.ads.send("#{attr}=", lbtt_return.send(attr))
        end
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save(output)
        # include ADS fields only if the user is currently shown the ADS wizard option (ie it could have been hidden
        # since ADS data was added)
        # is the ADS section currently available to the user
        output['ins1:AdsSellResidenceInd'] = convert_to_backoffice_yes_no_value(@ads_sell_residence_ind)
        output['ins1:AdsAddress'] = @ads_main_address.format_to_back_office_address unless @ads_main_address.blank?
        xml_element_if_present(output, 'ins1:AdsConsideration', @ads_consideration)
        xml_element_if_present(output, 'ins1:AdsAmountLiable', @ads_amount_liable)
        # Note that the ads reliefs are merged in as part of the parent return
        unless @rrep_ads_sold_address.blank?
          output['ins1:AdsSoldAddress'] = @rrep_ads_sold_address.format_to_back_office_address
        end
        return if @rrep_ads_sold_date.blank?

        output['ins1:AdsSoldDate'] = DateFormatting.to_xml_date_format(@rrep_ads_sold_date)
        # see lbtt_return for saving of the repayment amount
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(output) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        ads_output = {}
        unless output[:ads_address].blank?
          ads_output[:ads_main_address] = Address.convert_hash_to_address(output[:ads_address])
        end
        yes_nos_to_yns(output, %i[ads_sell_residence_ind])
        ads_output.merge!(convert_to_reliefs_claims(output[:reliefs])) unless output[:reliefs].blank?
        ads_output[:ads_sell_residence_ind] = output.delete(:ads_sell_residence_ind)
        ads_output[:ads_consideration_yes_no] = output.delete(:ads_consideration_yes_no)
        ads_output[:ads_consideration] = output.delete(:ads_consideration)
        ads_output[:ads_amount_liable] = output.delete(:ads_amount_liable)
        unless output[:ads_sold_address].blank?
          ads_output[:rrep_ads_sold_address] = Address.convert_hash_to_address(output.delete(:ads_sold_address))
        end
        # Set sold property details if we have a sold date
        unless output[:ads_sold_date].blank?
          ads_output[:ads_sold_main_yes_no] = 'Y'
          ads_output[:ads_repay_amount_claimed] = output[:repayment_amount_claimed]
          ads_output[:rrep_ads_sold_date] = output.delete(:ads_sold_date)
        end
        # derive yes no based on the data now that we've finished moving it around
        derive_yes_nos_in(ads_output) unless ads_output[:ads_sell_residence_ind].nil?
        Ads.new_from_fl(ads_output)
      end

      # Some attributes yes_no type depending on some other attribute value, so here we are setting them
      private_class_method def self.derive_yes_nos_in(lbtt)
        to_derive = {
          ads_reliefclaim_option_ind: :ads_relief_claims,
          ads_consideration_yes_no: :ads_consideration
        }
        derive_yes_nos(lbtt, to_derive, true)
      end

      # Convert the relief_claim data into relief objects separated into ADS and non-ADS reliefs.
      # @return [Hash] reliefs with indexes :non_ads_relief_claims and :ads_relief_claims.
      private_class_method def self.convert_to_reliefs_claims(reliefs_data)
        return nil if reliefs_data.nil? || reliefs_data[:relief].nil?

        # convert to array if it isn't already
        reliefs_data[:relief] = [reliefs_data[:relief]] unless reliefs_data[:relief].is_a? Array

        return nil if reliefs_data[:relief].empty?

        output = { ads_relief_claims: [] }
        reliefs_data[:relief].each do |raw_hash|
          convert_and_organise_relief(raw_hash, output)
        end
        # delete empty parts of the reliefs hash.
        output.delete(:ads_relief_claims) if output[:ads_relief_claims].empty?
        output
      end

      # Separated out of #convert_to_relief_claims.
      # @param raw_hash [Hash] data loaded from the back office about a relief
      private_class_method def self.convert_and_organise_relief(raw_hash, output)
        relief = ReliefClaim.convert_back_office_hash(raw_hash)
        output[:ads_relief_claims] << relief if /ADS.*/.match?(relief.relief_type)
      end
    end
  end
end
