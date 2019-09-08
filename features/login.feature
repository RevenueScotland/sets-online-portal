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
        And click on the "Sign in" button
        Then I should receive the message "Username can't be blank"
        And I should receive the message "Password can't be blank"

    Scenario: User provides incorrect details
        When I go to the "Login" page
        And enter "x" in the "Username" field
        And enter "x" in the "Password" field
        And click on the "Sign in" button
        Then I should receive the message "Enter the correct username and password"
        And I should see the text "username"
        And I should see the text "password"
        When I go to the "Account" page
        Then I should see the "Sign in" page

    Scenario: User provides the correct details
        When I go to the "Login" page
        And enter "portal.one" in the "Username" field
        And enter "Password1!" in the "Password" field
        And click on the "Sign in" button
        Then I should see the "Dashboard" page

    Scenario: User logs out and cannot access authenticate page
        Given I have signed in
        And go to the "Users" page
        When I click on the "Sign out" link
        And go to the "Users" page
        Then I should see the "Sign in" page

    @mock_locked_user
    Scenario: User provides the correct detail but the user is locked
        When I go to the "Login" page
        And enter "locked.user" in the "Username" field
        And enter "valid.password" in the "Password" field
        And click on the "Sign in" button
        Then I should receive the message "Your user is locked, use the forgotten password process to unlock it"

    @mock_not_actived_user
    Scenario: User provides the correct detail but the user is not activated
        When I go to the "Login" page
        And enter "not.activated.user" in the "Username" field
        And enter "valid.password" in the "Password" field
        And click on the "Sign in" button
        Then I should receive the message "Activate your account using the token you were sent"

    @mock_expired_password
    Scenario: Expired password
        When I go to the "Login" page
        And enter "expired.password" in the "Username" field
        And enter "valid.password" in the "Password" field
        And click on the "Sign in" button
        Then I should see the text "Password Expired"

    @mock_forced_password_change
    Scenario: Force password change
        When I go to the "Login" page
        And enter "forced.password.change.user" in the "Username" field
        And enter "valid.password" in the "Password" field
        And click on the "Sign in" button
        Then I should see the "Change Password" page

    @mock_due_password
    Scenario: Displaying password expired in n days
        When I go to the "Login" page
        And enter "due.password" in the "Username" field
        And enter "valid.password" in the "Password" field
        And click on the "Sign in" button
        And I go to the "Account" page
        Then I should see the "Sign up details" page
        And I should see the text "Your password expires in 4 days"

    @mock_confirm_tcs
    Scenario: User needs to confirm the terms and conditions
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Terms and Conditions" page
        And I should see the text "In order to proceed you must read and accept the terms and conditions."
        And I click on the "Confirm" button

        Then I should see the "Terms and Conditions" page
        And I should receive the message "This can't be blank"
        And I check "I confirm that I have read and understood the terms & conditions" checkbox
        And I click on the "Confirm" button

    # Then I should see the "Dashboard" page

    # We'll use I should see the text "This is the token in the e-mail you have been sent" as
    # an indicator that we're on the token capture page as the page has the same title as the
    # normal sign in page. This is the same for all the 2 factor tests that follow...
    @mock_two_factor_login
    Scenario: User provides the correct detail for a 2 factor login
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the e-mail you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Dashboard" page

    @mock_two_factor_login
    Scenario: User provides the correct detail but a blank username and token for a 2 factor login
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the text "This is the token in the e-mail you have been sent"
        And I enter "" in the "Username" field
        When I click on the "Sign in" button

        Then I should see the text "This is the token in the e-mail you have been sent"
        And I should receive the message "Username can't be blank"
        And I should receive the message "Token can't be blank"

    @mock_two_factor_login_invalid_token
    Scenario: User provides the correct detail but an invalid token for a 2 factor login
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the e-mail you have been sent"
        And I enter "invalid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the e-mail you have been sent"
        And I should receive the message "Enter the correct username and token"

    @mock_two_factor_login_expired_token
    Scenario: User provides the correct detail but an expired token for a 2 factor login
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the e-mail you have been sent"
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
        Then I should receive the message "Your user is locked, use the forgotten password process to unlock it"

    @mock_two_factor_login_user_not_activated
    Scenario: User provides the correct detail for a 2 factor login but the user is not activated
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the e-mail you have been sent"
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

        Then I should see the text "This is the token in the e-mail you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Password Expired" page

    @mock_two_factor_login_force_password_change
    Scenario: User provides the correct detail for a 2 factor login but the user is forced to change their password
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the e-mail you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Change Password" page

    @mock_two_factor_confirm_tcs
    Scenario: User needs to confirm the terms and conditions
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the text "This is the token in the e-mail you have been sent"
        And I enter "valid.token" in the "Token" field
        And I click on the "Sign in" button

        Then I should see the "Terms and Conditions" page

    @mock_force_password_change_and_tc_limited_permissions
    Scenario: User with limited permissions needs to change their password and confirm the terms and conditions
        When I go to the "Login" page
        And I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Change Password" page
        And enter "valid.password" in the "Old password" field
        And enter "New.password1" in the "New password" field
        And enter "New.password1" in the "Confirm new password" field
        And click on the "Change Password" button

        Then I should see the "Sign in" page
        When I enter "valid.user" in the "Username" field
        And I enter "valid.password" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Terms and Conditions" page
        And I should see the text "In order to proceed you must read and accept the terms and conditions."
        And I click on the "Confirm" button

        Then I should see the "Terms and Conditions" page
        And I should receive the message "This can't be blank"
        And I check "I confirm that I have read and understood the terms & conditions" checkbox
        And I click on the "Confirm" button
