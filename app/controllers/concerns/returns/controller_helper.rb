# frozen_string_literal: true

# Concerns for returns
module Returns
  # Helpful methods common to Returns controllers.
  module ControllerHelper
    extend ActiveSupport::Concern

    # Validate params[ref_no] is a number and not some kind of attack.
    def validate_load_param
      return if params[:ref_no] =~ /\d+/

      raise Error::AppError.new('Return Load', 'Invalid return number for loading')
    end

    # Extracted summary method
    # Checks if draft button was pressed & redirects to the save draft action if validation passes.
    # @return true if button was pressed, else false.
    def manage_draft(model)
      if params[:save_draft]
        Rails.logger.debug('save_draft pressed')
        if model.valid?(:draft)
          Rails.logger.debug('  validation passed')
          redirect_to action: :save_draft
          return true
        end
      end

      false
    end

    # Extracted summary method
    # Checks if calculate button was pressed & redirects to the calculate action if validation passes.
    # @return true if button was pressed, else false.
    def manage_calculate(model)
      if params[:calculate_return]
        Rails.logger.debug('calculate_return pressed - checking validation')
        if model.valid?(:submit)
          Rails.logger.debug('  validation passed')
          redirect_to action: :declaration_calculation
          return true
        end
      end

      false
    end
  end
end
