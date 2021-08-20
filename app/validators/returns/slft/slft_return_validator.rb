# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise SLfT return models
  module Slft
    # Validation model for the SLfT return
    class SlftReturnValidator < AbstractReturnValidator
      # validate complete slft_return model including child elements
      # Note the design pattern of passing the list of errors around outside of the model.errors list.  This is
      # because every time we call model.valid? it calls model.errors.clear so we would end up saying validation
      # passed when there errors.
      # @param slft [SlftReturn] the model to validate
      def validate(slft)
        save_validation(slft)
        # return if there is validation failed for required object
        return if slft.errors.present?

        # list to store error messages to be added to the model at the end (so it doesn't get cleared
        # by calls to model.valid?)
        errors = []
        validate_transaction_section(slft, errors)
        validate_credit_claimed_section(slft, errors)
        validate_site_waste_details(slft, errors)

        build_model_errors(slft, errors)
      end

      # performs the validation when the user presses submit
      # does the draft validation then that specific to save
      def save_validation(slft)
        # clear previous error
        slft.errors.clear

        slft.errors.add(:base, :missing_about_the_transaction, link_id: 'add_return_period') if slft.year.blank?
        slft.errors.add(:base, :missing_credits_claimed, link_id: 'add_credit_details') if slft.slcf_yes_no.blank?
      end

      # validate transaction section
      def validate_transaction_section(slft, errors)
        # Already showing validation on this condition( @see SlftReturn model) to fill details in this section
        # if it is completely blank
        return if slft.year.blank?

        # log error
        add_error(errors, (I18n.t '.return_period'), slft) unless slft.valid? SlftReturn.return_period_attr_list
      end

      # validate credit claimed section
      def validate_credit_claimed_section(slft, errors)
        # Already showing validation on this condition( @see SlftReturn model) to fill details in this section
        # if it is completely blank
        return if slft.slcf_yes_no.blank?

        # log error
        add_error(errors, (I18n.t '.credit_claimed'), slft) unless slft.valid? SlftReturn.credit_claimed_attr_list
      end

      # validate each site and associated waste details in the slft return
      def validate_site_waste_details(slft, errors)
        slft.sites.values&.each do |site|
          # only validate waste details if there are any
          return unless site.wastes.any?

          # if site have list of wastes then validate each waste
          validate_wastes(site, errors)
        end
      end

      # Validate individual waste object from the list for particular site
      def validate_wastes(site, errors)
        site.wastes.each_value do |waste|
          next if waste.valid? Waste.attribute_list

          error_msg = waste.ewc_code.blank? ? "Waste details for #{site.site_name}" : error_msg_for_site(waste, site)

          # log error
          add_error(errors, error_msg, waste)
        end
      end

      # Error message for waste site error if description is not blank
      def error_msg_for_site(waste, site)
        code_text = waste.description.blank? ? waste.ewc_code : "#{waste.ewc_code}/#{waste.description}"
        "Waste details with EWC code #{code_text} for #{site.site_name}"
      end
    end
  end
end
