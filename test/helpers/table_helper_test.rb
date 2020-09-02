# frozen_string_literal: true

require 'test_helper'
require 'table_helper'

# Unit Test for the table helper
class TableHelperTest < ActionView::TestCase
  include TableHelper
  include TableBuilderHelper

  # overiding translate method to display label name as its attribute to avoid
  # entry in translation file
  def t(attribute, _scope = [])
    attribute
  end

  test 'table with action' do
    user_test_data = [TestUser.new(username: 'one', name: 'John Smith', age: 25)]
    input = display_table(user_test_data,
                          %i[username name],
                          [
                            { label: t('show'), path: :dashboard_messages_path },
                            { label: t('edit'), path: :new_dashboard_message_path }
                          ])
    assert input == expected_output_with_action, 'Result was: ' + input
  end

  test 'table without action' do
    user_test_data = [TestUser.new(username: 'one')]
    input = display_table(user_test_data,
                          [:username])
    assert input == expected_output_without_action, 'Result was: ' + input
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
    '<table class="govuk-table"><thead class="govuk-table__head"><tr class="govuk-table__row">' \
             '<th class="govuk-table__header">Username</th><th class="govuk-table__header">Name</th>' \
             '</tr></thead><tbody class="govuk-table__body"><tr class="govuk-table__row">' \
             '<td class="govuk-table__cell remove_border_bottom_line">one</td>' \
             '<td class="govuk-table__cell remove_border_bottom_line">John Smith</td>' \
             '</tr><tr class="govuk-table__row"><td class="govuk-table__cell" colspan="2">' \
             '<a class="table_action_item govuk-link" aria-label="show for one" href="/dashboard/messages">show</a>' \
             '<a class="table_action_item govuk-link" aria-label="edit for one" href="/dashboard/messages/new">edit' \
             '</a></td></tr></tbody></table>'
  end

  # return expected output for test with out action
  def expected_output_without_action
    '<table class="govuk-table">' \
             '<thead class="govuk-table__head"><tr class="govuk-table__row">' \
             '<th class="govuk-table__header">Username</th></tr></thead>' \
             '<tbody class="govuk-table__body">' \
             '<tr class="govuk-table__row"><td class="govuk-table__cell remove_border_bottom_line">one</td></tr>' \
             '<tr class="govuk-table__row"><td class="govuk-table__cell" colspan="1"></td></tr>' \
             '</tbody></table>'
  end

  # Dummy test user class
  class TestUser < FLApplicationRecord
    attr_accessor :username, :name, :age
  end
end
