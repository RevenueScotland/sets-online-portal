# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # This provides a wrapper for delivering a fields_for based on the component architecture. It is yielded into the page
  # by ds_field_for method {DS::FieldsFor}, so you normally would not render this directly
  #
  # @example
  #   <%= ds_form_with(model: @test_model ) do |f| %>
  #     <%= f.email_field(method: :email, one_question: true, width: 'two-thirds') %>
  #   <% end %>
  class FieldsForComponent < Core::FieldsForComponent
    include DS::ComponentHelpers
    include DS::HiddenField
  end
end
