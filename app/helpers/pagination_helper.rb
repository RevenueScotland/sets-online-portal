# frozen_string_literal: true

# This is a helper to render the pagination link
module PaginationHelper
  # building standard pagination link for given collection.
  # @param paginate_collection [PaginationCollection] a collection require for build pagination link
  # @return [HTML block element] The HTML for pagination link
  def paginate(paginate_collection, page_name = 'page')
    return if paginate_collection.nil? || !paginate_collection.is_a?(Pagination::PaginationCollection)

    content = render_pagination_link(paginate_collection, page_name)
    navigation(content.html_safe)
  end

  private

  # It render pagination link
  # @param paginate_collection is passed through each of the mentioned methods that is combined to be
  #   the return value of this method.
  # @return [HTML block element] render of pagination link, which is the html block of {#previous_tag},
  #   {#next_tag} and {#pages_tag} using the {#get_last_rows_collection}
  def render_pagination_link(paginate_collection, page_name)
    content = previous_tag(page_name, paginate_collection.start_row, paginate_collection.current_page) +
              next_tag(paginate_collection.more_rows_exists, paginate_collection.current_page, page_name) +
              pages_tag(paginate_collection.start_row, get_last_rows_collection(paginate_collection))
    content
  end

  # Create navigation tag
  # @param contents [HTML block element] the block of element(s) to be wrapped in the standard navigation tag
  # @return [HTML block element] returns the standard navigation tag with the appropriate classes
  def navigation(contents)
    content_tag(:nav, contents, class: 'page-numbers-container pagination-container')
  end

  # Create previous tag
  # @param start_row [Integer] current row
  # @param page [Integer] the current page
  # @return [HTML block element] the standard element referring to the previous page with the appropriate classes
  def previous_tag(page_name, start_row = 1, page = 1)
    # hide previous link if current page is a first page
    if start_row > 1 && page > 1
      content_tag(:div, link_to(t('previous'), link_to_page(page - 1, page_name)), class: 'previous')
    else
      ''
    end
  end

  # Create next tag
  # @param more_row_exists [Boolean] used for checking if there are any more rows that exists
  # @param current_page [Integer] the current page
  # @return [HTML block element] the standard element referring to the next page with the appropriate classes
  def next_tag(more_row_exists, current_page, page_name)
    # hide next link if current page is a last page
    if more_row_exists
      content_tag(:div, link_to(t('next'), link_to_page(current_page + 1, page_name)), class: 'next')
    else
      ''
    end
  end

  # @return [String] The page number with all the other params of the page
  def link_to_page(page, page_name)
    # parses a query of the page number, so that it can be merged with the url's queries.
    response_query = Rack::Utils.parse_query(page_name.to_s + '=' + page.to_s)
    # parses a query of the current page's list of queries (params with values)
    request_query = Rack::Utils.parse_query(if request.nil?
                                              ''
                                            else
                                              request.env['QUERY_STRING']
                                            end)
    # merges all the parsed queries together
    '?' + request_query.merge(response_query).to_query
  end

  # Create Page tag contain start row number and last row in the current page
  # for example, I am on page 2 and showing five rows per page, and total rows are 15
  # then it will generate HTML out "6-10".
  # @param start_row [Integer] the start row of the pagination
  # @param last_row [Integer] the last row of the pagination
  # @return [HTML block element] the standard link to pages element with the appropriate classes
  def pages_tag(start_row, last_row)
    link_content = link_to(start_row.to_s + '-' + last_row.to_s, '', class: 'active')
    li_content = content_tag(:li, link_content)
    page_contents = content_tag(:ul, li_content.html_safe, class: 'list-inline')
    content_tag(:div, page_contents, class: 'pagination')
  end

  # to get last rows number in current page
  # @param paginate_collection [PaginationCollection] a collection require for build pagination link, in this case is
  #   used to get the last rows
  # @return [Integer] the last row number in current page
  def get_last_rows_collection(paginate_collection)
    last_row = if paginate_collection.total_rows.nil?
                 paginate_collection.start_row + paginate_collection.num_rows - 1
               else
                 paginate_collection.total_rows
               end
    last_row
  end
end
