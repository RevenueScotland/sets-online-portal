# frozen_string_literal: true

# module to organise tax return models
module Returns
  # module to organise Sat return models
  module Sat
    # Validation model for the Sat return
    class SatReturnValidator < AbstractReturnValidator
      # validate complete Sat_return model including child elements
      # Note the design pattern of passing the list of errors around outside of the model.errors list.  This is
      # because every time we call model.valid? it calls model.errors.clear so we would end up saying validation
      # passed when there errors.
      # @param sat [satReturn] the model to validate
      def validate(sat)
        save_validation(sat)
        # return if there is validation failed for required object
        return if sat.errors.present?

        # list to store error messages to be added to the model at the end (so it doesn't get cleared
        # by calls to model.valid?)
        errors = []
        validate_site_waste_details(sat, errors)

        build_model_errors(sat, errors)
      end

      # performs the validation when the user presses submit
      # does the draft validation then that specific to save
      def save_validation(sat)
        # clear previous error
        sat.errors.clear
      end

      # validate each site and associated waste details in the sat return
      def validate_site_waste_details(sat, errors)
        no_sites_data = 0
        sat.sites&.each_value do |site|
          # Skip the sites where aggregate_activity is set to No
          next if site.tld_nil_submit == 'Y'

          # check to see if the any data has been added for all sites
          no_sites_data = 1 if site.missing_sat_details_data?
        end

        return unless no_sites_data.positive?

        add_error(errors, (I18n.t '.returns.sat.summary.missing_sat_details'), sat)
      end
    end
  end
end
