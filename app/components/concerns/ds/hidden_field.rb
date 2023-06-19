# frozen_string_literal: true

# Main handling all of the core functions to support an application
module DS
  # Adds support to a view component to allow a standard hidden_fields on that component
  module HiddenField
    extend ActiveSupport::Concern

    # Convenience method for using hidden field on a component
    #
    # @example
    #   <%= ds_form_with(model: @account, url: @post_path) do |f| %>
    #     <%= f.ds_hidden_field(method: :registration_type) %>
    #   <% end %>
    # @return [String] The html to be rendered
    def ds_hidden_field(*args, **kwargs)
      builder.hidden_field(*args, **kwargs)
    end
  end
end
