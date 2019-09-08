# frozen_string_literal: true

# Returns module contain collection of classes associated with LBTT return.
module Returns
  # module to organise LBTT return models
  module Lbtt
    # Model for yearly rent records
    class YearlyRent < FLApplicationRecord
      include NumberFormatting
      include PrintData
      include CommonValidation

      # Attributes for this class, in list so can re-use as permitted params list in the controller
      def self.attribute_list
        %i[year rent]
      end
      attribute_list.each { |attr| attr_accessor attr }

      validates :rent, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000_000_000_000_000 },
                       format: { with: TWO_DP_PATTERN, message: :invalid_2dp }, presence: true

      # Layout to print the data in this model
      # This defines the sections that are to be printed and the content and layout of those sections
      def print_layout
        [{ code: :rental_years,
           key: :title, # key for the title translation
           key_scope: %i[returns lbtt_transactions rental_years], # scope for the title translation
           divider: false, # should we have a section divider
           display_title: false, # Is the title to be displayed
           type: :list,
           list_items: [{ code: :year, key_scope: %i[returns lbtt_transactions rental_years] },
                        { code: :rent, format: :money, key_scope: %i[returns lbtt_transactions rental_years] }] }]
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save
        output = {}
        output['ins1:Year'] = @year unless @year.blank?
        output['ins1:RentAmount'] = or_zero(@rent)
        output
      end

      # Create a new instance based on a back office style hash (@see LbttReturn.convert_back_office_hash).
      # Sort of like the opposite of @see #request_save
      def self.convert_back_office_hash(output)
        output[:rent] = output.delete(:rent_amount) unless output[:rent_amount].blank?

        # Create new instance
        YearlyRent.new_from_fl(output)
      end

      # @return a hash suitable for use in a save request to the back office
      def request_save_for_calc
        output = {}
        output['ins1:RentYear'] = @year unless @year.blank?
        output['ins1:RentAmount'] = or_zero(@rent)
        output
      end

      # Summarises the state of yearly rents.
      # NB return reference can be nil but if it's set then a value must be provided so we return :missing.
      # @return :good, :missing (value missing), :bad (fails validation) or :empty (no value).
      def validation_yearly_rents
        return :missing if @rent.blank?

        return :good if valid?

        :bad
      end
    end
  end
end
