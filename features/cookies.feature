# features/cookies.feature

Feature: Cookies
    As a user
    I want my cookie preferences to be honoured
    So that my privacy is protected

    @javascript
    Scenario: Banner notifications are only removed permanently when cookies can be set
        When I go to the "login" page
        Then I should see the "Sign in" page

        When I click on the "Cookies" link
        Then I should see the "Cookies" page
        And I should see the text "We use cookies to collect anonymous data to help us improve your site browsing experience."

        When I check the "Off" radio button in answer to the question "Cookies that remember your settings"
        And I check the "Off" radio button in answer to the question "Cookies that measure website use"
        And I click on the "Save cookie preferences" button
        Then I should see the "Cookies" page
        And I should see the text "Your cookie preferences have been saved. You can change your cookie settings at any time."
        And I should not see the text "We use cookies to collect anonymous data to help us improve your site browsing experience."

        When I click on the "Sign in" menu item
        Then I should see the "Sign in" page
        And I should receive the message "All - This is a test notice. More information"

        When I click on the 2 nd "Close this notification" button
        Then I should see the "Sign in" page
        And I should not receive the message "All - This is a test notice. More information"

        When I go to the "login" page
        Then I should see the "Sign in" page
        And I should receive the message "All - This is a test notice. More information"

        # Set cookie preference to yes and then prove that banner is now removed
        When I go to the "cookies" page
        Then I should see the "Cookies" page
        When I check the "On" radio button in answer to the question "Cookies that remember your settings"
        And I check the "On" radio button in answer to the question "Cookies that measure website use"
        And I click on the "Save cookie preferences" button
        Then I should see the "Cookies" page
        And I should see the text "Your cookie preferences have been saved. You can change your cookie settings at any time."

        When I click on the "Sign in" menu item
        Then I should see the "Sign in" page
        And I should receive the message "All - This is a test notice. More information"

        When I click on the 2 nd "Close this notification" button
        Then I should not receive the message "All - This is a test notice. More information"

        When I go to the "login" page
        Then I should see the "Sign in" page
        And I should not receive the message "All - This is a test notice. More information"
        And I should not see the text "We use cookies to collect anonymous data to help us improve your site browsing experience."
