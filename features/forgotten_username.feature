Feature: Forgotten Username

    # In case the user has forgotten his username, he/she can retrieve it
    # with help of the registered email address

    Scenario:  User tries to access a forgotten-username page
        When I go to the "Login" page
        And I click on the "Forgotten your username?" link
        Then I should see the "Forgotten username" page

    Scenario: User does not provide email address
        When I go to the "Forgotten-username" page
        And I click on the "Confirm" button
        Then I should receive the message "Email address can't be blank"

    Scenario: User provides incorrect email address
        When I go to the "Forgotten-username" page
        And I enter "x" in the "Email address" field
        And I click on the "Confirm" button
        Then I should receive the message "Email address is invalid"

    Scenario: User provides the correct details
        When I go to the "Forgotten-username" page
        And I enter "noreply@northgateps.com" in the "Email address" field
        And I click on the "Confirm" button
        Then I should see the "Forgotten username confirmation" page
