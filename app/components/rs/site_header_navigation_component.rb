# frozen_string_literal: true

# Main handling all of the core functions to support an application
module RS
  # Renders the list of navigation items on the page menu
  # This is normally rendered twice once for mobile and once for the website
  class SiteHeaderNavigationComponent < ViewComponent::Base
    include Core::ListValidator

    # List of allowed format types
    ALLOWED_FORMATS = %i[website mobile].freeze

    attr_reader :format, :menu_items

    # @param format [Symbol] The format being rendered
    def initialize(format:)
      super()
      @format = self.class.fetch_or_fallback(ALLOWED_FORMATS, format, :website)
    end

    # Runs before the render operation
    # Used to build the data as it needs access to the controller
    def before_render
      @menu_items = if current_user.nil?
                      create_unauthenticated_menu_items
                    else
                      create_authenticated_menu_items
                    end
    end

    private

    # Show cancel actions only for the given paths in the application
    # TODO : make the following more configurable/ generic
    def show_cancel_action_only?(path)
      messages_wizard_pages = ['dashboard/messages/upload-documents', 'dashboard/messages/send-message',
                               'dashboard/messages/new']
      (path.include?('returns/') && !path.ends_with?('/save_draft') &&
         !path.ends_with?('/declaration_submitted')) || messages_wizard_pages.any? { |page| path.include? page }
    end

    # Create the menu for an authenticated user
    def create_authenticated_menu_items
      path = request.path
      if show_cancel_action_only?(path)
        create_return_authenticated_menu_items
      elsif path.include?('/select_enrolment') || path.include?('/process_enrolment')
        create_select_enrolment_menu_items
      else
        create_standard_authenticated_menu_items
      end
    end

    # Create the menu for an authenticated user (non returns)
    def create_standard_authenticated_menu_items
      menu_items = dashboard_item
      menu_items += create_return_items
      menu_items += create_message_item
      menu_items += account_details_item
      menu_items += password_change_item
      menu_items += logout_item
      menu_items
    end

    # Create the menu for an authenticated user (returns)
    def create_return_authenticated_menu_items
      cancel_item
    end

    # Create the menu for select enrolment page
    def create_select_enrolment_menu_items
      logout_item
    end

    # Create the menu for an unauthenticated user
    def create_unauthenticated_menu_items
      [{ name: t('.login'), link: login_path, current?: current_page?(login_path) }]
    end

    # Creates the dashboard item
    def dashboard_item
      [{ name: t('.dashboard'), link: dashboard_path, current?: current_page?(dashboard_path) }]
    end

    # Creates the cancel item
    def cancel_item
      [{ name: t('.cancel'), link: dashboard_path, current?: current_page?(dashboard_path),
         data_action: 'cancel-warning#displayWarning' }]
    end

    # Creates the dashboard item
    def account_details_item
      [{ name: t('.account_details'), link: account_path, current?: current_page?(account_path) }]
    end

    # If the users password is about to expire a menu item to update it
    def password_change_item
      return [] unless current_user.days_to_password_expiry&.positive?

      [{ name: t('.password_notification', count: current_user.days_to_password_expiry),
         link: user_change_password_path, current?: current_page?(user_change_password_path) }]
    end

    # Create the return menu items (non, one or two)
    # @return [Array] menu items
    def create_return_items # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      menu_items = []
      if helpers.account_has_service?(:lbtt) && helpers.can?(RS::AuthorisationHelper::LBTT_SUMMARY)
        menu_items += create_lbtt_return_item
      end
      if helpers.account_has_service?(:slft) && helpers.can?(RS::AuthorisationHelper::SLFT_SUMMARY)
        menu_items += create_slft_return_item
      end
      if helpers.account_has_service?(:sat) && helpers.can?(RS::AuthorisationHelper::SAT_SUMMARY)
        menu_items += create_sat_return_item
      end

      menu_items
    end

    # Create an LBTT return menu item
    def create_lbtt_return_item
      [{ name: t('.lbtt_return'), link: returns_lbtt_return_type_path(new: true),
         current?: request.path.include?('returns/lbtt') }]
    end

    # Create an SLFT return menu item
    def create_slft_return_item
      [{ name: t('.slft_return'), link: returns_slft_summary_path(new: true),
         current?: request.path.include?('returns/slft') }]
    end

    # Create an SAT return menu item
    def create_sat_return_item
      [{ name: t('.sat_return'), link: returns_sat_return_period_path(new: true),
         current?: request.path.include?('returns/sat') }]
    end

    # Create a secure message menu item
    def create_message_item
      return [] unless helpers.can?(RS::AuthorisationHelper::CREATE_MESSAGE)

      [{ name: t('.new_message'), link: new_dashboard_message_path(step1: true),
         current?: current_page?(new_dashboard_message_path) }]
    end

    # Logout menu item
    def logout_item
      [{ name: t('.logout'), link: logout_path, current?: current_page?(logout_path) }]
    end
  end
end
