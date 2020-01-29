# frozen_string_literal: true

module Returns
  module Slft
    # An SLfT Site can contain multiple Waste records, each must have a different EWC code though
    # ie the Waste records have a composite key made up of the SLfT Return + Site + EWC code.
    class Waste < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting
      include PrintData
      include CommonValidation

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[ ewc_code description lau_code fmme_method from_non_disposal_ind pre_treated_ind
            standard_tonnage lower_tonnage exempt_tonnage water_tonnage
            nda_ex_yes_no nda_ex_tonnage restoration_ex_yes_no restoration_ex_tonnage
            other_ex_yes_no other_ex_tonnage other_ex_description ]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # Not including in the attribute_list so it can't be posted on every slft form, ie to prevent data injection.
      # uuid represents the waste entry in a site (ie just for keeping track of it during editing).
      attr_accessor :uuid

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { lau_code: 'LAU.SYS.RSTU', fmme_method: 'MANAGEMENT METHOD.SLFT.RSTU' }
      end

      # Define the ref data codes associated with the attributes but which won't becached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { from_non_disposal_ind: 'YESNO.SYS.RSTU', pre_treated_ind:  'YESNO.SYS.RSTU',
          nda_ex_yes_no: 'YESNO.SYS.RSTU', restoration_ex_yes_no:  'YESNO.SYS.RSTU', other_ex_yes_no: 'YESNO.SYS.RSTU',
          ewc_code: 'EWC_LIST.SLFT.RSTU' }
      end

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout # rubocop:disable Metrics/MethodLength
        [{ code: :wastes,
           divider: false,
           display_title: false,
           type: :table,
           row_cells: [{ list_items: [{ code: :ewc_code },
                                      { code: :ewc_code, lookup: true, nolabel: true },
                                      { code: :description },
                                      { code: :lau_code, lookup: true },
                                      { code: :fmme_method, lookup: true },
                                      { code: :from_non_disposal_ind, lookup: true },
                                      { code: :pre_treated_ind, lookup: true }] },
                       { list_items: [{ code: :standard_tonnage }] },
                       { list_items: [{ code: :lower_tonnage }] },
                       { list_items: [{ code: :exempt_tonnage }] },
                       { list_items: [{ code: :water_tonnage }] },
                       { list_items: [{ code: :nda_ex_yes_no, lookup: true, when: :exempt_tonnage, is_not: ['0'] },
                                      { code: :nda_ex_tonnage, when: :nda_ex_yes_no, is: ['Y'] },
                                      { code: :restoration_ex_yes_no, lookup: true,
                                        when: :exempt_tonnage, is_not: ['0'] },
                                      { code: :restoration_ex_tonnage, when: :restoration_ex_yes_no, is: ['Y'] },
                                      { code: :other_ex_yes_no, lookup: true, when: :exempt_tonnage, is_not: ['0'] },
                                      { code: :other_ex_tonnage, when:  :other_ex_yes_no, is: ['Y'] },
                                      { code: :other_ex_description, when: :other_ex_yes_no, is: ['Y'] }] }] }]
      end

      # waste-description validations
      validates :ewc_code, presence: true, on: %i[ewc_code]
      validates :description, presence: true, on: %i[ewc_code]
      validates :lau_code, presence: true, on: %i[ewc_code]
      validates :fmme_method, presence: true, on: %i[ewc_code]
      validates :from_non_disposal_ind, presence: true, on: %i[ewc_code]
      validates :pre_treated_ind, presence: true, on: %i[ewc_code]

      # waste-tonnage validations, blank or 2dp decimals >= 0
      validates :standard_tonnage, allow_blank: true, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                   numericality: { greater_than_or_equal_to: 0, allow_blank: true },
                                   on: :standard_tonnage
      validates :lower_tonnage, allow_blank: true, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                numericality: { greater_than_or_equal_to: 0, allow_blank: true },
                                on: :standard_tonnage
      validates :exempt_tonnage, allow_blank: true, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                 numericality: { greater_than_or_equal_to: 0, allow_blank: true },
                                 on: :standard_tonnage
      validates :water_tonnage, allow_blank: true, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                numericality: { greater_than_or_equal_to: 0, allow_blank: true },
                                on: :standard_tonnage

      validate :validate_tonnage, on: %i[standard_tonnage lower_tonnage exempt_tonnage]

      # waste_exemption validations, decimals to 2dp > 0 if their yes_no is 'Y'.
      validates :nda_ex_tonnage, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                 numericality: { greater_than: 0 }, on: :nda_ex_tonnage,
                                 if: proc { |w| w.nda_ex_yes_no == 'Y' }
      validates :restoration_ex_tonnage, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                         numericality: { greater_than: 0 }, on: :nda_ex_tonnage,
                                         if: proc { |w| w.restoration_ex_yes_no == 'Y' }
      validates :other_ex_tonnage, format: { with: TWO_DP_PATTERN, message: :invalid_2dp },
                                   numericality: { greater_than: 0 }, on: :nda_ex_tonnage,
                                   if: :other_ex_yes_no_y?
      # Commenting for RSTP-446
      # validates :other_ex_description, presence: true, length: { maximum: 255 }, on: :nda_ex_tonnage,
      #                                  if: :other_ex_yes_no_y?

      # check an exemption rule is chosen if there's any exempt tonnage
      # @see SlftSitesWasteController#waste_exemption_or_summary which duplicates this rule - TODO: should be a method
      # in this model so the model is authorititive about business rules.
      validate :validate_exemption_chosen, on: :nda_ex_tonnage,
                                           if: proc { |w| w.exempt_tonnage.present? && w.exempt_tonnage.to_f.positive? }

      # Override constructor to set initial values to zero and provide a UUID
      def initialize(attributes = {})
        super
        # unless we're loading a waste entry, set these attributes to zero in 2 lines rather than 4
        set_to_zero = %i[standard_tonnage= lower_tonnage= exempt_tonnage= water_tonnage=]
        set_to_zero.each { |x| send(x, 0) } if attributes.blank?
        # unless already set, provide a UUID
        @uuid = SecureRandom.uuid if @uuid.nil?
      end

      # Getter to work out the total
      def total_tonnage
        # only one of standard, lower and exempt will be set of course
        # if exempt only then total will still show as positive
        total = (((@standard_tonnage.to_f + @lower_tonnage.to_f) - @water_tonnage.to_f) + @exempt_tonnage.to_f).round(2)
        # removes trailing zeros from sum values
        total = total.to_i if total == total.to_i
        total
      end

      # Getter to work out the net lower total, if there is no lower total return 0
      def net_lower_tonnage
        return 0 if @lower_tonnage.to_f.zero?

        (@lower_tonnage.to_f - @water_tonnage.to_f)
      end

      # Getter to work out the net standard total, if there is no lower total return 0
      def net_standard_tonnage
        return 0 if @standard_tonnage.to_f.zero?

        (@standard_tonnage.to_f - @water_tonnage.to_f)
      end

      # More useful output for logging this object
      def to_s
        "EWC:#{@ewc_code} standard:#{@standard_tonnage} lower:#{@lower_tonnage} total:#{@total}"
      end

      # Create the request hash in the exact order given by the save wsdl.
      def request_save # rubocop:disable Metrics/MethodLength
        output = { 'ins1:EWCCode': @ewc_code, 'ins1:WasteDescription': @description,
                   'ins1:FMMEMethod': @fmme_method,
                   'ins1:PreTreatedInd': @pre_treated_ind == 'Y' ? 'yes' : 'no',
                   'ins1:LAUCode': @lau_code,
                   'ins1:FromNonDisposalInd': @from_non_disposal_ind == 'Y' ? 'yes' : 'no' }

        unless @nda_ex_tonnage.blank? && @restoration_ex_tonnage.blank? && @other_ex_tonnage.blank?
          output['ins1:Exempt'] = { 'ins1:NDAExTonnage': or_zero(@nda_ex_tonnage),
                                    'ins1:RestorationExTonnage': or_zero(@restoration_ex_tonnage),
                                    'ins1:OtherExTonnage': { 'ins1:Tonnage': or_zero(@other_ex_tonnage),
                                                             'ins1:Description': @other_ex_description } }
        end

        output.merge!('ins1:StandardTonnage': or_zero(@standard_tonnage), 'ins1:LowerTonnage': or_zero(@lower_tonnage),
                      'ins1:WaterTonnage': or_zero(@water_tonnage), 'ins1:ExemptTonnage': or_zero(@exempt_tonnage),
                      'ins1:TotalTonnage': total_tonnage) # call method to work out total

        output
      end

      # Create a new instance based on a back office style hash (@see SlftReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(raw_hash) # rubocop:disable Metrics/MethodLength
        # no need to be verbose
        raw_hash[:description] = raw_hash.delete(:waste_description)

        # we always derive the total_tonnage so delete that
        raw_hash.delete(:total_tonnage)

        # GeographicalOrigin should be LAUCode but it isn't on load
        raw_hash[:lau_code] = raw_hash.delete(:geographical_origin)

        # waste_movement should be from_non_disposal_ind but isn't on load
        raw_hash[:from_non_disposal_ind] = raw_hash.delete(:waste_movement)

        # convert back office yes/no to Y/N
        yes_nos_to_yns(raw_hash, %i[from_non_disposal_ind pre_treated_ind])

        # deal with the exempt section (nb it won't exist if no data)
        move_to_root(raw_hash, :exempt)
        if raw_hash.key?(:other_ex_tonnage)
          raw_hash[:other_ex_description] = raw_hash[:other_ex_tonnage][:description]
          # replace other_ex_tonnage with the tonnage
          raw_hash[:other_ex_tonnage] = raw_hash[:other_ex_tonnage][:tonnage]
        end

        # derive yes no based on the data now that we've finished moving it around
        derive_yes_nos_in(raw_hash)

        format_float(raw_hash, %i[standard_tonnage lower_tonnage exempt_tonnage water_tonnage
                                  nda_ex_tonnage restoration_ex_tonnage other_ex_tonnage])

        # Create new instance
        Waste.new_from_fl(raw_hash)
      end

      private

      # Details of waste validation method
      def other_ex_yes_no_y?
        @other_ex_yes_no == 'Y'
      end

      # Derive waste specific yes nos based on the data
      private_class_method def self.derive_yes_nos_in(raw_hash)
        to_derive = { nda_ex_yes_no: :nda_ex_tonnage, restoration_ex_yes_no: :restoration_ex_tonnage,
                      other_ex_yes_no: :other_ex_tonnage }

        derive_yes_nos(raw_hash, to_derive, true)
      end

      # Used when converting back office data.
      # The back office can strip of leading 0s from e.g. 0.78 which causes an issue with 2dp validation and looks bad
      # Convert the specified keys in the hash from .78 to 0.78
      # @param hash [Hash] the data structure representing back office data
      # @param keys [Array] list of keys to look at and convert
      private_class_method def self.format_float(hash, keys)
        keys.each do |key|
          value = hash[key]
          value = '0' + value if !value.nil? && value.start_with?('.')
          hash[key] = value
        end
      end

      # Validation method, waste can have either standard, lower or exempt.  The total must be positive.
      def validate_tonnage
        set_tonnages = filter_set_values(%i[standard_tonnage lower_tonnage exempt_tonnage])
        counter = set_tonnages.length

        if counter > 1
          set_tonnages.each { |item| errors.add(item, :only_one_waste_type) }
        elsif counter < 1
          errors.add(:base, :missing_tonnage)
        end

        validate_water_tonnage
      end

      # Water tonnage cannot be set if exempt tonnage is set and cannot make tonnage negative
      # called from validate_tonnage
      def validate_water_tonnage
        if net_lower_tonnage.negative? || net_standard_tonnage.negative?
          errors.add(:water_tonnage, :cannot_exceed_tonnage)
        end

        return unless value_set?(@exempt_tonnage) && value_set?(@water_tonnage)

        errors.add(:water_tonnage, :cannot_be_set_with_exempt)
      end

      # Validation method, exemption must have a reason entered and the sum of the individual
      # exemptions must add up to the total entered
      def validate_exemption_chosen
        list_to_check = [@nda_ex_tonnage, @restoration_ex_tonnage, @other_ex_tonnage]
        if count_set_values(list_to_check).positive?
          return if sum_exemptions == @exempt_tonnage.to_f

          errors.add(:base, :exemption_tonnage_isnt_equal)
        else
          errors.add(:base, :missing_exemption_tonnage)
        end
      end

      # Sum the exemptions
      def sum_exemptions
        to_sum = [{ value: @nda_ex_tonnage, use: @nda_ex_yes_no == 'Y' },
                  { value: @restoration_ex_tonnage, use: @restoration_ex_yes_no == 'Y' },
                  { value: @other_ex_tonnage, use: other_ex_yes_no_y? }]

        to_sum.inject(0) { |sum, hash| sum + (hash[:use] ? hash[:value].to_f : 0) }
      end

      # Validation helper method to check which attributes are set on this object.
      # @param list [Array] list of symbols of attributes to check
      # @return [Array] attributes in list that have a value set @see #value_set?
      def filter_set_values(list)
        output = []
        list.nil? || list.each { |item| output << item if value_set?(send(item)) }
        output
      end

      # Validation helper method to check how many attributes are set on this object.
      # @param list [Array] list of attributes to check
      # @return number of attributes in list that have a value set @see #value_set?
      def count_set_values(list)
        counter = 0
        list.nil? || list.each { |item| counter += 1 if value_set?(item) }
        counter
      end

      # @param value [Integer] number to check
      # @return true if value is non blank and positive
      def value_set?(value)
        return false if value.blank?

        value.to_f.positive?
      end
    end
  end
end
