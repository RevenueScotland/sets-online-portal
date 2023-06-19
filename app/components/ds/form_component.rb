# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # This provides a wrapper for delivering a form based on the component architecture. It is yielded into the page
  # by the {ViewComponentsHelper#ds_form_with}, so you normally would not render this directly
  #
  # The FormComponent automatically renders a summary header using the {DS::ErrorSummaryComponent} and a submit button
  # at the end of the form using the {DS::SubmitComponent}
  #
  # @example
  #   <%= ds_form_with(model: @test_model ) do |f| %>
  #     <%= f.email_field(method: :email, one_question: true, width: 'two-thirds') %>
  #   <% end %>
  class FormComponent < Core::FormComponent
    include DS::ComponentHelpers
    include DS::FieldsFor
    include DS::HiddenField

    ActiveSupport.run_load_hooks(:ds_form_component, self)
  end
end
