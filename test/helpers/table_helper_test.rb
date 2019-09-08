# frozen_string_literal: true

require 'test_helper'
require 'table_helper'

# Unit Test for the table helper
class TableHelperTest < ActionView::TestCase
  include TableHelper

  # overiding translate method to display label name as its attribute to avoid
  # entry in translation file
  def t(attribute, _scope = [])
    attribute
  end

  # overide action tag method to avoid create path in route files for testing
  def action_tag(action, _object)
    link_to action[:label], 'action path'
  end

  test 'table with action' do
    user_test_data = [TestUser.new(username: 'one', name: 'John Smith', age: 25)]
    input = display_table(user_test_data,
                          %i[username name],
                          [
                            { label: t('show'), action: :show },
                            { label: t('edit'), action: :edit }
                          ])
    assert input == expected_output_with_action
  end

  test 'table without action' do
    user_test_data = [TestUser.new(username: 'one')]
    input = display_table(user_test_data,
                          [:username])
    assert input == expected_output_without_action
  end

  test 'table with nil object' do
    input = display_table(nil,
                          [:username])
    assert input.nil?
  end

  test 'table with no records' do
    user_test_data = []
    input = display_table(user_test_data,
                          [:username])
    assert input.nil?
  end

  # return expected output for test with action
  def expected_output_with_action
    out_put = '<table class="govuk-table"><thead class="govuk-table__head"><tr class="govuk-table__head">' \
              '<th class="govuk-table__header">username</th><th class="govuk-table__header">name</th>' \
              '</tr></thead><tbody class="govuk-table__body"><tr class="govuk-table__row">' \
              '<td class="govuk-table__cell remove_border_bottom_line">one</td>' \
              '<td class="govuk-table__cell remove_border_bottom_line">John Smith</td>' \
              '</tr><tr class="govuk-table__row"><td colspan="2" class="govuk-table__cell">' \
              '<a href="action path">show</a>&emsp;&emsp;<a href="action path">edit</a>&emsp;&emsp;' \
              '</td></tr></tbody></table>'
    out_put
  end

  # return expected output for test with out action
  def expected_output_without_action
    out_put = '<table class="govuk-table">' \
              '<thead class="govuk-table__head"><tr class="govuk-table__head">' \
              '<th class="govuk-table__header">username</th></tr></thead>' \
              '<tbody class="govuk-table__body">' \
              '<tr class="govuk-table__row"><td class="govuk-table__cell remove_border_bottom_line">one</td></tr>' \
              '<tr class="govuk-table__row"><td colspan="1" class="govuk-table__cell"></td></tr>' \
              '</tbody></table>'
    out_put
  end

  # Dummy test user class
  class TestUser < FLApplicationRecord
    attr_accessor :username, :name, :age
  end
end
