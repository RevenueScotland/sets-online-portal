# frozen_string_literal: true

require 'test_helper'
require 'table_helper'

# Unit Test for the pagination helper
class PaginationHelperTest < ActionView::TestCase
  include Pagination
  include PaginationHelper

  # Overriding translate method to test displaying some of the common translations
  def t(attribute, scope = {})
    # The content of :context in some parts of the paginate_helper translates an attribute specific to a certain page,
    # but since this test environment doesn't have a page, it will look for the default which is not defined.
    # As this is only a test, it isn't really needed to define the context in the en.yml that is used in production.
    scope[:context] = 'test context' unless scope[:context].nil?
    I18n.t(attribute, scope)
  end

  test 'pagination display next previouslink' do
    pagination_collection = PaginationCollection.new(5, 5, nil, true, 2)
    input = paginate(pagination_collection)
    assert_equal input, expected_output_display_next_previous_link
  end

  test 'pagination display next link only' do
    pagination_collection = PaginationCollection.new(1, 5, nil, true, 2)
    input = paginate(pagination_collection)
    assert_equal input, expected_output_display_next_link_only
  end

  test 'pagination display only previous link only' do
    pagination_collection = PaginationCollection.new(10, 5, 15, false, 2)
    input = paginate(pagination_collection)
    assert_equal input, expected_output_display_previous_link_only
  end

  test 'pagination with nil object' do
    input = paginate(nil)
    assert input.nil?
  end

  def expected_output_display_next_previous_link
    '<nav class="page-numbers-container pagination-container">' \
    '<div class="previous"><a aria-label="Previous page of test context" href="?page=1">Previous</a></div>' \
    '<div class="next"><a aria-label="Next page of test context" href="?page=3">Next</a></div>' \
    '<div class="pagination-item-range">' \
    '<p class="govuk-body">5-9<span class="govuk-visually-hidden">Items of test context</span></p>' \
    '</div>' \
    '</nav>'.squish.gsub('> <', '><')
  end

  def expected_output_display_next_link_only
    '<nav class="page-numbers-container pagination-container">' \
    '<div class="next"><a aria-label="Next page of test context" href="?page=3">Next</a></div>' \
    '<div class="pagination-item-range">' \
    '<p class="govuk-body">1-5<span class="govuk-visually-hidden">Items of test context</span></p>' \
    '</div>' \
    '</nav>'.squish.gsub('> <', '><')
  end

  def expected_output_display_previous_link_only
    '<nav class="page-numbers-container pagination-container">' \
    '<div class="previous"><a aria-label="Previous page of test context" href="?page=1">Previous</a></div>' \
    '<div class="pagination-item-range">' \
    '<p class="govuk-body">10-15<span class="govuk-visually-hidden">Items of test context</span></p>' \
    '</div>' \
    '</nav>'.squish.gsub('> <', '><')
  end
end
