# frozen_string_literal: true

# DS specific parts of the UI
module DS
  # Display a standard back link
  # The management of the stack is from {Core::NavigationLinkComponent}
  class BackLinkComponent < Core::NavigationLinkComponent
    # (see NavigationLinkComponent#initialize)
    # @param back_link_url [String] the back link to display, overrides anything on the stack which is still
    #   maintained
    def initialize(skip_page: false, clear_stack: false, current_page: nil, back_link_url: nil)
      super(skip_page: skip_page, clear_stack: clear_stack, current_page: current_page)
      @back_link_url = back_link_url
    end

    # Returns the previous page URL, or the override URL provided by the developer
    # @return [String] the url to display as the back link
    def back_link_url
      return @back_link_url if @back_link_url

      # render? controls if this is shown or not
      link_stack[(index * -1)][:page_url]
    end
  end
end
