# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Adds support to a view component to allow ds_fields_for on that component
  module FieldsFor
    extend ActiveSupport::Concern

    # Adds the appropriate method to the base class when included
    included do
      if method_defined?(:builder)

        # This overrides the standard Rails fields_for to to work with components
        #
        # @example
        #   <%= ds_form_with(model: @account, url: @post_path) do |f| %>
        #     <%= f.ds_fields_for(@account.account_type) do |at| %>
        #       <%= at.ds_radio_group(method: :registration_type, options_list: AccountType.list ) %>
        #     <% end %>
        #   <% end %>
        # @return [String] The html to be rendered
        # @yield [FieldsForComponent] The FieldsFor component
        def ds_fields_for(*args, **kwargs, &block)
          builder.fields_for(*args, **kwargs) do |form|
            render(DS::FieldsForComponent.new(
                     builder: form
                   ), &block)
          end
        end
      else
        def ds_fields_for(*args, **kwargs, &block)
          fields_for(*args, **kwargs) do |form|
            render(DS::FieldsForComponent.new(
                     builder: form
                   ), &block)
          end
        end
      end
    end
  end
end
