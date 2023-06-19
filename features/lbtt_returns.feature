# feature/lbtt_returns.feature

Feature: LBTT Returns
    As a user
    I want to be able to create a Lbtt return

    Scenario: Make a Conveyance return with ADS for a tax payer, including non ADS and ADS claim

        Create the return as lease
        Change this to conveyance
        Attempt to submit to check the whole model validation for conveyance
        Add an other organisation (charity) buyer
        Attempt to submit to check the whole model validation

        Add an other organisation (partnership) buyer with contact address
        Add a registered company buyer with contact address
        Add an other organisation (charity) buyer checking previous address list functionality, use a previous address,
        check correct distinct previous addresses are displayed on contact address
        and correct previous address is populated into address fields after selecting one of address

        Add a private seller
        Add a property (checking scottish property validation) with ADS (not defaulted as no transaction)
        Attempt to submit the return to check no ADS error
        Amend the property (and add ADS)
        Add ADS details
        Check reliefs not yet calculated
        Amend the property to remove ADS to validate MDR without ADS
        Add transaction details as residential
        Add reliefs and validate MDR without ADS
        Validate that I cannot add the same relief type again

        Add a new property to check ADS defaulted
        Amend the property to remove ADS
        Attempt to submit the return to check ADS error
        Remove the property

        Amend the transaction details to be non residential
        Amend the transaction details to be residential and validate MDR
        Amend the property to add ADS to validate MDR with ADS
        Amend the transaction details to add ADS related data for MDR
        Amend the reliefs to add ADS reliefs to the return
        Check the max validations on relief
        Checks reliefs are calculated
        Attempt to submit and check ADS vs MDR relief validation
        Add ADS reliefs to the return
        Check validations for standard relief types
        Replace the standard relief with the ads relief
        Check to add and delete relief buttons
        Amend the reliefs details to correct MDR
        Amend the reliefs
        Edit ADS relief details and check that relief amendments are cleared
        Check full model validation is now ok
        Check that the calculation is recaluated when changing the ads amount
        Reset the ads amount back to the original values
        Amend the calculation
        Amend the reliefs, checking the validation against the amend calculation values
        Save the draft
        Retrieve the draft
        Check the data
        Submit the return (BACS), checking DD is not available
        Check you could send a secure message
        Check you can download receipt

        Amend the return to claim a non ADS repayment
        Sign out and back in

        Amend the return to edit a Buyer to edit existing address by selecting address from previously used address list
        Amend the return to claim an ADS repayment
        Save the draft return
        Retrieve the draft and check the ADS repayment data
        Submit the return

        # Create the return as lease
        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page
        And I should see the text "Which return do you want to submit?"

        # Mandatory validation for selection of lbtt return type
        When I click on the "Continue" button
        Then I should receive the message "Which return do you want to submit can't be blank"

        # Pick the wrong type at first to check the whole model validation on Submit return (later) works
        # with the correct type (ie doesn't get stuck with the old type)
        When I check the "Lease" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        # Check the dynamic text for the calculation region
        And  I should see the text "The amounts in this section will be automatically calculated when you create or update the transaction section. You can edit them before you submit the return."
        When I click on the "Back" link
        And if available, click the confirmation dialog
        Then I should see the "About the return" page
        And the radio button "Lease" should be selected
        # Change to a conveyance
        When I check the "Conveyance or transfer" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        # Check the dynamic text for the calculation region
        And I should see the text "The amounts in this section will be automatically calculated when you create or update the transaction section. You can edit them before you submit the return."
        # Attempt to submit to check the whole model validation for conveyance
        When I click on the "Submit return" button
        Then I should receive the message "Please fill in at least one property"
        And  I should receive the message "Please fill in the 'About the transaction' section"
        And  I should receive the message "Please fill in at least one buyer"
        And  I should receive the message "Please fill in at least one seller"

        # Check you can see agent details and non provided for the reference
        And the table of data is displayed
            | Name             | Your reference |
            | Adam Portal-Test | None provided  |

        # Add an other organisation (charity) buyer
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page
        When I check the "An other organisation" radio button
        And I click on the "Continue" button
        Then I should see the "Organisation details" page
        And I click on the "Continue" button
        Then I should receive the message "Type of organisation can't be blank"

        When I check the "Other" radio button
        And I click on the "Continue" button
        Then I should receive the message "Organisation description can't be blank"

        When I enter "RANDOM_text,256" in the "Organisation description" field
        And I click on the "Continue" button
        Then I should receive the message "Organisation description is too long (maximum is 255 characters)"

        When I enter "RANDOM_text,255" in the "Organisation description" field
        And I click on the "Continue" button
        Then I should see the "Organisation details" page
        And I should not see the text "Type of organisation"

        When I click on the "Back" link
        Then I should see the "Organisation details" page
        And I should see the text "Type of organisation"

        When I click on the "Back" link
        Then I should see the "About the buyer" page
        And the radio button "An other organisation" should be selected

        When I click on the "Continue" button
        Then I should see the "Organisation details" page
        And I should see the text "Type of organisation"
        And the radio button "Other" should be selected

        When I check the "Charity" radio button
        And I click on the "Continue" button
        Then I should see the "Charity" page
        And I should see the sub-title "Charity details"

        When I click on the "Continue" button
        Then I should receive the message "What country's law is the organisation governed by can't be blank"
        And I should receive the message "Name can't be blank"
        And I should receive the message "Charity number can't be blank"
        And I should receive the message "Use the postcode search or enter the address manually"

        When I enter "Marks & Spencer Fund" in the "Name" field
        And I enter "ALBANIA" in the "What country's law is the organisation governed by" select or text field
        And I enter "RANDOM_text,101" in the "Charity number" field

        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Charity" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Charity" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click on the "Continue" button

        Then I should receive the message "Charity number is too long (maximum is 100 characters)"
        When I enter "123456" in the "Charity number" field
        And I click on the "Continue" button
        Then I should see the "Contact details" page

        When I click on the "Continue" button
        Then I should receive the message "Contact phone number can't be blank"
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Job title or position can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Use the postcode search or enter the address manually"

        #invalid name, contact email and phone number
        When I enter "RANDOM_text,51" in the "First name" field
        And I enter "RANDOM_text,101" in the "Last name" field
        And I enter "RANDOM_text,256" in the "Job title or position" field
        And I enter "012" in the "Contact phone number" field
        And I enter "noreplynecsws.com" in the "Email" field
        And I click on the "Continue" button
        Then I should receive the message "Job title or position is too long (maximum is 255 characters)"
        And I should receive the message "First name is too long (maximum is 50 characters)"
        And I should receive the message "Last name is too long (maximum is 100 characters)"
        And I should receive the message "Contact phone number is invalid"
        And I should receive the message "Email is invalid"

        When I enter "member" in the "Last name" field
        And I enter "club" in the "First name" field
        And I enter "Developer" in the "Job title or position" field
        And I enter "0123456789" in the "Contact phone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Contact details" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Contact details" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Buyer details" page
        And I should see the text "The buyer and seller are connected if they have an existing personal or business relationship. See guidance on if they are connected (opens in a new window) for further details"
        And I should see a link with text "they are connected (opens in a new window)"
        When I click on the "Continue" button
        Then I should see the text "If they are linked can't be blank"
        When I check the "Yes" radio button
        And I enter "Test relation" in the "How are they connected?" field
        And I click on the "Continue" button

        Then I should see the "Buyer details" page
        And I should see the text "See guidance on the meaning of 'representative partner' (opens in a new window) for further details"
        And I should see a link with text "'representative partner' (opens in a new window)"
        When I click on the "Continue" button
        Then I should see the text "If they are acting as a trustee or representative partner for tax purposes can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Return Summary" page
        And I should see the text "Marks & Spencer Fund"
        And I should see the text "Charity"

        # Attempt to submit to check the whole model validation
        When I click on the "Submit return" button
        Then I should receive the message "Please fill in at least one property"
        And  I should receive the message "Please fill in the 'About the transaction' section"
        And  I should not receive the message "Please fill in at least one buyer"
        And  I should receive the message "Please fill in at least one seller"

        # Add an other organisation (partnership) buyer with contact address
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page
        When I check the "An other organisation" radio button
        And I click on the "Continue" button
        Then I should see the "Organisation details" page

        When I check the "Partnership" radio button
        And I click on the "Continue" button
        Then I should see the "Partnership" page
        And I should see the sub-title "Partnership details"

        When I click on the "Continue" button
        Then I should receive the message "What country's law is the organisation governed by can't be blank"
        And I should receive the message "Name can't be blank"
        And I should receive the message "Use the postcode search or enter the address manually"

        When I enter "Partnership name" in the "Name" field
        And I enter "ALBANIA" in the "What country's law is the organisation governed by" select or text field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Partnership" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Partnership" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click on the "Continue" button
        Then I should see the "Contact details" page

        When I enter "member" in the "Last name" field
        And I enter "club" in the "First name" field
        And I enter "Developer" in the "Job title or position" field
        And I enter "0123456789" in the "Contact phone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Contact details" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Contact details" page

        When I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I click on the "Continue" button
        Then I should see the text "If they are linked can't be blank"
        When I check the "Yes" radio button
        And I enter "Test relation" in the "How are they connected?" field
        And I click on the "Continue" button

        Then I should see the "Buyer details" page
        When I click on the "Continue" button
        Then I should see the text "If they are acting as a trustee or representative partner for tax purposes can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Return Summary" page
        And I should see the text "Partnership name"
        And I should see the text "Partnership"

        # Add a registered company buyer with contact address
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page
        When I check the "An organisation registered with Companies House" radio button
        And I click on the "Continue" button

        Then I should see the "Registered company" page
        When I enter "00233462" in the "Company number" field
        And I click on the "Find company" button

        Then I should see the text "JOHN LEWIS PLC" in field "company_company_name"
        And I should see the text "171 Victoria Street" in field "company_address_line1"
        And I should see the empty field "company_address_line2"
        And I should see the text "London" in field "company_locality"
        And I should see the empty field "company_county"
        And I should see the text "SW1E 5NN" in field "company_postcode"
        And field "Company name" should be readonly
        And field "Address line 1 of 2" should be readonly
        And field "Address line 2 of 2" should be readonly
        And field "Town" should be readonly
        And field "County" should be readonly
        And field "Postcode" should be readonly
        When I click on the "Continue" button

        # Test the contact details as this is a new page
        Then I should see the "Contact details" page
        When I click on the "Continue" button
        Then I should receive the message "Job title or position can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Last name can't be blank"
        And I should receive the message "Contact phone number can't be blank"
        And I should receive the message "Job title or position can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Use the postcode search or enter the address manually"

        When I enter "012" in the "Contact phone number" field
        And I enter "noreplynecsws.com" in the "Email" field
        And I click on the "Continue" button
        Then I should receive the message "Contact phone number is invalid"
        And I should receive the message "Email is invalid"

        When I enter "Smith" in the "Last name" field
        And I enter "John" in the "First name" field
        And I enter "Developer" in the "Job title or position" field
        And I enter "0123456789" in the "Contact phone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "RG30 6XT" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Contact details" page

        When I select "9 Rydal Avenue, Tilehurst, READING, RG30 6XT" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Contact details" page
        And I should see the text "9 Rydal Avenue" in field "address_address_line1"
        And I should see the text "Tilehurst" in field "address_address_line2"
        And I should see the empty field "address_address_line3"
        And I should see the text "READING" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "RG30 6XT" in field "address_postcode"
        And I click on the "Continue" button
        Then I should see the "Buyer details" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "JOHN LEWIS PLC"
        And I should see the text "171 Victoria Street, London, SW1E 5NN"

        # Add an other organisation (charity) buyer checking previous address list functionality, use a previous address
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page

        When I check the "An other organisation" radio button
        And I click on the "Continue" button
        Then I should see the "Organisation details" page
        And I should see the text "Type of organisation"

        When I check the "Charity" radio button
        And I click on the "Continue" button
        Then I should see the "Charity" page

        When I enter "PrvAdrCheck" in the "Name" field
        And  I should see the button with text "Select Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA"
        And  I should see the button with text "Select 9 Rydal Avenue, Tilehurst, READING, RG30 6XT"

        When I click on the "Select Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" button
        Then I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Or edit the selected address" button
        And I enter "Edited Royal Mail" in the "address_address_line1" field
        And I enter "121212" in the "Charity number" field
        And I enter "ALBANIA" in the "What country's law is the organisation governed by" select or text field
        And I click on the "Continue" button
        Then I should see the "Contact details" page

        When I enter "PrvAdrCheck" in the "Last name" field
        And I enter "James" in the "First name" field
        And I enter "0123456780" in the "Contact phone number" field
        And I enter "noreply2@necsws.com" in the "Email" field
        And I enter "Developer" in the "Job title or position" field
        # Check correct distinct previous addresses are displayed on contact address
        And  I should see the button with text "Select Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA"
        And  I should see the button with text "Select 9 Rydal Avenue, Tilehurst, READING, RG30 6XT"

        # and correct previous address is populated into address fields after selecting one of address
        When I click on the "Select Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" button
        Then I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Or edit the selected address" button
        And I enter "Edited Royal Mail" in the "address_address_line1" field
        And I click on the "Continue" button

        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "PrvAdrCheck"
        And I should see the text "Edited Royal Mail, LUTON, LU1 1AA"

        # Add a private seller
        When I click on the "Add a seller" link
        Then I should see the "About the seller" page

        When I check the "A private individual" radio button
        And I click on the "Continue" button

        Then I should see the "Seller details" page
        And I click on the "Continue" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I click on the "Continue" button
        Then I should see the "Seller address" page

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Seller address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Seller address" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        Then I should see the text "Mr firstname surname"
        Then I should see the text "Royal Mail, LUTON, LU1 1AA"
        Then I should see the text "A private individual"
        Then I should see the text "Edit"

        # Add a property (checking scottish property validation) with no ADS (not defaulted as no transaction)
        When I click on the "Add a property" link
        Then I should see the "Property address" page

        # validation to select address
        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"

        When I click on the "Or type in your full address" button
        And I enter "8 Lavender Lane" in the "address_address_line1" field
        And I enter "CIRENCESTER" in the "address_town" field
        And I enter "GL7 1PP" in the "address_postcode" field

        When I click on the "Continue" button
        Then I should receive the message "Property must be in Scotland for LBTT"
        Then I enter "EH1 1BE" in the "address_postcode" field

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        And I enter "12345678901234567890123456789012345678901" in the "returns_lbtt_property_title_number" field
        And I enter "12345678901234567890123456789012345678901" in the "returns_lbtt_property_parent_title_number" field
        And I click on the "Continue" button
        Then I should receive the message "Local authority can't be blank"
        And I should receive the message "Title number is too long (maximum is 40 characters)"
        And I should receive the message "Parent title number is too long (maximum is 40 characters)"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I select "ANG" from the "returns_lbtt_property_parent_title_code"
        And I enter "4567" in the "returns_lbtt_property_parent_title_number" field
        And I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"

        # Click on back link to check if the page data is retained
        When I click on the "Back" link
        Then I should see the "About the property" page
        When I click on the "Back" link
        Then I should see the "Property address" page
        And I should see the text "8 Lavender Lane" in field "address_address_line1"
        And I should see the text "CIRENCESTER" in field "address_town"
        And I should see the text "EH1 1BE" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see "Aberdeen City" in the "returns_lbtt_property_lau_code" select or text field
        And I should see "ABN" in the "returns_lbtt_property_title_code" select or text field
        And I should see the text "1234" in field "returns_lbtt_property_title_number"
        And I should see "ANG" in the "returns_lbtt_property_parent_title_code" select or text field
        And I should see the text "4567" in field "returns_lbtt_property_parent_title_number"
        And I click on the "Continue" button

        # Validation for ADS applies
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        When I click on the "Continue" button
        Then I should receive the message "Does Additional Dwelling Supplement (ADS) apply to this transaction can't be blank"
        When I check the "No" radio button in answer to the question "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        And I click on the "Continue" button
        # Verify entered details on return summary page
        Then I should see the "Return Summary" page
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                               | ADS? |
            | 8 Lavender Lane, CIRENCESTER, EH1 1BE | No   |
        And I should not see the text "About the Additional Dwelling Supplement"

        # Attempt to submit the return to check no ADS error
        When I click on the "Submit return" button
        Then I should see the "Return Summary" page
        And I should not receive the message "ADS must apply to all properties on this return where at least one of the buyers is not a private individual and the transaction is residential"
        And I should receive the message "Please fill in the 'About the transaction' section"

        # Amend the property (and add ADS)
        When I click on the 7 th "Edit" link
        Then I should see the "Property address" page
        When I click on the "Return to postcode lookup" button
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        When I click on the "Continue" button
        Then I should receive the message "Property must be in Scotland for LBTT"

        When I click on the "Return to postcode lookup" button
        And I enter "EH1 1HU" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "31b/2 Chambers Street, EDINBURGH, EH1 1HU" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        And I should see the text "31b/2 Chambers Street" in field "address_address_line1"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1HU" in field "address_postcode"
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        And "Local authority" should contain the option "Aberdeen City"
        And I should see the text "1234" in field "returns_lbtt_property[title_number]"

        When I select "Orkney" from the "Local authority"
        And I enter "4567" in the "returns_lbtt_property[title_number]" field

        And I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        When I check the "Yes" radio button in answer to the question "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        And I click on the "Continue" button

        # Verify modified details on return summary page
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | Address                                   | ADS? |
            | 31b/2 Chambers Street, EDINBURGH, EH1 1HU | Yes  |
        And I should see the text "About the Additional Dwelling Supplement"

        # Add ADS details
        When I click on the "Add ADS" link
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Is the buyer replacing their main residence?"
        When I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should receive the message "Is the buyer replacing their main residence can't be blank"

        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Total consideration liable to ADS"
        And I should see the text "The amount on which ADS is due - this will usually be the chargeable consideration of your new main residence but may change depending on your specific set of circumstances. See guidance on determining the chargeable consideration for the ADS (opens in a new window)"
        And I should see a link with text "determining the chargeable consideration for the ADS (opens in a new window)"
        And I should see the text "Total consideration attributable to new main residence"

        When I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should receive the message "Total consideration liable to ADS can't be blank"
        And I should receive the message "Total consideration attributable to new main residence can't be blank"

        # numeric validation
        When I enter "invalid" in the "Total consideration attributable to new main residence" field
        And I enter "invalid" in the "Total consideration liable to ADS" field
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should receive the message "Total consideration liable to ADS is not a number"
        And I should receive the message "Total consideration attributable to new main residence is not a number"

        # validation on negative and range check
        When I enter "-1" in the "Total consideration attributable to new main residence" field
        And I enter "1000000000000000000" in the "Total consideration liable to ADS" field
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Total consideration liable to ADS must be less than 1000000000000000000"
        And I should see the text "Total consideration attributable to new main residence must be greater than or equal to 0"

        When I enter "123.4567" in the "Total consideration attributable to new main residence" field
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Total consideration attributable to new main residence must be a number to 2 decimal places"

        When I enter "40503" in the "Total consideration attributable to new main residence" field
        And I enter " 40750" in the "Total consideration liable to ADS" field
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Does the buyer intend to sell their main residence within 18 months?"

        When I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        Then I should receive the message "Does the buyer intend to sell their main residence within 18 months can't be blank"

        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should receive the message "Use the postcode search or enter the address manually"

        When I enter "EH1 1HU" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        When I select "31b/2 Chambers Street, EDINBURGH, EH1 1HU" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "31b/2 Chambers Street" in field "address_address_line1"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1HU" in field "address_postcode"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | Address of existing main residence                                   | 31b/2 Chambers Street, EDINBURGH, EH1 1HU |
            | Does the buyer intend to sell their main residence within 18 months? | Yes                                       |
            | Total consideration attributable to new main residence               | £40,503.00                                |
            | Total consideration liable to ADS                                    | £40,750.00                                |

        #  Amend the property to remove ADS to validate MDR without ADS
        When I click on the 7 th "Edit" link
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        When I check the "No" radio button in answer to the question "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        And I click on the "Continue" button

        # Verify modified details on return summary page
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | Address                                   | ADS? |
            | 31b/2 Chambers Street, EDINBURGH, EH1 1HU | No   |
        And I should not see the text "About the Additional Dwelling Supplement"

        # Add transaction details as residential with minimal data
        When I click on the "Add transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page

        When I enter "02-08-2022" in the "Effective date of transaction" date field
        And I enter "03-08-2022" in the "Relevant date" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I check the "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About future events" page

        When I check the "returns_lbtt_lbtt_return_contingents_event_ind_n" radio button
        And I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I should not see the text "Linked transaction consideration"

        When I enter "1234565" in the "Total consideration" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add a new property to check ADS defaulted
        When I click on the "Add a property" link
        Then I should see the "Property address" page
        When I click on the "Or type in your full address" button
        And I enter "8 Lavender Lane" in the "address_address_line1" field
        And I enter "CIRENCESTER" in the "address_town" field
        And I enter "EH1 1BE" in the "address_postcode" field
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"

        When I select "Aberdeen City" from the "Local authority"
        And I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        # ADS should default
        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                               | ADS? |
            | 8 Lavender Lane, CIRENCESTER, EH1 1BE | Yes  |
        And I should see the text "About the Additional Dwelling Supplement"

        # Amend the property to remove ADS
        When I click on the 8 th "Edit" link
        Then I should see the "Property address" page
        # Check we have the correct property
        And I should see the text "8 Lavender Lane" in field "address_address_line1"
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        And I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        When I check the "No" radio button in answer to the question "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                               | ADS? |
            | 8 Lavender Lane, CIRENCESTER, EH1 1BE | No   |
        And I should not see the text "About the Additional Dwelling Supplement"

        # Attempt to submit the return to check ADS error
        When I click on the "Submit return" button
        Then I should see the "Return Summary" page
        And I should receive the message "ADS must apply to all properties on this return where at least one of the buyers is not a private individual and the transaction is residential"

        # Remove the property
        When I click on the 7 th "Delete row" link
        And if available, click the confirmation dialog
        And I wait for 2 seconds
        Then I should see the "Return Summary" page
        And I should not see the text "8 Lavender Lane, CIRENCESTER, EH1 1BE"

        # Amend the transaction details to be non residential
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Non-residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page

        When I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I click on the "Continue" button
        Then I should see the "About future events" page

        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page

        When I click on the "Continue" button
        Then I should receive the message "VAT amount can't be blank"
        And I should receive the message "Total consideration remaining can't be blank"

        When I enter "1000" in the "VAT amount" field
        And I enter "1235565" in the "Total consideration remaining" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Amend the transaction details to be residential and validate MDR
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page
        And I should see the text "02/08/2022" in field "Effective date of transaction"
        And I should see the text "03/08/2022" in field "Relevant date"

        When I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I click on the "Continue" button
        Then I should see the "About future events" page

        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I should see the text "1234565" in field "Total consideration"
        And I should not see the text "VAT Amount"
        And I should not see the text "Total consideration remaining"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add reliefs and validate MDR without ADS
        When I click on the "Add reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I select "Multiple dwellings relief" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded"
        And I enter "100" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount" field

        # Validate that I cannot add the same relief type again
        And I click on the "Add row" button
        And I select "Multiple dwellings relief" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_type_expanded"
        And I enter "100" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount" field
        And I click on the "Continue" button
        And I should receive the message "Type of relief has already been used on this return"
        And I should see at least one button with text "Delete row"

        When I click on the 2 nd "Delete row" button
        Then I should see the "Reliefs on this transaction" page

        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page

        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        And I should receive the message "Number of dwellings can't be blank"
        And I should receive the message "Total consideration attributable to dwellings can't be blank"

        When I enter "-1245" in the "Number of dwellings" field
        And I enter "0" in the "Number of dwellings that attract ADS" field
        And I enter "-1294657" in the "Total consideration attributable to dwellings" field
        And I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        And I should see the text "Number of dwellings must be greater than 0"
        And I should see the text "Number of dwellings that attract ADS must be greater than 0"
        And I should see the text "Total consideration attributable to dwellings must be greater than 0"

        When I enter "0.12" in the "Number of dwellings" field
        And I enter "112331340.23" in the "Number of dwellings that attract ADS" field
        And I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        And I should see the text "Number of dwellings must be a whole number"
        Then I should see the text "Number of dwellings that attract ADS must be a whole number"

        When I enter "1000000000000000000" in the "Number of dwellings" field
        And I enter "1000000000000000000" in the "Number of dwellings that attract ADS" field
        And I enter "1000000000000000000" in the "Total consideration attributable to dwellings" field
        And I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        And I should see the text "Number of dwellings must be less than 1000000000000000000"
        And I should see the text "Number of dwellings that attract ADS must be less than 1000000000000000000"
        And I should see the text "Total consideration attributable to dwellings must be less than 1000000000000000000"

        When I enter "123.4567" in the "Total consideration attributable to dwellings" field
        And I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        And I should see the text "Total consideration attributable to dwellings must be a number to 2 decimal places"
        When I enter "1580" in the "Number of dwellings" field
        And I enter "0.22" in the "Total consideration attributable to dwellings" field
        # Clearing the Number of dwellings that attract ADS to validate this field later with ADS presence.
        And I clear the "Number of dwellings that attract ADS" field

        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "100" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        #  Amend the property to add ADS back to validate MDR with ADS
        When I click on the 7 th "Edit" link
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        When I check the "Yes" radio button in answer to the question "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        And I click on the "Continue" button

        # Verify modified details on return summary page
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | Address                                   | ADS? |
            | 31b/2 Chambers Street, EDINBURGH, EH1 1HU | Yes  |

        # Attempt to submit and check ADS vs MDR relief validation
        When I click on the "Submit return" button
        Then I should receive the message "There's an error somewhere in the about the reliefs - please review the about the reliefs section of the return and update it"

        # Add ADS reliefs to the return
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "100" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount"
        And I should see the text "n/a" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount_ads"
        And I click on the "Add row" button
        # Validate for standard relief types
        And I select "Group relief (Partial Relief)" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_type_expanded"
        And I enter "ABC" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount" field
        And I enter "-100" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount_ads" field
        When I click on the "Continue" button
        And  I should receive the message "Amount of LBTT tax saved by relief is not a number"
        And  I should receive the message "Amount of ADS tax saved by relief must be greater than or equal to 0"
        # Replace the standard releif with the ads relief
        And I select "ADS - Family units" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_type_expanded"
        # Check to add and delete relief buttons
        And I click on the "Add row" button
        And I should see at least one button with text "Delete row"
        When I click on the 3 rd "Delete row" button
        And I should see the text "n/a" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount"
        And I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount_ads"
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount" should be readonly
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount_ads" should be readonly

        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page

        # Amend the reliefs details to correct MDR
        When I click on the "Continue" button
        Then I should receive the message "Number of dwellings that attract ADS can't be blank"


        When I enter "20" in the "Number of dwellings that attract ADS" field
        And I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "100" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "n/a" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount_ads"
        And I should see the text "n/a" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount"
        And I should see the text "1630" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount_ads"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Relief amount table
        And the table of data is displayed
            | About the reliefs         |                                    | Edit reliefs                      |
            | Type of relief            | Amount of LBTT tax saved by relief | Amount of ADS tax saved by relief |
            | Multiple dwellings relief | £100.00                            | £0.00                             |
            | ADS - Family units        | £0.00                              | £1,630.00                         |
        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,497.00      |
            | ADS calculated             | £1,630.00        |
            | Total liability            | £108,127.00      |
            | Total LBTT reliefs claimed | £100.00          |
            | Total ADS reliefs claimed  | £1,630.00        |
            | Total tax payable          | £106,397.00      |

        #Amend the reliefs
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "100" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount"
        And I should see the text "n/a" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount_ads"
        And I should see the text "n/a" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount"
        And I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount_ads"

        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        And I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page

        And I should see the text "100" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "1630" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount_ads"

        #Validation on Max Amount reliefs
        When I enter "1631" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount_ads" field
        And I click on the "Continue" button

        Then  I should receive the message "The amount you are claiming for ADS reliefs cannot be more than the ADS liability of £1630.00"
        And I enter "1000" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount_ads" field
        And I click on the "Continue" button

        And the table of data is displayed
            | About the reliefs         |                                    | Edit reliefs                      |
            | Type of relief            | Amount of LBTT tax saved by relief | Amount of ADS tax saved by relief |
            | Multiple dwellings relief | £100.00                            | £0.00                             |
            | ADS - Family units        | £0.00                              | £1,000.00                         |

        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,497.00      |
            | ADS calculated             | £1,630.00        |
            | Total liability            | £108,127.00      |
            | Total LBTT reliefs claimed | £100.00          |
            | Total ADS reliefs claimed  | £1,000.00        |
            | Total tax payable          | £107,027.00      |

        # reset the value on ads wizard changes
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "n/a" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount"
        And I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount_ads"

        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        And I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "1630" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount_ads"
        And I click on the "Continue" button
        # Relief amount table
        And the table of data is displayed
            | About the reliefs         |                                    | Edit reliefs                      |
            | Type of relief            | Amount of LBTT tax saved by relief | Amount of ADS tax saved by relief |
            | Multiple dwellings relief | £100.00                            | £0.00                             |
            | ADS - Family units        | £0.00                              | £1,630.00                         |

        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,497.00      |
            | ADS calculated             | £1,630.00        |
            | Total liability            | £108,127.00      |
            | Total LBTT reliefs claimed | £100.00          |
            | Total ADS reliefs claimed  | £1,630.00        |
            | Total tax payable          | £106,397.00      |

        # Check the full model validation passes before we touch the Calculate section
        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page
        When I click on the "Back" link
        Then I should see the "Return Summary" page

        # Check that the calculation is recaluated when changing the ads amount
        When I click on the "Edit ADS" link
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I click on the "Continue" button
        Then I should see the text "Total consideration liable to ADS"

        When I enter "50503" in the "Total consideration attributable to new main residence" field
        And I enter " 50750" in the "Total consideration liable to ADS" field
        And I click on the "Continue" button
        Then I should see the text "Does the buyer intend to sell their main residence within 18 months?"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,497.00      |
            | ADS calculated             | £2,030.00        |
            | Total liability            | £108,527.00      |
            | Total LBTT reliefs claimed | £100.00          |
            | Total ADS reliefs claimed  | £2,030.00        |
            | Total tax payable          | £106,397.00      |

        # reset the ads amount back to the original values
        When I click on the "Edit ADS" link
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I click on the "Continue" button
        Then I should see the text "Total consideration liable to ADS"

        When I enter "40503" in the "Total consideration attributable to new main residence" field
        And I enter " 40750" in the "Total consideration liable to ADS" field
        And I click on the "Continue" button
        Then I should see the text "Does the buyer intend to sell their main residence within 18 months?"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,497.00      |
            | ADS calculated             | £1,630.00        |
            | Total liability            | £108,127.00      |
            | Total LBTT reliefs claimed | £100.00          |
            | Total ADS reliefs claimed  | £1,630.00        |
            | Total tax payable          | £106,397.00      |

        # Calculate
        When I click on the "Edit calculation" link
        Then I should see the "Calculated tax" page
        And I should see the text "106497" in field "LBTT calculated"
        And I should see the text "1630" in field "ADS calculated"

        And I should see the text "100" in field "Total LBTT reliefs claimed"
        And I should see the text "1630" in field "Total ADS reliefs claimed"

        When I enter "107000" in the "LBTT calculated" field
        And I enter "1700" in the "ADS calculated" field
        And I click on the "Continue" button

        Then I should see the "Reliefs on this transaction" page
        And I should see the text "100" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "1630" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount_ads"
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount_ads" should be readonly
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount" should be readonly

        When I enter "1701" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount_ads" field
        And I click on the "Continue" button
        Then  I should receive the message "The amount you are claiming for ADS reliefs cannot be more than the ADS liability of £1700.00"

        When I enter "1700" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount_ads" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £107,000.00      |
            | ADS calculated             | £1,700.00        |
            | Total liability            | £108,700.00      |
            | Total LBTT reliefs claimed | £100.00          |
            | Total ADS reliefs claimed  | £1,700.00        |
            | Total tax payable          | £106,900.00      |

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "You can complete or cancel it later using the reference below."
        And I should see the text "Your return has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        And I should store the generated value with id "notification_banner_reference"
        And I should see a link with text "Go to dashboard"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see a link with text "Continue"

        # Buyer
        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        And I should see the text "Marks & Spencer Fund"
        And I should see the text "Charity"
        And I should see the text "Partnership name"
        And I should see the text "Partnership"
        And I should see the text "JOHN LEWIS PLC"
        And I should see the text "An organisation registered with Companies House"
        And I should see the text "PrvAdrCheck"
        And I should see the text "Charity"

        # Seller
        And I should see the text "Mr firstname surname"
        And I should see the text "Royal Mail, LUTON, LU1 1AA"
        And I should see the text "A private individual"
        And I should see the text "Edit"
        # Property and check can still get to ADS page
        And the table of data is displayed
            | Address                                   | ADS? |
            | 31b/2 Chambers Street, EDINBURGH, EH1 1HU | Yes  |


        When I click on the 4 th "Edit row" link
        Then I should see the "About the buyer" page
        And I click on the "Continue" button
        Then I should see the "Organisation details" page
        And I click on the "Continue" button
        Then I should see the "Charity" page
        When I click on the "Return to postcode lookup" button
        And  I should see the button with text "Select Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA"
        And  I should see the button with text "Select 9 Rydal Avenue, Tilehurst, READING, RG30 6XT"

        When I click on the "Select Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" button
        Then I should see the "Charity" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Contact details" page
        When I click on the "Continue" button
        Then I should see the "Buyer details" page
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the 7 th "Edit" link
        Then I should see the "Property address" page
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        And "Local authority" should contain the option "Aberdeen City"
        And I should see the text "4567" in field "returns_lbtt_property[title_number]"
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        And the radio button "Yes" should be selected in answer to the question "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        #ADS === YES
        And the table of data is displayed
            | Address of existing main residence                                   | 31b/2 Chambers Street, EDINBURGH, EH1 1HU |
            | Does the buyer intend to sell their main residence within 18 months? | Yes                                       |
            | Total consideration attributable to new main residence               | £40,503                                   |
            | Total consideration liable to ADS                                    | £40,750                                   |
        # Transaction
        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,497.00      |
            | ADS calculated             | £1,630.00        |
            | Total liability            | £108,127.00      |
            | Total LBTT reliefs claimed | £100.00          |
            | Total ADS reliefs claimed  | £1,630.00        |
            | Total tax payable          | £106,397.00      |

        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page
        And I should not see the text "Direct Debit"
        And I should see the text "I, the buyer, declare that this return is, to the best of my knowledge, correct and complete"
        And I should not see the text "I, the agent for the buyer(s), confirm that I have authority to deal with all matters relating to this transaction on behalf of my client(s)"
        When I click on the "Submit return" button
        Then I should see the text "How are you paying can't be blank"
        And I should see the text "The declaration must be accepted"

        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should see the text "Your Land and Buildings Transaction Tax return has now been submitted."

        When I click on the "Send secure message" link
        Then I should see the "New message" page
        And I should see the text "notification_banner_reference" in field "dashboard_message_reference"

        # test case to download Receipt on last return submit return
        When I click on the "Back" link
        Then I should see the "Your return has been submitted" page

        When I click on the "Receipt" link to download a file
        Then I should see the downloaded "PDF" content of "LBTT" by looking up "notification_banner_reference"
        And I should see a link with text "Go to dashboard"
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see a link with text "Amend"

        # Amend the return for a repayment
        When I click on the "Amend" link
        Then I should see the "Return Summary" page
        When I click on the "Submit return" button
        Then I should see the "Amendment reason" page

        When I click on the "Continue" button
        Then I should receive the message "Tell us why you are amending this return can't be blank"

        When I enter "RANDOM_text,4001" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button
        Then I should receive the message "Tell us why you are amending this return is too long (maximum is 4000 characters)"

        When I enter "Test" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button

        Then I should see the "Repayment details" page

        When I click on the "Continue" button
        Then I should receive the message "Do you want to request a repayment from Revenue Scotland can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Claim repayment" page

        # it should be blank to start with
        And I click on the "Continue" button
        Then I should receive the message "How much are you claiming for repayment can't be blank"
        When I enter "750.000000" in the "How much are you claiming for repayment?" field
        And I click on the "Continue" button
        Then I should receive the message "How much are you claiming for repayment must be a number to 2 decimal places"
        When I enter "1000000000000000000" in the "How much are you claiming for repayment?" field
        And I click on the "Continue" button
        Then I should receive the message "How much are you claiming for repayment must be less than 1000000000000000000"
        When I enter "750" in the "How much are you claiming for repayment?" field
        And I click on the "Continue" button
        Then I should see the "Enter bank details" page

        # details should be blank to start with
        When I click on the "Continue" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "RANDOM_text,256" in the "Name of the account holder" field
        And I enter "RANDOM_text,11" in the "Bank / building society account number" field
        And I enter "RANDOM_text,9" in the "Branch sort code" field
        And I enter "RANDOM_text,256" in the "Name of bank / building society" field
        And I click on the "Continue" button

        Then I should receive the message "Bank / building society account number must be 8 digits long"
        And I should receive the message "Branch sort code must be in the format 99-99-99"

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "00345678" in the "Bank / building society account number" field
        And I enter "01-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Continue" button

        Then I should see the "Declaration" page
        Then I should not see the text "I, the agent for the buyer(s), confirm that the buyer(s) have authorised repayment to be made to these bank details"
        And I should see the text "I, the buyer, declare that this claim is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the refund claimed"
        When I click on the "Continue" button
        Then I should receive the message "The refund declaration must be accepted"
        And I should not receive the message "The bank account declaration must be accepted"
        When I check the "returns_lbtt_lbtt_return_repayment_declaration" checkbox
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page

        # payment and submission
        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox

        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should store the reference from the notification panel as "notification_banner_reference"

        # Load that return for amending
        When I click on the "Sign out" menu item
        Then I should see the "Sign in" page

        When I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        Then I should see the "Dashboard" page
        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "dashboard_dashboard_return_filter_tare_reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I click on the "Amend" link
        Then I should see the "Return Summary" page

        # Sell the main property
        When I click on the "Edit ADS" link
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Are you amending the return because the buyer has sold or disposed of the previous main residence?"

        # Check that no navigates to the original pages
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Is the buyer replacing their main residence?"

        When I click on the "Back" link
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Are you amending the return because the buyer has sold or disposed of the previous main residence?"

        When I check the "Yes" radio button
        And I click on the "Continue" button
        And I click on the "Continue" button
        Then I should receive the message "What is the date of sale or disposal of the previous main residence can't be blank"

        When I enter "03-07-2022" in the "What is the date of sale or disposal of the previous main residence?" date field
        And I click on the "Continue" button
        Then I should see the text "Confirm the address of the previous main residence that has been sold or disposed of"
        When I enter "EH1 1HU" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        When I select "31b/2 Chambers Street, EDINBURGH, EH1 1HU" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "31b/2 Chambers Street" in field "address_address_line1"
        When I click on the "Continue" button
        Then I should see the text "When you submit the return you will be asked for the bank details for the repayment."
        When I enter "4321" in the "Amount of ADS you want to reclaim" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Save the draft and reload it with the ads details on
        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        And I should store the generated value with id "notification_banner_reference"
        And I should see a link with text "Go to dashboard"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        When I click on the "Continue" link
        Then I should see the "Return Summary" page

        # Check the data is still present
        When I click on the "Edit ADS" link
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And the radio button "returns_lbtt_ads_ads_sold_main_yes_no_y" should be selected
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "31b/2 Chambers Street" in field "address_address_line1"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1HU" in field "address_postcode"
        And I click on the "Continue" button
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "4321" in field "Amount of ADS you want to reclaim"
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # request repayment and check amount is preset
        When I click on the "Submit return" button
        Then I should see the "Amendment reason" page

        When I enter "Test" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button

        Then I should see the "Repayment details" page
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Claim repayment" page
        And I should see the text "4321" in field "How much are you claiming for repayment?"

        # validation checks
        When I clear the "How much are you claiming for repayment?" field
        And I click on the "Continue" button
        Then I should receive the message "How much are you claiming for repayment can't be blank"
        When I enter "abc" in the "How much are you claiming for repayment?" field
        And I click on the "Continue" button
        Then I should receive the message "How much are you claiming for repayment is not a number"
        When I enter "-1" in the "How much are you claiming for repayment?" field
        And I click on the "Continue" button
        Then I should receive the message "How much are you claiming for repayment must be greater than or equal to 0"

        When I enter "4321" in the "How much are you claiming for repayment?" field
        And I click on the "Continue" button
        Then I should see the "Enter bank details" page

        # details should be blank to start with
        When I click on the "Continue" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "RANDOM_text,256" in the "Name of the account holder" field
        And I enter "RANDOM_text,11" in the "Bank / building society account number" field
        And I enter "RANDOM_text,9" in the "Branch sort code" field
        And I enter "RANDOM_text,256" in the "Name of bank / building society" field
        And I click on the "Continue" button

        Then I should receive the message "Bank / building society account number must be 8 digits long"
        And I should receive the message "Branch sort code must be in the format 99-99-99"

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Continue" button
        Then I should see the "Declaration" page

        # Declarations and re-submit
        When I click on the "Continue" button
        Then I should receive the message "The refund declaration must be accepted"

        When I check the "returns_lbtt_lbtt_return_repayment_declaration" checkbox
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page

        # Submit amendment
        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return[declaration]" checkbox
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        # Make sure the return reference is the same
        And I should see the text "notification_banner_reference"
        And I should see the text "Return reference"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        And I should see the text "If you have any queries about this amendment"
        And the table of data is displayed

            | Title number (if provided) | ABN 4567                                  |
            | Property address           | 31b/2 Chambers Street, EDINBURGH, EH1 1HU |
            | Buyer                      | JOHN LEWIS PLC                            |
            | Description of transaction | Conveyance or transfer                    |
            | Effective date             | 02/08/2022                                |

    Scenario: Make a Conveyance return without ADS for an Agent, check that DD is only available when previous return was DD

        Create a conveyance return
        Save the draft
        Download the PDF from the dashboard
        Retrieve the draft
        Add a private buyer
        Add a registered company seller
        Add a residential property (with ADS)
        Add ADS details to the return
        Add transaction details including linked transactions (checking table functionality)
        Add a autocalc relief change to first time buyer
        Override the relief value
        Save as draft
        Retrieve  the return check relief has the correct amount
        Delete the relief
        Add a Partial relief to test the override
        Check that the override values are now used in the flow for Partial relief
        Remove the partial relief
        Add ADS relief to the return
        Update the property to remove ADS
        Submit the return to validate reliefs error is shown
        Check that ads reliefs and column is not shown
        Edit the reliefs
        Check you can remove all of the reliefs (including former ads releif row) and go back or forward
        Check validations on MD relief related fields
        Check the calculation of the first time buyer relief before and after the 15th July 2021
        Check the date warning(s) and link
        Submit the return (DD)
        Check you can't submit again

        Amend the return
        Check the date warning(s) are not shown
        Check DD is shown as payment method and change to BACS
        Save draft
        Retrieve the draft
        Check DD is shown as payment method and change to BACS
        Submit

        Amend the return
        Check DD is not shown as payment method

        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page
        When I check the "Conveyance or transfer" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "You can complete or cancel it later using the reference below."
        And I should see the text "Your return has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"

        Then I should store the generated value with id "notification_banner_reference"
        And I should see a link with text "Go to dashboard"
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page

        When I click on the 1 st "Download PDF" link to download a file
        Then I should see the downloaded "PDF" content of "LBTT" by looking up "notification_banner_reference"

        And I should see a link with text "Continue"

        And I click on the "Continue" link
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the transaction | Add transaction details |

        # Add a private buyer
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page

        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page

        When I enter "Smith" in the "Last name" field
        And I enter "James" in the "First name" field
        And I enter "0123456780" in the "Telephone number" field
        And I enter "noreply2@necsws.com" in the "Email" field
        And I enter "NP103456D" in the "National Insurance Number (NINO)" field
        And I click on the "Continue" button
        Then I should see the "Buyer address" page

        When I enter "RG30 6XT" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Buyer address" page
        When I select "9 Rydal Avenue, Tilehurst, READING, RG30 6XT" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Buyer address" page
        And I should see the text "9 Rydal Avenue" in field "address_address_line1"
        And I should see the text "Tilehurst" in field "address_address_line2"
        And I should see the empty field "address_address_line3"
        And I should see the text "READING" in field "address_town"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "RG30 6XT" in field "address_postcode"
        When I click on the "Continue" button
        Then I should see the "Buyer's contact address" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "James Smith"
        And I should see the text "9 Rydal Avenue, READING, RG30 6XT"

        #Registered company as a seller
        When I click on the "Add a seller" link
        Then I should see the "About the seller" page
        When I check the "An organisation registered with Companies House" radio button
        And I click on the "Continue" button

        Then I should see the "Registered company" page
        And I click on the "Find company" button
        Then I should receive the message "Company number can't be blank"
        And I enter "0123" in the "Company number" field
        And I click on the "Find company" button
        Then I should receive the message "Company number is too short (minimum is 8 characters)"
        And I enter "0123456789" in the "Company number" field
        And I click on the "Find company" button
        Then I should receive the message "Company number is too long (maximum is 8 characters)"
        And I enter "00000001" in the "Company number" field
        And I click on the "Find company" button
        Then I should receive the message "The company number doesn't return a company"
        And I clear the "Company number" field
        When I click on the "Continue" button

        Then I should receive the message "Company number can't be blank"
        And I should receive the message "A company must be chosen"
        When I enter "09338960" in the "Company number" field
        And I click on the "Find company" button

        Then I should see the text "NORTHGATE PUBLIC SERVICES LIMITED" in field "company_company_name"
        And I should see the text "1st Floor, Imex Centre" in field "company_address_line1"
        And I should see the text "575-599 Maxted Road" in field "company_address_line2"
        And I should see the text "Hemel Hempstead" in field "company_locality"
        And I should see the text "Hertfordshire" in field "company_county"
        And I should see the text "HP2 7DX" in field "company_postcode"
        When I click on the "Continue" button

        Then I should see the "Return Summary" page
        And I should see the text "NORTHGATE PUBLIC SERVICES LIMITED"

        # Add Property
        When I click on the "Add a property" link
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"

        When I enter "EH1 1HU" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "31b/2 Chambers Street, EDINBURGH, EH1 1HU" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        And I should see the text "31b/2 Chambers Street" in field "address_address_line1"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1HU" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I select "ANG" from the "returns_lbtt_property_parent_title_code"
        And I enter "4567" in the "returns_lbtt_property_parent_title_number" field

        And I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        And I click on the "Continue" button
        Then I should receive the message "Does Additional Dwelling Supplement (ADS) apply to this transaction can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add ads details
        When I click on the "Add ADS" link
        Then I should see the "Additional Dwelling Supplement (ADS)" page

        When I check the "No" radio button
        And I click on the "Continue" button

        Then I should see the text "Total consideration liable to ADS"
        And I enter "40750" in the "Total consideration liable to ADS" field
        And I click on the "Continue" button

        Then I should see the "Additional Dwelling Supplement (ADS)" page
        When I check the "No" radio button
        And I click on the "Continue" button


        # Transaction
        When I click on the "Add transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page

        When I enter "02-08-2022" in the "Effective date of transaction" date field
        And I enter "03-08-2022" in the "Relevant date" date field
        And I enter "03-08-2022" in the "Date of contract or conclusion of missives" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I check the "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Continue" button
        # Test core list processing for add and delete, including error handling
        Then I should see the "Linked transactions" page

        When I check the "Yes" radio button
        Then I should not see the button with text "Delete row"

        When I click on the "Continue" button
        Then I should see the text "Return consideration can't be blank"

        When I enter "RS1234567ABCD" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_return_reference" field
        And I enter "1000" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount" field
        And I click on the "Add row" button
        Then I should see at least one button with text "Delete row"
        And I should see the text "RS1234567ABCD" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_return_reference"
        And I should see the text "1000" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount"

        # Check you can't delete a row when there is an invalid row and that the message doesn't follow you
        When I click on the 1 st "Delete row" button
        Then I should receive the message "Return consideration can't be blank"
        And I should see the text "RS1234567ABCD" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_return_reference"
        And I should see the text "1000" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount"
        And I should see at least one button with text "Delete row"

        When I click on the "Back" link
        Then I should see the "About the transaction" page
        And I should not receive the message "Return consideration can't be blank"

        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        And I should see the text "RS1234567ABCD" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_return_reference"
        And I should see the text "1000" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount"
        # Check we remove the blank entry
        And I should not see the button with text "Delete row"

        When I click on the "Add row" button
        Then I should see at least one button with text "Delete row"

        # check we can delete the invalid row
        When I click on the 2 nd "Delete row" button
        Then I should not see the button with text "Delete row"
        And I should see the text "RS1234567ABCD" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_return_reference"
        And I should see the text "1000" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount"

        # Check that add also doesn't work when data is invalid and that data isn't saved
        When I enter "RS123456" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_return_reference" field
        And I click on the "Continue" button
        Then I should receive the message "Return reference (if known) format is invalid"

        When I click on the "Add row" button
        Then I should receive the message "Return reference (if known) format is invalid"
        And I should not see the button with text "Delete row"

        When I click on the "Back" link
        Then I should see the "About the transaction" page
        And I should not receive the message "Return consideration can't be blank"

        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        And I should see the text "RS1234567ABCD" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_return_reference"
        And I should see the text "1000" in field "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount"
        And I should not see the button with text "Delete row"

        # Check other validation
        When I clear the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount" field
        And I click on the "Continue" button
        Then I should see the text "Return consideration can't be blank"
        When I enter "-1000" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount" field
        And I click on the "Continue" button
        Then I should see the text "Return consideration must be greater than or equal to 0"
        When I enter "1000" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount" field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I check the "Yes" radio button
        And I check the "Goodwill" checkbox
        And I click on the "Continue" button
        And  I should see the "About future events" page

        When I check the "returns_lbtt_lbtt_return_contingents_event_ind_n" radio button
        And I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I should see the text "1000" in field "Linked transaction consideration"

        When I clear the "Linked transaction consideration" field
        And I click on the "Continue" button
        Then I should receive the message "Total consideration can't be blank"
        And I should receive the message "Linked transaction consideration can't be blank"
        And I should receive the message "Non-chargeable consideration can't be blank"
        And I should receive the message "Total consideration remaining can't be blank"

        When I enter "a" in the "Total consideration" field
        And I enter "b" in the "Linked transaction consideration" field
        And I enter "c" in the "Non-chargeable consideration" field
        And I enter "c" in the "Total consideration remaining" field
        And I click on the "Continue" button
        Then I should receive the message "Total consideration is not a number"
        And I should receive the message "Linked transaction consideration is not a number"
        And I should receive the message "Non-chargeable consideration is not a number"
        And I should receive the message "Total consideration remaining is not a number"

        When I enter "900000" in the "Total consideration" field
        When I enter "1100" in the "Linked transaction consideration" field
        And I enter "125" in the "Non-chargeable consideration" field
        And I enter "900000" in the "Total consideration remaining" field
        # Check the consideration has not been saved following the error
        When I click on the "Back" link
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I should see the empty field "Total consideration"
        And I should see the text "1000" in field "Linked transaction consideration"
        And I should see the empty field "Non-chargeable consideration"
        And I should see the empty field "Total consideration remaining"

        When I enter "1234560" in the "Total consideration" field
        When I enter "1100" in the "Linked transaction consideration" field
        And I enter "125" in the "Non-chargeable consideration" field
        And I enter "1234560" in the "Total consideration remaining" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add a autocalc relief change to first time buyer
        When I click on the "Add reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I select "Charities relief (Full Relief)" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded"

        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "106519" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "1630" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount_ads"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the reliefs              |                                    | Edit reliefs                      |
            | Type of relief                 | Amount of LBTT tax saved by relief | Amount of ADS tax saved by relief |
            | Charities relief (Full Relief) | £106,519                           | £1,630                            |

        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I select "First-Time Buyer Relief" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded"

        # Override the relief value
        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "600" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "n/a" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount_ads"
        And I enter "400" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Save as draft
        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "You can complete or cancel it later using the reference below."
        And I should see the text "Your return has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"

        # Retrieve  the return check relief has the correct amount
        And I should see a link with text "Back to return summary"
        When I click on the "Back to return summary" link
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the reliefs       |                                    | Edit reliefs                      |
            | Type of relief          | Amount of LBTT tax saved by relief | Amount of ADS tax saved by relief |
            | First-Time Buyer Relief | £400.00                            | £0.00                             |

        # Delete the relief
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        When I click on the 1 st "Delete row" button
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add Partial relief to test the override
        When I click on the "Add reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I select "Charities relief (Partial Relief)" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded"
        And I enter "100" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount" field
        And I enter "200" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount_ads" field

        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "100" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "200" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount_ads"
        And I enter "25" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount" field
        And I enter "75" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount_ads" field

        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the reliefs                 |                                    | Edit reliefs                      |
            | Type of relief                    | Amount of LBTT tax saved by relief | Amount of ADS tax saved by relief |
            | Charities relief (Partial Relief) | £25.00                             | £75.00                            |

        # Check that the override values are now used in the flow for Partial reliefs
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        Then "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded" should contain the option "Charities relief (Partial Relief)"
        And I should see the text "25" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount"
        And I should see the text "75" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount_ads"

        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "25" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "75" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount_ads"
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # remove the partial relief
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        When I click on the 1 st "Delete row" button
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add ADS reliefs
        When I click on the "Add reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I select "ADS - Family units" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded"
        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Update the property to remove ADS
        When I click on the 3 rd "Edit row" link
        Then I should see the "Property address" page
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the text "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        When I check the "No" radio button in answer to the question "Does Additional Dwelling Supplement (ADS) apply to this transaction?"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Submit the return and validate error is shown
        When I click on the "Submit return" button
        Then I should receive the message "There's an error somewhere in the about the reliefs - please review the about the reliefs section of the return and update it"

        # Amend reliefs in 'Edit Reliefs' section to remove the former ADS relief row and to validate MDR
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        Then "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded" should contain the option "Multiple dwellings relief"

        # Check that ads reliefs and column is not shown
        And I should not see the text "Amount of ADS tax saved by relief"
        And "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded" should not contain the option "ADS - Family units"

        # Check you can remove all of the reliefs and go back or forward
        # go back
        When I click on the 1 st "Delete row" button
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Back" link
        Then I should see the "Return Summary" page

        # go forward
        When I click on the "Add reliefs" link
        Then I should see the "Reliefs on this transaction" page
        When I click on the 1 st "Delete row" button
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Get back on the reliefs page
        When I click on the "Add reliefs" link
        Then I should see the "Reliefs on this transaction" page

        # NOT FULL or MAX amount relief
        When I select "Multiple dwellings relief" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded"
        And I click on the "Add row" button
        Then I should receive the message "Amount of LBTT tax saved by relief can't be blank"

        When I enter "Calculated" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount" field
        And I click on the "Continue" button
        Then I should receive the message "Amount of LBTT tax saved by relief is not a number"

        When I enter "-3" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount" field
        And I click on the "Continue" button
        Then I should receive the message "Amount of LBTT tax saved by relief must be greater than or equal to 0"

        When I enter "1000000000000000000" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount" field
        And I click on the "Continue" button
        Then I should receive the message "Amount of LBTT tax saved by relief must be less than 1000000000000000000"

        When I enter " 2087 " in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount" field
        And I click on the "Add row" button
        Then I should see the "Reliefs on this transaction" page
        # MAX amount relief
        When I select "First-Time Buyer Relief" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_type_expanded"
        And I click on the "Add row" button
        Then I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount"
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount" should be readonly
        And I should see the "Reliefs on this transaction" page

        # Add a third relief that is full that will take the full amounts
        # Note we delete as the above add row created a new row so still want to test delete
        # but also need to use add row to trigger the calculated again
        When I click on the 3 rd "Delete row" button
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Add row" button
        Then I should see the "Reliefs on this transaction" page
        When I select "Public bodies relief" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_type_expanded"
        And I click on the "Add row" button
        Then I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_amount"

        When I click on the 4 th "Delete row" button
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page

        When I enter "10" in the "Number of dwellings" field
        And  I enter "30.33" in the "Total consideration attributable to dwellings" field
        And  I click on the "Continue" button
        Then I should not receive the message "Number of dwellings that attract ADS can't be blank"
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "0" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "0" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount"
        And I should see the text "106519" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_override_amount"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # New 'About the Reliefs' detail*
        And the table of data is displayed
            | About the reliefs         | Edit reliefs                       |
            | Type of relief            | Amount of LBTT tax saved by relief |
            | Multiple dwellings relief | £0.00                              |
            | First-Time Buyer Relief   | £0.00                              |
            | Public bodies relief      | £106,519.00                        |

        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,519.00      |
            | Total LBTT reliefs claimed | £106,519.00      |
            | Total tax payable          | £0.00            |

        #Validation on relief amounts
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page

        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page

        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        When I enter "700" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount" field
        And I click on the "Continue" button
        Then I should receive the message "Amount of LBTT tax saved by relief should not exceed £600"

        When I enter "Hello" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount" field
        And I click on the "Continue" button
        Then I should receive the message "Amount of LBTT tax saved by relief is not a number"

        When I clear the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount" field
        And I click on the "Continue" button
        Then I should receive the message "Amount of LBTT tax saved by relief can't be blank"

        # Validation on Max Amount reliefs
        When I enter "106498" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount" field
        And I enter "600" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount" field
        And I enter "0" in the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_override_amount" field
        And I click on the "Continue" button
        Then I should receive the message "The amount you are claiming for reliefs cannot be more than the tax liability of £106519.00"

        # check the invalid relief value has not been saved
        When I click on the "Back" link
        Then I should see the "About multiple dwellings relief" page
        When I click on the "Back" link
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Back" link
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the reliefs         | Edit reliefs                       |
            | Type of relief            | Amount of LBTT tax saved by relief |
            | Multiple dwellings relief | £0.00                              |
            | First-Time Buyer Relief   | £0.00                              |
            | Public bodies relief      | £106,519.00                        |

        # Check the overridden linked transaction value is not changed by going through the wizard
        # The relief values are changed
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "0" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount"
        And I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount"
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount" should be readonly
        And I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_amount"
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_amount" should be readonly
        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        And I should see the text "10" in field "Number of dwellings"
        And I should see the text "30.33" in field "Total consideration attributable to dwellings"
        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "0" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "0" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount"
        And I should see the text "106519" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_override_amount"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the reliefs         | Edit reliefs                       |
            | Type of relief            | Amount of LBTT tax saved by relief |
            | Multiple dwellings relief | £0.00                              |
            | First-Time Buyer Relief   | £0.00                              |
            | Public bodies relief      | £106,519.00                        |

        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,519.00      |
            | Total LBTT reliefs claimed | £106,519.00      |
            | Total tax payable          | £0.00            |

        # Check the calculation of the first time buyer relief before and after the 15th July 2021
        When I click on the "Edit reliefs" link
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "0" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_amount"
        And I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount"
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_amount" should be readonly
        And I should see the text "Calculated" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_amount"
        And field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_2_relief_amount" should be readonly
        When I click on the 3 rd "Delete row" button
        Then I should see the "Reliefs on this transaction" page
        When I click on the "Continue" button
        Then I should see the "About multiple dwellings relief" page
        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "0" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"
        And I should see the text "600" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_1_relief_override_amount"
        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the reliefs         | Edit reliefs                       |
            | Type of relief            | Amount of LBTT tax saved by relief |
            | Multiple dwellings relief | £0.00                              |
            | First-Time Buyer Relief   | £600.00                            |

        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,519.00      |
            | Total LBTT reliefs claimed | £600.00          |
            | Total tax payable          | £105,919.00      |
        # check whether changing the date forces recalculation
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I enter "15-07-2021" in the "Effective date of transaction" date field
        And I enter "14-07-2021" in the "Relevant date" date field
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Back" link
        Then I should see the "About the dates" page
        When I click on the "Back" link
        Then I should see the "About the transaction" page
        When I click on the "Back" link
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the reliefs         | Edit reliefs                       |
            | Type of relief            | Amount of LBTT tax saved by relief |
            | Multiple dwellings relief | £0.00                              |
            | First-Time Buyer Relief   | £600.00                            |

        And the table of data is displayed
            | About the calculation      | Edit calculation |
            | LBTT calculated            | £106,519.00      |
            | Total LBTT reliefs claimed | £600.00          |
            | Total tax payable          | £106,519.00      |

        # Check the overridden linked transaction value is changed by changing the linked value
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I enter "2000" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_consideration_amount" field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I should see the text "1234560" in field "Total consideration"
        And I should see the text "2000" in field "Linked transaction consideration"
        And I should see the text "125" in field "Non-chargeable consideration"
        And I should see the text "1234560" in field "Total consideration remaining"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        # Check the date warning(s) and link
        # Start by setting the dates to today and checking that no message is shown
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I enter 0 days ago in the "Effective date of transaction" date field
        And I enter 0 days ago in the "Relevant date" date field
        And I enter 0 days ago in the "Date of contract or conclusion of missives" date field
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should not see the text "This is usually more recent than this."
        And I should not see the text "This has typically already happened"
        And I should not see a link with text "You can edit the transaction details if you need to"
        # Set one date in the past and one date in the future and check two messages are shown
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I enter 30 days ago in the "Effective date of transaction" date field
        And I enter 1 days in the future in the "Relevant date" date field
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "Effective date of transaction is 30 days in the past. This is usually more recent than this."
        And I should see the text "Relevant date is 1 day in the future. This has typically already happened"
        And I should see a link with text "You can edit the transaction details if you need to"
        # Reset both dates within the window and no messages are shown
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I enter 0 days in the future in the "Effective date of transaction" date field
        And I enter 5 days ago in the "Relevant date" date field
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should not see the text "This is usually more recent than this."
        And I should not see the text "This has typically already happened"
        And I should not see a link with text "You can edit the transaction details if you need to"
        # Reset one date to be within the window and the other outside and only one message is shown
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I enter 1 days ago in the "Effective date of transaction" date field
        And I enter 3 days in the future in the "Relevant date" date field
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "Relevant date is 3 days in the future. This has typically already happened."
        And I should not see the text "This is usually more recent than this"
        And I should see a link with text "You can edit the transaction details if you need to"

        # Submit the return
        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page
        And I should see the text "Direct Debit"
        And I should see the text "I, the agent of the buyer(s), having been authorised to complete this return on behalf of the buyer(s):"
        And I should see the text "I, the agent for the buyer(s), confirm that I have authority to deal with all matters relating to this transaction on behalf of my client(s)"
        And I should not see the text "Direct Debit is unavailable on this return as the previous submission did not use Direct Debit"
        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "Direct Debit" radio button
        And I click on the "Submit return" button
        Then I should see the text "The authority declaration can't be blank"
        # Must be checked again as cleared on error
        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should see the text "Return reference"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        And I should store the reference from the notification panel as "notification_banner_reference"
        And I should see the text "If you have any queries about this return"
        And the table of data is displayed
            | Title number (if provided) | ABN 1234                                  |
            | Property address           | 31b/2 Chambers Street, EDINBURGH, EH1 1HU |
            | Buyer                      | James Smith                               |
            | Description of transaction | Conveyance or transfer                    |
            | Effective date             | NOW_DATE                                  |
        # Check you can't submit again
        When I go to the "returns/lbtt/declaration" page
        Then I should see the "Payment and submission" page
        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button
        And I click on the "Submit return" button
        Then I should receive the message "This return has already been submitted. If you are unsure that the return has been submitted, save a draft version and check on the dashboard"

        # Check that DD is available on amend, an save a draft having saved it as BACS (note: that the BACS is not saved in the wizard)
        When I click on the "Cancel" menu item
        And if available, click the confirmation dialog
        Then I should see the "Dashboard" page
        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "dashboard_dashboard_return_filter_tare_reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        When I click on the "Amend" link
        Then I should see the "Return Summary" page
        # Check no warning messages are shown on amend
        And I should not see the text "This is usually more recent than this."
        And I should not see the text "This has typically already happened"
        And I should not see a link with text "You can edit the transaction details if you need to"

        # Edit Buyer to edit existing address by selecting address from previously used address list
        And the table of data is displayed
            | Name        | Type                 | Address                           |      |        |
            | James Smith | A private individual | 9 Rydal Avenue, READING, RG30 6XT | Edit | Delete |

        When I click on the "Submit return" button
        Then I should see the "Amendment reason" page
        When I enter "Test" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button
        Then I should see the "Repayment details" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page
        And the radio button labelled "Direct Debit" should exist
        And the radio button "Direct Debit" should be selected
        And I should not see the text "Direct Debit is unavailable on this return as the previous submission did not use Direct Debit"
        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button
        And I check the "Cheque" radio button
        And I click on the "Back" link
        Then I should see the "Repayment details" page
        When I click on the "Back" link
        Then I should see the "Amendment reason" page
        When I click on the "Back" link
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "You can complete or cancel it later using the reference below."
        And I should see the text "Your return has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        Then I should store the generated value with id "notification_banner_reference"
        And I should see a link with text "Go to dashboard"
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see a link with text "Continue"

        # Submit the returns as BACS checking that DD is still available
        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        When I click on the "Submit return" button
        Then I should see the "Amendment reason" page
        When I enter "Test" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button
        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page
        And the radio button labelled "Direct Debit" should exist
        And the radio button "Direct Debit" should be selected
        And I should not see the text "Direct Debit is unavailable on this return as the previous submission did not use Direct Debit"
        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button
        And I check the "BACS" radio button
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should see the text "Return reference"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        And I should store the reference from the notification panel as "notification_banner_reference"

        # Check that DD is no longer available
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "dashboard_dashboard_return_filter_tare_reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        When I click on the "Amend" link
        Then I should see the "Return Summary" page
        When I click on the "Submit return" button
        Then I should see the "Amendment reason" page
        When I enter "Test" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button
        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page
        And the radio button labelled "Direct Debit" should not exist
        And I should see the text "Direct Debit is unavailable on this return as the previous submission did not use Direct Debit"

    Scenario: Make a lease return for a tax payer (and first check session cache data is deleted when start new return)

        Create a conveyance return
        Add a private individual buyer
        Go the dashboard
        Create a return
        Go to the party details page directly and check we go to the dashboard
        Create a lease return
        Create an other organisation (trust) tenant
        Create an other organisation (company) landlord
        Add a residential property
        Add transaction details including linked transactions, non ads reliefs and rent for individual years (checking it is calculated correctly based on the lease dates)
        Edit the transaction details checking the calculated NPV is not changed
        Edit the transaction details checking the NPV value can be changed
        Edit the transaction details checking the overriden NPV value is not changed
        Change a linked transaction value and check the overriden NPV value is changed
        Check date warnings are given
        Save the draft
        Retrieve the draft
        Check date warnings are still given
        and submit

        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"

        # Verify party details are cleared when starting a new return, first start a return
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page
        When I check the "Conveyance or transfer" radio button
        And I click on the "Continue" button

        # put party details into the wizard cache
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I enter "Victoria" in the "Last name" field
        And I enter "Dilbert" in the "First name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "AB123456C" in the "National Insurance Number (NINO)" field
        And I click on the "Continue" button
        Then I should see the "Buyer address" page

        # Now go back to the dashboard and click the create return button (should clear wizard caches)
        When I click on the "Cancel" menu item
        And if available, click the confirmation dialog
        Then I should see the "Dashboard" page
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        # Go to the party page directly and check we're actually taken back to the dashboard page
        # indicating that the party and lbtt wizard caches have been cleared correctly
        When I go to the "returns/lbtt/party_details" page
        Then I should see the "Dashboard" page

        # Start the lease return for tax payer test
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        When I check the "Lease" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Tenant
        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        And I click on the "Continue" button
        Then I should receive the message "Who they are can't be blank"
        When I check the "An other organisation" radio button
        And I click on the "Continue" button
        Then I should see the "Organisation details" page
        And I click on the "Continue" button
        Then I should receive the message "Type of organisation can't be blank"

        When I check the "Trust" radio button
        And I click on the "Continue" button
        Then I should see the "Trust" page
        And I should see the sub-title "Trust details"

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"

        When I enter "Trust name" in the "Name" field
        And I enter "ALBANIA" in the "What country's law is the organisation governed by" select or text field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Trust" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Trust" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Contact details" page
        When I enter "member" in the "Last name" field
        And I enter "club" in the "First name" field
        And I enter "Developer" in the "Job title or position" field
        And I enter "0123456789" in the "Contact phone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Contact details" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Contact details" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Tenant details" page
        And I should see the text "The tenant and landlord are connected if they have an existing personal or business relationship. See guidance on if they are connected (opens in a new window) for further details"
        And I should see a link with text "they are connected (opens in a new window)"
        When I check the "Yes" radio button
        And I enter "Test relation" in the "How are they connected?" field
        And I click on the "Continue" button

        Then I should see the "Tenant details" page
        And I should see the text "See guidance on the meaning of 'representative partner' (opens in a new window) for further details"
        And I should see a link with text "'representative partner' (opens in a new window)"
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Return Summary" page
        And I should see the text "Trust name"
        And I should see the text "Trust"


        #Landlord
        When I click on the "Add a landlord" link
        Then I should see the "About the landlord" page
        When I check the "An other organisation" radio button
        And I click on the "Continue" button
        Then I should see the "Organisation details" page
        # Company
        When I check the "Company" radio button
        And I click on the "Continue" button

        Then I should see the "Company" page
        And I should see the sub-title "Company details"

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"

        When I enter "Company name" in the "Name" field
        And I enter "ALBANIA" in the "What country's law is the organisation governed by" select or text field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Company" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Company" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "Company name"
        And I should see the text "Company"

        # Add Property
        When I click on the "Add a property" link
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"

        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        And I should see the text "Royal Zoological Society Of Scotland" in field "address_address_line1"
        And I should see the text "134 Corstorphine Road" in field "address_address_line2"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH12 6TS" in field "address_postcode"
        When I click on the "Continue" button

        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I select "ANG" from the "returns_lbtt_property_parent_title_code"
        And I enter "4567" in the "returns_lbtt_property_parent_title_number" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        #transaction

        When I click on the "Add transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page

        # Check the date validation
        When I enter "01-01-2015" in the "Effective date of transaction" date field
        And I enter "30-03-2015" in the "Relevant date" date field
        And I enter "30-03-2015" in the "Date of contract or conclusion of missives" date field
        And I enter "11-10-2019" in the "Lease start date" date field
        And I enter "10-10-2019" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should receive the message "Effective date of transaction must be on or after 1st April 2015"
        And I should receive the message "Relevant date must be on or after 1st April 2015"
        And I should receive the message "Date of contract or conclusion of missives must be on or after 1st April 2015"
        And I should receive the message "Lease start date must be before lease end date"
        And I should receive the message "Lease end date must be after lease start date"

        When I enter "02-08-2022" in the "Effective date of transaction" date field
        And I enter "03-08-2022" in the "Relevant date" date field
        And I enter "10-10-2022" in the "Lease start date" date field
        And I enter "08-10-2026" in the "Lease end date" date field
        And I clear the "Date of contract or conclusion of missives" field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I check the "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Continue" button

        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should receive the message "Are there any linked transactions can't be blank"
        When I check the "Yes" radio button
        Then I should see the text "Return reference (if known)"
        And I should see the text "NPV (inc VAT)"
        And I should see the text "Premium (inc VAT)"
        When I enter "1234" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_npv_inc" field
        And I enter "456" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_premium_inc" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        # about the lease_values rental years
        And I click on the "Continue" button
        Then I should receive the message "The rent for the first year can't be blank"
        When I enter "invalid" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should receive the message "The rent for the first year is not a number"
        When I enter "-1234" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should receive the message "The rent for the first year must be greater than or equal to 0"
        When I enter "1234.56789" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should receive the message "The rent for the first year must be a number to 2 decimal places"
        When I enter "1000000000000000000" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should receive the message "The rent for the first year must be less than 1000000000000000000"
        When I enter "350000" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page


        When I click on the "Continue" button
        Then I should receive the message "Is this the same value for all rental years can't be blank"
        # Validation for rental years
        When I check the "No" radio button
        # Rental years
        Then I should see the text "Year 4"
        And I should not see the text "Year 5"
        When I clear the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_0_rent" field
        When I clear the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_1_rent" field
        When I clear the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_2_rent" field
        When I clear the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_3_rent" field
        When I click on the "Continue" button
        Then I should receive the message "Rent can't be blank"

        When I enter " 750000" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_0_rent" field
        When I enter "Hello" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_1_rent" field
        When I enter "0" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_2_rent" field
        When I clear the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_3_rent" field
        And I click on the "Continue" button
        Then I should receive the message "Rent is not a number"
        And I should receive the message "Rent can't be blank"
        When I enter "350100" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_1_rent" field
        And I enter "360200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_2_rent" field
        And I enter "370200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_3_rent" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I should see the text "Is a premium being paid?"
        # Going back to the about the dates page to set the years
        # checking the text on the page as the page name is the same for all
        When I click on the "Back" link
        Then I should see the text "Is this the same value for all rental years?"
        When I click on the "Back" link
        Then I should see the text "How much is the rent for the first year (inc VAT)?"
        When I click on the "Back" link
        Then I should see the "Linked transactions" page
        When I click on the "Back" link
        Then I should see the "About the transaction" page
        When I click on the "Back" link
        Then I should see the "About the dates" page
        # Deducted two years
        When I enter "09-10-2024" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should see the text "How much is the rent for the first year (inc VAT)?"
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I should see the text "Year 2"
        And I should not see the text "Year 3"
        # Then back to rental years page to re-add the rental year values
        When I click on the "Back" link
        Then I should see the text "How much is the rent for the first year (inc VAT)?"
        When I click on the "Back" link
        Then I should see the "Linked transactions" page
        When I click on the "Back" link
        Then I should see the "About the transaction" page
        When I click on the "Back" link
        Then I should see the "About the dates" page
        And I enter "08-10-2026" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should see the text "How much is the rent for the first year (inc VAT)?"
        And I click on the "Continue" button
        Then I should see the text "350000" in field "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_2_rent"
        And I should see the text "350000" in field "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_3_rent"
        And I should see the text "Year 3"
        And I should see the text "Year 4"
        And I should not see the text "Year 5"
        And I enter "32200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_2_rent" field
        And I enter "32200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_3_rent" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I should see the text "456" in field "Premium for linked transactions"
        # Premium paid
        And I click on the "Continue" button
        Then I should receive the message "Is a premium being paid can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should receive the message "Premium amount (inc VAT) can't be blank"
        And I should receive the message "What is the relevant rent amount for this transaction can't be blank"

        When I enter "123" in the "Premium amount (inc VAT)" field
        And I click on the "Continue" button
        Then I should receive the message "What is the relevant rent amount for this transaction can't be blank"

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page

        When I click on the "Back" link
        Then I should see the "About the lease values" page

        When I check the "Yes" radio button

        When I enter "invalid" in the "Premium amount (inc VAT)" field
        And I enter "invalid" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Continue" button
        Then I should receive the message "Premium amount (inc VAT) is not a number"
        And I should receive the message "What is the relevant rent amount for this transaction is not a number"

        When I enter "-1300" in the "Premium amount (inc VAT)" field
        And I enter "-12300" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Continue" button
        Then I should receive the message "Premium amount (inc VAT) must be greater than or equal to 0"
        And I should receive the message "What is the relevant rent amount for this transaction must be greater than or equal to 0"

        When I enter "1300.123456" in the "Premium amount (inc VAT)" field
        And I enter "123.5600" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Continue" button
        Then I should receive the message "Premium amount (inc VAT) must be a number to 2 decimal places"
        And I should receive the message "What is the relevant rent amount for this transaction must be a number to 2 decimal places"

        When I enter "1000000000000000000" in the "Premium amount (inc VAT)" field
        And I enter "1000000000000000000" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Continue" button
        Then I should receive the message "Premium amount (inc VAT) must be less than 1000000000000000000"
        And I should receive the message "What is the relevant rent amount for this transaction must be less than 1000000000000000000"

        When I enter "352000" in the "Premium amount (inc VAT)" field
        And I enter "351000" in the "What is the relevant rent amount for this transaction?" field
        And I enter "654" in the "Premium for linked transactions" field
        And I click on the "Continue" button

        Then I should see the "Calculated Net Present Value (NPV)" page

        # NPV calculated tax
        And I should see the text "1108562.77" in field "Net Present Value (NPV)"
        And I should see the text "1234" in field "Net Present Value (NPV) for linked transactions"

        When I clear the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        Then I should receive the message "Net Present Value (NPV) can't be blank"
        When I enter "invalid" in the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        Then I should receive the message "Net Present Value (NPV) is not a number"
        When I enter "-12101" in the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        Then I should receive the message "Net Present Value (NPV) must be greater than or equal to 0"
        When I enter "12.101" in the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        Then I should receive the message "Net Present Value (NPV) must be a number to 2 decimal places"
        And I enter "1000000000000000000" in the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        And I should receive the message "Net Present Value (NPV) must be less than 1000000000000000000"

        When I enter "353000" in the "Net Present Value (NPV)" field
        And I enter "4321" in the "Net Present Value (NPV) for linked transactions" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add the reliefs in 'Add Reliefs' section
        When I click on the "Add reliefs" link
        Then I should see the "Reliefs on this transaction" page

        # reliefs on transaction
        Then I should see the text "Type of relief"
        And I should see the text "Amount of LBTT tax saved by relief"
        And "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded" should not contain the option "Multiple dwellings relief"
        And I select "Friendly societies relief" from the "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_type_expanded"

        When I click on the "Continue" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the text "13542" in field "returns_lbtt_lbtt_return_returns_lbtt_relief_claim_0_relief_override_amount"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the reliefs         | Edit reliefs                       |
            | Type of relief            | Amount of LBTT tax saved by relief |
            | Friendly societies relief | £13,542.00                         |
        And the table of data is displayed
            | About the calculation         | Edit calculation |
            | LBTT tax liability on rent    | £2,048.00        |
            | LBTT tax liability on premium | £11,494.00       |
            | Total LBTT reliefs claimed    | £13,542.00       |
            | Total tax payable             | £0.00            |

        # go back through the transaction details check we can still see the calculated npv before overriding
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I should see the text "654" in field "Premium for linked transactions"
        When I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        And I should see the text "353000" in field "Net Present Value (NPV)"
        And I should see the text "4321" in field "Net Present Value (NPV) for linked transactions"

        # Then go through and override the values so they work
        And I enter "4521" in the "Net Present Value (NPV) for linked transactions" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the transaction                                  | Edit        |
            | What is the property type for this transaction?        | Residential |
            | Effective date of transaction                          | 02/08/2022  |
            | Relevant date                                          | 03/08/2022  |
            | Lease start date                                       | 10/10/2022  |
            | Lease end date                                         | 08/10/2026  |
            | Are there any linked transactions?                     | Yes         |
            | Premium amount (inc VAT)                               | £352,000.00 |
            | What is the relevant rent amount for this transaction? | £351,000.00 |
            | Net Present Value (NPV)                                | £353,000.00 |

        # Check the overridden transaction value isn't changed just by going through the wizard
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I should see the text "654" in field "Premium for linked transactions"
        When I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        And I should see the text "353000" in field "Net Present Value (NPV)"
        And I should see the text "4521" in field "Net Present Value (NPV) for linked transactions"
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Check the overridden transaction value is changed by changing the linked value
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I enter "1000" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_npv_inc" field
        And I enter "500" in the "returns_lbtt_lbtt_return_returns_lbtt_link_transactions_0_premium_inc" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I enter "360100" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_1_rent" field
        And I enter "370200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_2_rent" field
        And I enter "380200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_3_rent" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I should see the text "500" in field "Premium for linked transactions"
        When I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page

        # NPV calculated tax
        And I should see the text "1000" in field "Net Present Value (NPV) for linked transactions"
        And I should see the text "1726016.41" in field "Net Present Value (NPV)"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the transaction                                  | Edit          |
            | What is the property type for this transaction?        | Residential   |
            | Effective date of transaction                          | 02/08/2022    |
            | Relevant date                                          | 03/08/2022    |
            | Lease start date                                       | 10/10/2022    |
            | Lease end date                                         | 08/10/2026    |
            | Are there any linked transactions?                     | Yes           |
            | Premium amount (inc VAT)                               | £352,000.00   |
            | What is the relevant rent amount for this transaction? | £351,000.00   |
            | Net Present Value (NPV)                                | £1,726,016.41 |
        # Check the date warnings are given for a lease return, not checking full text
        And I should see the text "in the past. This is usually more recent than this."
        And I should see a link with text "You can edit the transaction details if you need to"

        # Save the draft
        When I click on the "Save draft" button

        Then I should see the "Your return has been saved" page
        And I should see the text "You can complete or cancel it later using the reference below."
        And I should see the text "Your return has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"

        Then I should store the generated value with id "notification_banner_reference"
        And I should see a link with text "Go to dashboard"
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        When I click on the "See all returns" link
        Then I should see the "All returns" page

        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see a link with text "Continue"

        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        # Check the date warnings are still shown
        And I should see the text "in the past. This is usually more recent than this."
        And I should see a link with text "You can edit the transaction details if you need to"

        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page
        And I should see the text "I, the tenant, declare that this return is, to the best of my knowledge, correct and complete"
        And I should not see the text "I, the agent for the tenant(s), confirm that I have authority to deal with all matters relating to this transaction on behalf of my client(s)"


    Scenario: Make a lease assignation for an agent, including duplicate NINO check

        Create an assignation return
        Validate the return effective date errors
        Attempt to submit to check the whole model validation for assignation
        Save the draft
        Retrieve the draft to check no detals are defaulted
        Edit the agent details to change them
        Edit the agent details to check they aren't reset to the default by editing
        Add a property (check ADS is not shown/allowed)
        Add a private individual tenant, checking international details are allowed
        Add a private individual new tenant
        Add another private individual new tenant
        Delete the second new tenant
        Add the transaction details, with no linked transactions and with yearly rents
        Check the date warnings are not shown
        Submit the return entering repayment details

        Amend the return
        Attempt to add a private individual tenant, checking NINO duplication check
        Submit the return, selecting no to repayment details

        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        And I check the "Assignation" radio button
        And I click on the "Continue" button
        Then I should see the "Return reference number" page
        And I click on the "Continue" button
        Then I should receive the message "What was the original return reference can't be blank"
        And I should receive the message "What was the original return effective date can't be blank"
        And I should not receive the message "Return reference is a required item"

        When I enter "RS1234567ABCD" in the "What was the original return reference" field
        And I click on the "Continue" button
        # Validate the return effective date errors
        Then I should see the "Return reference number" page
        And I should receive the message "What was the original return effective date can't be blank"
        When I enter "01-01-2023" in the "What was the original return effective date" date field
        And I click on the "Continue" button
        Then I should see the "Return reference number" page
        And I should receive the message "The original return reference and original effective date is not a filed lease return"

        When I enter "RS2000003BBBB" in the "What was the original return reference" field
        # Check invalid date processing and that doesn't call back office
        And I enter "01062020" in the "What was the original return effective date" field
        And I click on the "Continue" button
        Then I should see the "Return reference number" page
        And I should receive the message "What was the original return effective date is invalid"
        When I enter "01-06-2020" in the "What was the original return effective date" date field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        # Check the dynamic text for the calculation region
        And I should see the text "The amount of tax already paid below will show as £0.00. You will need to change this field to show the correct amount of tax already paid in order for the correct amount of tax due to show. For all other fields, the amounts in this section will be automatically calculated when you create or update the transaction section. You can edit them before you submit the return."

        # pre-calculate validation
        When I click on the "Submit return" button
        Then I should see the text "Please fill in the 'About the transaction' section"
        And I should see the text "Please fill in at least one property"
        And I should see the text "Please fill in at least one new tenant"
        And I should see the text "Please fill in at least one tenant"

        # Check no details are defaulted
        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "You can complete or cancel it later using the reference below."
        And I should see the text "Your return has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"

        Then I should store the generated value with id "notification_banner_reference"
        And I should see a link with text "Go to dashboard"
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        When I click on the "See all returns" link
        Then I should see the "All returns" page

        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page

        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        # Not shown for this return type
        And I should not see the text "What is the property type for this transaction?"
        # Always shown even when blank
        And The cell with the heading "Are there any linked transactions?" should be blank

        # Agent
        When I click on the "Edit agent details" link
        Then I should see the "Agent details" page
        And I should see the text "Portal User" in field "First name"
        And I should see the text "New Users" in field "Last name"
        And I should see the text "07700900321" in field "Telephone number"
        And I should see the text "noreply@necsws.com" in field "Email"

        When I select "Mr" from the "Title"
        And I enter "Fred" in the "First name" field
        And I enter "Bloggs" in the "Last name" field
        And I enter "my agent ref" in the "Your reference (optional)" field
        # Uk phone number start with '+442079460654'
        And I enter "+442079460654" in the "Telephone number" field
        And I enter "neverreply@necsws.com" in the "Email" field

        When I click on the "Continue" button
        Then I should see the "Agent address" page
        And I should see the text "2 Park Lane" in field "address_address_line1"
        And I should see the text "Garden Village" in field "address_address_line2"
        And I should see the text "NORTHTOWN" in field "Town"
        And I should see the text "Northshire" in field "County"
        And I should see "UNITED KINGDOM" in the "address_country" select or text field
        And I should see the text "RG1 1PB" in field "address_postcode"

        When I click on the "Return to postcode lookup" button
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Agent address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Agent address" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        # Check you can see agent details
        And the table of data is displayed
            | Name           | Your reference |
            | Mr Fred Bloggs | my agent ref   |

        # Check Agent Data was changed
        When I click on the "Edit agent details" link
        Then I should see the "Agent details" page
        And I should see the "Mr" option selected in "Title"
        And I should see the text "Fred" in field "First name"
        And I should see the text "Bloggs" in field "Last name"
        And I should see the text "+442079460654" in field "Telephone number"
        And I should see the text "neverreply@necsws.com" in field "Email"
        And I click on the "Continue" button
        Then I should see the "Agent address" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "Town"
        And I should see the empty field "County"
        And I should see "ENGLAND" in the "address_country" select or text field
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Property
        When I click on the "Add a property" link
        Then I should see the "Property address" page
        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        And I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"

        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Continue" button
        # No does ADS apply page for non-conveyance returns
        Then I should see the "Return Summary" page
        # Verify entered details on return summary page do not include ADS
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                                                   |
            | Royal Zoological Society Of Scotland, EDINBURGH, EH12 6TS |
        And I should not see the text "About the Additional Dwelling Supplement"
        And I should not see the text "ADS?"

        # Tenant
        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        And I click on the "Continue" button
        Then I should receive the message "Who they are can't be blank"
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        And I click on the "Continue" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Telephone number can't be blank"
        And I should receive the message "Provide a NINO or an alternate reference"

        When I enter "TenantSurname" in the "Last name" field
        And I enter "TenantFirstname" in the "First name" field
        And I select "Mr" from the "Title"
        # Allow spanish phone number
        And I enter "+34629629629" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "AB323455C" in the "National Insurance Number (NINO)" field
        And I click on the "Continue" button
        Then I should see the "Tenant address" page

        When I click on the "Or type in your full address" button
        And I enter "Plaza del Ayuntamiento" in the "address_address_line1" field
        And I enter "1. 03002 Alicante" in the "Town" field
        And I enter "SPAIN" in the "Country" select or text field
        And I click on the "Continue" button
        Then I should see the "Tenant's contact address" page
        When I click on the "Continue" button
        Then I should receive the message "Should we use a different address for future correspondence in relation to this return can't be blank"
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        Then I should see the text "Is the tenant connected to the landlord?"
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should receive the message "How are they connected can't be blank"

        When I enter "RANDOM_text,300" in the "How are they connected?" field
        And I click on the "Continue" button
        Then I should receive the message "How are they connected is too long (maximum is 255 characters)"

        When I enter "Test relation" in the "How are they connected?" field
        And I click on the "Continue" button


        Then I should see the "Tenant details" page
        When I click on the "Continue" button
        Then I should see the text "If they are acting as a trustee or representative partner for tax purposes can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Return Summary" page
        Then I should see the text "Mr TenantFirstname TenantSurname"
        Then I should see the text "Plaza del Ayuntamiento, 1. 03002 Alicante"
        Then I should see the text "A private individual"
        Then I should see the text "Edit row"

        # add new tenant
        When I click on the "Add a new tenant" link

        Then I should see the "About the new tenant" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button

        Then I should see the "New tenant details" page
        And I click on the "Continue" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"


        When I enter "TenantSurname2" in the "Last name" field
        And I enter "TenantFirstname2" in the "First name" field
        And I select "Mr" from the "Title"

        And I click on the "Continue" button

        Then I should see the "New tenant address" page
        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "New tenant address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "New tenant address" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "New tenant's contact address" page
        When I click on the "Continue" button
        Then I should receive the message "Should we use a different address for future correspondence in relation to this return can't be blank"
        When I check the "No" radio button
        And I click on the "Continue" button

        Then I should see the "New tenant details" page
        When I click on the "Continue" button
        Then I should receive the message "If they are linked can't be blank"
        When I check the "Yes" radio button
        And I enter "Test relation" in the "How are they connected?" field
        And I click on the "Continue" button

        Then I should see the "New tenant details" page
        When I click on the "Continue" button
        Then I should see the text "If they are acting as a trustee or representative partner for tax purposes can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Return Summary" page
        Then I should see the text "Mr TenantFirstname2 TenantSurname2"
        Then I should see the text "Royal Mail, LUTON, LU1 1AA"
        Then I should see the text "A private individual"
        Then I should see the text "Edit"

        # adding another tenant
        When I click on the "Add a new tenant" link

        Then I should see the "About the new tenant" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button

        Then I should see the "New tenant details" page
        When I enter "lname" in the "Last name" field
        And I enter "fname" in the "First name" field
        And I select "Mr" from the "Title"

        And I enter "0123456789" in the "Telephone number (optional)" field
        And I enter "noreply@necsws.com" in the "Email (optional)" field

        And I click on the "Continue" button

        Then I should see the "New tenant address" page
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "New tenant address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "New tenant address" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "New tenant's contact address" page
        When I check the "No" radio button
        And I click on the "Continue" button

        Then I should see the "New tenant details" page
        When I check the "Yes" radio button
        And I enter "Test relation" in the "How are they connected?" field
        And I click on the "Continue" button

        Then I should see the "New tenant details" page
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Return Summary" page
        And I should see the text "Mr fname lname"
        And I should see the text "Royal Mail, LUTON, LU1 1AA"
        And I should see the text "A private individual"
        And I should see the text "Edit"

        When I click on the 2 nd "Delete row" link
        And if available, click the confirmation dialog
        Then I should see the "Return Summary" page
        And I should not see the text "Mr TenantFirstname2 TenantSurname2"

        # Transaction
        When I click on the "Add transaction details" link
        Then I should see the "About the dates" page
        When I enter "02-08-2022" in the "Effective date of transaction" date field
        And I enter "03-08-2022" in the "Relevant date" date field
        And I enter "03-08-2022" in the "Date of contract or conclusion of missives" date field
        And I enter "10-10-2022" in the "Lease start date" date field
        And I enter "08-10-2026" in the "Lease end date" date field
        And I click on the "Continue" button

        Then I should see the "Linked transactions" page
        # linked-transactions - select no to get positive calculation results
        When I check the "No" radio button
        And I click on the "Continue" button

        Then I should see the "About the lease values" page
        # about the lease_values rental years
        When I enter "350000" in the "How much was the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button

        Then I should see the "About the lease values" page
        When I check the "No" radio button
        # Rental years
        Then I should see the text "Year 4"
        When I enter "350100" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_1_rent" field
        And I enter "360200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_2_rent" field
        And I enter "370200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_3_rent" field
        And I enter "340200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_0_rent" field
        And I click on the "Continue" button

        Then I should see the "About the lease values" page
        When I check the "Yes" radio button
        When I enter "352000" in the "Premium amount" field
        And I enter "351000" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Continue" button

        Then I should see the "Calculated Net Present Value (NPV)" page
        And I should not see the text "for linked transactions"
        # NPV calculated tax
        And I should see the text "1303005.42" in field "Net Present Value (NPV)"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the transaction                                  | Edit          |
            | Effective date of transaction                          | 02/08/2022    |
            | Relevant date                                          | 03/08/2022    |
            | Lease start date                                       | 10/10/2022    |
            | Lease end date                                         | 08/10/2026    |
            | Are there any linked transactions?                     | No            |
            | Premium amount (inc VAT)                               | £352,000.00   |
            | What is the relevant rent amount for this transaction? | £351,000.00   |
            | Net Present Value (NPV)                                | £1,303,005.42 |
        And I should not see the text "What is the property type for this transaction?"


        # Calculation happened after the transaction section
        And the table of data is displayed
            | About the calculation          | Edit       |
            | LBTT tax liability on rent     | £11,530.00 |
            | LBTT tax liability on premium  | £7,600.00  |
            | Total tax payable              | £19,130.00 |
            | Amount already paid            | £0.00      |
            | Amount payable for this return | £19,130.00 |

        # Check the date warnings are not given for a lease assignation
        And I should not see the text "This is usually more recent than this."
        And I should not see the text "This has typically already happened"
        And I should not see a link with text "You can edit the transaction details if you need to"

        When I click on the "Submit return" button
        Then I should see the "Repayment details" page
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Claim repayment" page
        When I enter "750" in the "How much are you claiming for repayment?" field
        And I click on the "Continue" button
        Then I should see the "Enter bank details" page

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Continue" button

        Then I should see the "Declaration" page
        And I should see the text "I, the agent for the tenant(s), confirm that the tenant(s) have authorised repayment to be made to these bank details"
        And I should see the text "I, the agent of the tenant(s), having been authorised to complete this claim on behalf of the tenant(s), certify that the tenant(s) has/have declared that the information provided in the claim is to the best of their knowledge, correct and complete, and confirm that the tenant(s) is/are eligible for the refund claimed"
        When I click on the "Continue" button
        Then I should receive the message "The refund declaration must be accepted"
        And I should receive the message "The bank account declaration must be accepted"
        When I check the "returns_lbtt_lbtt_return_repayment_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_repayment_agent_declaration" checkbox
        And I click on the "Continue" button

        Then I should see the "Payment and submission" page
        And I should see the text "I, the agent of the tenant(s), having been authorised to complete this return on behalf of the tenant(s):"
        And I should see the text "I, the agent for the tenant(s), confirm that I have authority to deal with all matters relating to this transaction on behalf of my client(s)"

        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button

        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should store the reference from the notification panel as "notification_banner_reference"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"

        # Load that return for amending
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        When I click on the "See all returns" link
        Then I should see the "All returns" page
        And I enter the stored value "notification_banner_reference" in field "dashboard_dashboard_return_filter_tare_reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I click on the "Amend" link
        Then I should see the "Return Summary" page

        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I enter "Tenant3Surname" in the "Last name" field
        And I enter "Tenant3Firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "AB 32 34 55 C" in the "National Insurance Number (NINO)" field
        And I click on the "Continue" button
        And I should receive the message "National Insurance Number (NINO) is a duplicate of that for Mr TenantFirstname TenantSurname"
        When I click on the "Back" link
        Then I should see the "About the tenant" page
        And I click on the "Back" link
        And I click on the "Submit return" button
        Then I should see the "Amendment reason" page
        When I enter "Test" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button
        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button

        Then I should see the "Payment and submission" page
        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button

        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And the table of data is displayed
            | Title number (if provided)   | ABN 1234                                                                         |
            | Property address             | Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS |
            | Tenant                       | Mr TenantFirstname TenantSurname                                                 |
            | Description of transaction   | Assignation                                                                      |
            | Effective date               | 02/08/2022                                                                       |
            | Your reference (if provided) | my agent ref                                                                     |

    Scenario: Make a lease review return return for a public user

        Check a public user cannot go to the authenticated pages
        Validate that the user is stopped when using a disregarded  return
        Create a 3 year lease review return
        Validate that the triennial date validation works
        Check you cannot save a draft
        Add a private individual tenant
        Add a property
        Add transaction details, with no rent years
        Edit the calculation
        Check date warnings are not shown
        Submit the return with no repayment checking DD payment method not available
        Check the secure message and dashboard links are not shown/allowed

        # Check signed in user does not have access
        Given I have signed in
        When I go to the "returns/lbtt/public_landing" page
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/public_return_type" page
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/return_reference_number" page
        Then I should see the "Dashboard" page

        # Now test with public user
        Given I have signed out
        When I go to the "returns/lbtt/public_landing" page
        Then I should see the "To complete this return, you will need the following information" page

        When I click on the "Start now" link
        Then I should see the "About the return" page

        When I check the "3 year lease review" radio button
        And I click on the "Continue" button
        Then I should see the "Return reference number" page

        # Validate that the user is stopped when using a disregarded  return
        When I enter "RS3000003FFFF" in the "What was the original return reference" field
        And I enter "01-10-2019" in the "What was the original return effective date" date field
        And I click on the "Continue" button
        And I should see the text "The original return reference and original effective date is not a filed lease return. Contact Revenue Scotland as there could be a duplicate return for this reference"

        When I enter "RS2000003BBBB" in the "What was the original return reference" field
        And I enter "01-06-2020" in the "What was the original return effective date" date field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        # Check the dynamic text for the calculation region
        And I should see the text "The amount of tax already paid below will show as £0.00. You will need to change this field to show the correct amount of tax already paid in order for the correct amount of tax due to show. For all other fields, the amounts in this section will be automatically calculated when you create or update the transaction section. You can edit them before you submit the return."
        And I should not see the text "Contact details for this return"
        And I should not see the text "Save draft"

        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        # Allow intenational phone number
        And I enter "+12 123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I open the "Tenant does not have NINO" summary item
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field

        And I click on the "Continue" button
        Then I should see the "Tenant address" page
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Tenant address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Tenant address" page
        When I click on the "Continue" button
        Then I should see the "Tenant's contact address" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Add a property" link
        Then I should see the "Property address" page
        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Check triennial dates validation
        # First check failure
        # Then none leap year
        # Then leap year for 28th and 1st
        When I click on the "Add transaction details" link
        Then I should see the "About the dates" page
        Then I should see the "About the dates" page
        When I enter "01-01-2019" in the "Effective date of transaction" date field
        And I enter "01-01-2019" in the "Relevant date" date field
        And I enter "01-01-2019" in the "Lease start date" date field
        And I enter "01-01-2025" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should receive the message "Relevant date must be a triennial anniversary of the effective date"

        When I enter "01-01-2019" in the "Effective date of transaction" date field
        And I enter "03-08-2019" in the "Relevant date" date field
        And I enter "01-01-2019" in the "Lease start date" date field
        And I enter "01-01-2025" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should receive the message "Relevant date must be a triennial anniversary of the effective date"

        When I enter "01-01-2019" in the "Effective date of transaction" date field
        And I enter "01-01-2022" in the "Relevant date" date field
        And I enter "01-01-2019" in the "Lease start date" date field
        And I enter "01-01-2025" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I click on the "Back" link
        And I enter "29-02-2020" in the "Effective date of transaction" date field
        And I enter "28-02-2023" in the "Relevant date" date field
        And I enter "01-03-2020" in the "Lease start date" date field
        And I enter "01-03-2030" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I click on the "Back" link
        And I enter "29-02-2020" in the "Effective date of transaction" date field
        And I enter "01-03-2023" in the "Relevant date" date field
        And I enter "01-03-2020" in the "Lease start date" date field
        And I enter "01-03-2030" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I click on the "Continue" button
        Then I should receive the message "The rent for the first year can't be blank"
        When I enter "a" in the "How much was the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should receive the message "The rent for the first year is not a number"
        When I enter "1234" in the "How much was the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should receive the message "Is this the same value for all rental years can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        When I enter "100" in the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Edit calculation" link
        Then I should see the "Calculated tax" page
        And I enter " 100 " in the "Amount already paid" field
        And I click on the "Continue" button
        Then I should see the "Calculated tax" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        # Check the date warnings are not given for a lease review
        And I should not see the text "This is usually more recent than this."
        And I should not see the text "This has typically already happened"
        And I should not see a link with text "You can edit the transaction details if you need to"

        # submit
        When I click on the "Submit return" button
        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page
        And I should not see the text "Direct Debit"
        And I should not see the text "I, the agent for the buyer"
        And I should see the text "I, the tenant, declare that this return is, to the best of my knowledge, correct and complete"

        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should not see the text "secure message"
        And I should not see the text "dashboard"


    Scenario: Make a lease termination return for a taxpayer

        Create a termination return
        Validate that a disregarded versions effective  date is not used
        Attempt to submit to check the whole model validation for termination
        Edit agent details, including phone number allows + (note Agent is correct)
        Add a property
        Delete the property
        Add the propery checking ADS not allowed
        Add a private individual tenant, including international details
        Add the transaction details, including yearly rents
        Check the date warnings are not shown
        Save the draft
        Save the draft again
        Go to dashboard and download PDF
        Go to all returns and download PDF
        Retrieve the draft
        Submit the return

        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        And I check the "Termination" radio button
        And I click on the "Continue" button
        Then I should see the "Return reference number" page

        # Validate that a disregarded versions effective  date is not used
        When I enter "RS3000003GGGG" in the "What was the original return reference" field
        And I enter "03-10-2019" in the "What was the original return effective date" date field
        And I click on the "Continue" button
        And I should see the text "The original return reference and original effective date is not a filed lease return"

        When I enter "02-10-2019" in the "What was the original return effective date" date field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page


        When I click on the "Back" link
        And if available, click the confirmation dialog
        And I enter "RS2000003BBBB" in the "What was the original return reference" field
        And I enter "01-06-2020" in the "What was the original return effective date" date field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        # Check the dynamic text for the calculation region
        And I should see the text "The amount of tax already paid below will show as £0.00. You will need to change this field to show the correct amount of tax already paid in order for the correct amount of tax due to show. For all other fields, the amounts in this section will be automatically calculated when you create or update the transaction section. You can edit them before you submit the return."

        # pre-calculate validation
        When I click on the "Submit return" button
        Then I should see the text "Please fill in the 'About the transaction' section"
        And I should see the text "Please fill in at least one property"
        And I should see the text "Please fill in at least one tenant"

        # Agent
        When I click on the "Edit agent details" link
        Then I should see the "Agent details" page
        And I select "Mr" from the "Title"
        And I enter "my agent ref" in the "Your reference (optional)" field

        # Uk phone number start with '+442079460654'
        And I enter "+442079460654" in the "Telephone number" field
        And I click on the "Continue" button
        Then I should see the "Agent address" page

        When I click on the "Return to postcode lookup" button
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Agent address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Agent address" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Property
        # Adding and then immediately deleting the row of property data added
        When I click on the "Add a property" link
        Then I should see the "Property address" page
        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"

        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Continue" button
        # No does ADS apply page for non-conveyance returns
        Then I should see the "Return Summary" page
        And I click on the 1 st "Delete row" link
        And if available, click the confirmation dialog
        # no wait as the not implies a wait anyway
        Then I should not see the text "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS"

        When I click on the "Add a property" link
        Then I should see the "Property address" page
        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"

        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Continue" button
        # No does ADS apply page for non-conveyance returns
        Then I should see the "Return Summary" page
        # Verify entered details on return summary page do not include ADS
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                                                   |
            | Royal Zoological Society Of Scotland, EDINBURGH, EH12 6TS |
        And I should not see the text "About the Additional Dwelling Supplement"
        And I should not see the text "ADS?"

        # Tenant
        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        And I click on the "Continue" button
        Then I should receive the message "Who they are can't be blank"
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I enter "+34629629629" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I open the "Tenant does not have NINO" summary item
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I click on the "Continue" button
        Then I should receive the message "Provide a NINO or an alternate reference"

        When I enter "AB323455C" in the "National Insurance Number (NINO)" field
        And I open the "Tenant does not have NINO" summary item
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field
        And I click on the "Continue" button
        Then I should receive the message "Don't provide the alternate reference if you provide a NINO"

        When I clear the "National Insurance Number (NINO)" field
        And I click on the "Continue" button
        Then I should see the "Tenant address" page

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Tenant address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Tenant address" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        When I click on the "Continue" button
        Then I should see the "Tenant's contact address" page
        When I click on the "Continue" button
        Then I should receive the message "Should we use a different address for future correspondence in relation to this return can't be blank"
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        Then I should see the text "Is the tenant connected to the landlord?"
        When I check the "Yes" radio button
        And I enter "Test relation" in the "How are they connected?" field
        And I click on the "Continue" button

        Then I should see the "Tenant details" page
        When I click on the "Continue" button
        Then I should see the text "If they are acting as a trustee or representative partner for tax purposes can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Return Summary" page
        Then I should see the text "Mr firstname surname"
        Then I should see the text "Royal Mail, LUTON, LU1 1AA"
        Then I should see the text "A private individual"
        Then I should see the text "Edit"

        # Transaction
        When I click on the "Add transaction details" link
        Then I should see the "About the dates" page

        When I enter "02-08-2019" in the "Effective date of transaction" date field
        And I enter "08-10-2023" in the "Relevant date" date field
        And I enter "03-08-2019" in the "Date of contract or conclusion of missives" date field
        And I enter "10-10-2019" in the "Lease start date" date field
        And I enter "07-08-2023" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "About the dates" page
        And I should receive the message "Lease end date must be the same as the relevant date"

        When I enter "08-10-2023" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page
        # linked-transactions - select no to get positive calculation results
        When I check the "No" radio button
        And I click on the "Continue" button

        Then I should see the "About the lease values" page
        # about the lease_values rental years
        When I enter "350000" in the "How much was the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button

        Then I should see the "About the lease values" page
        When I check the "No" radio button
        # Rental years
        Then I should see the text "Year 4"
        When I enter "350100" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_1_rent" field
        And I enter "360200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_2_rent" field
        And I enter "370200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_3_rent" field
        And I enter "340200" in the "returns_lbtt_lbtt_return_returns_lbtt_yearly_rent_0_rent" field
        And I click on the "Continue" button

        Then I should see the "About the lease values" page
        When I check the "Yes" radio button
        When I enter "352000" in the "Premium amount" field
        And I enter "351000" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Continue" button

        Then I should see the "Calculated Net Present Value (NPV)" page
        And I should not see the text "for linked transactions"
        # NPV calculated tax
        And I should see the text "1303005.42" in field "Net Present Value (NPV)"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the transaction                                  | Edit          |
            | Effective date of transaction                          | 02/08/2019    |
            | Relevant date                                          | 08/10/2023    |
            | Are there any linked transactions?                     | No            |
            | Lease start date                                       | 10/10/2019    |
            | Lease end date                                         | 08/10/2023    |
            | Premium amount (inc VAT)                               | £352,000.00   |
            | What is the relevant rent amount for this transaction? | £351,000.00   |
            | Net Present Value (NPV)                                | £1,303,005.42 |

        # Calculation happened after the transaction section
        And the table of data is displayed
            | About the calculation          | Edit       |
            | LBTT tax liability on rent     | £11,530.00 |
            | LBTT tax liability on premium  | £7,600.00  |
            | Total tax payable              | £19,130.00 |
            | Amount already paid            | £0.00      |
            | Amount payable for this return | £19,130.00 |

        # Check the date warnings are not given for a lease review
        And I should not see the text "This is usually more recent than this."
        And I should not see the text "This has typically already happened"
        And I should not see a link with text "You can edit the transaction details if you need to"

        And I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "You can complete or cancel it later using the reference below."
        And I should see the text "Your return has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        Then I should store the generated value with id "notification_banner_reference"
        And I should see a link with text "Go to dashboard"
        And I should see a link with text "Back to return summary"
        # Check we can go back and save again
        When I click on the "Back" link
        Then I should see the "Return Summary" page
        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"

        # Download test for the LBTT pdf on dashboard home page
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        When I click on the 1 st "Download PDF" link to download a file
        Then I should see the downloaded "PDF" content of "LBTT" by looking up "notification_banner_reference"

        # Download test for the LBTT pdf on all returns index page
        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see a link with text "Download PDF"
        When I click on the 1 st "Download PDF" link to download a file
        Then I should see the downloaded "PDF" content of "LBTT" by looking up "notification_banner_reference"

        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see a link with text "Continue"

        When I click on the "Continue" link
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the transaction                                  | Edit          |
            | Effective date of transaction                          | 02/08/2019    |
            | Relevant date                                          | 08/10/2023    |
            | Lease start date                                       | 10/10/2019    |
            | Lease end date                                         | 08/10/2023    |
            | Premium amount (inc VAT)                               | £352,000.00   |
            | What is the relevant rent amount for this transaction? | £351,000.00   |
            | Net Present Value (NPV)                                | £1,303,005.42 |
            | Are there any linked transactions?                     | No            |

        # Calculation happened after the transaction section
        And the table of data is displayed
            | About the calculation          | Edit       |
            | LBTT tax liability on rent     | £11,530.00 |
            | LBTT tax liability on premium  | £7,600.00  |
            | Total tax payable              | £19,130.00 |
            | Amount already paid            | £0.00      |
            | Amount payable for this return | £19,130.00 |

        When I click on the "Submit return" button

        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button

        Then I should see the "Payment and submission" page
        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "BACS" radio button

        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should see the text "Return reference"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        And the table of data is displayed
            | Title number (if provided)   | ABN 1234                                                                         |
            | Property address             | Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS |
            | Tenant                       | Mr firstname surname                                                             |
            | Description of transaction   | Termination                                                                      |
            | Effective date               | 02/08/2019                                                                       |
            | Your reference (if provided) | my agent ref                                                                     |


    Scenario: Make a lease return for an agent

        Create a lease return
        Add a private individual tenant
        Add a registered company landlord
        Add a property
        Add transaction details
        Save draft
        Submit return

        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        When I check the "Lease" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Tenant
        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "AB123456C" in the "National Insurance Number (NINO)" field
        And I open the "Tenant does not have NINO" summary item
        And I select "ID Card" from the "Type of ID"
        And I click on the "Continue" button
        Then I should receive the message "Country where ID was issued can't be blank"
        And I should receive the message "Reference number of the ID can't be blank"
        When I clear the "National Insurance Number (NINO)" field
        And I open the "Tenant does not have NINO" summary item
        And I select "" from the "Type of ID"
        And I enter "1" in the "Reference number of the ID" field
        And I click on the "Continue" button
        Then I should receive the message "Type of ID can't be blank"
        And I should receive the message "Country where ID was issued can't be blank"
        When I open the "Tenant does not have NINO" summary item
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I select "ID Card" from the "Type of ID"
        And I click on the "Continue" button
        Then I should see the "Tenant address" page

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Tenant address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Tenant address" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        When I click on the "Continue" button
        Then I should see the "Tenant's contact address" page
        When I click on the "Continue" button
        Then I should receive the message "Should we use a different address for future correspondence in relation to this return can't be blank"
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        Then I should see the text "Is the tenant connected to the landlord?"
        When I click on the "Continue" button
        Then I should receive the message "If they are linked can't be blank"
        When I check the "Yes" radio button
        And I enter "Test relation" in the "How are they connected?" field
        And I click on the "Continue" button

        Then I should see the "Tenant details" page
        When I click on the "Continue" button
        Then I should see the text "If they are acting as a trustee or representative partner for tax purposes can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Return Summary" page
        Then I should see the text "Mr firstname surname"
        Then I should see the text "Royal Mail, LUTON, LU1 1AA"
        Then I should see the text "A private individual"
        Then I should see the text "Edit"

        #Landlord
        When I click on the "Add a landlord" link
        Then I should see the "About the landlord" page
        When I check the "An organisation registered with Companies House" radio button
        And I click on the "Continue" button

        Then I should see the "Registered company" page
        When I enter "09338960" in the "Company number" field
        And I click on the "Find company" button
        Then I should see the text "NORTHGATE PUBLIC SERVICES LIMITED" in field "company_company_name"
        And I should see the text "1st Floor, Imex Centre" in field "company_address_line1"
        And I should see the text "575-599 Maxted Road" in field "company_address_line2"
        And I should see the text "Hemel Hempstead" in field "company_locality"
        And I should see the text "Hertfordshire" in field "company_county"
        And I should see the text "HP2 7DX" in field "company_postcode"
        When I click on the "Continue" button

        Then I should see the "Return Summary" page
        And I should see the text "NORTHGATE PUBLIC SERVICES LIMITED"

        # Add Property
        When I click on the "Add a property" link
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"

        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        And I should see the text "Royal Zoological Society Of Scotland" in field "address_address_line1"
        And I should see the text "134 Corstorphine Road" in field "address_address_line2"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH12 6TS" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I select "ANG" from the "returns_lbtt_property_parent_title_code"
        And I enter "4567" in the "returns_lbtt_property_parent_title_number" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        #TRANSACTION
        When I click on the "Add transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page

        Then I should see the "About the dates" page
        When I enter "02-08-2019" in the "Effective date of transaction" date field
        And I enter "03-08-2022" in the "Relevant date" date field
        And I enter "03-08-2019" in the "Date of contract or conclusion of missives" date field
        And I enter "10-10-2019" in the "Lease start date" date field
        And I enter "08-10-2023" in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I check the "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Continue" button

        Then I should see the "Linked transactions" page
        When I check the "No" radio button
        When I click on the "Continue" button

        Then I should see the "About the lease values" page
        When I enter "350000" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page

        And I should see the text "1285577.72" in field "Net Present Value (NPV)"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I click on the "Save draft" button

        Then I should see the "Your return has been saved" page
        And I should see the text "You can complete or cancel it later using the reference below."
        And I should see the text "Your return has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"

        Then I should store the generated value with id "notification_banner_reference"

        And I should see a link with text "Go to dashboard"
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        When I click on the "See all returns" link
        Then I should see the "All returns" page

        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see a link with text "Continue"

        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page

        When I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_lease_declaration" checkbox
        And I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should see the text "Return reference"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        And the table of data is displayed
            | Title number (if provided) | ABN 1234                                                                         |
            | Property address           | Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS |
            | Tenant                     | Mr firstname surname                                                             |
            | Description of transaction | Lease                                                                            |
            | Effective date             | 02/08/2019                                                                       |

    @mock_update_lbtt_details
    Scenario: Update Lbtt return details with mocking to simulate a corruption error

        Retrieve return
        Edit buyer details
        Attempt to submit return (errors due to incomplete details)
        Fix the data on the transaction details
        Submit the return

        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "dashboard/dashboard_returns/251-1-LBTT-RS/load" page
        Then I should see the "Return Summary" page

        # see agent details
        And I should see the text "Mr Portal User New Users"

        And the table of data is displayed
            | Name                 | Type                 | Address                    |      |        |
            | Mr firstname surname | A private individual | Royal Mail, LUTON, LU1 1AA | Edit | Delete |

        When I click on the 1 st "Edit row" link
        Then I should see the "About the buyer" page
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I enter "lastname" in the "Last name" field
        And I select "Mrs" from the "Title"
        And I open the "Buyer does not have NINO" summary item
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field
        And I click on the "Continue" button
        Then I should see the "Buyer address" page
        And I click on the "Continue" button
        Then I should see the "Buyer's contact address" page
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        And I click on the "Continue" button

        Then I should see the "Buyer details" page
        And I should see the text "Is the buyer acting as a trustee or representative partner for tax purposes?"
        And I click on the "Continue" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | Name                   | Type                 | Address                    |      |        |
            | Mrs firstname lastname | A private individual | Royal Mail, LUTON, LU1 1AA | Edit | Delete |

        # hooks file purposely incomplete to simulate back office loading lost data = validation message
        When I click on the "Submit return" button
        Then I should receive the message "There's an error somewhere in the about the calculation - please review the about the calculation section of the return and update it"
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page

        # get to page to enter incomplete data
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button

        # fix the data
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # try again
        When I click on the "Submit return" button
        Then I should see the "Amendment reason" page
        When I enter "This is a test amendment reason" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button
        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page
        When I check the "BACS" radio button

        # data is mocked so won't show a real declaration so select by id
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox

        And I click on the "Submit return" button
        Then I should see the text "Your amendment to your Land and Buildings Transaction Tax return has now been submitted."
        And I should see the text "If you have any queries about this amendment"
        And I should store the generated value with id "notification_banner_reference"
        And the table of data is displayed
            | Return reference           | RS1000202XWQY                                                          |
            | Title number (if provided) | ABN 1234                                                               |
            | Property address           | Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA |
            | Buyer                      | Mrs firstname lastname                                                 |
            | Description of transaction | Conveyance or transfer                                                 |
            | Effective date             | 02/08/2019                                                             |

        When I click on the "Send secure message" link
        Then I should see the "New message" page
        And I should see the text "notification_banner_reference" in field "dashboard_message_reference"

    @mock_address_identifier_details
    Scenario: Create a return with mocking to check address identifiers are passed correctly

        Create a conveyance return
        Add a private individual buyer (address from postcode search)
        Add a private individual buyer (amend the address)
        Save the return

        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        When I check the "Conveyance or transfer" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # First buyer with address selected
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page

        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page

        When I enter "Buyer" in the "Last name" field
        And I enter "Albert" in the "First name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "AB123456C" in the "National Insurance Number (NINO)" field
        And I click on the "Continue" button
        Then I should see the "Buyer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Buyer address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Buyer address" page
        When I click on the "Continue" button
        Then I should see the "Buyer's contact address" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Second Buyer with edited address
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page

        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page

        When I enter "Buyer" in the "Last name" field
        And I enter "Bert" in the "First name" field
        And I enter "0123456780" in the "Telephone number" field
        And I enter "noreply2@necsws.com" in the "Email" field
        And I enter "NP123456D" in the "National Insurance Number (NINO)" field
        And I click on the "Continue" button
        Then I should see the "Buyer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Buyer address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Buyer address" page
        When I click on the "Or edit the selected address" button
        And I click on the "Continue" button
        Then I should see the "Buyer's contact address" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"

    Scenario: To test the ADS claim draft created prior to 12 months but does not submit until after the effective date

        Create a conveyance return
        Add a private individual buyer
        Add a private individual seller
        Add a Seller to check previously used address links funtionality
        Add a property with ADS
        Add ADS details
        Add transaction details (date 94 days ago)
        Submit the return (BACS)

        Amend the return
        Save the draft
        Check the return is amendable
        Retrieve the draft
        Update the transaction date to 394 days ago
        Save the draft
        Check the message about amending by tomorrow is shown
        Retrieve the draft
        Update the transaction date to 395 days ago
        Save the draft
        Check the message about amending by today is shown
        retrieve the draft
        Update the transaction date to 398 days ago
        Save the draft
        Check the draft is no longer amendable
        Check the draft can be deleted

        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"

        #Step 1:  Create new ADS return and check Amend is available
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        When I check the "Conveyance or transfer" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Check you can see agent details and non provided for the reference
        And the table of data is displayed
            | Name             | Your reference |
            | Adam Portal-Test | None provided  |

        # Buyer as organisation
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page

        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I enter "Victoria" in the "Last name" field
        And I enter "Dilbert" in the "First name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "AB 12 34 56 C" in the "National Insurance Number (NINO)" field
        And I click on the "Continue" button

        Then I should see the "Buyer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Buyer address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Buyer address" page
        When I click on the "Continue" button
        Then I should see the "Buyer's contact address" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Buyer details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Seller with Private individual
        When I click on the "Add a seller" link
        Then I should see the "About the seller" page

        When I check the "A private individual" radio button
        And I click on the "Continue" button

        Then I should see the "Seller details" page

        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I click on the "Continue" button
        Then I should see the "Seller address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Seller address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Seller address" page

        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add Seller to check previously used address links
        When I click on the "Add a seller" link
        Then I should see the "About the seller" page

        When I check the "A private individual" radio button
        And I click on the "Continue" button

        Then I should see the "Seller details" page
        When I enter "SellerPrvAddChk" in the "Last name" field
        And I enter "Daniel" in the "First name" field
        And I click on the "Continue" button

        Then I should see the "Seller address" page
        And  I should see the button with text "Select Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA"
        When I click on the "Select Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Add a property" link
        Then I should see the "Property address" page

        When I enter "EH1 1BB" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Boots The Chemists Ltd, Waverley Railway Station, EDINBURGH, EH1 1BB" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page

        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I select "ANG" from the "returns_lbtt_property_parent_title_code"
        And I enter "4567" in the "returns_lbtt_property_parent_title_number" field

        When I click on the "Continue" button
        Then I should see the "About the property" page
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Verify modified details on return summary page
        Then I should see the "Return Summary" page

        When I click on the "Add ADS" link
        Then I should see the "Additional Dwelling Supplement (ADS)" page

        When I check the "No" radio button
        And I click on the "Continue" button

        Then I should see the text "Total consideration liable to ADS"
        And I enter "40750" in the "Total consideration liable to ADS" field
        And I click on the "Continue" button

        Then I should see the "Additional Dwelling Supplement (ADS)" page
        When I check the "No" radio button
        And I click on the "Continue" button

        When I click on the "Add transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page

        When I enter 94 days ago in the "Effective date of transaction" date field
        When I enter "22-07-2022" in the "Relevant date" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I check the "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About future events" page

        When I check the "returns_lbtt_lbtt_return_contingents_event_ind_n" radio button
        And I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        And I should not see the text "Linked transaction consideration"

        When I enter "1234565" in the "Total consideration" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page

        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I click on the "Submit return" button

        Then I should see the "Your return has been submitted" page
        And I should store the reference from the notification panel as "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        And I enter the stored value "notification_banner_reference" in field "dashboard_dashboard_return_filter_tare_reference"
        And I click on the "Find" button
        Then I should see the "All returns" page

        When I click on the "Amend" link
        Then I should see the "Return Summary" page

        # Step 2: Save the created return in draft list with less than seven days left to submit return
        #         Check warning message is visible on screen
        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        And the table of data is displayed
            | Return reference              | Your reference | Description            | Version | Action_1 | Action_2     | Action_3 |
            | notification_banner_reference |                | Conveyance or transfer | 2       | Continue | Download PDF | Delete   |

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should not see the text "This return is no longer amendable, use the claim option"
        And I should not see the text "You have until TOMORROW_DATE to complete this draft"

        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page

        When I enter 394 days ago in the "Effective date of transaction" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference              | Your reference | Description            | Version | Action_1 | Action_2     | Action_3 | Action_4                                            |
            | notification_banner_reference |                | Conveyance or transfer | 2       | Continue | Download PDF | Delete   | You have until TOMORROW_DATE to complete this draft |

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should not see the text "This return is no longer amendable, use the claim option"
        And I should see the text "You have until TOMORROW_DATE to complete this draft"

        # Test for allowing to submit drafted return until the relevant date
        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page

        When I enter 395 days ago in the "Effective date of transaction" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference              | Your reference | Description            | Version | Action_1 | Action_2     | Action_3 | Action_4                                       |
            | notification_banner_reference |                | Conveyance or transfer | 2       | Continue | Download PDF | Delete   | You have until NOW_DATE to complete this draft |

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should not see the text "This return is no longer amendable, use the claim option"
        And I should see the text "You have until NOW_DATE to complete this draft"

        # Step 3: Amend saved return in draft list change date to after 12 months and 30 day to submit return
        #         Check return is not amendable warning message is visible on screen and "Continue" link is not available

        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        When I click on the "Edit transaction details" link
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About the dates" page
        When I enter 398 days ago in the "Effective date of transaction" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "Linked transactions" page
        When I click on the "Continue" button
        Then I should see the "About the transaction" page
        When I click on the "Continue" button
        Then I should see the "About future events" page
        When I click on the "Continue" button
        Then I should see the "About the conveyance or transfer" page
        When I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference              | Your reference | Description            | Version | Action_1     | Action_2 | Action_3                                                 |
            | notification_banner_reference |                | Conveyance or transfer | 2       | Download PDF | Delete   | This return is no longer amendable, use the claim option |

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see the text "This return is no longer amendable, use the claim option"
        And I should not see the text "You have until "
        And I should not see a link with text "Continue"

        When I click on the "Delete" link
        Then if available, click the confirmation dialog
        Then I should see the "Dashboard" page

        When I click on the "See all returns" link
        Then I should see the "All returns" page

        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I open the "Show more filter options" summary item
        And I select "Draft" from the "Return status"
        And I click on the "Find" button
        Then I should see the "All returns" page

    Scenario: To test the 3 year lease review return draft created prior to 12 months but does not submit until after the relevant date

        Create a 3 year lease review return
        Add a private individual tenant
        Add a property
        Add transaction details (Effective date of transaction to 1098 days & Relevant date is 2 days ago)
        Submit the return (BACS)

        Amend the return
        Submit the return to check that the non notifiable reason is not shown
        Retrieve the draft
        Save the draft
        Check the return is amendable
        Retrieve the draft


        Update the Effective date of transaction to 1490 days & Relevant date to 394 days ago
        Save the draft
        Check the message about amending by tomorrow is shown
        Retrieve the draft
        Update the Effective date of transaction to 1491 days & Relevant date to 395 days ago
        Save the draft
        Check the message about amending by today is shown
        retrieve the draft
        Update the Effective date of transaction to 1494 days & Relevant date to 398 days ago
        Save the draft
        Check the draft is no longer amendable
        Check the draft can be deleted

        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"

        #Step 1:  Create new return and check Amend is available
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        When I check the "3 year lease review" radio button
        And I click on the "Continue" button
        Then I should see the "Return reference number" page

        When I enter "RS2000003BBBB" in the "What was the original return reference" field
        And I enter "01-06-2020" in the "What was the original return effective date" date field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        # Allow intenational phone number
        And I enter "+12 123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I open the "Tenant does not have NINO" summary item
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field

        And I click on the "Continue" button
        Then I should see the "Tenant address" page
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Tenant address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Tenant address" page
        When I click on the "Continue" button
        Then I should see the "Tenant's contact address" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Add a property" link
        Then I should see the "Property address" page
        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Add transaction details" link
        Then I should see the "About the dates" page

        When I enter 36 months and 2 days ago in the "Effective date of transaction" date field
        And I enter 2 days ago in the "Relevant date" date field
        And I enter 1100 days ago in the "Lease start date" date field
        And I enter 1100 days in the future in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I enter "1234" in the "How much was the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        When I enter "100" in the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # submit
        When I click on the "Submit return" button
        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page

        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should store the reference from the notification panel as "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        When I click on the "See all returns" link
        Then I should see the "All returns" page

        When I enter the stored value "notification_banner_reference" in field "dashboard_dashboard_return_filter_tare_reference"
        And I click on the "Find" button
        Then I should see the "All returns" page

        When I click on the "Amend" link
        Then I should see the "Return Summary" page

        # Submit the return to check that the non notifiable reason is not shown on screen
        # The reason should not be shown as this is not the first version of the return (its an amendment) hence
        # the return is not treated as non notifiabe
        When I click on the "Submit return" button
        Then I should see the "Amendment reason" page
        When I enter "This is a test amendment reason" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button
        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page
        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should store the reference from the notification panel as "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        And I click on the "See all returns" link
        Then I should see the "All returns" page

        When I enter the stored value "notification_banner_reference" in field "dashboard_dashboard_return_filter_tare_reference"
        And I click on the "Find" button
        Then I should see the "All returns" page

        When I click on the "Amend" link
        Then I should see the "Return Summary" page

        # Submit the return to check that the non notifiable reason is not shown
        When I click on the "Submit return" button
        Then I should see the "Amendment reason" page
        When I enter "This is a test amendment reason" in the "Tell us why you are amending this return" field
        And I click on the "Continue" button
        Then I should see the "Repayment details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page
        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should store the reference from the notification panel as "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        And I click on the "See all returns" link
        Then I should see the "All returns" page

        When I enter the stored value "notification_banner_reference" in field "dashboard_dashboard_return_filter_tare_reference"
        And I click on the "Find" button
        Then I should see the "All returns" page

        When I click on the "Amend" link
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        And the table of data is displayed
            | Return reference              | Your reference | Description         | Version | Action_1 | Action_2     | Action_3 |
            | notification_banner_reference |                | 3 year lease review | 3       | Continue | Download PDF | Delete   |

        # Step 2: Save the created return in draft list with less than seven days left to submit return
        #         Check warning message is visible on screen
        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should not see the text "This return is no longer amendable, use the claim option"
        And I should not see the text "You have until TOMORROW_DATE to complete this draft"

        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        When I click on the "Edit transaction details" link
        Then I should see the "About the dates" page

        When I enter 1490 days ago in the "Effective date of transaction" date field
        And I enter 394 days ago in the "Relevant date" date field
        And I enter 1600 days ago in the "Lease start date" date field
        And I enter 1100 days in the future in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference              | Your reference | Description         | Version | Action_1 | Action_2     | Action_3 | Action_4                                            |
            | notification_banner_reference |                | 3 year lease review | 2       | Continue | Download PDF | Delete   | You have until TOMORROW_DATE to complete this draft |

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should not see the text "This return is no longer amendable, use the claim option"
        And I should see the text "You have until TOMORROW_DATE to complete this draft"

        # Test for allowing to submit drafted return until the relevant date
        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        When I click on the "Edit transaction details" link
        Then I should see the "About the dates" page

        When I enter 1491 days ago in the "Effective date of transaction" date field
        And I enter 395 days ago in the "Relevant date" date field
        And I enter 1600 days ago in the "Lease start date" date field
        And I enter 1100 days in the future in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference              | Your reference | Description         | Version | Action_1 | Action_2     | Action_3 | Action_4                                       |
            | notification_banner_reference |                | 3 year lease review | 2       | Continue | Download PDF | Delete   | You have until NOW_DATE to complete this draft |

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should not see the text "This return is no longer amendable, use the claim option"
        And I should see the text "You have until NOW_DATE to complete this draft"

        # Step 3: Amend saved return in draft list change date to after 12 months and 30 day to submit return
        #         Check return is not amendable warning message is visible on screen and "Continue" link is not available

        When I click on the "Continue" link
        Then I should see the "Return Summary" page
        When I click on the "Edit transaction details" link
        Then I should see the "About the dates" page

        When I enter 1494 days ago in the "Effective date of transaction" date field
        And I enter 398 days ago in the "Relevant date" date field
        And I enter 1600 days ago in the "Lease start date" date field
        And I enter 1100 days in the future in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I click on the "Continue" button
        Then I should see the "About the lease values" page
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        When I click on the "Save draft" button
        Then I should see the "Your return has been saved" page
        And I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference              | Your reference | Description         | Version | Action_1     | Action_2 | Action_3                                                 |
            | notification_banner_reference |                | 3 year lease review | 2       | Download PDF | Delete   | This return is no longer amendable, use the claim option |

        When I click on the "See all returns" link
        Then I should see the "All returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should see the text "This return is no longer amendable, use the claim option"
        And I should not see the text "You have until "
        And I should not see a link with text "Continue"

        When I click on the "Delete" link
        Then if available, click the confirmation dialog
        Then I should see the "Dashboard" page

        When I click on the "See all returns" link
        Then I should see the "All returns" page

        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I open the "Show more filter options" summary item
        And I select "Draft" from the "Return status"
        And I click on the "Find" button
        Then I should see the "All returns" page
        And I should not see a link with text "Continue"

    Scenario: To test no option when creating a return that is non notifable for authenticated

        Create a lease return
        Add a private individual tenant
        Add an other organisation landlord
        Add a property
        Add transaction details (Effective date of transaction to 1098 days & Relevant date is 2 days ago)
        Submit the return (Cheque)
        Reject the return as non notifiable

        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"

        # Create a lease return
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        When I check the "Lease" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add a private individual tenant
        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I enter "+12 123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I open the "Tenant does not have NINO" summary item
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field

        And I click on the "Continue" button
        Then I should see the "Tenant address" page
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Tenant address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Tenant address" page
        When I click on the "Continue" button
        Then I should see the "Tenant's contact address" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add an other organisation landlord
        When I click on the "Add a landlord" link
        Then I should see the "About the landlord" page
        When I check the "An other organisation" radio button
        And I click on the "Continue" button
        Then I should see the "Organisation details" page
        When I check the "Company" radio button
        And I click on the "Continue" button

        Then I should see the "Company" page
        And I should see the sub-title "Company details"

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"

        When I enter "Company name" in the "Name" field
        And I enter "ALBANIA" in the "What country's law is the organisation governed by" select or text field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Company" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Company" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "Company name"
        And I should see the text "Company"

        # Add a property
        When I click on the "Add a property" link
        Then I should see the "Property address" page
        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add transaction details (Effective date of transaction to 3 years and 2 days & Relevant date is 2 days ago)
        When I click on the "Add transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page

        When I enter 36 months and 2 days ago in the "Effective date of transaction" date field
        And I enter 2 days ago in the "Relevant date" date field
        And I enter 1400 days ago in the "Lease start date" date field
        And I enter 1400 days in the future in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I check the "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I enter "799" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        When I enter "1000" in the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Submit the return (Cheque)
        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page

        When I check the "Cheque" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_lease_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the "Non-notifiable return" page
        And I should see the text "The lease is for 7 years or more and the rent is less than £1,000 per annum or any chargeable consideration other than rent is less than £40,000."
        And I should see a link with text "notifiable lease transactions (opens in a new window)"
        And I should see a link with text "back to return summary"

        # Reject the return as non notifiable
        # Click on No button and should be redirected to Dashboard page
        When I click on the "Continue" button
        Then I should see the text "Do you still want to submit the return can't be blank"

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Dashboard" page

    Scenario: To test yes option when creating a return that is non notifable for authenticated

        Create a lease return
        Add a private individual tenant
        Add an other organisation landlord
        Add a property
        Add transaction details (Effective date of transaction to 1098 days & Relevant date is 2 days ago)
        Submit the return (BACS)
        Submit the return as non notifiable checking the validation on the non notifiable pages

        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"

        #Create a lease return
        When I click on the "Create LBTT return" menu item
        Then I should see the "About the return" page

        When I check the "Lease" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add a private individual tenant
        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        When I check the "A private individual" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I enter "+12 123456789" in the "Telephone number" field
        And I enter "noreply@necsws.com" in the "Email" field
        And I enter "GG778833C" in the "National Insurance Number (NINO)" field

        And I click on the "Continue" button
        Then I should see the "Tenant address" page
        When I enter "AB54 8SX" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Tenant address" page
        When I select "Sellars Agriculture Ltd, Steven Road, HUNTLY, AB54 8SX" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Tenant address" page
        When I click on the "Continue" button
        Then I should see the "Tenant's contact address" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Tenant details" page

        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add an other organisation landlord
        When I click on the "Add a landlord" link
        Then I should see the "About the landlord" page
        When I check the "An other organisation" radio button
        And I click on the "Continue" button
        Then I should see the "Organisation details" page
        # Company
        When I check the "Company" radio button
        And I click on the "Continue" button

        Then I should see the "Company" page
        And I should see the sub-title "Company details"

        When I click on the "Continue" button
        Then I should receive the message "Use the postcode search or enter the address manually"

        When I enter "Company name" in the "Name" field
        And I enter "ALBANIA" in the "What country's law is the organisation governed by" select or text field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Company" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Company" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click on the "Continue" button
        Then I should see the "Return Summary" page
        And I should see the text "Company name"
        And I should see the text "Company"

        # Add a property
        When I click on the "Add a property" link
        Then I should see the "Property address" page
        When I enter "EH12 6TS" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Property address" page
        When I select "Royal Zoological Society Of Scotland, 134 Corstorphine Road, EDINBURGH, EH12 6TS" from the "search_results"
        And if available, click the "Select" button
        Then I should see the "Property address" page
        When I click on the "Continue" button
        Then I should see the "About the property" page
        And I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Add transaction details (Effective date of transaction to 1098 days & Relevant date is 2 days ago)
        When I click on the "Add transaction details" link
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Continue" button
        Then I should see the "About the dates" page

        When I enter 36 months and 2 days ago in the "Effective date of transaction" date field
        And I enter 2 days ago in the "Relevant date" date field
        And I enter 1100 days ago in the "Lease start date" date field
        And I enter 1100 days in the future in the "Lease end date" date field
        And I click on the "Continue" button
        Then I should see the "About the transaction" page

        When I check the "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check the "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Continue" button
        Then I should see the "Linked transactions" page

        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I enter "800" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "Yes" radio button
        And I click on the "Continue" button
        Then I should see the "About the lease values" page
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        When I enter "100" in the "Net Present Value (NPV)" field
        And I click on the "Continue" button
        Then I should see the "Return Summary" page

        # Submit the return (BACS)
        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page

        When I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_lease_declaration" checkbox
        And I click on the "Submit return" button

        # Submit the return as non notifiable checking the validation on the non notifiable pages
        Then I should see the "Non-notifiable return" page
        And I should see the text "The lease is for less than 7 years and the chargeable consideration does not exceed the nil rate band so no tax is payable."
        And I should see a link with text "notifiable lease transactions (opens in a new window)"
        And I should see a link with text "back to return summary"
        When I click on the "Continue" button
        Then I should see the text "Do you still want to submit the return can't be blank"

        When I check the "Yes" radio button
        And I click on the "Continue" button

        # Enter the reason why the return is non notifiable
        Then I should see the "Non-notifiable return" page
        And I should see the text "Why are you submitting a non-notifiable return"

        When I click on the "Submit return" button
        Then I should see the text "Why are you submitting a non-notifiable return can't be blank"
        When I enter "RANDOM_text,4001" in the "Why are you submitting a non-notifiable return" field
        And I click on the "Submit return" button
        And I should see the text "Why are you submitting a non-notifiable return is too long (maximum is 4000 characters)"

        When I enter "abcd" in the "Why are you submitting a non-notifiable return" field
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
