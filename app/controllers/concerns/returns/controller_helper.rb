# frozen_string_literal: true

# Concerns for returns
module Returns
  # Helpful methods common to Returns controllers.
  module ControllerHelper
    extend ActiveSupport::Concern

    # Validate params[ref_no] is a number and not some kind of attack.
    def validate_load_param
      return if params[:id].match?(/\d+/)

      raise Error::AppError.new('Return Load', 'Invalid return number for loading')
    end

    # Extracted summary method
    # Checks if draft button was pressed & redirects to the save draft action if validation passes.
    # @return true if button was pressed, else false.
    def manage_draft(model)
      return false unless params[:save_draft]

      Rails.logger.debug('save_draft pressed')
      if model.valid?(:draft)
        Rails.logger.debug('  validation passed')
        redirect_to(action: :save_draft)
      else
        render(status: :unprocessable_entity)
      end
      true
    end

    # Extracted summary method
    # Checks if calculate button was pressed & redirects to the calculate action if validation passes.
    # @return true if button was pressed, else false.
    def manage_calculate(model)
      return false unless params[:calculate_return]

      Rails.logger.debug('calculate_return pressed - checking validation')
      if model.valid?(:submit)
        Rails.logger.debug('  validation passed')
        redirect_to(action: :declaration_calculation)
      else
        render(status: :unprocessable_entity)
      end
      true
    end

    # Does the account have a dd instruction
    # @return [String] returns true if the account has the service otherwise false
    def account_has_dd_instruction?
      return false if current_user.nil?

      @account ||= Account.find(current_user)
      @account.dd_instruction_available
    end

    included do
      helper_method :account_has_dd_instruction?
    end
  end
end
