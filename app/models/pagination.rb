# frozen_string_literal: true

# This is module to populate pagination collection which is require to render
# pagination link
module Pagination
  # Class to hold pagination collections value
  class PaginationCollection
    attr_reader :start_row, :num_rows, :sort_option, :total_rows, :more_rows_exists, :current_page
    def initialize(start_row, num_rows, total_rows, more_rows_exists, current_page)
      @start_row = start_row
      @num_rows = num_rows
      @total_rows = total_rows
      @more_rows_exists = more_rows_exists
      @current_page = current_page
    end
  end

  # Creates the initial pagination which will be used to pass the pagination data for requesting back office data.
  # @return [Object] pagination collection without the total-rows and more-rows-exists
  def self.initialise_pagination(num_rows, page)
    page, start_row = if page.nil?
                        [1, 1]
                      else
                        [page.to_i, get_pagination_start_row_parameter(num_rows, page.to_i)]
                      end
    PaginationCollection.new(start_row, num_rows, nil, nil, page)
  end

  # Creates the pagination collection for the data gathered from the back office response
  # @param pagination [Object] an instance of PaginationCollection, used for getting the existing pagination data.
  # @param back_office_pagination [Hash] contains the total_rows and more_rows_exist symbols which is derived from
  #   the back office response.
  def self.paginate_back_office(pagination, back_office_pagination)
    back_office_pagination = { total_rows: 0, more_rows_exist: 'N' } if back_office_pagination.nil?
    PaginationCollection.new(pagination.start_row,
                             pagination.num_rows,
                             total_rows(pagination, back_office_pagination),
                             back_office_pagination[:more_rows_exist] == 'Y',
                             pagination.current_page)
  end

  # Calculates the total rows to be used to make a new instance of PaginationCollection.
  private_class_method def self.total_rows(pagination, back_office_pagination)
    [back_office_pagination[:total_rows].to_i, pagination.start_row + pagination.num_rows - 1].min
  end

  # This is main method to filter rows as per selected page. It also return pagination collection
  # required to render pagination link
  # @param collections [Objects] on which pagination has to apply.
  # @param page [Integer] is the current page number in pagination
  # @param num_rows is to control number row need to show per page if it is nil then it used
  #                 property.x.pagination.per_page value mention in configuration
  # @return [Object][PaginationCollection] return 2 object ,Object collection filter as per input page
  # and PaginationCollection object required to render pagination link
  def self.paginate_record(collections, page, num_rows = nil)
    return if collections.nil? || collections.empty?

    current_page = 1
    current_page = page.to_i unless page.nil?
    pagination_collection = populate_pagination_collection(collections, current_page, num_rows)

    unless pagination_collection.nil?
      collections = collections[pagination_collection.start_row - 1, pagination_collection.num_rows]
    end
    [collections, pagination_collection]
  end

  # This is a private method to populate pagination collection
  # @param page [Integer] is the current page number in pagination
  private_class_method def self.populate_pagination_collection(collections, page, num_rows)
    more_rows_exists = true
    # set default per page number of rows
    num_rows = Rails.configuration.x.pagination.per_page if num_rows.nil?
    # default start row
    start_row = get_pagination_start_row_parameter(num_rows, page)
    total_rows = nil
    # check if its last set of rows display on pagination screen
    if collections.count <= start_row + num_rows - 1
      more_rows_exists = false
      # do not delete this line as its used in pagination helper file to render last rows number
      # displayed
      total_rows = collections.count
    end
    pagination_collection = PaginationCollection.new(start_row, num_rows, total_rows, more_rows_exists, page)
    pagination_collection
  end

  # Method is used to define start row of page as per pages in pagination
  # @note param num_rows [Integer] the number of rows
  # @note param page [Integer] is the current page
  # @return [Integer] the start row
  private_class_method def self.get_pagination_start_row_parameter(num_rows, page)
    start_row = if page > 1
                  (num_rows * (page - 1)) + 1
                else
                  1
                end
    start_row
  end
end
