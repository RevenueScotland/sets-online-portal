# frozen_string_literal: true

# module to organise tax return models
module Returns
  # Common returns superclass validator with methods common to returns.
  class AbstractReturnValidator < ActiveModel::Validator
    # Adds error details to a list and logs detailed information about errors in the model (so we can tell the client
    # why the validation message was shown).
    # @param error_list [Array] list of errors that we add to and which is eventually used by #build_model_errors
    # @param field_to_blame [String] displayable name of the form attribute or section on which errors occured
    #                                ie the area that's got errors
    # @param model [ActiveModel] object containing errors to be logged pass nil for list
    def add_error(error_list, field_to_blame, model)
      # always log something (ie even if errors is blank)
      Rails.logger.info "Errors validating: #{field_to_blame}"

      # log detail about errors due to specific attributes (ignore :base ones as they may have been added by
      # calling #build_model_errors prematurely)

      # add the general reason for the error to the list
      error_list << field_to_blame

      model.errors.each { |key, message| Rails.logger.info "  #{key} - #{message}" unless key == :base }
    end

    # Clears out existing errors on the model and creates new errors in the :base context with a suitable message.
    # @param model [ActiveModel] object to add errors to
    # @param errors [Array] list of error sections created by the #add_error method.  Used as the attr arguement when
    #                       adding an error to the model
    # @param message [Symbol] translation key to the message to add; defaults to :section_not_complete
    def build_model_errors(model, errors, message = :section_not_complete)
      return if errors.blank?

      model.errors.clear
      errors.each { |err_attr| model.errors.add :base, message, attr: err_attr unless err_attr.nil? }
    end
  end
end
