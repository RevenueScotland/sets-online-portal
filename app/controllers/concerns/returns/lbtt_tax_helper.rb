# frozen_string_literal: true

# Concerns for returns
module Returns
  # Common code for LBTT controllers which need to update the tax calculations information
  module LbttTaxHelper
    extend ActiveSupport::Concern

    # Call the back office to update the calculations based on the latest data
    # Requires @lbtt_return be set up (which it usually is).
    # @return [Boolean] true if this was successful
    def update_tax_calculations
      process_tax_calculation
    end

    # Call the back office to update the npv calculations based on the latest data
    # Requires @lbtt_return be set up (which it usually is).
    # @return [Boolean] true if this was successful
    def update_npv_calculation
      process_tax_calculation(:npv)
    end

    # Call the back office to update the calculations based on the relief_type changes
    # Requires @lbtt_return be set up (which it usually is).
    # @return [Boolean] true if this was successful
    def update_relief_type_calculation
      process_tax_calculation(:relief_type)
    end

    private

    # Does the actual processing for the tax calculation
    # @param calc_type [Symbol] the type of calculation npv or main
    # @return [Boolean] true if this was successful
    def process_tax_calculation(calc_type = :main)
      # if haven't enough information for tax calculation then consider successful.i.e. call
      # hasn't failed.
      return true unless @lbtt_return.ready_for_tax_calc?

      success = @lbtt_return.tax.calculate_tax(current_user, @lbtt_return, calc_type)
      if success
        success = @lbtt_return.tax.valid?(%i[total_reliefs])
        return false unless success

        @lbtt_return.show_trans_declaration = 'Y' if @lbtt_return.recalc_required == 'Y'
        @lbtt_return.recalc_required = 'N'
        wizard_save(@lbtt_return, LbttController)
      end
      success
    end
  end
end
