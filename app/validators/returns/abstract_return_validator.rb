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

      model.errors.each do |error|
        Rails.logger.info "  #{error.attribute} - #{error.message}" unless error.attribute == :base
      end
    end

    # Clears out existing errors on the model and creates new errors in the :base context with a suitable message.
    # @param model [ActiveModel] object to add errors to
    # @param errors [Array] list of error sections created by the #add_error method.  Used as the attr argument when
    #                       adding an error to the model
    def build_model_errors(model, errors)
      return if errors.blank?

      model.errors.clear
      errors.each do |err_attr|
        next if err_attr.blank?

        # Note lowercase the first letter as some section names have upper case first which does not
        # work with the current message
        err_attr[0] = err_attr[0].downcase
        model.errors.add(:base, :section_not_complete, attr: err_attr)
      end
    end
  end
end
