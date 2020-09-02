# frozen_string_literal: true

require 'capybara-screenshot/minitest'

# feature/step_definitions/slft_steps.rb
short_wait = 2 # period to wait when checking an item is not present

# Adds or updates the period for an SLFT return from the summary page
When('I set a period of {string} and {string}') do |year, quarter|
  if page.has_link?('Add return period', wait: short_wait)
    click_link('Add return period')
  else
    click_link('Edit return period')
  end
  select year, from: 'year'
  choose(quarter, visible: false)
  click_button('Continue')
  choose('No', visible: false)
  click_button('Continue')
  choose('No', visible: false)
  click_button('Continue')
end
