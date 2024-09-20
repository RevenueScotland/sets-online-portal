# frozen_string_literal: true

# Digital Scotland specific UI code
module DS
  # Adds support to a view component to allow digital scotland components to be used in the
  # template file using ds_<name> rather than the full render command.
  # There is an equivalent that adds into the standard Rails helpers
  # @see DS::ViewComponentsHelper
  module ComponentHelpers
    extend ActiveSupport::Concern

    # Supported list of Digital Scotland components
    # ds_form_component is not added in this list as it has a specific template helper
    COMPONENT_LIST = {
      ds_address_search: 'DS::AddressSearchComponent',
      ds_back_to_top: 'DS::BackToTopComponent',
      ds_breadcrumbs: 'DS::BreadcrumbsComponent',
      ds_button: 'DS::ButtonComponent',
      ds_button_group: 'DS::ButtonGroupComponent',
      ds_cookie_banner: 'DS::CookieBannerComponent',
      ds_details: 'DS::DetailsComponent',
      ds_field_set: 'DS::FieldSetComponent',
      ds_inset_text: 'DS::InsetTextComponent',
      ds_link: 'DS::LinkComponent',
      ds_notification_banner: 'DS::NotificationBannerComponent',
      ds_notification_panel: 'DS::NotificationPanelComponent',
      ds_page_header: 'DS::PageHeaderComponent',
      ds_pagination: 'DS::PaginationComponent',
      ds_paragraph: 'DS::ParagraphComponent',
      ds_print_link: 'DS::PrintLinkComponent',
      ds_section_title: 'DS::SectionTitleComponent',
      ds_section_sub_title: 'DS::SectionSubTitleComponent',
      ds_summary_list: 'DS::SummaryListComponent',
      ds_skip_link: 'DS::SkipLinkComponent',
      ds_table: 'DS::TableComponent',
      ds_warning: 'DS::WarningComponent',
      ds_phase_banner: 'DS::PhaseBannerComponent'
    }.freeze

    # Supported list of Digital Scotland form components
    # These are handled separately as the builder is automatically passed in
    FORM_COMPONENT_LIST = {
      ds_checkbox: 'DS::CheckboxComponent',
      ds_checkbox_group: 'DS::CheckboxGroupComponent',
      ds_currency: 'DS::CurrencyComponent',
      ds_date_picker: 'DS::DatePickerComponent',
      ds_email_field: 'DS::EmailFieldComponent',
      ds_error_summary: 'DS::ErrorSummaryComponent',
      ds_field_wrapper: 'DS::FieldWrapperComponent',
      ds_file_field: 'DS::FileFieldComponent',
      ds_password_field: 'DS::PasswordFieldComponent',
      ds_radio_group: 'DS::RadioGroupComponent',
      ds_select: 'DS::SelectComponent',
      ds_submit: 'DS::SubmitComponent',
      ds_table_form: 'DS::TableFormComponent',
      ds_text_area: 'DS::TextAreaComponent',
      ds_text_field: 'DS::TextFieldComponent'
    }.freeze

    # Override this method to set defaults for all components that are included
    # for example to set a width
    # If using this remember that not all components support all options
    # @param _component_name [String] The name of the component
    def form_component_defaults(_component_name)
      {}
    end

    COMPONENT_LIST.each do |name, klass|
      define_method(name) do |*args, **kwargs, &block|
        capture do
          render(klass.constantize.new(*args, **kwargs)) do |com|
            block.call(com) if block.present?
          end
        end
      end
    end

    included do
      FORM_COMPONENT_LIST.each do |name, klass|
        # If the class we are being included in has a builder method pass that down automatically
        if method_defined?(:builder)
          define_method(name) do |*args, **kwargs, &block|
            capture do
              render(klass.constantize.new(*args, **form_component_defaults(klass)
                                           .merge({ builder: builder }).merge(kwargs))) do |com|
                block.call(com) if block.present?
              end
            end
          end
        else
          define_method(name) do |*args, **kwargs, &block|
            capture do
              render(klass.constantize.new(*args, **form_component_defaults(klass).merge(kwargs))) do |com|
                block.call(com) if block.present?
              end
            end
          end
        end
      end
    end
  end
end
