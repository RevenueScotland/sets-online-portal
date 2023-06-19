# frozen_string_literal: true

# DS specific parts of the UI (normally referencing classes)
module DS
  # Display a standard breadcrumbs link
  # The management of the stack is from {Core::NavigationLinkComponent}
  class BreadcrumbsComponent < Core::NavigationLinkComponent
    # (see NavigationLinkComponent#initialize)
    # @param breadcrumb_urls [Array<Hash>] The list of breadcrumbs to show, normally an Array but if there is only
    #   one breadcrumb you can provide a single hash {page_url: 'www.bbc.co.uk',page_title: 'BBC - Home' }
    def initialize(skip_page: false, clear_stack: false, current_page: nil, breadcrumb_urls: nil)
      super(skip_page: skip_page, clear_stack: clear_stack, current_page: current_page)
      @breadcrumb_urls = breadcrumb_urls
    end

    # Returns the list of breadcrumb pages, or the list provided if the developer has overridden the list
    # @return [Array] the urls to display as the breadcrumbs e.g.
    #  {page_url: 'www.bbc.co.uk', page_title: 'BBC - Home' }
    def breadcrumb_urls
      if @breadcrumb_urls
        return @breadcrumb_urls if @breadcrumb_urls.is_a? Array

        return [@breadcrumb_urls]
      end

      # The render? controls if this should be shown or not
      link_stack
    end
  end
end
