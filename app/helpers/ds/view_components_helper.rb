# frozen_string_literal: true

# Digital Scotland specific UI code
module DS
  # Adds helpers to the standard rails helpers to allow digital scotland components to be used in the
  # template file using ds_<name> rather than the full render command.
  # There is an equivalent that adds into a specific view component if needed
  # @see DS::ComponentHelpers
  module ViewComponentsHelper
    DS::ComponentHelpers::COMPONENT_LIST.merge(DS::ComponentHelpers::FORM_COMPONENT_LIST).each do |name, klass|
      define_method(name) do |*args, **kwargs, &block|
        capture do
          render(klass.constantize.new(*args, **kwargs)) do |com|
            block.call(com) if block.present?
          end
        end
      end
    end

    # This overrides the standard Rails form_with to add specific options and to work with components
    # @see DS::FormComponent
    #
    # {https://api.rubyonrails.org/v6.0.2/classes/ActionView/Helpers/FormHelper.html#method-i-form_with form_with}
    #
    # Forced options are
    # * Add novalidate to prevent use of  HTML validation
    # * Add autocomplete off to prevent data being stored
    # @param options [Hash] The standard form with options, plus specific options
    # @option options [String] :button_action the action name to use on the submit button
    # @option options [String] :button_label An overriding label to be used on the button
    # @option autofocus [Boolean] should autofocus be on the submit button
    # @option autocomplete [Boolean] Turn autocomplete back on
    # @option file_upload [Boolean] Add the file upload controller on
    # @option hidden_submit [Boolean] Adds a hidden submit button to the top of the form that will act as the
    #  default action when the user pushes the enter key
    # @return [String] The html to be rendered
    # @yield [FormComponent] The form component
    def ds_form_with(**options, &block) # rubocop:disable Metrics/MethodLength
      button_action = options.delete(:button_action)
      button_label = options.delete(:button_label)
      autofocus = options.delete(:autofocus)
      file_upload = options.delete(:file_upload)
      autocomplete = (options.delete(:autocomplete) ? 'on' : 'off')
      options[:multipart] = true if file_upload
      hidden_submit = options.delete(:hidden_submit)
      form_with(**{ html: { novalidate: true, autocomplete: autocomplete } }.deep_merge(options)) do |form|
        render(DS::FormComponent.new(
                 builder: form, button_action: button_action, button_label: button_label, autofocus: autofocus,
                 file_upload: file_upload, hidden_submit: hidden_submit
               ), &block)
      end
    end

    # Renders a navigation link on the page
    #
    # The default is a back link to the previous page, but you can override this by
    # providing a content for on the individual page
    #
    # @example To clear the stack
    #   <% content_for(:navigation_link, :clear_stack) %>
    #
    # @example To provide breadcrumbs
    #   <% content_for(:navigation_link) do %>
    #     <%= ds_breadcrumbs %>
    #   <% end %>
    #
    # @see DS::BreadcrumbsComponent and DS::BackLinkComponent for how to customise the link
    # @param options [Hash] configuration options
    def ds_navigation_link(options = {})
      content_for = content_for(:navigation_link)
      back_link = content_for(:back_link)

      # If the content for is nil or a back link is provided then use the standard back link
      # Also assume it is a back link unless the content for is already rendered
      if back_link.present?
        render(DS::BackLinkComponent.new(back_link_url: back_link))
      elsif content_for.nil? || !content_for.strip.start_with?('<nav')
        options = DS::BackLinkComponent.expand_options(content_for)
        render(DS::BackLinkComponent.new(**options))
      else
        content_for
      end
    end
  end
end
