# frozen_string_literal: true

require 'test_helper'
require 'table_helper'

# Unit Test for the pagination helper
class PaginationHelperTest < ActionView::TestCase
  include Pagination
  include PaginationHelper

  # overiding translate method to display label name as its attribute to avoid
  # entry in translation file
  def t(attribute, _scope = [])
    attribute
  end

  test 'pagination display next previouslink' do
    pagination_collection = PaginationCollection.new(5, 5, nil, true, 2)
    input = paginate(pagination_collection)
    assert input == expected_output_display_next_previous_link
  end

  test 'pagination display next link only' do
    pagination_collection = PaginationCollection.new(1, 5, nil, true, 2)
    input = paginate(pagination_collection)
    assert input == expected_output_display_next_link_only
  end

  test 'pagination display only previous link only' do
    pagination_collection = PaginationCollection.new(10, 5, 15, false, 2)
    input = paginate(pagination_collection)
    assert input == expected_output_display_previous_link_only
  end

  test 'pagination with nil object' do
    input = paginate(nil)
    assert input.nil?
  end

  def expected_output_display_next_previous_link
    out_put = '<nav class="page-numbers-container pagination-container"><div class="previous"><a href' \
              '="?page=1">previous</a></div><div class="next"><a href="?page=3">next</a></div><div class="paginatio' \
              'n"><ul class="list-inline"><li><a class="active" href="">5-9</a></li></ul></div></nav>'
    out_put
  end

  def expected_output_display_next_link_only
    out_put = '<nav class="page-numbers-container pagination-container"><div class="next"' \
               '><a href="?page=3">next</a></div><div class="pagination"><ul class="list-inline"><li><a class="activ' \
               'e" href="">1-5</a></li></ul></div></nav>'
    out_put
  end

  def expected_output_display_previous_link_only
    out_put = '<nav class="page-numbers-container pagination-cont' \
                'ainer"><div class="previous"><a href="?page=1">previous</a></div><div class="pagination"><ul class="' \
                'list-inline"><li><a class="active" href="">10-15</a></li></ul></div></nav>'
    out_put
  end
end
