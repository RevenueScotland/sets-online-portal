# feature/login.feature

Feature: Login and authentication
    As a registered user
    I want to be able to sign in and out from the site
    So that my data is secure

    Scenario: User tries to access a secure page
        When I go to the "users" page
        Then I should see the "Sign in" page

    Scenario: User does not provide any details
        When I go to the "Login" page
        And I click on the "Sign in" button
        Then I should receive the message "Username can't be blank"
        And I should receive the message "Password can't be blank"

    Scenario: User provides incorrect details
        When I go to the "Login" page
        And I enter "x" in the "Username" field
        And I enter "x" in the "Password" field
        And I click on the "Sign in" button
        Then I should receive the message "Invalid login credentials"
        And I should see the text "username"
        And I should see the text "password"
        When I go to the "Account" page
        Then I should see the "Sign in" page

    Scenario: User provides the correct details
        When I go to the "Login" page
        And I enter "portal.one" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the "Dashboard" page

    Scenario: User logs out and cannot access authenticate page
        Given I have signed in
        And I go to the "Users" page
        When I click on the "Sign out" menu item
        Then I should see the "Sign in" page
        And I go to the "Users" page
        Then I should see the "Sign in" page
        When I click on the "Cookies" link
        Then I should see the "Cookies" page

    @mock_locked_user
    Scenario: User provides the correct detail but the user is locked
        When I go to the "Login" page
        And I enter "locked.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button
        Then I should receive the message "Invalid login credentials"

    @mock_not_actived_user
    Scenario: User provides the correct detail but the user is not activated
        When I go to the "Login" page
        And I enter "not.activated.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button
        Then I should receive the message "Activate your account using the token you were sent"

    @mock_expired_password
    Scenario: Expired password
        When I go to the "Login" page
        And I enter "expired.password" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the text "Password expired"

    @mock_forced_password_change
    Scenario: Force password change
        When I go to the "Login" page
        And I enter "forced.password.change.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the "Change password" page

    @mock_due_password
    Scenario: Displaying password expired in n days
        When I go to the "Login" page
        And I enter "due.password" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the "Dashboard" page

        When I go to the "Account" page
        Then I should see the "Sign up details" page
        And I should see the text "Your password expires in 4 days"

    @mock_confirm_tcs
    Scenario: User needs to confirm the terms and conditions
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Terms and conditions" page
        And I should see the text "In order to proceed you must read and accept the terms and conditions"
        And I should see a link with text "Terms & conditions (opens in a new tab)"
        And I click on the "Confirm" button

        Then I should see the "Terms and conditions" page
        And I should receive the message "The terms and conditions must be accepted"
        And I check the "I confirm that I have read and understood the terms and conditions" checkbox
        And I click on the "Confirm" button

    # Then I should see the "Dashboard" page

    # We'll use I should see the text "This is the token in the email you have been sent" as
    # an indicator that we're on the token capture page as the page has the same title as the
    # normal sign in page. This is the same for all the 2 factor tests that follow...
    @mock_two_factor_login
    Scenario: User provides the correct detail for a 2 factor login
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Dashboard" page

    @mock_two_factor_login
    Scenario: User provides the correct detail but a blank username and token for a 2 factor login
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the text "This is the token in the email you have been sent"
        And I clear the "Username" field
        When I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I should receive the message "Username can't be blank"
        And I should receive the message "Token can't be blank"

    @mock_two_factor_login_invalid_token
    Scenario: User provides the correct detail but an invalid token for a 2 factor login
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I enter "invalid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I should receive the message "Enter the correct username and token"

    @mock_two_factor_login_expired_token
    Scenario: User provides the correct detail but an expired token for a 2 factor login
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I enter "expired.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Sign in" page
        And I should receive the message "Your token has expired. Please sign in again to generate a new one"

    @mock_two_factor_login_user_locked
    Scenario: User provides the correct detail for a 2 factor login but the user is locked
        When I go to the "Login" page
        And I enter "locked.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button
        Then I should receive the message "Invalid login credentials"

    @mock_two_factor_login_user_not_activated
    Scenario: User provides the correct detail for a 2 factor login but the user is not activated
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Sign in" page
        And I should receive the message "Activate your account using the token you were sent"

    @mock_two_factor_login_expired_password
    Scenario: User provides the correct detail for a 2 factor login but the users password has expired
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Password expired" page

    @mock_two_factor_login_force_password_change
    Scenario: User provides the correct detail for a 2 factor login but the user is forced to change their password
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Change password" page

    @mock_two_factor_confirm_tcs
    Scenario: User needs to confirm the terms and conditions
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the email you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Terms and conditions" page

    @mock_force_password_change_and_tc_limited_permissions
    Scenario: User with limited permissions needs to change their password and confirm the terms and conditions
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Change password" page
        And I enter "valid.password" in the "Old password" field
        And I enter "New.password1" in the "New password" field
        And I enter "New.password1" in the "Confirm new password" field
        And I click on the "Change password" button

        Then I should see the "Sign in" page
        When I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Terms and conditions" page
        And I should see the text "In order to proceed you must read and accept the terms and conditions"
        And I should see a link with text "Terms & conditions (opens in a new tab)"
        And I click on the "Confirm" button

        Then I should see the "Terms and conditions" page
        And I should receive the message "The terms and conditions must be accepted"
        And I check the "I confirm that I have read and understood the terms and conditions" checkbox
        And I click on the "Confirm" button

    Scenario: User provides correct details and has single portal object (enrolment)
        When I go to the "Login" page
        And I enter "portal.sat.one" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button
    # Then I should see the "Dashboard : SAT1000000TVTV Kevin Peterson Partnership" page

    Scenario: User provides correct details and has multiple portal object (enrolment)
        When I go to the "Login" page
        And I enter "portal.sat.users" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Select your SAT registration" page
        And I should see the text "Which of your SAT registrations do you wish to view?"
        When I click on the "Continue" button
        Then I should see the "Select your SAT registration" page
        And I should not see the text "Create new message"
        And I should see the text "Which of your SAT registrations do you wish to view can't be blank"
        When I check the "SAT1000000VVVV Black Sands Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button
        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page
