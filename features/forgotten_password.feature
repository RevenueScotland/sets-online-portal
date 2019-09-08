Feature: Forgotten Password

    As user  I can reset password in case of forgotten.

    Scenario:  User tries to access a forgotten-password page
        When I go to the "Login" page
        And click on the "Forgotten your password?" link
        Then I should see the "Forgotten password" page


    Scenario: User does not provide any details
        When I go to the "Forgotten-password" page
        And click on the "Change Password" button
        #Then I should receive the message "Username can't be blank"
        And I should receive the message "New password can't be blank"
        And I should receive the message "Email address can't be blank"

    Scenario: User provides incorrect details
        When I go to the "Forgotten-password" page
        And enter "x" in the "Email address" field
        And enter "y" in the "Username" field
        And enter "invalidpassword" in the "New password" field
        And click on the "Change Password" button
        Then I should receive the message "Email address is invalid"
        Then I should receive the message "Username is too short (minimum is 3 characters)"
    # deferred to back office for now Then I should receive the message "New password is invalid"

    Scenario: User provides mismatch password and confirm password
        When I go to the "Forgotten-password" page
        And enter "Xyz1234" in the "New password" field
        And enter "Abc1234" in the "Confirm new password" field
        And click on the "Change Password" button
        Then I should receive the message "Confirm new password doesn't match New password"

    Scenario: User provides the correct details
        When I go to the "Forgotten-password" page
        And enter "portal.change.details" in the "Username" field
        And enter "noreply@northgateps.com" in the "Email address" field
        And enter "AbcXyz123!" in the "New password" field
        And enter "AbcXyz123!" in the "Confirm new password" field
        And click on the "Change Password" button
        Then I should see the "Forgotten password confirmation" page
