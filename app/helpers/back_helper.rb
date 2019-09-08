# frozen_string_literal: true

# The BackHelper is used to provide the back link on every page which keeps track of which is the last one by
# storing it into session[:link_visited] and then removing duplicates, which prevents the back link from looping
# back to the same link.
#
# The session[:link_visited] is kind-of treated as a stack; position 0 is the top.
# Position 0 is the current page and position 1 is the last visited link.
#
# FAQ:
#
# Q1: How do I show the back link on a page?
# A1: You simply don't have to do anything as this is already placed in all of the page.
#
# Q2: How do I remove the back link from a page?
# A2: You must add this line in your .html.erb at the top of the page:
#   <% content_for :hide_back_link, true %>
#
# Q3: How do I modify the back link's URI on the page?
# A3: To modify any parts of the back link you need to put the content_for section in your .html.erb page,
#     but instead of setting it to true, you will need to put in a symbol which will be called, either from
#     this BackHelper or another XHelper (eg LbttHelper) where that method is created.
#     Or simply put in the exact link.
#
#   @example Here are a few examples:
#     <% content_for :hide_back_link, :remove_param_new %>
#     <% content_for :hide_back_link, :lbtt_about_the_party_url %>
#     <% content_for :hide_back_link, '/en/dashboard' %>
#     <% content_for :hide_back_link, '/en/dashboard?page=3' %>
#
#   @example keeps the stack of previous links but hides the back link on that page
#     <% content_for :hide_back_link, :hide_link_keep_stack %>
#
#   @note what you put in the :hide_back_link content is what goes on to the link stack.
#
#   IMPORTANT (Pointers for how to create a method to set the content_for :hide_back_link):
#   1) Must have 1 parameter value (to pass the full path)
#   2) Do what is needed with it, only add extra methods in back_helper if it can be used by everyone.
#   3) Return the full url with all the changes made.
#
#   @example methods @see #change_all_params, @see #remove_params.
#   @see https://ruby-doc.org/stdlib-2.1.5/libdoc/uri/rdoc/URI.html
#
module BackHelper
  # Clears the session of previous page links.
  # @see application.html.erb content_for [true] option.
  # @return [String] empty space to hide back link.
  def clear_previous_stack
    # Always sets the session of visited links to the current page
    session[:link_visited] = [current_page_path(nil)]
    ''
  end

  # Creates the back link that will go to the correct previous page.
  #
  # The previous page link is processed by adding the current page's link onto the top of the stack
  # and then checking the stack for a loop @see #remove_loop.
  #
  # Finally shows the back link if the yield value is not 'hide_link_keep_stack'
  #
  # @note if the yield value is 'hide_link_keep_stack' this should keep the stack of links while hiding the back link
  # @yield [Symbol || String] The value that will be used to modify all or parts of the link if it exists.
  # @see application.html.erb content_for [false] option.
  # @return [HTML block element] link to previous page with the correct class.
  def previous_page_link
    session[:link_visited] = Array(link_stack).unshift(current_page_path(yield))

    # We want to clear the stack of the repeated link so that when the back link is clicked, it won't loop around.
    remove_not_last_link
    remove_reloaded_page
    remove_loop

    # Hides the back link while keeping the stack.
    return if yield == 'hide_link_keep_stack'

    # return link to the previous page in the stack
    # Applies the CSS class 'external-link' to the back button, will show confirm warning message
    # before leaving the page.
    # Note : warning message will apply only for those form where "data: form-dirty-warning-message" property is set.
    # @see return-form-dirty.js for details
    link_to(t('back'), link_stack[1], class: 'govuk-back-link external-link')
  end

  # Removes the 'new' param from the URL query string.
  #
  # @example in a .html.erb page :
  #   <% content_for :hide_back_link, :remove_param_new %>
  #
  # @return [String] The full link with the 'new' param removed
  def remove_param_new(link_path)
    remove_params(link_path, ['new'])
  end

  # Used for removing the params of the link.
  # Mainly used in methods which are called from methods passed in yield in the {#current_page_path} method.
  # @example removing the params id of a url
  #   remove_params(link_path, %w[id])
  # @param link_path [String] is the full path of the link.
  # @param link_params [Array] the params in an array of Strings that are to be removed.
  # @return [String] the first item of the list of link_queries if it's the only item, or all joined by '&'
  # @note the difference between params and queries in this case is that an example of params is 'id' and an example
  #   of a query is 'id=25', so the param is just the attribute and the query is the full attribute with value.
  #   In addition, removing the params also removes its values.
  def remove_params(link_path, link_params)
    return link_path if link_params.blank? || !link_path.include?('?')

    link_queries = URI(link_path).query.split('&')
    # Looking at each of the link params - the params to be removed
    link_params.each do |link_param|
      # Remove from the link queries if it starts with the link param data
      link_queries.delete_if { |link_query| link_query.start_with?(link_param + '=') }
    end
    change_all_params(link_path, link_queries)
  end

  # Used for changing the params of the path, the parameter values passed will overwrite anything that is
  # currently in the path.
  # Mainly used in methods which are called from methods passed in yield in the {#current_page_path} method.
  # @param link_path [String] is the full path of the link.
  # @param link_queries [Array] an array of string that consists of queries to overwrite its path query.
  # @return [String] the string value of the the full path of the link with the changed query/params
  def change_all_params(link_path, link_queries)
    # returns a string which is either the first item on the list or all the items joined by '&'
    link_queries = if link_queries.length <= 1
                     link_queries[0]
                   else
                     link_queries.join('&')
                   end
    parsed_uri = URI.parse(link_path)
    # sets the link's query to the link_queries (params)
    parsed_uri.query = link_queries
    parsed_uri.to_s
  end

  private

  # @return [String] Returns the current stack of links of the visited pages
  def link_stack
    session[:link_visited]
  end

  # Returns the link/path of the current page optionally modifying/replacing it based on the url_string_method.
  # @param url_string_method [Symbol || String] Either a pointer to a method to modify the URL
  #                                               or a String value to replace it
  # @return [String] link to the current page.
  def current_page_path(url_string_method)
    link_path = request.env['ORIGINAL_FULLPATH']
    return link_path if url_string_method.blank? || url_string_method == 'hide_link_keep_stack'

    respond_to?(url_string_method) ? send(url_string_method, link_path) : url_string_method
  end

  # Grabs the path of the url
  # @return [String] the link without it's params or any other things
  def uri_parse_path(link_path)
    URI.parse(link_path).path.to_s
  end

  # Removes the reloaded page from the stack of links.
  def remove_reloaded_page
    link_stack.shift if uri_parse_path(link_stack[0]) == uri_parse_path(link_stack[1])
  end

  # Removes duplicate from the link stack so we don't go round in a loop.
  # It removes the links from the top of the stack to the position of the link where it matches the current
  # page's link, but the current page's link will remain and will still be on the top of the stack. This is
  # done to prevent the pages from looping around.
  def remove_loop
    # Determines whether parts of the stack should be cleared.
    link_match = false
    # Position of the duplicate link's occurrence - used for clearing parts of the stack.
    link_position = 1
    return unless link_stack.size > 1

    # @note [].drop(1) skips the first item because that is the current page.
    link_stack.drop(1).each do |back_url|
      break if link_match

      # if a duplicate link is found, link_match will be true and remain true.
      link_match ||= current_page?(uri_parse_path(back_url))
      link_position += 1 unless link_match
    end

    # Then it removes the links from the top of the stack to where the duplicate link is found
    # (so for example if we have a stack of links [A, E, D, C, B, A, H] and the current page now is A,
    # this removes AEDCB and leaves us with [A, H]) if a duplicate exists.
    link_stack.shift(link_position) if link_match
  end

  # This is used to catch when the user clicks buttons/links too fast to go to different
  # pages with or without back link while the pages in between hasn't finished rendering.
  def remove_not_last_link
    browser_last_link = request.referer
    # As the user manually reloads/refreshes the page, the request.referer becomes nil
    return if browser_last_link.nil?

    browser_last_link_path = uri_parse_path(browser_last_link)

    # Update the stack's last visited link to the browser's last visited link when the browser's last visited link
    # isn't found in the stack. This means that the user has clicked too fast to go from a page without-back-link to
    # another page without-back-link to a page with-back-link.
    # These two lines reset the stack to be the current page and the referrer if the referrer
    # isn't already the previous page
    link_stack[1] = browser_last_link_path unless link_stack[1].include?(browser_last_link_path)

    link_stack.slice!(1) unless browser_last_link_path == uri_parse_path(link_stack[1])
  end
end
