# frozen_string_literal: true

# Core user interface components and helpers
# This holds all core logic, except that which is specific to how a particular user interface is rendered
module Core
  # Calculates and displays the details for the pagination areas based on the PaginationCollection.
  class PaginationComponent < ViewComponent::Base
    attr_reader :region_name, :page_list, :current_page, :previous_page_link, :next_page_link

    # @param collection [PaginationCollection] a collection require for build pagination link
    # @param region_name [String] The name of the region used to create an aria label
    # @param page_name [String] A unique identifier of the paging region in a page, used if there is more than
    #   one paging region
    # @param anchor [String] An anchor back to the table region
    def initialize(collection:, region_name:, page_name: 'page', anchor: nil)
      super()
      @collection = collection
      @region_name = region_name
      @page_name = page_name || 'page'
      @anchor = anchor
      return unless @collection

      @current_page, @total_pages = calculate_pages(@collection)
    end

    # Since we need access to the request variable to get any current query parameters
    # we can only do this in a before render
    def before_render
      return unless @current_page

      @previous_page_link, @next_page_link = paging_links(@current_page, @total_pages, @page_name, @anchor)
      @page_list = create_page_list(@current_page, @total_pages, @page_name, @anchor)
    end

    # Override render so it is only shown if there is a page list
    def render?
      return true if @current_page && @total_pages > 1

      false
    end

    private

    # Calculated the current and total number of pages
    # @param collection [PaginationCollection] A collection of information about the paging
    # @return [Integer] The current page number
    # @return [Integer] The total number of pages
    def calculate_pages(collection)
      [(collection.start_row / collection.num_rows.to_f).ceil,
       (collection.total_rows / collection.num_rows.to_f).ceil]
    end

    # Returns the previous and next page links
    # @param current_page [Integer] The current page
    # @param total_pages [Integer] The total number of pages
    # @param page_name [String] A unique identifier of the paging region in a page, used if there is more than
    # @param anchor [String] An anchor back to the table
    # @return [String] previous page link
    # @return [String] next page link
    def paging_links(current_page, total_pages, page_name, anchor)
      p = create_page_link(current_page - 1, page_name, anchor) if current_page > 1
      n = create_page_link(current_page + 1, page_name, anchor) if current_page < total_pages
      [p, n]
    end

    # Creates a page list based on the current page number and total pages
    # We always show five pages with ellipsis separating them if needed
    # @param current_page [Integer] The current page
    # @param total_pages [Integer] The total number of pages
    # @param page_name [String] A unique identifier of the paging region in a page, used if there is more than
    # @param anchor [String] An anchor back to the table
    def create_page_list(current_page, total_pages, page_name, anchor)
      # page 1
      page_list = []
      page_list << create_page_list_entry(1, page_name, current_page == 1, anchor)
      page_list << create_page_list_ellipsis if current_page > 3 && total_pages > 5

      page_list += create_middle_pages(current_page, total_pages, page_name, anchor)

      # Last page
      page_list << create_page_list_ellipsis unless current_page > total_pages - 3
      page_list << create_page_list_entry(total_pages, page_name, current_page == total_pages, anchor)
    end

    # Creates a page list for the pages n-1 to n+1
    # @param current_page [Integer] The current page
    # @param total_pages [Integer] The total number of pages
    # @param page_name [String] A unique identifier of the paging region in a page, used if there is more than
    # @param anchor [String] An anchor back to the table
    # @return [Array] The array for the middle three pages
    def create_middle_pages(current_page, total_pages, page_name, anchor)
      page_list = []
      start_range = [current_page - 1, total_pages - 3].min
      # Start range must be >= 2 as first page always created
      start_range = 2 if start_range < 2
      end_range = [start_range + 2, total_pages - 1].min
      # Middle three pages or last three pages
      [*(start_range..end_range)].each do |page|
        page_list << create_page_list_entry(page, page_name, page == current_page, anchor)
      end
      page_list
    end

    # Create a page list entry consisting of the page and the link to that page
    def create_page_list_entry(page, page_name, current_page, anchor)
      entry = { page: page }
      entry[:current_page?] = current_page
      entry[:link] = create_page_link(page, page_name, anchor)
      entry
    end

    # Create an ellipsis entry
    def create_page_list_ellipsis
      { ellipsis?: true }
    end

    # Create an page link to a specific page
    # @param anchor [String] An anchor back to the table
    def create_page_link(page, page_name, anchor)
      additional_parameters = Rack::Utils.parse_query("#{page_name}=#{page}")
      "?#{request.query_parameters.merge(additional_parameters).to_query}#{"##{anchor}" if anchor}"
    end
  end
end
