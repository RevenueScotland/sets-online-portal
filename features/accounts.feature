# feature/account.feature


Feature: Account
    As a user
    I want to see and update details of my account
    so that my information is up to date and I am secure

    Scenario: View account details of a person
        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Email address"
        And I should see the text "noreply@northgateps.com"
        And I should see the text "Address"
        And I should see the text "Park Lane, Garden Village, NORTHTOWN, Northshire, RG1 1PB"
        And I should see the text "Contact telephone number"
        And I should not see the text "Company number"
        And I should not see the text "Company name"
        And I should not see the text "Registered address"
        And I should not see the text "To change your registered company details use the update option against the company number"
        And I should see the text "Username"
        And I should see the text "ADAM.PORTAL-TEST"
        And I click on the "Create or update users" link

        Then I should see the "Account users" page

    Scenario: View accounts details of a registered company
        Given I have signed in "PORTAL.NORTHGATE" and password "Password1!"
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Email address"
        And I should see the text "noreply@northgateps.com"
        And I should see the text "Contact telephone number"
        And I should see the text "Company number"
        And I should see the text "09338960"
        And I should see the text "NORTHGATE PUBLIC SERVICES LIMITED"
        And I should see the text "Registered address"
        And I should see the text "Peoplebuilding 2 Peoplebuilding Estate, Maylands Avenue, Hemel Hempstead, Hertfordshire, HP2 4NW"
        And I should see the text "Address"
        And I should see the text "Peoplebuilding 2 Peoplebuilding Estate, Maylands Avenue, Hemel Hempstead, Hertfordshire, HP2 4NW"
        And I should see the text "Contact Revenue Scotland if you want to change your company number or company name"
        And I should see the text "Username"
        And I should see the text "PORTAL.NORTHGATE"

    Scenario: View accounts details of a non-registered company
        Given I have signed in
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Email address"
        And I should see the text "noreply@northgateps.com"
        And I should see the text "Contact telephone number"
        And I should see the text "Test Portal Company"
        And I should see the text "Address"
        And I should see the text "1 Acacia Avenue, Garden Village, NORTHTOWN, Northshire, RG1 1PB"
        And I should not see the text "Company Number"
        And I should not see the text "Registered address"
        And I should not see the text "To change your registered company details use the update option against the company number"
        And I should see the text "Username"
        And I should see the text "PORTAL.ONE"

    Scenario: Update basic details of a person validation rules
        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Username"
        And I should see the text "ADAM.PORTAL-TEST"
        And I click on the 1 st "Update" link

        Then I should see the "Update account" page
        When I enter "" in the "First name" field
        And I enter "" in the "Last name" field
        And I enter "noreply@northgateps@com" in the "Email address" field
        And I enter "noreply@northgateps@com" in the "Confirm email address" field
        And I enter "" in the "Contact telephone number" field
        And I enter "AB123456E" in the "National insurance number (NINO)" field
        And I click on the "Confirm" button

        Then I should see the "Update account" page
        And I should receive the message "Email address is invalid"
        And I should receive the message "Contact telephone number can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Last name can't be blank"
        And I should receive the message "National insurance number (NINO) is invalid"
        And I should not receive the message "Company name can't be blank"
        And I should not receive the message "Address can't be blank"
        When I enter "noreply@northgateps.com" in the "Confirm email address" field
        And I click on the "Confirm" button

        Then I should see the "Update account" page
        Then I should receive the message "Confirm email address doesn't match Email address"
        And I click on the "Back" link

        Then I should see the "Update account" page
        And I click on the "Back" link

        Then I should see the "Sign up details" page

    Scenario: Update basic details of a person
        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Username"
        And I should see the text "ADAM.PORTAL-TEST"
        And I click on the 1 st "Update" link

        Then I should see the "Update account" page
        And I flip "First name" field between "Adam" and "Dave" using marker "account_user_forename"
        And I flip "Last name" field between "Portal-Test" and "Porthole-Test" using marker "account_user_surname"
        And I flip "Email address" field between "noreply@northgateps.com" and "noreply2@northgateps.com" using marker "account_email_address"
        And I flip "Confirm email address" field between "noreply@northgateps.com" and "noreply2@northgateps.com" using marker "account_email_address_confirmation"
        And I flip "Contact telephone number" field between "07700900123" and "07700900321" using marker "account_contact_number"
        And I flip "National insurance number (NINO)" field between "AB123456A" and "AB123455A" using marker "account_nino"
        And I click on the "Confirm" button

        Then I should see the "Sign up details" page
        And I should see the value flipped using marker "account_user_forename"
        And I should see the value flipped using marker "account_user_surname"
        And I should see the value flipped using marker "account_contact_number"
        And I should see the value flipped using marker "account_email_address"

    Scenario: Update basic details of a registered company validation rules
        Given I have signed in "PORTAL.NORTHGATE" and password "Password1!"
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Username"
        And I should see the text "PORTAL.NORTHGATE"
        And I click on the 1 st "Update" link

        Then I should see the "Update account" page
        And I enter "noreply@northgateps@com" in the "Email address" field
        And I enter "noreply@northgateps@com" in the "Confirm email address" field
        And I enter "sfdfdsfd" in the "Contact telephone number" field
        And I click on the "Confirm" button

        Then I should see the "Update account" page
        And I should receive the message "Email address is invalid"
        And I should receive the message "Contact telephone number is invalid"
        And I should not receive the message "Company name can't be blank"
        And I should not receive the message "Address can't be blank"
        And I should not receive the message "First name can't be blank"
        And I should not receive the message "Last name can't be blank"
        And I should not receive the message "National insurance number (NINO) can't be blank"

    Scenario: Update basic details of a registered company
        Given I have signed in "PORTAL.NORTHGATE" and password "Password1!"
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Username"
        And I should see the text "PORTAL.NORTHGATE"
        And I click on the 1 st "Update" link

        Then I should see the "Update account" page
        And I flip "Email address" field between "noreply@northgateps.com" and "noreply2@northgateps.com" using marker "account_email_address"
        And I flip "Confirm email address" field between "noreply@northgateps.com" and "noreply2@northgateps.com" using marker "account_email_address_confirmation"
        And I flip "Contact telephone number" field between "07700900123" and "07700900321" using marker "account_contact_number"
        And I click on the "Confirm" button

        Then I should see the "Sign up details" page
        And I should see the value flipped using marker "account_email_address"
        And I should see the value flipped using marker "account_contact_number"

    Scenario: Update basic details of a other company validation rules
        Given I have signed in
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Username"
        And I should see the text "PORTAL.ONE"
        And I click on the 1 st "Update" link

        Then I should see the "Update account" page
        When I enter "" in the "account_company_company_name" field
        And I enter "noreply@northgateps@com" in the "Email address" field
        And I enter "noreply@northgateps@com" in the "Confirm email address" field
        And I enter "" in the "Contact telephone number" field
        And I enter "AB123456E" in the "account_nino" field
        And I click on the "Confirm" button

        Then I should see the "Update account" page
        And I should receive the message "Email address is invalid"
        And I should receive the message "Representative national insurance number (NINO) is invalid"
        And I should receive the message "Contact telephone number can't be blank"
        And I should receive the message "Organisation name can't be blank"
        And I should not receive the message "Address can't be blank"
        And I should not receive the message "First name can't be blank"
        And I should not receive the message "Last name can't be blank"

    Scenario: Update basic details of a other company
        Given I have signed in
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Username"
        And I should see the text "PORTAL.ONE"
        And I click on the 1 st "Update" link

        Then I should see the "Update account" page
        And I flip "account_company_company_name" field between "Test Portal Company" and "Updated Test Portal Company" using marker "account_company_company_name"
        And I flip "Email address" field between "noreply@northgateps.com" and "noreply2@northgateps.com" using marker "account_email_address"
        And I flip "Confirm email address" field between "noreply@northgateps.com" and "noreply2@northgateps.com" using marker "account_email_address_confirmation"
        And I flip "Contact telephone number" field between "07700900123" and "07700900321" using marker "account_contact_number"
        And I flip "account_nino" field between "AB123456C" and "AB123456D" using marker "account_nino"
        And I click on the "Confirm" button

        Then I should see the "Sign up details" page
        And I should see the value flipped using marker "account_company_company_name"
        And I should see the value flipped using marker "account_email_address"
        And I should see the value flipped using marker "account_contact_number"

    Scenario: Update address details validation
        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Username"
        And I should see the text "ADAM.PORTAL-TEST"
        And I click on the 2 nd "Update" link

        Then I should see the "Update address" page
        When enter "" in the "address_summary_postcode" field
        And click on the "Find Address" button
        Then I should receive the message "This can't be blank"
        And I should receive the message "This is too short (minimum is 6 characters)"
        And I should receive the message "This is invalid"
        And enter "short" in the "address_summary_postcode" field
        And click on the "Find Address" button
        Then I should receive the message "This is too short (minimum is 6 characters)"
        And I should receive the message "This is invalid"
        And enter "wibble wobble" in the "address_summary_postcode" field
        And click on the "Find Address" button
        Then I should receive the message "This is too long (maximum is 8 characters)"
        And I should receive the message "This is invalid"
        And enter "wibble" in the "address_summary_postcode" field
        And click on the "Find Address" button
        Then I should receive the message "This is invalid"
        And enter "RG1 1AA" in the "address_summary_postcode" field
        And click on the "Find Address" button
        Then I should receive the message "Postcode returns no address"
        When I click on the "Back" link

        Then I should see the "Update address" page
        And click on the "Edit address" button
        And enter "" in the "address_address_line1" field
        And enter "" in the "address_address_line2" field
        And enter "" in the "address_address_line3" field
        And enter "" in the "address_address_line4" field
        And enter "" in the "address_town" field
        And enter "" in the "address_county" field
        And enter "" in the "address_postcode" field
        When I click on the "Confirm" button

        Then I should see the "Update address" page
        Then I should receive the message "Address line 1 can't be blank"
        Then I should receive the message "Town can't be blank"
        # postcode is optional on mannual address
        Then I should not receive the message "Postcode can't be blank"

        Then I should see the "Update address" page
        And click on the "Edit address" button
        And enter "16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegdfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwy" in the "address_address_line1" field
        And enter "16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegdfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwy" in the "address_address_line2" field
        And enter "16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegdfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwy" in the "address_address_line3" field
        And enter "16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegd16 Lavender Laneewrhygfryuegdfyuwegdfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwyfyusfyugyurgwy" in the "address_address_line4" field
        And enter "16 Lavender Laneewrhygfryuegdfyuwegdfyusfyugyurgwyfrgwyegfwygfsdgfhbvhugyuergfygrygfsgrfywergfywerfgqwertyuifghfg" in the "address_town" field
        And enter "16 Lavender Laneewrhydfgfdfggfryuegdfyuwegdfyusfyugyurgwy16 Lavender Laneewrhygfryuegdfyuwegdfyusfyugyurgwy" in the "address_county" field
        When I click on the "Confirm" button

        Then I should see the "Update address" page
        Then I should receive the message "Address line 1 is too long (maximum is 255 characters)"
        Then I should receive the message "Address line 2 is too long (maximum is 255 characters)"
        Then I should receive the message "Address line 3 is too long (maximum is 255 characters)"
        Then I should receive the message "Address line 4 is too long (maximum is 255 characters)"
        Then I should receive the message "County is too long (maximum is 50 characters)"
        Then I should receive the message "Town is too long (maximum is 100 characters)"

    Scenario: Update address details of a person
        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        When I click on the "Account details" link

        Then I should see the "Sign up details" page
        And I should see the text "Username"
        And I should see the text "ADAM.PORTAL-TEST"
        And I should see the text "NORTHTOWN"
        And I click on the 2 nd "Update" link

        Then I should see the "Update address" page
        When click on the "Edit address" button
        And I enter "SOUTHTOWN" in the "address_town" field
        And I click on the "Back" link

        Then I should see the "Update address" page
        And I click on the "Back" link

        Then I should see the "Sign up details" page
        And I should see the text "NORTHTOWN"
        When I click on the 2 nd "Update" link

        Then I should see the "Update address" page
        When click on the "Edit address" button
        And I flip "address_address_line1" field between "8 Park Lane" and "9 Park Lane" using marker "address_address_line1"
        And I click on the "Confirm" button

        Then I should see the "Sign up details" page
        And I should see the value flipped using marker "address_address_line1"

    Scenario: Change password of user account(validation)
        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"

        And go to the "Account" page
        And click on the "Change your password" link

        Then I should see the "Change Password" page
        # Mandatory validation
        When I click on the "Change Password" button
        Then I should receive the message "Old password can't be blank"
        And I should receive the message "New password can't be blank"
        # Invalid password format
        When I enter "invalidpassword" in the "New password" field
        And click on the "Change Password" button
        # deferred to back office for now Then I should receive the message "New password is invalid"
        # Mismatch password
        When I enter "Password1234" in the "New password" field
        And enter "NoMatch1234" in the "Confirm new password" field
        And click on the "Change Password" button
        Then I should receive the message "Confirm new password doesn't match New password"
        # wrong old password
        When I enter "invalidpassword" in the "Old password" field
        And enter "Password1234" in the "New password" field
        And enter "Password1234" in the "Confirm new password" field
        And click on the "Change Password" button
        Then I should receive the message "Sign in credentials supplied are invalid"

    @mock_change_password
    Scenario: Successfully changing password of user account
        When I go to the "Login" page
        And enter "VALID.USER" in the "Username" field
        And enter "valid.password" in the "Password" field
        And click on the "Sign in" button
        And I click on the "Account details" link
        And click on the "Change your password" link

        Then I should see the "Change Password" page
        And enter "valid.password" in the "Old password" field
        And enter "New.password1" in the "New password" field
        And enter "New.password1" in the "Confirm new password" field
        And click on the "Change Password" button

        Then I should see the "Change password confirmation" page

    Scenario: Validation on activating account
        When I go to the "Login" page
        And click on the "Activate your account" link

        Then I should see the "Complete registration" page
        And click on the "Confirm" button
        Then I should receive the message "Registration token can't be blank"
        And enter "invalid.registation.token" in the "Registration token" field
        And click on the "Confirm" button
        Then I should receive the message "The Registration Token supplied is invalid. If you wish to use this service you will need to register an account."

    @mock_activate_account
    Scenario: Activating account to complete registration
        When I go to the "Login" page
        And click on the "Activate your account" link
        And enter "valid.registation.token" in the "Registration token" field
        And click on the "Confirm" button

        Then I should see the "Completed registration" page
