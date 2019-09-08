# feature/messages.feature

Feature: Back Link
    As a registered user
    I want use the back link
    So that I can go back to the correct previous page

    Scenario: Back clicks and page reload doesn't affect the back link
        Given I have signed in
        Then I should see the "Dashboard" page

        # Scenario's test part 1 - Multiple back clicks
        # Currently at page A (Dashboard page)
        When I click on the "Create LBTT return" link
        # Then I should be in page B
        Then I should see the "About the return" page
        When I check the "3 year lease review" radio button
        And I click on the "Next" button
        # Now I should be in page C
        Then I should see the "Return reference number" page
        # Going back to page B
        When I click on the "Back" link
        # Lastly back to page A
        And I click on the "Back" link
        Then I should see the "Dashboard" page

        # Scenario's test part 2 - Page reload doesn't affect the back link
        When I click on the "Create LBTT return" link
        And I check the "3 year lease review" radio button
        And I click on the "Next" button
        And I enter "RS1234567Helo" in the "What was the original return reference?" field
        And I click on the "Next" button
        And I click on the "Add a tenant" link
        And I check the "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Tenant details" page
        # Page A

        When I select "Mr" from the "Title"
        And I enter "North" in the "First name" field
        And I enter "Gate" in the "Last name" field
        And I enter "01344 407703" in the "Telephone number" field
        And I enter "north.gate@nps.co.uk" in the "Email" field
        And I enter "AB 12 34 56 C" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button
        Then I should see the "Tenant address" page
        # Page B

        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        # This should re-load page B
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click on the "Next" button

        # Going to page C
        Then I should see the "Tenant's contact address" page

        # Now go back to page B
        When I click on the "Back" link
        Then I should see the text "Tenant address"

        # Then back to page A
        When I click on the "Back" link
        Then I should see the text "Tenant details"

    Scenario: Finish filling in a form and then going back to main page
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        # Scenario's test part 1
        # Starting page: page A
        Then I should see the "Dashboard" page

        When I click on the "Create SLfT return" link
        # This is now page B
        Then I should see the "Return summary" page

        When I click on the "Add return period" link
        # Page C
        Then I should see the "What accounting period is this return for?" page

        When I select "2015/16" from the "returns_slft_slft_return[year]"
        And I check "April to June (Quarter 1)" radio button
        And I click on the "Next" button
        # Page D
        Then I should see the "Non disposal area information" page
        And I should see the text "Have you designated a new non-disposal area on any of your sites?"

        When I check "returns_slft_slft_return_non_disposal_add_ind_n" radio button
        And I click on the "Next" button
        # Page E
        Then I should see the "Non disposal area information" page
        And I should see the text "Have you ceased to operate a non-disposal area on any of your sites?"

        When I check "returns_slft_slft_return_non_disposal_delete_ind_n" radio button
        And I click on the "Next" button
        # Now looped back to Page B
        Then I should see the "Return summary" page

        When I click on the "Back" link
        And if available, click the confirmation dialog
        # Now back to page A
        Then I should see the "Dashboard" page
        # Done

        # Scenario's test part 2 - Back click going to the correct page
        When I click on the "Create SLfT return" link
        # Page A
        Then I should see the "Return summary" page

        When I click on the "Add return period" link
        # Page B
        Then I should see the "What accounting period is this return for?" page

        When I select "2015/16" from the "returns_slft_slft_return[year]"
        And I check "April to June (Quarter 1)" radio button
        And I click on the "Next" button
        # Page C
        Then I should see the "Non disposal area information" page
        And I should see the text "Have you designated a new non-disposal area on any of your sites?"

        # back to page B
        When I click on the "Back" link
        # back to page A
        And I click on the "Back" link
        # details updated
        Then I should see the "Return summary" page
        And I should see the text "SLfT year"
        And I should see the text "2015/16"
        And I should see the text "SLfT quarter"
        And I should see the text "Quarter 1"