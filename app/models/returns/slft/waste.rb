# frozen_string_literal: true

module Returns
  module Slft
    # An SLfT Site can contain multiple Waste records, each must have a different EWC code though
    # ie the Waste records have a composite key made up of the SLfT Return + Site + EWC code.
    class Waste < FLApplicationRecord # rubocop:disable Metrics/ClassLength
      include NumberFormatting

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[ ewc_code description lau_code fmme_method from_non_disposal_ind pre_treated_ind
            standard_tonnage lower_tonnage exempt_tonnage water_tonnage
            nda_ex_yes_no nda_ex_tonnage restoration_ex_yes_no restoration_ex_tonnage
            other_ex_yes_no other_ex_tonnage other_ex_description ]
      end

      # Attributes used when exporting or importing waste as a CSV file
      # @see post_csv_import for processing of other attributes
      def self.csv_attribute_list
        %i[ ewc_code ewc_description description lau_code lau_description
            fmme_method from_non_disposal_ind pre_treated_ind
            standard_tonnage lower_tonnage water_tonnage
            nda_ex_tonnage restoration_ex_tonnage other_ex_tonnage other_ex_description ]
      end

      attribute_list.each { |attr| attr_accessor attr }

      # Not including in the attribute_list so it can't be posted on every slft form, ie to prevent data injection.
      # uuid represents the waste entry in a site (ie just for keeping track of it during editing).
      # site_name is also denormalised mainly so it can be displayed on the page during edits
      attr_accessor :uuid, :site_name

      # Define the ref data codes associated with the attributes to be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def cached_ref_data_codes
        { lau_code: comp_key('LAU', 'SYS', 'RSTU'), fmme_method: comp_key('MANAGEMENT METHOD', 'SLFT', 'RSTU') }
      end

      # Define the ref data codes associated with the attributes but which won't be cached in this model
      # @return [Hash] <attribute> => <ref data composite key>
      def uncached_ref_data_codes
        { from_non_disposal_ind: comp_key('YESNO', 'SYS', 'RSTU'), pre_treated_ind:  comp_key('YESNO', 'SYS', 'RSTU'),
          nda_ex_yes_no: comp_key('YESNO', 'SYS', 'RSTU'), restoration_ex_yes_no:  comp_key('YESNO', 'SYS', 'RSTU'),
          other_ex_yes_no: comp_key('YESNO', 'SYS', 'RSTU'), ewc_code: comp_key('EWC_LIST', 'SLFT', 'RSTU') }
      end

      # waste-description validations
      validates :ewc_code, presence: true, InReferenceValues: true, on: %i[ewc_code]
      validates :description, presence: true, on: %i[ewc_code]
      validates :lau_code, presence: true, InReferenceValues: true, on: %i[ewc_code]
      validates :fmme_method, presence: true, InReferenceValues: true, on: %i[ewc_code]
      validates :from_non_disposal_ind, presence: true, InReferenceValues: true, on: %i[ewc_code]
      validates :pre_treated_ind, presence: true, InReferenceValues: true, on: %i[ewc_code]

      # waste-tonnage validations, blank or 2dp decimals >= 0
      validates :standard_tonnage, allow_blank: true, two_dp_pattern: true,
                                   numericality: { greater_than_or_equal_to: 0, allow_blank: true },
                                   on: :standard_tonnage
      validates :lower_tonnage, allow_blank: true, two_dp_pattern: true,
                                numericality: { greater_than_or_equal_to: 0, allow_blank: true },
                                on: :standard_tonnage
      validates :exempt_tonnage, allow_blank: true, two_dp_pattern: true,
                                 numericality: { greater_than_or_equal_to: 0, allow_blank: true },
                                 on: :standard_tonnage
      validates :water_tonnage, allow_blank: true, two_dp_pattern: true,
                                numericality: { greater_than_or_equal_to: 0, allow_blank: true },
                                on: :standard_tonnage

      validate :validate_tonnage, on: %i[standard_tonnage lower_tonnage exempt_tonnage]

      # validates exemption yes nos are set
      validates :nda_ex_yes_no, presence: true, InReferenceValues: true, on: [:nda_ex_yes_no],
                                if: :exempt_breakdown_needed?
      validates :restoration_ex_yes_no, presence: true, InReferenceValues: true, on: [:restoration_ex_yes_no],
                                        if: :exempt_breakdown_needed?
      validates :other_ex_yes_no, presence: true, InReferenceValues: true, on: [:other_ex_yes_no],
                                  if: :exempt_breakdown_needed?

      # waste_exemption validations, decimals to 2dp > 0 if their yes_no is 'Y'.
      validates :nda_ex_tonnage, two_dp_pattern: true,
                                 numericality: { greater_than: 0 }, on: :nda_ex_tonnage,
                                 if: :nda_ex_details_needed?
      validates :restoration_ex_tonnage, two_dp_pattern: true,
                                         numericality: { greater_than: 0 }, on: :nda_ex_tonnage,
                                         if: :restoration_ex_details_needed?
      validates :other_ex_tonnage, two_dp_pattern: true,
                                   numericality: { greater_than: 0 }, on: :nda_ex_tonnage,
                                   if: :other_ex_details_needed?
      validates :other_ex_description, presence: true, length: { maximum: 255 }, on: :nda_ex_tonnage,
                                       if: :other_ex_details_needed?

      # check an exemption rule is chosen if there's any exempt tonnage
      # @see SlftSitesWasteController#waste_exemption_or_summary
      validate :validate_exemption_chosen, on: :nda_ex_tonnage,
                                           if: :exempt_breakdown_needed?

      # Override constructor to set initial values to zero and provide a UUID
      def initialize(attributes = {})
        super

        # unless already set, provide a UUID
        @uuid = SecureRandom.uuid if @uuid.nil?
      end

      # Overrides the param value passed into the id of the path when the instance of the object is used
      # as the parameter value of a path.
      def to_param
        @uuid
      end

      # EWC description 'attribute' getter.
      # @return [String] the EWC description that corresponds to the ewc_code
      # Used to support CSV imports and exports.
      def ewc_description
        lookup_ref_data_value :ewc_code
      end

      # EWC description 'attribute' setter. Does nothing. Used to support CSV imports and exports.
      def ewc_description=(_ewc_description) end

      # local authority description 'attribute' getter.
      # @return [String] the lau description that corresponds to the lau code
      # Used to support CSV imports and exports.
      def lau_description
        lookup_ref_data_value :lau_code
      end

      # lau description 'attribute' setter. Does nothing. Used to support CSV imports and exports.
      def lau_description=(_lau_description) end

      # The attribute value
      def ewc_code_and_description
        "#{@ewc_code}/#{@description}"
      end

      # custom setter to make sure that the value is upper case mainly for csv load
      def from_non_disposal_ind=(value)
        @from_non_disposal_ind = value&.upcase
      end

      # custom setter to make sure that the value is upper case mainly for csv load
      def pre_treated_ind=(value)
        @pre_treated_ind = value&.upcase
      end

      # Getter for standard tonnage to return the default of zero
      # @return [String] the string for the tonnage
      def standard_tonnage
        @standard_tonnage || 0
      end

      # Getter for lower tonnage to return the default of zero
      # @return [String] the string for the tonnage
      def lower_tonnage
        @lower_tonnage || 0
      end

      # Getter for exempt tonnage to return the default of zero
      # @return [String] the string for the tonnage
      def exempt_tonnage
        @exempt_tonnage || 0
      end

      # Getter for water tonnage to return the default of zero
      # @return [String] the string for the tonnage
      def water_tonnage
        @water_tonnage || 0
      end

      # Getter for nda_ex_tonnage taking into account flags
      # @return [String] the string for the tonnage
      def nda_ex_tonnage
        return @nda_ex_tonnage if nda_ex_details_needed?
      end

      # Getter for restoration_ex_tonnage taking into account flags
      # @return [String] the string for the tonnage
      def restoration_ex_tonnage
        return @restoration_ex_tonnage if restoration_ex_details_needed?
      end

      # Getter for other_ex_tonnage taking into account flags
      # @return [String] the string for the tonnage
      def other_ex_tonnage
        return @other_ex_tonnage if other_ex_details_needed?
      end

      # Getter for nda_ex_tonnage taking into account flags
      # @return [String] the string for the tonnage
      def other_ex_description
        return @other_ex_description if other_ex_details_needed?
      end

      # Getter to work out the total
      def total_tonnage
        # only one of standard, lower and exempt will be set of course
        # if exempt only then total will still show as positive, 2f treats nil as zero so this is fine
        total = (((@standard_tonnage.to_f + @lower_tonnage.to_f) - @water_tonnage.to_f) + @exempt_tonnage.to_f).round(2)
        # remove trailing zeros
        (total == total.to_i ? total.to_i : total)
      end

      # Getter to work out the net lower total, if there is no lower total return 0
      def net_lower_tonnage
        (@lower_tonnage.to_f - @water_tonnage.to_f) unless @lower_tonnage.to_f.zero?
      end

      # Getter to work out the net standard total, if there is no lower total return 0
      def net_standard_tonnage
        (@standard_tonnage.to_f - @water_tonnage.to_f) unless @standard_tonnage.to_f.zero?
      end

      # More useful output for logging this object
      def to_s
        "EWC:#{@ewc_code} standard:#{@standard_tonnage} lower:#{@lower_tonnage}"
      end

      # returns true if an exempt breakdown is needed
      # i.e. the user entered an exempt tonnage
      def exempt_breakdown_needed?
        @exempt_tonnage.present? && @exempt_tonnage.to_f.positive?
      end

      # Create the request hash in the exact order given by the save wsdl.
      def request_save
        output = { 'ins1:EWCCode': ewc_code, 'ins1:WasteDescription': description,
                   'ins1:FMMEMethod': fmme_method, 'ins1:PreTreatedInd': pre_treated_ind == 'Y' ? 'yes' : 'no',
                   'ins1:LAUCode': lau_code, 'ins1:FromNonDisposalInd': from_non_disposal_ind == 'Y' ? 'yes' : 'no' }

        output['ins1:Exempt'] = request_save_exempt_hash if exempt_breakdown_needed?

        output.merge!('ins1:StandardTonnage': standard_tonnage, 'ins1:LowerTonnage': lower_tonnage,
                      'ins1:WaterTonnage': water_tonnage, 'ins1:ExemptTonnage': exempt_tonnage,
                      'ins1:TotalTonnage': total_tonnage) # call method to work out total

        output
      end

      # Create a new instance based on a back office style hash (@see SlftReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      # @param raw_hash [Hash] the hash for this site
      # @param site_name [String] the site name for this site
      def self.convert_back_office_hash(raw_hash, site_name)
        # deal with the exempt section (nb it won't exist if no data)
        move_to_root(raw_hash, :exempt)

        # rename various keys
        raw_hash = rename_items_in_back_office_hash(raw_hash)

        # we always derive the total_tonnage so delete that
        raw_hash.delete(:total_tonnage)

        # convert back office yes/no to Y/N
        yes_nos_to_yns(raw_hash, %i[from_non_disposal_ind pre_treated_ind])

        # derive yes no based on the data now that we've finished moving it around
        derive_yes_nos_in(raw_hash)

        # add the exempt total in
        add_exempt_total(raw_hash)

        raw_hash[:site_name] = site_name

        # make sure we have leading zeros on float values
        add_leading_zero(raw_hash, %i[standard_tonnage lower_tonnage water_tonnage
                                      nda_ex_tonnage restoration_ex_tonnage other_ex_tonnage])

        # Create new instance
        Waste.new_from_fl(raw_hash)
      end

      # Note: As used in print data these need to be public
      # Do we need to enter the nda tonnage
      def nda_ex_details_needed?
        @nda_ex_yes_no == 'Y' && exempt_breakdown_needed?
      end

      # Do we need to enter the restoration tonnage
      def restoration_ex_details_needed?
        @restoration_ex_yes_no == 'Y' && exempt_breakdown_needed?
      end

      # Do we need to enter the other tonnage and description
      def other_ex_details_needed?
        @other_ex_yes_no == 'Y' && exempt_breakdown_needed?
      end

      # Derive waste specific yes nos based on the data
      private_class_method def self.derive_yes_nos_in(raw_hash)
        to_derive = { nda_ex_yes_no: :nda_ex_tonnage, restoration_ex_yes_no: :restoration_ex_tonnage,
                      other_ex_yes_no: :other_ex_tonnage }

        derive_yes_nos(raw_hash, to_derive, true)
      end

      # Create a new instance based on a back office style hash (@see SlftReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      private_class_method def self.rename_items_in_back_office_hash(raw_hash)
        # no need to be verbose
        raw_hash[:description] = raw_hash.delete(:waste_description)

        # GeographicalOrigin should be LAUCode but it isn't on load
        raw_hash[:lau_code] = raw_hash.delete(:geographical_origin)

        # waste_movement should be from_non_disposal_ind but isn't on load
        raw_hash[:from_non_disposal_ind] = raw_hash.delete(:waste_movement)

        if raw_hash.key?(:other_ex_tonnage)
          raw_hash[:other_ex_description] = raw_hash[:other_ex_tonnage][:description]
          # replace other_ex_tonnage with the tonnage
          raw_hash[:other_ex_tonnage] = raw_hash[:other_ex_tonnage][:tonnage]
        end

        raw_hash
      end

      # add the exempt total in
      private_class_method def self.add_exempt_total(raw_hash)
        exempt_tonnage = raw_hash[:nda_ex_tonnage].to_f + raw_hash[:restoration_ex_tonnage].to_f +
                         raw_hash[:other_ex_tonnage].to_f
        # special case remove trailing 0 which may have been added
        raw_hash[:exempt_tonnage] = (exempt_tonnage == exempt_tonnage.to_i ? exempt_tonnage.to_i : exempt_tonnage)
      end

      private

      # Post CSV import processing on this model
      # This sets attributes not provided on the CSV import which can be derived
      # @see csv_attribute_list
      def post_csv_import
        # Because of the getters above the order is important and needs to mirror the page
        total = @nda_ex_tonnage.to_f + @restoration_ex_tonnage.to_f + @other_ex_tonnage.to_f
        # remove trailing zeros
        @exempt_tonnage = (total == total.to_i ? total.to_i : total)
        # don't set the yes no flags if no exempt values
        return if @exempt_tonnage.zero?

        @nda_ex_yes_no = (@nda_ex_tonnage.nil? ? 'N' : 'Y')
        @restoration_ex_yes_no = (@restoration_ex_tonnage.nil? ? 'N' : 'Y')
        @other_ex_yes_no = (@other_ex_tonnage.nil? ? 'N' : 'Y')
      end

      # Validation method, waste can have either standard, lower or exempt.  The total must be positive.
      def validate_tonnage
        set_tonnages = filter_set_values(%i[standard_tonnage lower_tonnage exempt_tonnage])
        counter = set_tonnages.length

        if counter > 1
          set_tonnages.each { |item| errors.add(item, :only_one_waste_type) }
        elsif counter < 1
          errors.add(:standard_tonnage, :missing_tonnage)
        end

        validate_water_tonnage
      end

      # Water tonnage cannot be set if exempt tonnage is set and cannot make tonnage negative
      # called from validate_tonnage
      def validate_water_tonnage
        if net_lower_tonnage.to_f.negative? || net_standard_tonnage.to_f.negative?
          errors.add(:water_tonnage, :cannot_exceed_tonnage)
        end

        return unless @exempt_tonnage.to_f.positive? && @water_tonnage.to_f.positive?

        errors.add(:water_tonnage, :cannot_be_set_with_exempt)
      end

      # Validation method, exemption must have a reason entered and the sum of the individual
      # exemptions must add up to the total entered
      def validate_exemption_chosen
        # Check at least one yes/no flag is set
        unless @nda_ex_yes_no == 'Y' || @restoration_ex_yes_no == 'Y' || @other_ex_yes_no == 'Y'
          errors.add(:nda_ex_yes_no, :missing_exemption_tonnage)
          return # no point checking sum
        end

        # If the sum is not equal set the message on the first set value
        return if sum_exemptions.to_f == @exempt_tonnage.to_f

        errors.add(:base, :exemption_tonnage_isnt_equal, link_id: 'new_returns_slft_waste')
      end

      # Sum the exemptions
      def sum_exemptions
        # uses the method so the visibility rules are obeyed
        nda_ex_tonnage.to_f + restoration_ex_tonnage.to_f + other_ex_tonnage.to_f
      end

      # Validation helper method to check which attributes are set on this object.
      # note nil values are treated as 0 float
      # @param list [Array] list of symbols of attributes to check
      # @return [Array] attributes in list that have a value set
      def filter_set_values(list)
        output = []
        list.nil? || list.each { |item| output << item if send(item).to_f.positive? }
        output
      end

      # provide the details for the request for the exemption details
      def request_save_exempt_hash
        { 'ins1:NDAExTonnage': nda_ex_tonnage,
          'ins1:RestorationExTonnage': restoration_ex_tonnage,
          'ins1:OtherExTonnage': { 'ins1:Tonnage': other_ex_tonnage,
                                   'ins1:Description': other_ex_description } }
      end

      # Layout to print the data in this model
      # REturns the array for the row title
      def print_layout_row_title
        [{ code: :ewc_code },
         { code: :ewc_code, lookup: true, nolabel: true },
         { code: :description },
         { code: :lau_code, lookup: true },
         { code: :fmme_method, lookup: true },
         { code: :from_non_disposal_ind, lookup: true },
         { code: :pre_treated_ind, lookup: true }]
      end

      # Layout to print the data in this model
      # REturns the array for the last column in the row
      def print_layout_row_suffix
        [{ code: :nda_ex_yes_no, lookup: true, when: :exempt_breakdown_needed?, is: [true] },
         { code: :nda_ex_tonnage, when: :nda_ex_details_needed?, is: [true] },
         { code: :restoration_ex_yes_no, lookup: true, when: :exempt_breakdown_needed?, is: [true] },
         { code: :restoration_ex_tonnage, when: :restoration_ex_details_needed, is: [true] },
         { code: :other_ex_yes_no, lookup: true, when: :exempt_breakdown_needed?, is: [true] },
         { code: :other_ex_tonnage, when:  :other_ex_details_needed?, is: [true] },
         { code: :other_ex_description, when: :other_ex_details_needed?, is: [true] }]
      end
    end
  end
end
