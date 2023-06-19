# frozen_string_literal: true

# RS specific UI code
module RS
  # Adds support to a view component to allow digital scotland components to be used in the
  # template file using ds_<name> rather than the full render command.
  # There is an equivalent that adds into the standard Rails helpers
  # @see RS::ViewComponentsHelper
  module ComponentHelpers
    extend ActiveSupport::Concern

    # Support Revenue Scotland specific components
    COMPONENT_LIST = {
      rs_company_search: 'RS::CompanySearchComponent',
      rs_conditional_visibility: 'RS::ConditionalVisibilityComponent',
      rs_financial_transaction_table: 'RS::FinancialTransactionTableComponent',
      rs_message_table: 'RS::MessageTableComponent',
      rs_notification_banner: 'RS::NotificationBannerComponent',
      rs_resource_item_table: 'RS::ResourceItemTableComponent',
      rs_return_table: 'RS::ReturnTableComponent',
      rs_site_header_navigation: 'RS::SiteHeaderNavigationComponent',
      rs_site_table: 'RS::SiteTableComponent',
      rs_user_table: 'RS::UserTableComponent',
      rs_lbtt_party_table: 'RS::PartyTableComponent'
    }.freeze

    # Support Revenue Scotland specific components
    FORM_COMPONENT_LIST = {
      rs_file_upload: 'RS::FileUploadComponent',
      rs_percent: 'RS::PercentComponent'
    }.freeze

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

  # Load the rs form components into the ds form component
  ActiveSupport.on_load(:ds_form_component) do
    Rails.logger.info { 'Loading RS::ComponentHelpers into DS::FormComponent' }

    include RS::ComponentHelpers
  end
end
