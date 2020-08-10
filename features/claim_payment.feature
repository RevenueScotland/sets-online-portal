Feature: Claim payment
    As a registered or unauthenticated user
    I want to be able to claim or request a repayment
    So that I can claim a refund for a LBTT return or SLFT return
    Scenario: Public user ADS claim repayment less than 12 months with no agent and two taxpayers

        When I go to the "claim/claim_payments/public_claim_landing" page
        Then I should see the "Claim a repayment of Additional Dwelling Supplement" page

        When I click on the "Continue" link
        Then I should see the "Eligibility checker" page

        When I click on the "Continue" button
        Then I should see the text "Please confirm the following criteria are met in order to proceed with the application must be accepted"

        When I check the "ADS was paid on the new property purchase" checkbox
        And I check the "The previous property was sold within 18 months of buying the new one" checkbox
        And I check the "The new property is, or has been, the only or main residence of all buyers" checkbox
        And I check the "The previous property was the only or main residence of all buyers of the new property at some time in the 18 month period before the new property was purchased" checkbox
        And I click on the "Continue" button
        Then I should see the "Before you start" page

        When I click on the "Start now" button
        Then I should see the "Return reference" page

        # Check back behaviour
        When I click on the "Back" link
        Then I should see the "Before you start" page
        When I click on the "Back" link
        Then I should see the "Eligibility checker" page
        # Check we haven't lost the data on the eligibility check page
        And I click on the "Continue" button
        Then I should see the "Before you start" page
        When I click on the "Back" link
        Then I should see the "Eligibility checker" page
        When I click on the "Back" link
        Then I should see the "Claim a repayment of Additional Dwelling Supplement" page
        # Now data is lost
        When I click on the "Continue" link
        Then I should see the "Eligibility checker" page

        When I click on the "Continue" button
        Then I should see the text "Please confirm the following criteria are met in order to proceed with the application must be accepted"

        When I check the "ADS was paid on the new property purchase" checkbox
        And I check the "The previous property was sold within 18 months of buying the new one" checkbox
        And I check the "The new property is, or has been, the only or main residence of all buyers" checkbox
        And I check the "The previous property was the only or main residence of all buyers of the new property at some time in the 18 month period before the new property was purchased" checkbox
        And I click on the "Continue" button
        Then I should see the "Before you start" page
        When I click on the "Start now" button
        Then I should see the "Return reference" page

        # check error where ads claim is open
        When I enter "RS2000003BBBB" in the "What was the tax return reference of your new property purchase ?" field
        And I click on the "Continue" button
        Then I should see the text "This reference number is not recognised. Please contact us for assistance with this claim"

        # pick the working return
        When I enter "RS3000002AAAA" in the "What was the tax return reference of your new property purchase ?" field
        And I click on the "Continue" button
        Then I should see the "Your previous main residence" page

        When I enter "NP7 8LB" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Grosmont Wood Farm, Grosmont, ABERGAVENNY, NP7 8LB" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Continue" button

        When I enter "08-08-2020" in the "What is the date of sale or disposal of the previous main residence" date field
        And I click on the "Continue" button

        Then I should see the "Evidence to support your claim" page
        And I should see the text "Evidence all buyers occupied the previous property as their only or main residence at any time between January 01, 2016 and July 01, 2017"

        When I click on the "Continue" button
        Then I should receive the message "A document must be uploaded for each category in order to make a valid ADS Repayment request"

        When I upload "testjpg.jpg" to "resource_item_occupancy_file_data"
        And I click on the "Upload document" button
        Then I should see a link with text "testjpg.jpg"
        And I should receive the message "File can't be blank"
        # Check we don't lose the file
        When I click on the "Upload document" button
        Then I should see a link with text "testjpg.jpg"
        And I should receive the message "File can't be blank"
        # Upload the other file
        When I upload "testdoc.doc" to "resource_item_sale_file_data"
        And I click on the "Upload document" button
        Then I should see a link with text "testjpg.jpg"
        And I should see a link with text "testdoc.doc"
        And I should not receive the message "File can't be blank"
        # Clear the files and check that they are gone
        When I click on the 1 st "Remove file" button
        And I click on the 1 st "Remove file" button
        And I click on the "Continue" button
        Then I should receive the message "A document must be uploaded for each category in order to make a valid ADS Repayment request"
        # Upload two files and carry on
        When I upload "testjpg.jpg" to "resource_item_occupancy_file_data"
        When I upload "testdoc.doc" to "resource_item_sale_file_data"
        And I click on the "Upload document" button
        Then I should see a link with text "testjpg.jpg"
        And I should see a link with text "testdoc.doc"

        When I click on the "Continue" button
        Then I should see the "Claim amount" page

        When I click on the "Continue" button
        Then I should receive the message "claiming for a full repayment of ADS can't be blank"
        When I check the "No" radio button
        And I click on the "Continue" button
        Then I should receive the message "Claiming amount can't be blank"
        When I enter "600" in the "I am eligible for partial repayment of ADS and wish to reclaim the following amount" field
        And I click on the "Continue" button
        # ads amount is 100 so it should be less than 100
        Then I should receive the message "Claim amount cannot be greater than the amount of ADS paid"
        When I enter "60" in the "I am eligible for partial repayment of ADS and wish to reclaim the following amount" field
        And I click on the "Continue" button

        # Since RS3000002AAAA has number of buyer is 5
        Then I should see the "Your details (buyer 1 of 5)" page
        And I should not see the text "Organisation name (optional)"

        When I enter "First name" in the "First name" field
        And I enter "Last tname" in the "Last name" field
        And I enter "0111456789" in the "Telephone number" field
        And I enter "noreply5@northgateps.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Your address (buyer 1 of 5)" page

        When I click on the "Continue" button

        Then I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Continue" button

        Then I should see the "Buyer details (buyer 2 of 5)" page

        When I enter "Buyer 2 First name" in the "First name" field
        And I enter "Buyer 2 Last tname" in the "Last name" field
        And I click on the "Continue" button
        Then I should see the "Buyer address (buyer 2 of 5)" page
        When I check the "Yes" radio button
        And I click on the "Continue" button

        Then I should see the "Buyer details (buyer 3 of 5)" page

        When I enter "Buyer 3 First name" in the "First name" field
        And I enter "Buyer 3 Last tname" in the "Last name" field
        And I click on the "Continue" button
        Then I should see the "Buyer address (buyer 3 of 5)" page
        When I check the "No" radio button

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Continue" button

        Then I should see the "Buyer details (buyer 4 of 5)" page

        When I enter "Buyer 4 First name" in the "First name" field
        And I enter "Buyer 4 Last tname" in the "Last name" field
        And I click on the "Continue" button
        Then I should see the "Buyer address (buyer 4 of 5)" page
        When I check the "No" radio button

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Continue" button


        Then I should see the "Buyer details (buyer 5 of 5)" page

        When I enter "Additional Buyer First name" in the "First name" field
        And I enter "Additional Buyer Last tname" in the "Last name" field
        And I click on the "Continue" button
        Then I should see the "Buyer address (buyer 5 of 5)" page
        When I check the "No" radio button

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Continue" button

        Then I should see the "Bank details" page
        When I click on the "Continue" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Continue" button

        Then I should see the "Declarations" page
        When I click on the "Continue" button
        Then I should receive the message "The declaration must be accepted"
        And I check the "I, First name Last tname, declare that this claim is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the repayment claimed" checkbox
        And I check the "I, Buyer 2 First name Buyer 2 Last tname, declare that this claim is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the repayment claimed" checkbox
        And I check the "I, Buyer 3 First name Buyer 3 Last tname, declare that this claim is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the repayment claimed" checkbox
        And I check the "I, Buyer 4 First name Buyer 4 Last tname, declare that this claim is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the repayment claimed" checkbox
        And I check the "I, Additional Buyer First name Additional Buyer Last tname, declare that this claim is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the repayment claimed" checkbox

        When I click on the "Continue" button
        Then I should see the "Your request has been sent to Revenue Scotland" page
    Scenario: Checking Claim repayment wizard functionality for LBTT ADS returns with one tax payer
        Given I have signed in 'PORTAL.ONE' and password 'Password1!'
        # A draft return
        When I click on the "All returns" link

        And I enter "RS2000003BBBB" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Claim"

        # Claim payment wizard and validation
        When I click on the "Claim" link
        Then I should see the "Claim repayment" page
        And I should not see the text "ADS repayment following a sale or disposal of previous main residence"
        When I click on the "Back" link
        Then I should see the "All returns" page
        And I should see the text "RS2000003BBBB"
        And I should see the text "Filed"
        And I should see a link with text "Claim"

        # A latest filed return that is over 12 months old
        And I enter "RS2000002AAAA" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Claim"
        # Claim payment wizard and validation
        And I click on the "Claim" link
        Then I should see the "Claim repayment" page
        And I click on the "Continue" button
        And I should see the text "What is the reason for the claim for payment from Revenue Scotland can't be blank"

        And I check the "ADS repayment following a sale or disposal of previous main residence" radio button
        And I click on the "Continue" button
        Then I should see the "Previous main residence" page

        When I enter "NP7 8LB" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Grosmont Wood Farm, Grosmont, ABERGAVENNY, NP7 8LB" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Continue" button

        When I enter "08-08-2020" in the "What was the date of sale or disposal of the previous main residence" date field
        And I click on the "Continue" button

        Then I should see the "Evidence to support the claim" page

        When I upload "testjpg.jpg" to "resource_item_portal_sale_file_data"
        When I upload "testjpg.jpg" to "resource_item_occupancy_file_data"
        And I click on the "Upload document" button
        Then I should see a link with text "testjpg.jpg"
        And I click on the "Continue" button

        Then I should see the "Claim amount" page
        And I click on the "Continue" button
        Then I should receive the message "claiming for a full repayment of ADS can't be blank"
        When I check the "Yes" radio button
        And I click on the "Continue" button

        # Since RS2000002AAAA has number of buyer is 1
        Then I should see the "Taxpayer details" page
        And I should not see the text "Organisation name (optional)"

        When I enter "First name" in the "First name" field
        And I enter "Last tname" in the "Last name" field
        And I enter "0111456789" in the "Telephone number" field
        And I enter "noreply5@northgateps.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Taxpayer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button

        When I click on the "Continue" button
        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Continue" button

        Then I should see the "Declarations" page
        When I click on the "Continue" button
        Then I should receive the message "The declaration must be accepted"
        And I check the "claim_claim_payment_authenticated_declaration_1" checkbox
        And I check the "claim_claim_payment_authenticated_declaration_2" checkbox

        When I click on the "Continue" button
        Then I should see the "Your request has been sent to Revenue Scotland" page
        Then I should not see a link with text "testjpg.jpg"

    Scenario: Checking Claim repayment wizard functionality for LBTT Non ADS returns with one tax payer
        Given I have signed in 'PORTAL.ONE' and password 'Password1!'
        # A draft return
        When I click on the "All returns" link

        And I enter "RS2000003BBBB" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Claim"
        # Claim payment wizard and validation
        And I click on the "Claim" link
        Then I should see the "Claim repayment" page

        And I check the "Impact of legislation change" radio button
        And I click on the "Continue" button

        Then I should see the "Evidence to support the claim" page
        And I click on the "Continue" button

        Then I should see the "Details about your request for repayment" page
        And I click on the "Continue" button
        Then I should receive the message "Claiming amount can't be blank"

        When I enter "90" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Continue" button

        # Since RS3000002AAAA has number of buyer is 1
        Then I should see the "Taxpayer details" page

        When I enter "My organisation" in the "Organisation name (optional)" field
        When I enter "First name" in the "First name" field
        And I enter "Last tname" in the "Last name" field
        And I enter "0111456789" in the "Telephone number" field
        And I enter "noreply5@northgateps.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Taxpayer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button

        When I click on the "Continue" button
        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Continue" button

        Then I should see the "Declarations" page
        When I click on the "Continue" button
        Then I should receive the message "The declaration must be accepted"
        And I check the "claim_claim_payment_authenticated_declaration_1" checkbox
        And I check the "claim_claim_payment_authenticated_declaration_2" checkbox

        When I click on the "Continue" button
        Then I should see the "Your request has been sent to Revenue Scotland" page

    Scenario: Checking Claim repayment wizard functionality for SLFT returns one tax payer
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        # A draft return
        When I click on the "All returns" link

        And I enter "RS1008001HALO" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Claim"
        # Claim payment wizard and validation
        And I click on the "Claim" link
        Then I should see the "Claim repayment" page

        And I check the "Claim for Repayment" radio button
        And I click on the "Continue" button

        Then I should see the "Evidence to support the claim" page
        When I upload "testjpg.jpg" to "resource_item_default_file_data"
        And I click on the "Upload document" button
        Then I should see a link with text "testjpg.jpg"
        And I click on the "Continue" button

        Then I should see the "Details about your request for repayment" page
        And I click on the "Continue" button
        Then I should receive the message "Claiming amount can't be blank"

        When I enter "90" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Continue" button

        # Since RS1008001HALO has number of buyer is 1
        Then I should see the "Taxpayer details" page

        When I enter "First name" in the "First name" field
        And I enter "Last tname" in the "Last name" field
        And I enter "0111456789" in the "Telephone number" field
        And I enter "noreply5@northgateps.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Taxpayer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button

        When I click on the "Continue" button
        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Continue" button

        Then I should see the "Declarations" page
        When I click on the "Continue" button
        Then I should receive the message "The declaration must be accepted"
        And I check the "claim_claim_payment_authenticated_declaration_1" checkbox
        And I check the "claim_claim_payment_authenticated_declaration_2" checkbox

        When I click on the "Continue" button
        Then I should see the "Your request has been sent to Revenue Scotland" page
        Then I should not see a link with text "testjpg.jpg"

        # Check the file uploads on the final page
        When I upload "testdoc.doc" to "resource_item_default_file_data"
        And I click on the "Upload document" button
        Then I should see the text "testdoc.doc"
        When I click on the "Remove file" button
        Then I should not see the text "testdoc.doc"

        # Upload multiple file types
        When I upload "testdoc.doc" to "resource_item_default_file_data"
        And I click on the "Upload document" button
        And I upload "testpng.png" to "resource_item_default_file_data"
        And I click on the "Upload document" button
        Then the table of data is displayed
            | File uploaded |             |
            | testdoc.doc   | Remove file |
            | testpng.png   | Remove file |

        When I click on the 1 st "Remove file" button
        Then the table of data is displayed
            | File uploaded |             |
            | testpng.png   | Remove file |
        And I should not see the text "testdoc.doc"
