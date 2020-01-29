Feature: Claim payment
    As a registered or unauthenticated user
    I want to be able to claim or request a repayment
    So that I can claim a refund for a LBTT return or SLFT return

    Scenario: Checking Claim repayment wizard functionality for LBTT ADS returns with two tax payers
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
        And I should not see the text "ADS repayment following a sale or disposal of previous main residence"
        And I click on the "Back" link

        # A latest filed return that is over 12 months old
        And I enter "RS2000002AAAA" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Claim"
        # Claim payment wizard and validation
        And I click on the "Claim" link
        Then I should see the "Claim repayment" page
        And I click on the "Next" button
        Then I should receive the message "What is the reason for your claim for payment from Revenue Scotland can't be blank"
        And I check the "ADS repayment following a sale or disposal of previous main residence" radio button
        And I click on the "Next" button

        Then I should see the "ADS repayment - date of sale or disposal" page
        And I click on the "Next" button
        Then I should receive the message "What is the date of sale or disposal of the previous main residence can't be blank"
        When I enter "08-08-2019" in the "What is the date of sale or disposal of the previous main residence" date field
        And I click on the "Next" button

        Then I should see the "ADS repayment - previous main residence address" page
        And I click on the "Next" button
        Then I should see the text "Use the postcode search or enter the address manually"
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the text "This address does not match the one provided on the original return"
        And I click on the "Change" button

        When I enter "NP7 8LB" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Grosmont Wood Farm, Grosmont, ABERGAVENNY, NP7 8LB" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "ADS repayment - further claim information" page
        And I click on the "Next" button
        Then I should receive the message "Is the tax payer claiming repayment as a result of the changes to the ADS rules around family units and replacing main residences can't be blank"
        When I check the "No" radio button
        And I click on the "Next" button

        Then I should see the "Details about your claim for repayment" page
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue Scotland can't be blank"

        When I enter "aaa" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue Scotland is not a number"

        When I enter "-34" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue Scotland must be greater than 0"

        When I enter "300.1234" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue Scotland must be a number to 2 decimal places"

        When I enter "1000000000000000000" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue Scotland must be less than 1000000000000000000"

        When I enter "200" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button

        Then I should see the "Tax payer details" page

        And I click on the "Next" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Telephone number can't be blank"

        When I enter "landlord-surname" in the "Last name" field
        And I enter "lanlord firstname" in the "First name" field
        And I enter "1234" in the "Telephone number" field
        And I enter "noreplnorthgateps.com" in the "Email" field
        And I enter "AN1236C" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button

        Then I should see the text "Email is invalid"
        And I should see the text "Telephone number is invalid"
        And I should see the text "National Insurance Number (NINO) is invalid"

        And I click on the "Next" button

        When I enter "landlord-surname" in the "Last name" field
        And I enter "lanlord firstname" in the "First name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "AN123456C" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button

        Then I should see the "Tax payer address" page
        And I click on the "Next" button
        Then I should see the text "Use the postcode search or enter the address manually"

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "Additional tax payer" page
        When I check the "Yes" radio button
        And I click on the "Next" button

        Then I should see the "Tax payer details" page

        When I enter "Second-surname" in the "Last name" field
        And I enter "Second-firstname" in the "First name" field
        And I enter "0234567899" in the "Telephone number" field
        And I enter "noreply2@northgateps.com" in the "Email" field
        And I enter "AN123456D" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button

        Then I should see the "Tax payer address" page
        And I click on the "Next" button
        Then I should see the text "Use the postcode search or enter the address manually"

        When I enter "RG1 1PB" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "10a Stanshawe Road, READING, RG1 1PB" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "Enter bank details" page

        When I click on the "Next" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "RANDOM_text,256" in the "Name of the account holder" field
        And I enter "RANDOM_text,11" in the "Bank / building society account number" field
        And I enter "22=22=22=2" in the "Branch sort code" field
        And I enter "RANDOM_text,256" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the text "Bank / building society account number is not a number"
        And I should see the text "Bank / building society account number is the wrong length (should be 8 characters)"
        And I should see the text "Branch sort code is invalid"

        When I enter "RANDOM_text,256" in the "Name of the account holder" field
        And I enter "123456789" in the "Bank / building society account number" field
        And I enter "11@11@11" in the "Branch sort code" field
        And I enter "RANDOM_text,256" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the text "Bank / building society account number is the wrong length (should be 8 characters)"
        And I should see the text "Branch sort code is invalid"

        When I enter "RANDOM_text,256" in the "Name of the account holder" field
        And I enter "1234" in the "Bank / building society account number" field
        And I enter "85-96-88-74-14" in the "Branch sort code" field
        And I enter "RANDOM_text,256" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the text "Bank / building society account number is the wrong length (should be 8 characters)"
        And I should see the text "Branch sort code is invalid"

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the "Upload evidence to support your repayment request" page

        # Uploading a valid docx attachment
        When I upload "testdocx.docx" to "resource_item_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button

        When I click on the "Next" button

        And I click on the "Back" link
        Then I should see the "Upload evidence to support your repayment request" page
        And I should see a link with text "testdocx.docx"
        When I click on the "Next" button

        Then I should see the "Declarations" page
        When I click on the "Next" button
        Then I should receive the message "The declaration must be accepted"
    # Do not submit the ADS claim as it will stop processing on the next run as open ADS will exist

    Scenario: Checking Claim repayment wizard functionality for SLFT returns
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        When I click on the "All returns" link
        And I enter "RS1008001HalO" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see the text "Q1 2016"
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        And I should see a link with text "Transactions"
        And I should see a link with text "Message"
        And I should see a link with text "Claim"

        And I click on the "Claim" link
        Then I should see the "Claim repayment" page
        Then I check the "Claim for Repayment" radio button
        And I click on the "Next" button

        Then I should see the "Details about your claim for repayment" page
        When I enter "200" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button
        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the "Upload evidence to support your repayment request" page

        # Uploading a valid pdf attachment
        When I upload "testpdf.pdf" to "resource_item_file_data"
        And I click on the "Upload document" button
        Then I should see a link with text "testpdf.pdf"
        When I click on the "Remove file" button
        Then I should not see a link with text "testpdf.pdf"

        # Uploading file with file size that is too big
        When I upload "testimage_over_size_limit.jpg" to "resource_item_file_data" on the browser
        Then I should receive the message "File should be less than 10 mb" on the browser

        # Uploading invalid file type
        When I upload "testtxt_invalid_file_type.txt" to "resource_item_file_data"
        And I click on the "Upload document" button
        Then I should receive the message "Invalid file type"

        When I upload "testrtf.rtf" to "resource_item_file_data"
        And I enter "This is a doc file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button
        Then I should see a link with text "testrtf.rtf"
        And the table of data is displayed
            | File uploaded | Description        |             |
            | testrtf.rtf   | This is a doc file | Remove file |
        When I click on the "Remove file" button
        Then I should not see the text "testdoc.doc"
        And I should not see the text "This is a doc file"

        # Uploading a valid docx attachment
        When I upload "testdocx.docx" to "resource_item_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button

        When I click on the "Next" button

        Then I should see the "Declarations" page
        When I click on the "Next" button
        And I should receive the message "The declaration must be accepted"
        And I check the "claim_claim_payment_declaration_public" checkbox
        And I check the "claim_claim_payment_declaration" checkbox
        When I click on the "Next" button

        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I click on the "Finish" button
        Then I should receive the message "Do you want to upload any more documents can't be blank"
        When I check the "Yes" radio button

        When I upload "testtiff.tiff" to "resource_item_file_data"
        And I enter "Test tiff image file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button
        Then I should see a link with text "testtiff.tiff"
        When I click on the "Remove file" button
        Then I should not see a link with text "testtiff.tiff"

        When I upload "testxls.xls" to "resource_item_file_data"
        And I enter "Test xls excel spreadsheet file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button
        Then I should see a link with text "testxls.xls"

        When I upload "testxlsx.xlsx" to "resource_item_file_data"
        And I enter "Test xlsx excel spreadsheet file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button
        Then I should see a link with text "testxlsx.xlsx"

        # Uploading file with file size that is too big
        When I upload "testimage_over_size_limit.jpg" to "resource_item_file_data" on the browser
        Then I should receive the message "File should be less than 10 mb" on the browser

        # Uploading invalid file type
        When I upload "testtxt_invalid_file_type.txt" to "resource_item_file_data"
        And I click on the "Upload document" button
        Then I should receive the message "Invalid file type"

        And the table of data is displayed
            | File uploaded | Description                      |             |
            | testxls.xls   | Test xls excel spreadsheet file  | Remove file |
            | testxlsx.xlsx | Test xlsx excel spreadsheet file | Remove file |

        When I check the "No" radio button
        And I click on the "Finish" button

        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I should see a link with text "Print confirmation details"
        And I should see a link with text "Download details of repayment claim"

        # Download test for the slft claim pdf
        When I click on the "Download details of repayment claim" link to download a file
        Then I should see the downloaded "CLAIM" content of "SLFT"
        And I should see the "Your claim has been sent to Revenue Scotland" page

    Scenario: Checking Claim repayment wizard functionality for LBTT Non-ADS returns
        Given I have signed in 'PORTAL.ONE' and password 'Password1!'
        When I click on the "All returns" link
        And I enter "RS2000002AAAA" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Download PDF"
        And I should not see a link with text "Download waste details"
        And I should see a link with text "Transactions"
        And I should see a link with text "Message"
        And I should see a link with text "Claim"

        And I click on the "Claim" link
        Then I should see the "Claim repayment" page
        And I check the "Impact of legislation change" radio button
        And I click on the "Next" button

        Then I should see the "Details about your claim for repayment" page
        When I enter "200" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button

        Then I should see the "Tax payer details" page
        When I enter "landlord-surname" in the "Last name" field
        And I enter "ABC org" in the "Organisation name (Optional)" field
        And I enter "lanlord firstname" in the "First name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "AN123456C" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button

        Then I should see the "Tax payer address" page
        And I click on the "Next" button
        Then I should see the text "Use the postcode search or enter the address manually"

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "Additional tax payer" page
        When I check the "No" radio button
        And I click on the "Next" button

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the "Upload evidence to support your repayment request" page
        # Uploading a valid docx attachment
        When I upload "testdocx.docx" to "resource_item_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button

        When I click on the "Next" button

        Then I should see the "Declarations" page
        When I click on the "Next" button
        Then I should receive the message "The declaration must be accepted"
        And I check the "claim_claim_payment_declaration_public" checkbox
        And I check the "claim_claim_payment_declaration" checkbox
        When I click on the "Next" button

        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I click on the "Finish" button
        Then I should receive the message "Do you want to upload any more documents can't be blank"
        When I check the "No" radio button
        And I click on the "Finish" button

        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I should see a link with text "Print confirmation details"
        And I should see a link with text "Download details of repayment claim"

        # Download test for the lbtt claim pdf
        When I click on the "Download details of repayment claim" link to download a file
        Then I should see the downloaded "CLAIM" content of "LBTT"
        And I should see the "Your claim has been sent to Revenue Scotland" page

    Scenario: Public user ADS claim repayment greater than 12 months submitting non ADS for non tax payer with an Agent and one taxpayer

        When I go to the "claim/claim_payments/public_claim_landing" page
        Then I should see the "To complete this ADS repayment/ claim request, you will need the following information:" page

        When I click on the "Create repayment request" link
        Then I should see the "Return reference number" page

        And I enter "RS1000503YQVY" in the "What was the original reference of the return that you are requesting an ADS repayment or claim for " field
        And I click on the "Next" button
        Then I should receive the message "Return does not exist"

        # check error where claim prior to 12 months and not conveyance
        When I enter "RS3000003EEEE" in the "What was the original reference of the return that you are requesting an ADS repayment or claim for " field
        And I click on the "Next" button
        Then I should receive the message "Claim requests within 12 months of filing are not supported for this type of Return. Contact Revenue Scotland for more information"

        # check error where ads claim is open
        When I enter "RS3000002AAAA" in the "What was the original reference of the return that you are requesting an ADS repayment or claim for " field
        And I click on the "Next" button
        Then I should see the "Claim repayment" page
        When I check the "ADS repayment following a sale or disposal of previous main residence" radio button
        And I click on the "Next" button
        Then I should receive the message "An ADS repayment already exists for this return"

        # Pick a working return
        When I click on the "Back" link
        And I enter "RS2000002AAAA" in the "What was the original reference of the return that you are requesting an ADS repayment or claim for " field
        And I click on the "Next" button
        Then I should see the "Claim repayment" page
        And I should see the text "ADS repayment following a sale or disposal of previous main residence"
        When I check the "Other" radio button
        And I click on the "Next" button
        Then I should see the text "Claim description can't be blank"
        And I enter "test" in the "Claim description" field
        And I click on the "Next" button
        Then I should see the "Details about your claim for repayment" page

        When I enter "200" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button
        Then I should see the "Claimant information" page

        When I check the "No" radio button
        And I click on the "Next" button
        Then I should see the "Agent details" page

        When I enter "Agent-surname" in the "Last name" field
        And I enter "Agent firstname" in the "First name" field
        And I enter "0123456777" in the "Telephone number" field
        And I enter "noreply3@northgateps.com" in the "Email" field
        And I enter "Agent 1" in the "DX number and exchange" field
        And I click on the "Next" button

        Then I should see the "Agent address" page
        And I click on the "Next" button
        Then I should see the text "Use the postcode search or enter the address manually"

        When I enter "RG30 6XT" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "12 Rydal Avenue, Tilehurst, READING, RG30 6XT" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "Tax payer details" page

        When I enter "My organisation" in the "Organisation name (Optional)" field
        And I enter "Contact-surname" in the "Last name" field
        And I enter "Contact firstname" in the "First name" field
        And I enter "0122256789" in the "Telephone number" field
        And I enter "noreply1@northgateps.com" in the "Email" field
        And I enter "NP123456D" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button

        Then I should see the "Tax payer address" page
        And I click on the "Next" button
        Then I should see the text "Use the postcode search or enter the address manually"

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "Additional tax payer" page
        When I check the "No" radio button
        And I click on the "Next" button

        Then I should see the "Enter bank details" page

        When I click on the "Next" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the "Upload evidence to support your repayment request" page

        # Uploading a valid docx attachment
        When I upload "testdocx.docx" to "resource_item_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button

        When I click on the "Next" button

        Then I should see the "Declarations" page
        When I click on the "Next" button
        Then I should receive the message "The declaration must be accepted"
        And I check the "claim_claim_payment_declaration_public" checkbox
        And I check the "claim_claim_payment_declaration" checkbox
        When I click on the "Next" button
        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I click on the "Finish" button
        Then I should receive the message "Do you want to upload any more documents can't be blank"
        When I check the "No" radio button
        And I click on the "Finish" button

        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I should see a link with text "Print confirmation details"
        And I should see a link with text "Download details of repayment claim"

    Scenario: Public user ADS claim repayment less than 12 months with no agent and two taxpayers

        When I go to the "claim/claim_payments/public_claim_landing" page
        Then I should see the "To complete this ADS repayment/ claim request, you will need the following information:" page

        When I click on the "Create repayment request" link
        Then I should see the "Return reference number" page

        # check error where ads claim is open
        When I enter "RS3000004DDDD" in the "What was the original reference of the return that you are requesting an ADS repayment or claim for " field
        And I click on the "Next" button
        Then I should see the text "An ADS repayment already exists for this return"

        # pick the working return
        When I enter "RS2000004DDDD" in the "What was the original reference of the return that you are requesting an ADS repayment or claim for " field
        And I click on the "Next" button
        Then I should see the "ADS repayment - date of sale or disposal" page

        When I enter "08-08-2019" in the "What is the date of sale or disposal of the previous main residence" date field
        And I click on the "Next" button
        Then I should see the "ADS repayment - previous main residence address" page

        When I enter "NP7 8LB" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Grosmont Wood Farm, Grosmont, ABERGAVENNY, NP7 8LB" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "ADS repayment - further claim information" page
        When I check the "No" radio button
        And I click on the "Next" button

        Then I should see the "Details about your request for repayment" page
        When I enter "600" in the "How much are you claiming from Revenue Scotland" field
        And I click on the "Next" button

        Then I should see the "Claimant information" page

        When I check the "Yes" radio button
        And I click on the "Next" button
        Then I should see the "Tax payer details" page
        And I should not see the text "Organisation name (Optional)"

        When I enter "First-surname" in the "Last name" field
        And I enter "First firstname" in the "First name" field
        And I enter "0111456789" in the "Telephone number" field
        And I enter "noreply5@northgateps.com" in the "Email" field
        And I clear the "National Insurance Number (NINO)" field
        And I click on the "Next" button
        Then I should see the "Tax payer address" page

        When I click on the "Next" button
        Then I should see the text "Use the postcode search or enter the address manually"

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "Additional tax payer" page
        When I check the "Yes" radio button
        And I click on the "Next" button

        Then I should see the "Tax payer details" page

        When I enter "Second-surname" in the "Last name" field
        And I enter "second firstname" in the "First name" field
        And I enter "0123466789" in the "Telephone number" field
        And I enter "noreply5@northgateps.com" in the "Email" field
        And I enter "NP123457C" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button

        Then I should see the "Tax payer address" page
        And I click on the "Next" button
        Then I should see the text "Use the postcode search or enter the address manually"

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "Enter bank details" page

        When I click on the "Next" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the "Upload evidence to support your repayment request" page

        # Uploading a valid docx attachment
        When I upload "testdocx.docx" to "resource_item_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (Optional)" field
        And I click on the "Upload document" button

        When I click on the "Next" button

        Then I should see the "Declarations" page
        When I click on the "Next" button
        Then I should receive the message "The declaration must be accepted"
# Do not submit the ADS claim as it will stop processing on the next run as open ADS will exist

