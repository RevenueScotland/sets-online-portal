Feature: Forgotten Password

    As user  I can reset password in case of forgotten.

    Scenario:  User tries to access a forgotten-password page
        When I go to the "Login" page
        And I click on the "Forgotten your password?" link
        Then I should see the "Forgotten password" page


    Scenario: User does not provide any details
        When I go to the "Forgotten-password" page
        And I click on the "Change Password" button
        #Then I should receive the message "Username can't be blank"
        And I should receive the message "New password can't be blank"
        And I should receive the message "Email address can't be blank"

    Scenario: User provides incorrect details
        When I go to the "Forgotten-password" page
        And I enter "x" in the "Email address" field
        And I enter "y" in the "Username" field
        And I enter "invalidpassword" in the "New password" field
        And I click on the "Change Password" button
        Then I should receive the message "Email address is invalid"
        Then I should receive the message "Username is too short (minimum is 3 characters)"
    # deferred to back office for now Then I should receive the message "New password is invalid"

    Scenario: User provides mismatch password and confirm password
        When I go to the "Forgotten-password" page
        And I enter "Xyz1234" in the "New password" field
        And I enter "Abc1234" in the "Confirm new password" field
        And I click on the "Change Password" button
        Then I should receive the message "New password does not match"

    Scenario: User provides the correct details
        When I go to the "Forgotten-password" page
        And I enter "portal.change.details" in the "Username" field
        And I enter "noreply@northgateps.com" in the "Email address" field
        And I enter "AbcXyz123!" in the "New password" field
        And I enter "AbcXyz123!" in the "Confirm new password" field
        And I click on the "Change Password" button
        Then I should see the "Forgotten password confirmation" page
