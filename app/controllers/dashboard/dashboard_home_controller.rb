# frozen_string_literal: true

module Dashboard
  # DashboardHomeController handles all the dashboard home related things.
  class DashboardHomeController < ApplicationController
    authorise requires_all: AuthorisationHelper::DASHBOARD_HOME

    # This processes what main dashboard would show in terms of the list of messages, returns and transactions.
    def index
      load_messages
      load_returns
      load_outstanding
    end

    private

    # Used for the messages section, to go to it's next page.
    def message_page
      params[:message_page]
    end

    # Used for the all returns section, to go to it's next page.
    def returns_page
      params[:returns_page]
    end

    # Used for the outstanding balance section, to go to it's next page.
    def outstanding_page
      params[:balance_page]
    end

    # get the messages
    def load_messages
      return unless can? AuthorisationHelper::VIEW_MESSAGES

      @messages, @messages_pagination =
        Message.list_paginated_messages(current_user, message_page, MessageFilter.new(unread_only: 'yes'), 3)
    end

    # get the returns
    def load_returns
      return unless can? AuthorisationHelper::VIEW_RETURNS

      @dashboard_returns, @returns_pagination =
        DashboardReturn.list_all_returns(current_user, returns_page, DashboardReturnFilter.new(draft_only: 'Y'), 3)
    end

    # get the outstanding
    def load_outstanding
      @outstanding, @outstanding_pagination =
        DashboardReturn.list_all_returns(current_user,
                                         outstanding_page,
                                         DashboardReturnFilter.new(outstanding_balance: 'Y', return_status: 'L'), 3)
    end
  end
end
