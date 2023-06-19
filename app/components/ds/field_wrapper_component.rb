# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # This is the standard Digital Scotland field wrapper that adds labels, hints and errors to a rendered field
  #
  # It also records any errors for the field in the error_summary_list content_for (see {DS::ErrorSummaryComponent}).
  # Most of the logic is from {Core::WrapperDelegate}
  # see {https://designsystem.gov.scot/components/question}
  class FieldWrapperComponent < Core::FieldWrapperComponent
    # Utility function that adds extra html options to a field for the width and the aria described by if they are
    # needed, called from template for the component
    # @param existing_hash The existing hash of html options
    # @param ds_width_class The width class for this field
    # @return [Hash] the revised hash with the extra options for rendering the field
    def add_ds_html_options(existing_hash, ds_width_class: nil)
      extra_options = { class: "#{'ds_input--error' if error_list.present?} #{ds_width_class}".strip }
      add_html_options(existing_hash, extra_options: extra_options)
    end
  end
end
