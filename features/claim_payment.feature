Feature: Claim payment
    As a registered user
    I want to be able to claim a repayment if i have been filed return 12 months ago
    So that I can claim a repayment for LBTT return or SLFT return
    Scenario: Checking Claim repayment wizard functionality for LBTT ADS returns
        Given I have signed in 'PORTAL.ONE' and password 'Password1!'
        # A draft return
        When I click on the "All returns" link
        # A latest filed return that is over 12 months old
        And I enter "RS200002AAAAA" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Claim"
        # Claim payment wizard and validation
        And I click on the "Claim" link
        Then I should see the "Claim payment" page
        And I click on the "Next" button
        Then I should receive the message "What is the reason for your claim for payment from Revenue Scotland can't be blank"
        And I check the "ADS repayment following a sale or disposal of previous main residence" radio button
        And I click on the "Next" button

        Then I should see the "Date of sale or disposal" page
        And I click on the "Next" button
        Then I should receive the message "What is the date of sale or disposal of the previous main residence can't be blank"
        When I enter "2019-08-08" in the "What is the date of sale or disposal of the previous main residence" field
        And I click on the "Next" button

        Then I should see the "Main residence address" page
        And I click on the "Next" button
        Then I should see the text "Postcode search should be used, or the address should be entered manually"
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        Then I should see the "Further claim information" page
        And I click on the "Next" button
        Then I should receive the message "Is the tax payer claiming repayment as a result of the changes to the ADS rules around family units and replacing main residences can't be blank"
        When I check the "No" radio button
        And I click on the "Next" button

        Then I should see the "Details about your claim for payment" page
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue scotland can't be blank"
        Then I should receive the message "How much are you claiming from Revenue scotland is not a number"
        Then I should receive the message "How much are you claiming from Revenue scotland must be a number to 2 decimal places"

        When I enter "aaa" in the "How much are you claiming from Revenue scotland" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue scotland is not a number"

        When I enter "-34" in the "How much are you claiming from Revenue scotland" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue scotland must be greater than 0"

        When I enter "300.1234" in the "How much are you claiming from Revenue scotland" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue scotland must be a number to 2 decimal places"

        When I enter "1000000000000000000" in the "How much are you claiming from Revenue scotland" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming from Revenue scotland must be less than 1000000000000000000"

        When I enter "200" in the "How much are you claiming from Revenue scotland" field
        And I click on the "Next" button

        Then I should see the "Confirm tax payer details" page

        And I click on the "Next" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Telephone number can't be blank"
        And I should receive the message "National Insurance Number (NINO) can't be blank"

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

        Then I should see the "Confirm tax payer address" page
        And I click on the "Next" button
        Then I should see the text "Postcode search should be used, or the address should be entered manually"

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

        Then I should see the "Declarations" page
        When I click on the "Next" button
        Then I should receive the message "I, the agent for the taxpayers(s), confirm that the taxpayer(s) have authorised repayment to be made to these bank details must be accepted"
        And I should receive the message "I, the agent of the taxpayer(s), having been authorised to complete this claim form on behalf of the taxpayer(s), certify that the buyer(s) has/have declared that the information provided in the claim form is to the best of their knowledge, correct and complete, and confirm that the taxpayer(s) is/are eligible for the refund claimed must be accepted"
        And I check the "claim_claim_payment_agent_declaration" checkbox
        And I check the "claim_claim_payment_agent_second_declaration" checkbox
        When I click on the "Next" button

        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I should see a link with text "secure message"
        And I click on the "secure message" link
        Then I should see the "New message" page

        And I click on the "Back" link
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page



    Scenario: Checking Claim repayment wizard functionality for SLFT returns
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        When I click on the "All returns" link
        And I enter "RS1008001HalO" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see the text "Q1 2016"
        And I should see a link with text "Download"
        And I should see a link with text "Transactions"
        And I should see a link with text "Message"
        And I should see a link with text "Claim"

        And I click on the "Claim" link
        Then I should see the "Claim payment" page
        Then I check the "Claim for Repayment" radio button
        And I click on the "Next" button

        Then I should see the "Details about your claim for payment" page
        When I enter "200" in the "How much are you claiming from Revenue scotland" field
        And I click on the "Next" button
        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the "Declarations" page
        When I click on the "Next" button
        Then I should receive the message "I, the taxpayer(s), declare that this claim form is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the refund claimed must be accepted"
        And I check the "taxpayer" checkbox
        When I click on the "Next" button

        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I should see a link with text "secure message"
        And I should see a link with text "Go to dashboard"
        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

    Scenario: Checking Claim repayment wizard functionality for LBTT Non-ADS returns
        Given I have signed in 'PORTAL.ONE' and password 'Password1!'
        When I click on the "All returns" link
        And I enter "RS200002AAAAA" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Download"
        And I should see a link with text "Transactions"
        And I should see a link with text "Message"
        And I should see a link with text "Claim"

        And I click on the "Claim" link
        Then I should see the "Claim payment" page
        And I check the "Impact of legislation change" radio button
        And I click on the "Next" button

        Then I should see the "Details about your claim for payment" page
        When I enter "200" in the "How much are you claiming from Revenue scotland" field
        And I click on the "Next" button

        Then I should see the "Confirm tax payer details" page
        When I enter "landlord-surname" in the "Last name" field
        And I enter "ABC org" in the "Organisation Name (Optional)" field
        And I enter "lanlord firstname" in the "First name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "AN123456C" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button

        Then I should see the "Confirm tax payer address" page
        And I click on the "Next" button
        Then I should see the text "Postcode search should be used, or the address should be entered manually"

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the "Declarations" page
        When I click on the "Next" button
        Then I should receive the message "I, the agent for the taxpayers(s), confirm that the taxpayer(s) have authorised repayment to be made to these bank details must be accepted"
        And I should receive the message "I, the agent of the taxpayer(s), having been authorised to complete this claim form on behalf of the taxpayer(s), certify that the buyer(s) has/have declared that the information provided in the claim form is to the best of their knowledge, correct and complete, and confirm that the taxpayer(s) is/are eligible for the refund claimed must be accepted"
        And I check the "claim_claim_payment_agent_declaration" checkbox
        And I check the "claim_claim_payment_agent_second_declaration" checkbox
        When I click on the "Next" button
        Then I should see the "Your claim has been sent to Revenue Scotland" page
        And I should see a link with text "secure message"
        And I click on the "secure message" link
        Then I should see the "New message" page