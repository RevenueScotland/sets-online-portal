# feature/registration_wizard.feature

Feature: Registration Wizard
  As a user
  I want to register to use the Revenue Scotland system

  Scenario: Register as an individual user validation
    When I go to the "Login" page
    And if available, click the "Accept all cookies" button
    And I click on the "Register if you don't have an account" link
    Then I should see the text "Which type of tax return do you want to be able to file?"

    When I click on the "Continue" button
    Then I should see the text "Which type of tax return do you want to be able to file?"
    And I should receive the message "Which type of tax return do you want to be able to file can't be blank"

    When I check the "Land and Building Transaction Tax" radio button in answer to the question "Which type of tax return do you want to be able to file?"
    And I click on the "Continue" button
    Then I should see the text "Sign up to file tax returns"
    And I should see the text "Who is the account for?"

    When I click on the "Continue" button
    Then I should see the text "Sign up to file tax returns"
    And I should receive the message "Who is the account for can't be blank"

    When  I click on the "Who is the account for can't be blank" link
    Then The field with id "account_party_account_type_agent" should get focus
    And I check the "A taxpayer" radio button in answer to the question "Who is the account for?"
    And I click on the "Continue" button
    And I should see the text "Who are you signing up on behalf of?"

    When I click on the "Continue" button
    Then I should receive the message "Who are you signing up on behalf of can't be blank"
    And I should see the text "Who are you signing up on behalf of?"

    When I check the "Individual/Sole trader" radio button in answer to the question "Who are you signing up on behalf of?"
    And I click on the "Continue" button
    Then I should see the sub-title "Your individual account details"

    When I click on the "Continue" button
    Then I should see the sub-title "Your individual account details"
    And I should receive the message "Email address can't be blank"
    And I should receive the message "National insurance number (NINO) can't be blank"
    And I should receive the message "Last name can't be blank"
    And I should receive the message "First name can't be blank"
    And I should receive the message "Contact phone number can't be blank"

    # Check error links are working correct
    When I click on the "First name can't be blank" link
    Then The field with id "account_current_user_forename" should get focus
    When I click on the "Last name can't be blank" link
    Then The field with id "account_current_user_surname" should get focus
    When I click on the "National insurance number (NINO) can't be blank" link
    Then The field with id "account_nino" should get focus
    When I click on the "Email address can't be blank" link
    Then The field with id "account_email_address" should get focus
    When I click on the "Contact phone number can't be blank" link
    Then The field with id "account_contact_number" should get focus

    When I enter "noreply@necsws@com" in the "Email address" field
    And I enter "noreply@necsws@com" in the "Confirm email address" field
    And I enter "AB123456E" in the "National insurance number (NINO)" field
    And I click on the "Continue" button
    Then I should see the sub-title "Your individual account details"
    And I should receive the message "Email address is invalid"
    And I should receive the message "National insurance number (NINO) is invalid"

    When I enter "noreply@necswswithaverylonaddressthatisgreaterthan100andthisisnowgettingboringtotypebutIonlyhaveafewmoretogo.com" in the "Email address" field
    And I enter "noreply@necswswithaverylonaddressthatisgreaterthan100andthisisnowgettingboringtotypebutIonlyhaveafewmoretogo.com" in the "Confirm email address" field
    And I click on the "Continue" button
    Then I should see the sub-title "Your individual account details"
    And I should receive the message "Email address is too long (maximum is 100 characters)"

    When I enter "noreply@necsws.com" in the "Email address" field
    And I click on the "Continue" button
    Then I should see the sub-title "Your individual account details"
    And I should receive the message "Email address does not match"

    When I enter "forename" in the "First name" field
    And I enter "surname" in the "Last name" field
    And I enter "noreply@necsws.properties" in the "Email address" field
    And I enter "noreply@necsws.properties" in the "Confirm email address" field
    And I enter "07700 900123" in the "Contact phone number" field
    And I enter "AB123456D" in the "National insurance number (NINO)" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your contact address"

    When I clear the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode can't be blank"
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "short" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "wibble wobble" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode is too long (maximum is 8 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "wibble" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode is invalid"

    When I enter "RG1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "The postcode doesn't return any addresses"

    When I clear the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode can't be blank"
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page
    When I click on the "Or edit the selected address" button
    And I clear the "address_address_line1" field
    And I clear the "address_town" field
    And I clear the "address_postcode" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your contact address"
    And I should receive the message "Building and street can't be blank"
    And I should receive the message "Town can't be blank"
    # postcode is optional on manual address
    And I should not receive the message "Postcode can't be blank"

    When I click on the "Return to postcode lookup" button
    And I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page
    When I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your individual account details"
    And I should see a link with text "Terms & conditions (opens in a new tab)"
    And I should see a link with text "Email communication policy (opens in a new tab)"

    When I click on the "Confirm" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your individual account details"
    And I should receive the message "Username is too short (minimum is 5 characters)"
    And I should receive the message "Password can't be blank"
    And I should receive the message "The terms and conditions must be accepted"
    And I should receive the message "The email communication policy agreement can't be blank"

    When I enter "SM" in the "Username" field
    And I check the "I confirm that I have read and understood the terms & conditions" checkbox using the span
    And I check the "Yes" radio button in answer to the question "I confirm that I have read and understood Revenue Scotland’s email communication policy. I agree to receive email communication from Revenue Scotland and accept the associated risks"
    And I enter "Password001" in the "Password" field
    And I enter "Password002" in the "Confirm password" field
    And I click on the "Confirm" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your individual account details"
    And I should receive the message "Username is too short (minimum is 5 characters)"
    And I should receive the message "Password does not match"

    When I enter "B1I6<12A65@AG0BHA:H?AA34??36I7C725;11?=;G1329B@11HG?8<8?I8B@21FEG>FDHH=FB664B;;27C@7706E8?H48E?6@<;ED2@<9@3D4:DHI>6>::E<HF1;?8II>:C=G78B:;:7FH5@D@>BA>699B0<28?HDG1F<=<90=FA==A<:9H:>58:55:<57CF@>@70;43<FA0611=8>" in the "Password" field
    And I enter "B1I6<12A65@AG0BHA:H?AA34??36I7C725;11?=;G1329B@11HG?8<8?I8B@21FEG>FDHH=FB664B;;27C@7706E8?H48E?6@<;ED2@<9@3D4:DHI>6>::E<HF1;?8II>:C=G78B:;:7FH5@D@>BA>699B0<28?HDG1F<=<90=FA==A<:9H:>58:55:<57CF@>@70;43<FA0611=8>" in the "Confirm password" field
    And I click on the "Confirm" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your individual account details"
    And I should receive the message "Password is too long (maximum is 200 characters)"

  # this only tests the specific bits for other company, assuming the rest has been tested by
  # Register as an individual user validation
  Scenario: Register as an other company validation
    When I go to the "Login" page
    And I click on the "Register if you don't have an account" link
    And I should see the "Sign up to file tax returns" page
    Then I should see the text "Which type of tax return do you want to be able to file?"

    When I click on the "Continue" button
    Then I should see the text "Which type of tax return do you want to be able to file?"
    And I should receive the message "Which type of tax return do you want to be able to file can't be blank"
    When I check the "Land and Building Transaction Tax" radio button in answer to the question "Which type of tax return do you want to be able to file?"
    And I click on the "Continue" button
    Then I should see the text "Who is the account for?"

    When I check the "A taxpayer" radio button in answer to the question "Who is the account for?"
    And I click on the "Continue" button
    Then I should see the text "Who are you signing up on behalf of?"

    When I check the "Non registered body" radio button in answer to the question "Who are you signing up on behalf of?"
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation"

    When I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation"
    And I should receive the message "Name can't be blank"
    When I enter "Other Company" in the "account_company_company_name" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation address"

    When I clear the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode can't be blank"
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "short" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "wibble wobble" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode is too long (maximum is 8 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "wibble" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode is invalid"

    When I enter "RG1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "The postcode doesn't return any addresses"

    When I clear the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation address"
    And I should receive the message "Postcode can't be blank"
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page
    When I click on the "Or edit the selected address" button
    And I clear the "address_address_line1" field
    And I clear the "address_town" field
    And I clear the "address_postcode" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation address"
    And I should receive the message "Building and street can't be blank"
    And I should receive the message "Town can't be blank"
    # postcode is optional on mannual address
    And I should not receive the message "Postcode can't be blank"

    When I click on the "Return to postcode lookup" button
    And I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page

    When I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation contact details"

    When I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation contact details"
    And I should receive the message "Organisation phone number can't be blank"
    And I should receive the message "Organisation email address can't be blank"
    And I should receive the message "Organisation main representative name can't be blank"
    And I should receive the message "National insurance number (NINO) can't be blank"

    When I enter "Mr Wobble" in the "Organisation main representative name" field
    And I enter "noreply@necsws@com" in the "Organisation email address" field
    And I enter "1234" in the "Organisation phone number" field
    And I enter "1234" in the "account_nino" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation contact details"
    And I should receive the message "Organisation phone number is invalid"
    And I should receive the message "Organisation email address is invalid"
    And I should receive the message "National insurance number (NINO) is invalid"

    When I enter "noreply@necsws.com" in the "Organisation email address" field
    And I enter "01234567891" in the "Organisation phone number" field
    And I enter "AB123456D" in the "account_nino" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Representatives address"

    When I clear the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode can't be blank"
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "short" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "wibble wobble" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should receive the message "Postcode is too long (maximum is 8 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "wibble" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should receive the message "Postcode is invalid"
    And I enter "RG1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should receive the message "The postcode doesn't return any addresses"

    When I clear the "address_summary_postcode" field

    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Representatives address"
    And I should receive the message "Postcode can't be blank"
    And I should receive the message "Postcode is too short (minimum is 6 characters)"
    And I should receive the message "Postcode is invalid"

    When I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page

    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page

    When I click on the "Or edit the selected address" button
    And I clear the "address_address_line1" field
    And I clear the "address_town" field
    And I clear the "address_postcode" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Representatives address"
    And I should receive the message "Building and street can't be blank"
    And I should receive the message "Town can't be blank"
    # postcode is optional on mannual address
    And I should not receive the message "Postcode can't be blank"

    When I click on the "Return to postcode lookup" button
    And I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page

    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page

    When I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page

  # this only tests the specific bits for registered company, assuming the rest has been tested by
  # Register as an individual user validation
  Scenario: Register as an registered company validation
    When I go to the "Login" page
    And I click on the "Register if you don't have an account" link
    Then I should see the text "Which type of tax return do you want to be able to file?"

    When I click on the "Continue" button
    Then I should see the text "Which type of tax return do you want to be able to file?"
    And I should receive the message "Which type of tax return do you want to be able to file can't be blank"
    When I check the "Scottish Aggregate Tax" radio button in answer to the question "Which type of tax return do you want to be able to file?"
    And I click on the "Continue" button
    Then I should see the text "Who is the account for?"

    When I check the "A UK tax representative" radio button in answer to the question "Who is the account for?"
    And I click on the "Continue" button
    Then I should see the text "Which SAT reference do you want this account to be able to access?"
    And I should see the text "Taxpayer's business name"
    And I should see the text "Taxpayer's business postcode"
    And I should see the text "Taxpayer's business contact email address"

    When I click on the "Continue" button
    Then I should see the text "Which SAT reference do you want this account to be able to access?"
    And I should receive the message "Which SAT reference do you want this account to be able to access can't be blank"
    And I should receive the message "Taxpayer's business name can't be blank"
    And I should receive the message "Taxpayer's business postcode can't be blank"
    And I should receive the message "Taxpayer's business contact email address can't be blank"

    When I enter "SAT1234567ABCD" in the "Which SAT reference do you want this account to be able to access?" field
    And I enter "RANDOM_text,150" in the "Taxpayer's business name" field
    And I enter "RANDOM_text,6" in the "Taxpayer's business postcode" field
    And I enter "test@example.com" in the "Taxpayer's business contact email address" field
    And I click on the "Continue" button
    Then I should see the text "Who are you signing up on behalf of?"

    When I click on the "Continue" button
    Then I should see the text "Who are you signing up on behalf of?"
    And I should receive the message "Who are you signing up on behalf of can't be blank"

    When I check the "Companies House registered body" radio button in answer to the question "Who are you signing up on behalf of?"
    And I click on the "Continue" button
    Then I should see the sub-title "Company"

    When I click on the "Find company" button
    Then I should receive the message "Company number can't be blank"

    When I enter "0123" in the "Company number" field
    And I click on the "Find company" button
    Then I should receive the message "Company number is too short (minimum is 8 characters)"

    When I enter "0123456789" in the "Company number" field
    And I click on the "Find company" button
    Then I should receive the message "Company number is too long (maximum is 8 characters)"

    When I enter "invalid1" in the "Company number" field
    And I click on the "Find company" button
    Then I should receive the message "Company number is invalid"

    When I enter "00000001" in the "Company number" field
    And I click on the "Find company" button
    Then I should receive the message "The company number doesn't return a company"
    And I clear the "Company number" field
    And I click on the "Continue" button

    Then I should see the sub-title "Company"
    And I should receive the message "Company number can't be blank"
    And I should receive the message "A company must be chosen"

    When I enter "00928555" in the "Company number" field
    And I click on the "Find company" button
    Then I should see the text "BOOTS UK LIMITED" in the 1 st field "Address"
    And I should see the text "Nottingham" in field "Town"
    And I should see the text "NG2 3AA" in field "Postcode"
    And field "Company name" should be readonly
    And the 1 st field "Address" should be readonly
    And field "Address line 2" should be readonly
    And field "Town" should be readonly
    And field "County" should be readonly
    And field "Postcode" should be readonly

    When I click on the "Continue" button
    Then I should see the sub-title "Contact address"

    When I click on the "Continue" button
    Then I should see the sub-title "Contact address"
    And I should receive the message "Is your registered address also your contact address can't be blank"

    When I check the "Yes" radio button in answer to the question "Is your registered address also your contact address?"
    And I click on the "Continue" button
    Then I should see the sub-title "Organisation contact details"

    When I click on the "Continue" button
    Then I should see the sub-title "Organisation contact details"
    And I should receive the message "Organisation phone number can't be blank"
    And I should receive the message "Organisation email address can't be blank"
    And I should receive the message "Organisation main representative name can't be blank"

    When I enter "Mr Wobble" in the "Organisation main representative name" field
    And I enter "noreply@necsws@com" in the "Organisation email address" field
    And I enter "1234" in the "Organisation phone number" field
    And I click on the "Continue" button
    Then I should see the sub-title "Organisation contact details"
    And I should receive the message "Organisation phone number is invalid"
    And I should receive the message "Organisation email address is invalid"

    When I enter "noreply@necsws.com" in the "Organisation email address" field
    And I enter "01234567891" in the "Organisation phone number" field
    And I click on the "Continue" button
    Then I should see the text "Sign up to file tax returns"

  @mock_new_user_registration
  Scenario: Register as an individual user
    When I go to the "Login" page
    And I click on the "Register if you don't have an account" link
    Then I should see the text "Which type of tax return do you want to be able to file?"

    When I check the "Land and Building Transaction Tax" radio button in answer to the question "Which type of tax return do you want to be able to file?"
    And I click on the "Continue" button
    Then I should see the text "Who is the account for?"

    When I check the "A taxpayer" radio button in answer to the question "Who is the account for?"
    And I click on the "Continue" button

    Then I should see the text "Who are you signing up on behalf of?"
    When I check the "Individual/Sole trader" radio button in answer to the question "Who are you signing up on behalf of?"
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your individual account details"

    When I enter "forename" in the "First name" field
    And I enter "surname" in the "Last name" field
    And I enter "test@example.com" in the "Email address" field
    And I enter "test@example.com" in the "Confirm email address" field
    And I enter "07700 900123" in the "Contact phone number" field
    And I enter "AB123456D" in the "National insurance number (NINO)" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your contact address"

    When I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page
    And I should see the text "Royal Mail" in field "address_address_line1"
    And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
    And I should see the text "Dunstable Road" in field "address_address_line3"
    And I should see the text "LUTON" in field "address_town"
    And I should see the text "LU1 1AA" in field "address_postcode"

    When I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your individual account details"

    When I enter "NEW.USER.REGISTRATION" in the "Username" field
    And I enter "Password001" in the "Password" field
    And I enter "Password001" in the "Confirm password" field
    And I check the "I confirm that I have read and understood the terms & conditions" checkbox using the span
    And I check the "Yes" radio button in answer to the question "I confirm that I have read and understood Revenue Scotland’s email communication policy. I agree to receive email communication from Revenue Scotland and accept the associated risks"
    And I click on the "Confirm" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Complete sign up"

  @mock_new_other_company_registration
  Scenario: Register as a non-registered company
    When I go to the "Login" page
    And I click on the "Register if you don't have an account" link
    Then I should see the text "Which type of tax return do you want to be able to file?"

    When I check the "Land and Building Transaction Tax" radio button in answer to the question "Which type of tax return do you want to be able to file?"
    And I click on the "Continue" button
    Then I should see the text "Who is the account for?"

    When I check the "A taxpayer" radio button in answer to the question "Who is the account for?"
    And I click on the "Continue" button

    Then I should see the text "Who are you signing up on behalf of?"
    When I check the "Non registered body" radio button in answer to the question "Who are you signing up on behalf of?"
    When I click on the "Continue" button

    Then I should see the sub-title "Organisation"
    And I enter "Other Company" in the "account_company_company_name" field
    And I click on the "Continue" button

    Then I should see the sub-title "Organisation address"
    When I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page
    And I should see the text "Royal Mail" in field "address_address_line1"
    And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
    And I should see the text "Dunstable Road" in field "address_address_line3"
    And I should see the text "LUTON" in field "address_town"
    And I should see the text "LU1 1AA" in field "address_postcode"
    When I click on the "Continue" button

    Then I should see the sub-title "Organisation contact details"
    When I enter "Mr Wobble" in the "Organisation main representative name" field
    And I enter "noreply@necsws.com" in the "Organisation email address" field
    And I enter "01234567891" in the "Organisation phone number" field
    And I enter "AB123456D" in the "account_nino" field
    And I click on the "Continue" button

    Then I should see the sub-title "Representatives address"
    When I enter "RG30 6XT" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "10 Rydal Avenue, Tilehurst, READING, RG30 6XT" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page
    And I should see the text "10 Rydal Avenue" in field "address_address_line1"
    And I should see the text "Tilehurst" in field "address_address_line2"
    And I should see the text "READING" in field "address_town"
    And I should see the text "RG30 6XT" in field "address_postcode"

    When I click on the "Continue" button
    Then I should see the sub-title "Your individual account details"
    And I enter "forename" in the "First name" field
    And I enter "surname" in the "Last name" field
    And I enter "test@example.com" in the "Email address" field
    And I enter "test@example.com" in the "Confirm email address" field
    And I enter "01234567890" in the "Contact phone number" field
    When I click on the "Continue" button

    Then I should see the sub-title "Your individual account details"
    And I enter "NEW.USER.REGISTRATION" in the "Username" field
    And I enter "Password001" in the "Password" field
    And I enter "Password001" in the "Confirm password" field
    And I check the "I confirm that I have read and understood the terms & conditions" checkbox using the span
    And I check the "Yes" radio button in answer to the question "I confirm that I have read and understood Revenue Scotland’s email communication policy. I agree to receive email communication from Revenue Scotland and accept the associated risks"
    And I click on the "Confirm" button

    Then I should see the sub-title "Complete sign up"

  @mock_new_company_registration
  Scenario: Register as a registered company with a separate contact address
    When I go to the "Login" page
    And I click on the "Register if you don't have an account" link
    Then I should see the text "Which type of tax return do you want to be able to file?"

    When I check the "Land and Building Transaction Tax" radio button in answer to the question "Which type of tax return do you want to be able to file?"
    And I click on the "Continue" button
    Then I should see the text "Who is the account for?"

    When I check the "A taxpayer" radio button in answer to the question "Who is the account for?"
    And I click on the "Continue" button

    Then I should see the text "Who are you signing up on behalf of?"
    When I check the "Companies House registered body" radio button in answer to the question "Who are you signing up on behalf of?"
    When I click on the "Continue" button

    Then I should see the sub-title "Company"
    When I enter "09338960" in the "Company number" field
    And I click on the "Find company" button
    Then I should see the text "NORTHGATE PUBLIC SERVICES LIMITED" in field "company_company_name"
    And I should see the text "1st Floor, Imex Centre" in field "company_address_line1"
    And I should see the text "575-599 Maxted Road" in field "company_address_line2"
    And I should see the text "Hemel Hempstead" in field "company_locality"
    And I should see the text "Hertfordshire" in field "company_county"
    And I should see the text "HP2 7DX" in field "company_postcode"
    And I click on the "Continue" button

    Then I should see the sub-title "Contact address"
    When I check the "No" radio button in answer to the question "Is your registered address also your contact address?"
    And I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page
    And I should see the text "Royal Mail" in field "address_address_line1"
    And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
    And I should see the text "Dunstable Road" in field "address_address_line3"
    And I should see the text "LUTON" in field "address_town"
    And I should see the text "LU1 1AA" in field "address_postcode"

    When I click on the "Continue" button
    Then I should see the sub-title "Organisation contact details"
    When I enter "Mr Wobble" in the "Organisation main representative name" field
    And I enter "noreply@necsws.com" in the "Organisation email address" field
    And I enter "01234567891" in the "Organisation phone number" field
    And I click on the "Continue" button

    Then I should see the text "Sign up to file tax returns"
    And I should see the sub-title "Your individual account details"
    And I enter "forename" in the "First name" field
    And I enter "surname" in the "Last name" field
    And I enter "test@example.com" in the "Email address" field
    And I enter "test@example.com" in the "Confirm email address" field
    And I enter "01234567890" in the "Contact phone number" field
    When I click on the "Continue" button

    Then I should see the sub-title "Your individual account details"
    And I enter "NEW.USER.REGISTRATION" in the "Username" field
    And I enter "Password001" in the "Password" field
    And I enter "Password001" in the "Confirm password" field
    And I check the "I confirm that I have read and understood the terms & conditions" checkbox using the span
    And I check the "Yes" radio button in answer to the question "I confirm that I have read and understood Revenue Scotland’s email communication policy. I agree to receive email communication from Revenue Scotland and accept the associated risks"
    And I click on the "Confirm" button
    Then I should see the sub-title "Complete sign up"

  @mock_new_company_no_address_registration
  Scenario: Register as a registered company without a separate contact address
    When I go to the "Login" page
    And I click on the "Register if you don't have an account" link
    Then I should see the text "Which type of tax return do you want to be able to file?"

    When I check the "Land and Building Transaction Tax" radio button in answer to the question "Which type of tax return do you want to be able to file?"
    And I click on the "Continue" button
    Then I should see the text "Who is the account for?"

    When I check the "A taxpayer" radio button in answer to the question "Who is the account for?"
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the text "Who are you signing up on behalf of?"

    When I check the "Companies House registered body" radio button in answer to the question "Who are you signing up on behalf of?"
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Company"

    When I enter "09338960" in the "Company number" field
    And I click on the "Find company" button
    Then I should see the text "NORTHGATE PUBLIC SERVICES LIMITED" in field "company_company_name"
    And I should see the text "1st Floor, Imex Centre" in field "company_address_line1"
    And I should see the text "575-599 Maxted Road" in field "company_address_line2"
    And I should see the text "Hemel Hempstead" in field "company_locality"
    And I should see the text "Hertfordshire" in field "company_county"
    And I should see the text "HP2 7DX" in field "company_postcode"

    When I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Contact address"
    When I check the "Yes" radio button in answer to the question "Is your registered address also your contact address?"
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Organisation contact details"

    When I enter "Mr Wobble" in the "Organisation main representative name" field
    And I enter "noreply@necsws.com" in the "Organisation email address" field
    And I enter "01234567891" in the "Organisation phone number" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your individual account details"

    When I enter "forename" in the "First name" field
    And I enter "surname" in the "Last name" field
    And I enter "test@example.com" in the "Email address" field
    And I enter "test@example.com" in the "Confirm email address" field
    And I enter "01234567890" in the "Contact phone number" field
    And I click on the "Continue" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Your individual account details"

    When I enter "NEW.USER.REGISTRATION" in the "Username" field
    And I enter "Password001" in the "Password" field
    And I enter "Password001" in the "Confirm password" field
    And I check the "I confirm that I have read and understood the terms & conditions" checkbox using the span
    And I check the "Yes" radio button in answer to the question "I confirm that I have read and understood Revenue Scotland’s email communication policy. I agree to receive email communication from Revenue Scotland and accept the associated risks"
    And I click on the "Confirm" button
    Then I should see the "Sign up to file tax returns" page
    And I should see the sub-title "Complete sign up"

  @mock_new_company_registration_for_SAT
  Scenario: Register as a registered company with a separate contact address for SAT service
    When I go to the "Login" page
    And I click on the "Register if you don't have an account" link
    Then I should see the text "Which type of tax return do you want to be able to file?"

    When I check the "Scottish Aggregate Tax" radio button in answer to the question "Which type of tax return do you want to be able to file?"
    And I click on the "Continue" button
    Then I should see the text "Who is the account for?"

    When I check the "A UK tax representative" radio button in answer to the question "Who is the account for?"
    And I click on the "Continue" button
    Then I should see the text "Which SAT reference do you want this account to be able to access?"
    And I should see the text "Taxpayer's business name"
    And I should see the text "Taxpayer's business postcode"
    And I should see the text "Taxpayer's business contact email address"

    When I enter "SAT1234777AABB" in the "Which SAT reference do you want this account to be able to access?" field
    And I enter "RANDOM_text,150" in the "Taxpayer's business name" field
    And I enter "RANDOM_text,6" in the "Taxpayer's business postcode" field
    And I enter "test@example.com" in the "Taxpayer's business contact email address" field
    And I click on the "Continue" button
    Then I should see the text "Who are you signing up on behalf of?"
    When I check the "Companies House registered body" radio button in answer to the question "Who are you signing up on behalf of?"
    When I click on the "Continue" button

    Then I should see the sub-title "Company"
    When I enter "09338960" in the "Company number" field
    And I click on the "Find company" button
    Then I should see the text "NORTHGATE PUBLIC SERVICES LIMITED" in field "company_company_name"
    And I should see the text "1st Floor, Imex Centre" in field "company_address_line1"
    And I should see the text "575-599 Maxted Road" in field "company_address_line2"
    And I should see the text "Hemel Hempstead" in field "company_locality"
    And I should see the text "Hertfordshire" in field "company_county"
    And I should see the text "HP2 7DX" in field "company_postcode"
    And I click on the "Continue" button

    Then I should see the sub-title "Contact address"
    When I check the "No" radio button in answer to the question "Is your registered address also your contact address?"
    And I enter "LU1 1AA" in the "address_summary_postcode" field
    And I click on the "Find address" button
    Then I should see the "Sign up to file tax returns" page
    When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
    And I click on the "Use this address" button when available
    Then I should see the "Sign up to file tax returns" page
    And I should see the text "Royal Mail" in field "address_address_line1"
    And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
    And I should see the text "Dunstable Road" in field "address_address_line3"
    And I should see the text "LUTON" in field "address_town"
    And I should see the text "LU1 1AA" in field "address_postcode"

    When I click on the "Continue" button
    Then I should see the sub-title "Organisation contact details"
    When I enter "Mr Wobble" in the "Organisation main representative name" field
    And I enter "noreply@necsws.com" in the "Organisation email address" field
    And I enter "01234567891" in the "Organisation phone number" field
    And I click on the "Continue" button

    Then I should see the text "Sign up to file tax returns"
    And I should see the sub-title "Your individual account details"
    And I enter "forename" in the "First name" field
    And I enter "surname" in the "Last name" field
    And I enter "test@example.com" in the "Email address" field
    And I enter "test@example.com" in the "Confirm email address" field
    And I enter "01234567890" in the "Contact phone number" field
    When I click on the "Continue" button

    Then I should see the sub-title "Your individual account details"
    And I enter "NEW.USER.REGISTRATION" in the "Username" field
    And I enter "Password001" in the "Password" field
    And I enter "Password001" in the "Confirm password" field
    And I check the "I confirm that I have read and understood the terms & conditions" checkbox using the span
    And I check the "Yes" radio button in answer to the question "I confirm that I have read and understood Revenue Scotland’s email communication policy. I agree to receive email communication from Revenue Scotland and accept the associated risks"
    And I click on the "Confirm" button
    Then I should see the sub-title "Complete sign up"