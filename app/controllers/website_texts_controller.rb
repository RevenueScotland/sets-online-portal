# frozen_string_literal: true

# Controller for handling public website text retrieved from back-office
# We need to pass code in the link as parameter and
# depending on that parameter, text retrieve from back-office and display on the page
# eg http://localhost:3000/en/website_texts/REGTSANDCS, http://localhost:3000/en/website_texts/termsandconditions
class WebsiteTextsController < ApplicationController
  # Allow pages to be unauthenticated
  skip_before_action :require_user, only: :show

  # Renders pws_text
  def show
    pws_text = ReferenceData::PwsText.lookup(params[:text_code], 'SYS', 'RSTU')
    @text = pws_text.to_s
    @page_title = pws_text.page_title
  end
end
