# frozen_string_literal: true

# Concerns for returns
module Returns
  # Common code for LBTT controllers which need to update the tax calculations information
  module LbttTaxHelper
    extend ActiveSupport::Concern

    # Call the back office to update the calculations based on the latest data
    # Doesn't run if there's not enough data (ie validation fails).
    # Doesn't update the orig_ fields since we're just updating the data
    # Requires @lbtt_return be set up (which it usually is).
    def update_tax_calculations
      Rails.logger.debug('Checking if valid enough for a call to lbtt_transactions')
      return unless @lbtt_return.valid_for_tax_calc?

      @lbtt_return.tax.calculate_tax(current_user, @lbtt_return, false)

      store_calculated_tax
    end

    private

    # If there's no errors reported, updates/saves @lbtt_return in the LbttController wizard cache.
    def store_calculated_tax
      # don't store anything if back office sent errors
      if @lbtt_return.errors.any? || @lbtt_return.tax.errors&.any?
        Rails.logger.debug("Not updating wizard_cache with tax calculations this time - #{@lbtt_return.errors}")
        false
      else
        Rails.logger.debug("Updating wizard_cache with tax calculations - #{@lbtt_return.tax}")
        wizard_save(@lbtt_return, LbttController)
        true
      end
    end
  end
end
