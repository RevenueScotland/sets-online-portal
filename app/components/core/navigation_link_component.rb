# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # This provides common functionality for displaying navigation links
  #
  # This base component manages the stack of links that have been visited so that they can be displayed
  #
  # The links are displayed using either a back link or a breadcrumb link, these are UI specific
  # @see DS::BackLinkComponent
  # @see DS::BreadcrumbsComponent
  #
  # @example To clear the stack
  #   <% content_for(:navigation_link, :clear_stack) %>
  #
  # @example To go to a specific page (only works for back link)
  #   <% content_for(:back_link, 'path'}) %>
  #
  # @example To provide breadcrumbs
  #   <% content_for(:navigation_link) do %>
  #     <%= d.breadcrumb_component %>
  #   <% end %>
  class NavigationLinkComponent < ViewComponent::Base
    # @param skip_page [Boolean] stops the existing page being added to the stack. This won't stop the back
    #   link showing but means the next page will have the same back link as this page
    # @param clear_stack [Boolean] causes the existing stack to be cleared prior to adding the current page
    #   to the stack. This means no link will be shown as the current page is never included
    # @param current_page [Hash] This overrides the URL and page title to be added to the stack. Use this
    #   if you want to manipulate them before they are added to the stack e.g. to remove parameters. There are
    #   (or will be) utility routines added to this routine to help with this.
    #   You can provide both or only one option the other will be defaulted based on the normal rules
    #   { page_url: <URL>, page_title: <TITLE> }
    # @option current_page [String] :page_url The url to use for the current page
    # @option current_page [String] :page_title The page title to use for the current page
    def initialize(skip_page: false, clear_stack: false, current_page: nil)
      super()
      @skip_page = skip_page
      @clear_stack = clear_stack
      @current_page = current_page
    end

    # Sets up the link stack based on current information, called before the page in rendered
    def before_render
      manage_link_stack
    end

    # A link is only shown when there is a previous link to show
    def render?
      link_stack.length >= index
    end

    # Convenience routine to turn the content for into a consistent hash of parameters for this routine
    # It handles the back link formats as breadcrumbs are always rendered using the breadcrumb component
    #
    # It interprets the passed in data types so that the developer only needs to provide
    # the simple options
    #
    # The rules are
    # * If one of skip_page or clear_stack is provided then this is converted to that parameter as true
    # * If another string is provided that is assumed to be overriding the current page URL
    #
    # @example Triggering a clear stack on a page with the back link
    #   content_for(:navigation_link,:clear_stack)
    # @example Overriding the current URL for the page
    #   content_for(:navigation_link,"/my_url/with_no/parameters")
    #
    # @param options [String] the current contents of the content for (always a string)
    # @return [Hash] an options hash with all the options expanded
    def self.expand_options(options)
      return {} if options.blank?

      # If the options is a string which is one of the boolean keys then turn into symbol hash
      return { options.to_sym => true } if %w[skip_page clear_stack].include?(options)

      # Assume it is the current page url for the back link
      { current_page: { page_url: options } }
    end

    protected

    attr_reader :skip_page

    # Convenience method to provide access to the link stack stored in the session
    # @return [Array] The array of links
    def link_stack
      session = request.session
      return session[:link_stack] = [] if session[:link_stack].nil?

      # Storing the session converts the symbols to strings the below converts them back
      session[:link_stack].each(&:symbolize_keys!)
    end

    # Returns the correct index (from the end of the stack) based on the skip page parameter
    # If he current page is skipped then we want the top of the stack not the previous page
    # @return [Integer] 1 or 2 for the depth of the stack
    def index
      skip_page ? 1 : 2
    end

    private

    attr_reader :clear_stack, :current_page

    # Manages the back_link stack within the session. Used for breadcrumbs and the back link
    # Updates the links based on any options provided into the component
    def manage_link_stack
      return unless request.get?

      check_existing_stack

      # Store the fact we didn't store this page in the stack if the user has said so
      # OR if the user has overridden the URL (otherwise the check stack on the next request
      # adds it back in)
      store_skip_page_option(true) if skip_page || current_page

      add_current_page(current_page) unless skip_page

      Rails.logger.debug { "Back links stack is now #{link_stack.inspect}" }
    end

    # Store the fact we skipped this page in the session. This is used on the next page
    # to stop this page being added as a referrer
    # @param skip_page [Boolean] are we skipping this page
    def store_skip_page_option(skip_page)
      request.session[:skip_page] = skip_page
    end

    # Sets the existing link stack up before adding the current page to it
    #
    # This may clear the stack, but also checks the previous page wasn't missed, which it can be if the user
    # has clicked rapidly between pages
    def check_existing_stack
      if clear_stack

        link_stack.clear
      else
        check_referrer_on_stack
      end
    end

    # If the user has been clicking between pages fast or has come from a page outside the system
    # the previous page will not be on the stack, so this routine checks and adds the referrer (if there is one)
    # to the stack if it is not already present
    #
    # @note
    #   When using breadcrumbs we can only get the referrer from the browser. This routine tries to derive a title
    #   from the translations using the page path, if it fails then it just uses the URL see {#try_to_get_title}
    def check_referrer_on_stack
      uri = uri_parse_path(request.referer, host: request.host)

      # may not have a referrer or we may have skipped the last page in which case
      # we don't want to add it here
      return if uri.nil? || request.session[:skip_page] == true

      # Try to get the title based on the path and no parameters
      last_page_title = try_to_get_title(uri.path)

      # Add the page to the stack if not present
      add_page_to_stack(uri.path, last_page_title, uri.query)
    end

    # Adds the current page onto the stack
    #
    # The current page details may be overridden by the current_page hash
    def add_current_page(current_page)
      current_page ||= {}

      # If the url has been overridden then we don't add the parameters automatically
      if current_page[:page_url]
        this_page_url = current_page[:page_url]
      else
        uri = uri_parse_path(request.env['ORIGINAL_FULLPATH'], host: request.host)
        this_page_url = uri.path
      end
      # If the below doesn't appear to be working check that the title is the first content_for
      this_page_title = view_context.page_title

      # apply the overrides
      this_page_title = current_page[:page_title] if current_page[:page_title]
      add_page_to_stack(this_page_url, this_page_title, uri&.query)
    end

    # Adds the given page and title onto the stack
    #
    # If the page url already exists on the stack we simply cut the stack back to that
    # position, and any title is ignored
    # Query parameters are updated to the latest ones, if they exist
    #
    # @param page_path [String] The URL to add
    # @param page_title [String] The title of the page
    # @param page_query [String] The query parameters
    def add_page_to_stack(page_path, page_title, page_query)
      # Find index of the current page in the stack
      # and then slice back down to that
      page_url = "#{page_path}#{"?#{page_query}" if page_query}"
      index = link_stack.find_index { |i| i[:page_path] == page_path }
      if index.nil?
        link_stack.push({ page_path: page_path, page_title: page_title, page_url: page_url })
      else
        link_stack.slice!(index + 1, link_stack.length)
        link_stack[index][:page_url] = page_url
      end
    end

    # Tries to allocate a title to the page based on the path, returns the url
    # if no title found
    #
    # @param page_url [String] The URL to process
    # @return [String] The title of the page
    def try_to_get_title(page_url)
      # Try and get a translation for the page title, otherwise use URL
      translation_key = page_url[1..].gsub(%r{/_?}, '.').tr('-', '_')
      if translation_key.blank?
        # :nocov:
        # No coverage we shouldn't hit this fall back position
        page_url
        # :nocov:
      else
        I18n.t("#{translation_key}.title", default: page_url)
      end
    end

    # Grabs the path of the url
    # @param link_path [String] the current URL
    # @param host [String] the current host, if passed the URI is checked to be for the same host
    # @return [URI] The parsed URI, or nil if not for the same host
    def uri_parse_path(link_path, host: nil)
      return if link_path.blank?

      uri = URI.parse(link_path)
      if host.present? && uri.host.present? && uri.host != host
        Rails.logger.warn { "#{link_path} is not being added to stack as it does not match #{host}" }
        return
      end

      uri
    end
  end
end
