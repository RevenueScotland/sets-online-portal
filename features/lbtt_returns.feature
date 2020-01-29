# feature/lbtt_returns.feature
Feature: LBTT Returns
    As a user
    I want to be able to make a Lbtt return
    Scenario: Property wizard
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page

        # Mandatory validation for selection of lbtt return type
        When I click on the "Next" button
        Then I should receive the message "Which return do you want to submit can't be blank"
        When I check "Conveyance or transfer" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        When I click on the "Add" link with id "add_property"
        Then I should see the "Property address" page
        And I click on the "Next" button

        # validation to select address
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"
        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "First Scotrail Ltd" in field "address_address_line1"
        And I should see the text "Waverley Railway Station" in field "address_address_line2"
        # And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1BE" in field "address_postcode"
        And I click on the "Next" button

        # Validation to select property details
        Then I should see the sub-title "Provide property details"
        And I click on the "Next" button
        Then I should receive the message "Local authority can't be blank"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I select "ANG" from the "returns_lbtt_property_parent_title_code"
        And I enter "4567" in the "returns_lbtt_property_parent_title_number" field
        And I click on the "Next" button

        # validation for ADS applies
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page
        And I click on the "Next" button
        Then I should receive the message "Does Additional Dwelling Supplement (ADS) apply to this transaction can't be blank"
        And I check "No" radio button
        And I click on the "Next" button

        # Verify entered details on return summary page
        Then I should see the "Return Summary" page
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                                | ADS? |
            | First Scotrail Ltd, EDINBURGH, EH1 1BE | No   |
        And I should not see the text "About the Additional Dwelling Supplement"

        # Go back and check a form still has data and modify it
        When I click on the 1 st "Edit row" link
        Then I should see the "Property address" page
        And I should see the text "First Scotrail Ltd" in field "address_address_line1"
        And I should see the text "Waverley Railway Station" in field "address_address_line2"
        # And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1BE" in field "address_postcode"
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"
        Then "Local authority" should contain the option "Aberdeen City"
        Then I should see the text "1234" in field "returns_lbtt_property[title_number]"
        When I select "Orkney" from the "Local authority"
        And I enter "4567" in the "returns_lbtt_property[title_number]" field

        And I click on the "Next" button
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page
        And I check the "Yes" radio button
        And I click on the "Next" button

        # Verify modified details on return summary page
        Then I should see the "Return Summary" page
        And I should see the text "First Scotrail Ltd, EDINBURGH, EH1 1BE"
        And I should see the text "Yes"

        # delete it
        When I click on the "Delete row" link
        Then if available, click the confirmation dialog
        Then I should see the "Return Summary" page
        And I should not see the text "ABN 4567"
        And I should not see the text "First Scotrail Ltd, EDINBURGH, EH1 1BE"
        And I should not see the text "report this error"

    Scenario: Postcode Check For Manual Address
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page

        # Mandatory validation for selection of lbtt return type
        When I click on the "Next" button
        Then I should receive the message "Which return do you want to submit can't be blank"
        When I check "Conveyance or transfer" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        When I click on the "Add" link with id "add_property"
        Then I should see the "Property address" page
        And I click on the "Next" button

        # validation to select address
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"
        When click on the "Enter an address manually" button
        And enter "8 Lavender Lane" in the "address_address_line1" field
        And enter "CIRENCESTER" in the "address_town" field
        And enter "GL7 1PP" in the "address_postcode" field

        When I click on the "Next" button
        Then I should receive the message "Postcode must be in Scotland for LBTT"
        Then I enter "EH1 1BE" in the "address_postcode" field
        When I click on the "Next" button

        Then I should see the sub-title "Provide property details"
        And I click on the "Next" button
        Then I should receive the message "Local authority can't be blank"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I select "ANG" from the "returns_lbtt_property_parent_title_code"
        And I enter "4567" in the "returns_lbtt_property_parent_title_number" field
        And I click on the "Next" button

        # validation for ADS applies
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page
        And I click on the "Next" button
        Then I should receive the message "Does Additional Dwelling Supplement (ADS) apply to this transaction can't be blank"
        And I check "No" radio button
        And I click on the "Next" button

        # Verify entered details on return summary page
        Then I should see the "Return Summary" page
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                               | ADS? |
            | 8 Lavender Lane, CIRENCESTER, EH1 1BE | No   |
        And I should not see the text "About the Additional Dwelling Supplement"

        # Go back and check a form still has data and modify it
        When I click on the 1 st "Edit row" link
        Then I should see the "Property address" page
        And I should see the text "8 Lavender Lane" in field "address_address_line1"
        And I should see the text "CIRENCESTER" in field "address_town"
        And I should see the text "EH1 1BE" in field "address_postcode"
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"
        Then "Local authority" should contain the option "Aberdeen City"
        Then I should see the text "1234" in field "returns_lbtt_property[title_number]"

        When I select "Orkney" from the "Local authority"
        And I enter "4567" in the "returns_lbtt_property[title_number]" field

        And I click on the "Next" button
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page
        And I check the "Yes" radio button
        And I click on the "Next" button

        # Verify modified details on return summary page
        Then I should see the "Return Summary" page
        And I should see the text "8 Lavender Lane, CIRENCESTER, EH1 1BE"
        And I should see the text "Yes"

        # delete it
        When I click on the "Delete row" link
        Then if available, click the confirmation dialog
        Then I should see the "Return Summary" page
        And I should not see the text "ABN 4567"
        And I should not see the text "8 Lavender Lane, CIRENCESTER, EH1 1BE"
        And I should not see the text "report this error"

    Scenario: Country Code Check
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page

        # Mandatory validation for selection of lbtt return type
        When I click on the "Next" button
        Then I should receive the message "Which return do you want to submit can't be blank"
        When I check "Conveyance or transfer" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        When I click on the "Add" link with id "add_property"
        Then I should see the "Property address" page
        And I click on the "Next" button

        # validation to select address
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click on the "Next" button
        Then I should receive the message "Postcode must be in Scotland for LBTT"

        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "First Scotrail Ltd" in field "address_address_line1"
        And I should see the text "Waverley Railway Station" in field "address_address_line2"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1BE" in field "address_postcode"
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"
        And I click on the "Next" button
        Then I should receive the message "Local authority can't be blank"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I select "ANG" from the "returns_lbtt_property_parent_title_code"
        And I enter "4567" in the "returns_lbtt_property_parent_title_number" field
        And I click on the "Next" button

        # validation for ADS applies
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page
        And I click on the "Next" button
        Then I should receive the message "Does Additional Dwelling Supplement (ADS) apply to this transaction can't be blank"
        And I check "No" radio button
        And I click on the "Next" button

        # Verify entered details on return summary page
        Then I should see the "Return Summary" page
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                                | ADS? |
            | First Scotrail Ltd, EDINBURGH, EH1 1BE | No   |
        And I should not see the text "About the Additional Dwelling Supplement"

        # Go back and check a form still has data and modify it
        When I click on the 1 st "Edit row" link
        Then I should see the "Property address" page
        And I should see the text "First Scotrail Ltd" in field "address_address_line1"
        And I should see the text "Waverley Railway Station" in field "address_address_line2"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1BE" in field "address_postcode"
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"
        Then "Local authority" should contain the option "Aberdeen City"
        Then I should see the text "1234" in field "returns_lbtt_property[title_number]"

        When I select "Orkney" from the "Local authority"
        And I enter "4567" in the "returns_lbtt_property[title_number]" field

        And I click on the "Next" button
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page
        And I check the "Yes" radio button
        And I click on the "Next" button

        # Verify modified details on return summary page
        Then I should see the "Return Summary" page
        And I should see the text "First Scotrail Ltd, EDINBURGH, EH1 1BE"
        And I should see the text "Yes"

        # delete it
        When I click on the "Delete row" link
        Then if available, click the confirmation dialog
        Then I should see the "Return Summary" page
        And I should not see the text "ABN 4567"
        And I should not see the text "First Scotrail Ltd, EDINBURGH, EH1 1BE"
        And I should not see the text "report this error"

    Scenario: Additional Dwelling Supplement
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        And I check "Conveyance or transfer" radio button
        And I click on the "Next" button

        Then I should see the "Return Summary" page
        And I should not see the text "About the Additional Dwelling Supplement"

        # Fill in property details to access the ADS section
        When I click on the "Add" link with id "add_property"
        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "First Scotrail Ltd" in field "address_address_line1"
        And I should see the text "Waverley Railway Station" in field "address_address_line2"
        # And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1BE" in field "address_postcode"
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Next" button
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page

        When I check "Yes" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        # ADS section should now be shown
        And I should see the text "About the Additional Dwelling Supplement"

        When I click on the "Add" link with id "add_ads"
        Then I should see the "Additional Dwelling Supplement (ADS)" page
        And I should see the text "Is the buyer replacing their main residence?"
        When I click the "Next" button
        And I should receive the message "Is the buyer replacing their main residence can't be blank"
        When I check the "Yes" radio button
        And I click the "Next" button

        Then I should see the text "Total consideration liable to ADS"
        And I should see the text "Amount of ADS liability from new main residence"
        When I click the "Next" button
        Then I should receive the message "Total consideration liable to ADS can't be blank"
        And I should receive the message "Amount of ADS liability from new main residence can't be blank"

        # numeric validation
        When I enter "invalid" in the "Amount of ADS liability from new main residence" field
        And I enter "invalid" in the "Total consideration liable to ADS" field
        And I click the "Next" button

        Then I should receive the message "Total consideration liable to ADS is not a number"
        And I should receive the message "Amount of ADS liability from new main residence is not a number"

        # validation on negative and range check
        When I enter "-1" in the "Amount of ADS liability from new main residence" field
        And I enter "1000000000000000000" in the "Total consideration liable to ADS" field
        And I click the "Next" button

        Then I should see the text "Total consideration liable to ADS must be less than 1000000000000000000"
        And I should see the text "Amount of ADS liability from new main residence must be greater than or equal to 0"

        When I enter "123.4567" in the "Amount of ADS liability from new main residence" field
        And I click the "Next" button
        Then I should see the text "Amount of ADS liability from new main residence must be a number to 2 decimal places"

        When I enter "40503" in the "Amount of ADS liability from new main residence" field
        And I enter "40750" in the "Total consideration liable to ADS" field
        And I click the "Next" button

        Then I should see the text "Does the buyer intend to sell their main residence within 18 months?"
        When I click the "Next" button
        Then I should receive the message "Does the buyer intend to sell their main residence within 18 months can't be blank"

        # Check the radio button value is stored in wizard
        When I check the "No" radio button
        And I click the "Next" button
        And I click on the "Back" link
        Then the radio button "returns_lbtt_lbtt_return_ads_sell_residence_ind_n" should be selected

        When I check the "Yes" radio button
        And I click the "Next" button
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"

        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "First Scotrail Ltd" in field "address_address_line1"
        And I should see the text "Waverley Railway Station" in field "address_address_line2"
        # And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "EDINBURGH" in field "address_town"
        And I should see the text "EH1 1BE" in field "address_postcode"
        And I click on the "Next" button
        Then I should see the "Reliefs on ADS consideration" page

        When I click on the "Next" button
        Then I should receive the message "Is relief being claimed from the ADS consideration can't be blank"

        When I check the "Yes" radio button
        # check non ADS options are filtered out
        And "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_type" should not contain the option "Group relief"
        And "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_type" should not contain the option "Charities relief"
        And "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_type" should not contain the option "Public bodies relief"
        # Delete button link should not be shown when there is only on row of data
        Then I should not see the button with text "Delete row"
        When I click on the "Next" button
        Then I should receive the message "At least one record must be entered"
        When I click on the "Add row" button
        Then I should see the button with text "Delete row"

        When I enter "2087" in the "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_amount" field
        And I click on the "Next" button
        Then I should receive the message "Missing relief details row 1"

        When I enter " " in the "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_amount" field
        And I select "ADS - Family units" from the "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_type"
        And I click on the "Next" button
        Then I should receive the message "Missing relief details row 1"

        When I enter "123.ab" in the "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_amount" field
        And I click on the "Next" button
        Then I should receive the message "Invalid relief amount row 1"
        When I enter "-3" in the "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_amount" field
        And I click on the "Next" button
        Then I should receive the message "Invalid relief amount row 1"
        When I enter "1000000000000000000" in the "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_amount" field
        And I click on the "Next" button
        Then I should receive the message "Invalid relief amount row 1"
        When I enter "123.50" in the "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_amount" field
        And I click on the "Next" button

        Then I should see the "Return Summary" page
        And the table of data is displayed
            | Address of existing main residence                                   | First Scotrail Ltd, EDINBURGH, EH1 1BE |
            | Does the buyer intend to sell their main residence within 18 months? | Yes                                    |
            | Amount of ADS liability from new main residence                      | £40503                                 |
            | Total consideration liable to ADS                                    | £40750                                 |
            | Is relief being claimed from the ADS consideration?                  | Yes                                    |
        # Transaction
        When I click on the "Add" link with id "add_transaction_calculation"
        Then I should see the "About the transaction" page

        When I check the "Residential" radio button
        And I click on the "Next" button
        Then I should see the "About the dates" page

        When I enter "2019-08-02" in the "Effective date of transaction" field
        And I enter "2019-08-03" in the "Relevant date" field
        And I enter "2019-08-03" in the "Date of contract or conclusion of missives" field
        And I click on the "Next" button
        Then I should see the "About the transaction" page

        When I check "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Next" button
        Then I should see the "Linked Transactions" page

        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "About the transaction" page

        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "Reliefs on this transaction" page

        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "About future events" page

        When I check "returns_lbtt_lbtt_return_contingents_event_ind_n" radio button
        And I click on the "Next" button
        Then I should see the "About the conveyance or transfer" page
        And I should not see the text "Linked transaction consideration"

        When I enter "1234565" in the "Total consideration" field
        And I enter "0" in the "VAT amount" field
        And I enter "0" in the "Non-chargeable consideration" field
        And I enter "1234565" in the "Total consideration remaining" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        # Calculate
        When I click on the "Edit" link with id "edit_calculation"
        Then I should see the "Calculated tax" page
        And I should see the text "106497" in field "LBTT calculated"
        And I should see the text "1630" in field "ADS calculated"
        And I should see the text "0" in field "Total LBTT reliefs claimed"
        And I should see the text "123.5" in field "Total ADS reliefs claimed"

        When I enter "abc" in the "Total ADS reliefs claimed" field
        And I click on the "Next" button
        Then I should receive the message "Total ADS reliefs claimed is not a number"

        When I enter "-1" in the "Total ADS reliefs claimed" field
        And I click on the "Next" button
        Then I should receive the message "Total ADS reliefs claimed must be greater than or equal to 0"

        When I enter "124" in the "Total ADS reliefs claimed" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the calculation      | Edit       |
            | LBTT calculated            | £106497.00 |
            | ADS calculated             | £1630.00   |
            | Total liability            | £108127.00 |
            | Total LBTT reliefs claimed | £0.00      |
            | Total ADS reliefs claimed  | £124.00    |
            | Total tax payable          | £108003.00 |

    # Loads Lbtt details
    @mock_load_lbtt_convey_details_with_tax_calc
    Scenario: Load mock Lbtt return details
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/load/251-1" page
        Then I should see the "Return Summary" page
        # see agent details
        And I should see the text "Mr Portal User New Users"

        And the table of data is displayed
            | Name                 | Type                 | Address                    |      |        |
            | Mr firstname surname | A private individual | Royal Mail, LUTON, LU1 1AA | Edit | Delete |

        And the table of data is displayed
            | Name                               | Type                 | Address                    |      |        |
            | Mr seller firstname seller surname | A private individual | Royal Mail, LUTON, LU1 1AA | Edit | Delete |

        And the table of data is displayed
            | Address                    | ADS? |      |        |
            | Royal Mail, LUTON, LU1 1AA | Yes  | Edit | Delete |

        And the table of data is displayed
            | About the Additional Dwelling Supplement (ADS)                      | Edit       |
            | Does the buyer intend to sell their main residence within 18 months | No         |
            | Amount of ADS liability from new main residence                     | £750.00    |
            | Total consideration liable to ADS                                   | £460000.00 |
            | Is relief being claimed from the ADS consideration?                 | Yes        |

        And the table of data is displayed
            | About the transaction                              | Edit           |
            | What is the property type for this transaction?    | Residential    |
            | Effective date of transaction                      | 02 August 2019 |
            | Relevant date                                      | 03 August 2019 |
            | Are there any linked transactions?                 | Yes            |
            | Is the transaction part of the sale of a business? | Yes            |
            | Is relief being claimed for this transaction?      | Yes            |
            | Total consideration remaining                      | £1234567.00    |

        And the table of data is displayed
            | About the calculation      | Edit       |
            | LBTT calculated            | £106090.82 |
            | ADS calculated             | £10        |
            | Total liability            | £106100.82 |
            | Total LBTT reliefs claimed | £60        |
            | Total ADS reliefs claimed  | £0         |
            | Total tax payable          | £106040.00 |

        # check reliefs and linked transactions loaded correctly (selecting No to a repayment on first screen)
        When I click on the "Edit" link with id "add_ads"
        And I check the "No" radio button
        And I click on the "Next" button
        And I click on the "Next" button
        Then I should see the text "460000" in field "Total consideration liable to ADS"
        And I should see the text "750" in field "Amount of ADS liability from new main residence"
        When I click on the "Next" button
        Then the radio button "No" should be selected
        When I click on the "Next" button
        Then I should see the "Reliefs on ADS consideration" page
        Then the radio button "Yes" should be selected
        And I should see the "ADS - Family units" option selected in "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_type"
        And I should see the text "40" in field "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_amount"
        # Check the non-ADS relief isn't shown
        And I should not see the text "Crofting"

        When I click on the "Next" button
        Then I should see the "Return Summary" page
        When I click on the "Edit" link with id "add_transaction_calculation"
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        Then I should see the "Linked Transactions" page
        And I should see the text "1" in field "returns_lbtt_lbtt_return_link_transactions_0_return_reference"
        And I should see the text "10" in field "returns_lbtt_lbtt_return_link_transactions_0_consideration_amount"
        And I should see the text "2" in field "returns_lbtt_lbtt_return_link_transactions_1_return_reference"
        And I should see the text "20" in field "returns_lbtt_lbtt_return_link_transactions_1_consideration_amount"
        And I should see the text "3" in field "returns_lbtt_lbtt_return_link_transactions_2_return_reference"
        And I should see the text "30" in field "returns_lbtt_lbtt_return_link_transactions_2_consideration_amount"

        When I click on the "Next" button
        And I click on the "Next" button
        Then I should see the "Reliefs on this transaction" page
        And I should see the "Relief for incorporation of limited liability partnership" option selected in "returns_lbtt_lbtt_return_non_ads_relief_claims_0_relief_type"
        And I should see the text "10" in field "returns_lbtt_lbtt_return_non_ads_relief_claims_0_relief_amount"
        And I should see the "Crofting community right to buy relief" option selected in "returns_lbtt_lbtt_return_non_ads_relief_claims_1_relief_type"
        And I should see the text "20" in field "returns_lbtt_lbtt_return_non_ads_relief_claims_1_relief_amount"
        And I should see the "Property accepted in satisfaction of tax relief (heritage bodies)" option selected in "returns_lbtt_lbtt_return_non_ads_relief_claims_2_relief_type"
        And I should see the text "30" in field "returns_lbtt_lbtt_return_non_ads_relief_claims_2_relief_amount"
        # Check the ADS relief isn't shown
        And I should not see the text "ADS"

    # Checks amending a conveyance return (similar to Load mock Lbtt return details but separated so we don't re-calculate the values)
    @mock_load_lbtt_convey_details_for_amend
    Scenario: Load mock Lbtt return details and amend
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/load/251-1" page
        Then I should see the "Return Summary" page

        # Check ADS amend
        When I click on the "Edit" link with id "add_ads"
        Then I should see the text "Are you amending the return because"

        When I click on the "Next" button
        Then I should receive the message "Are you amending the return because the buyer has sold or disposed of the previous main residence can't be blank"

        When I check "Yes" radio button
        And I click on the "Next" button
        Then I should see the text "What is the date of sale or disposal of the previous main residence?"
        When I click on the "Next" button
        Then I should receive the message "What is the date of sale or disposal of the previous main residence can't be blank"
        When I enter "2019-08-03" in the "What is the date of sale or disposal of the previous main residence?" field
        And I click on the "Next" button
        Then I should see the text "Confirm the address of the previous main residence that has been sold or disposed of"

        When I click on the "Next" button
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "LU1 1AA" in field "address_postcode"

        And I click on the "Next" button
        Then I should see the text "When you submit the return you will be asked for the bank details for the repayment."
        And I should see the text "Original total ADS paid"
        And I should see the text "Amount of ADS you want to reclaim"

        When I enter "" in the "Amount of ADS you want to reclaim" field
        And I click on the "Next" button
        Then I should receive the message "Amount of ADS you want to reclaim is not a number"
        When I enter "abc" in the "Amount of ADS you want to reclaim" field
        And I click on the "Next" button
        Then I should receive the message "Amount of ADS you want to reclaim is not a number"

        When I enter "371.50" in the "Amount of ADS you want to reclaim" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # Check the ADS reliefs radio button is set correctly
        When I click on the "Edit" link with id "add_ads"
        Then I should see the text "Are you amending the return because"

        When I check "No" radio button
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        And I should see the "Reliefs on ADS consideration" page
        And the radio button "Yes" should be selected

    @mock_update_lbtt_details
    Scenario: Update Lbtt return details with mocking
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/load/251-1" page
        Then I should see the "Return Summary" page

        # see agent details
        And I should see the text "Mr Portal User New Users"

        And the table of data is displayed
            | Name                 | Type                 | Address                    |      |        |
            | Mr firstname surname | A private individual | Royal Mail, LUTON, LU1 1AA | Edit | Delete |

        When I click on the 1 st "Edit row" link
        Then I should see the "About the buyer" page
        And I click on the "Next" button
        Then I should see the "Buyer details" page
        When I enter "lastname" in the "Last name" field
        And I select "Mrs" from the "Title"
        And I click on the "Buyer does not have NINO" text
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field
        And I click the "Next" button
        Then I should see the "Buyer address" page
        And I click the "Next" button
        Then I should see the "Buyer's contact address" page
        And I click the "Next" button
        Then I should see the "Buyer details" page
        And I click the "Next" button

        Then I should see the "Buyer details" page
        And I should see the text "Is the buyer acting as a trustee or representative partner for tax purposes?"
        And I click the "Next" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | Name                   | Type                 | Address                    |      |        |
            | Mrs firstname lastname | A private individual | Royal Mail, LUTON, LU1 1AA | Edit | Delete |

        When I click the "Submit return" button

        # hooks file purposely incomplete to simulate back office loading lost data = validation message
        Then I should receive the message "About the calculation has errors that need to be corrected, please edit it"
        When I click on the "Edit" link with id "add_transaction_calculation"
        Then I should see the "About the transaction" page

        # get to page to enter incomplete data
        When I click on the "Next" button
        Then I should see the "About the dates" page
        When I click on the "Next" button
        Then I should see the "About the transaction" page
        When I click on the "Next" button
        Then I should see the "Linked Transactions" page
        When I click on the "Next" button
        Then I should see the "About the transaction" page
        When I click on the "Next" button
        Then I should see the "Reliefs on this transaction" page

        # fix the data
        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "About future events" page
        When I click on the "Next" button
        Then I should see the "About the conveyance or transfer" page
        When I click on the "Next" button
        Then I should see the "Return Summary" page

        # try again
        When I click the "Submit return" button
        Then I should see the "Repayment details" page
        When I check "No" radio button
        And I click the "Next" button
        Then I should see the "Payment and submission" page
        When I check "BACS" radio button

        # data is mocked so won't show a real declaration so select by id
        And I check "returns_lbtt_lbtt_return_declaration" checkbox

        And I click the "Submit return" button
        Then I should see the text "Your amendment to your Land and Buildings Transaction Tax return has now been submitted."
        And the table of data is displayed
            | Transaction reference      | RS1000202XWQY                                                          |
            | Title number               | ABN 1234                                                               |
            | Property address           | Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA |
            | Buyer                      | Mrs firstname lastname                                                 |
            | Description of transaction | Conveyance or transfer                                                 |
            | Effective date             | 02/08/2019                                                             |

        And I click on the "Send secure message" link
        Then I should see the "New message" page

    Scenario: Saving draft for lease return
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page

        And I check "Assignation" radio button
        And I click on the "Next" button
        Then I should see the "Return reference number" page
        When I enter "RS1234567ABCD" in the "What was the original return reference" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        And I click on the "Save draft" button

        Then I should see the "Return saved" page
        And I should see the text "Your tax return has been saved so that you can return to either complete or cancel it."
        And I should see the text "It has not been submitted to Revenue Scotland."
        And I should see the regex "Your return reference is RS\d{7}[a-zA-Z]{4}\."

    Scenario: Assignation submission wizard

        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page

        And I check "Assignation" radio button
        And I click on the "Next" button
        Then I should see the "Return reference number" page
        When I enter "RS1234567ABCD" in the "What was the original return reference" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # pre-calculate validation
        When I click on the "Submit return" button
        Then I should see the text "Please fill in the 'About the transaction' section"
        And I should see the text "Please fill at least one property details"
        And I should see the text "Please fill at least one new tenant details"
        And I should see the text "Please fill at least one tenant details"

        # Agent
        When I click on the "Amend" link
        Then I should see the "Agent details" page
        And I select "Mr" from the "Title"

        # Uk phone number start with '+442079460654'
        And I enter "+442079460654" in the "Telephone number" field
        And I click on the "Next" button
        Then I should see the "Agent address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Return Summary" page

        # Property
        When I click on the "Add" link with id "add_property"
        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        When I click on the "Back" link
        Then I should see the "Property address" page

        # entered spannish address manually
        When click on the "Edit address" button
        And enter "Calle Aduana, 29" in the "address_address_line1" field
        And enter "" in the "address_address_line2" field
        And enter "" in the "address_address_line3" field
        And enter "" in the "address_address_line4" field
        And enter "MADRID" in the "address_town" field
        And enter "Alicante, Espana" in the "address_county" field

        # if postcode is entered then validate it is UK postcode
        And enter "03184" in the "address_postcode" field

        When I click on the "Next" button
        Then I should receive the message "Postcode is invalid"
        And enter "EH1 1BE" in the "address_postcode" field
        When I click on the "Next" button


        Then I should see the sub-title "Provide property details"

        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Next" button
        # No does ADS apply page for non-conveyance returns
        Then I should see the "Return Summary" page
        # Verify entered details on return summary page do not include ADS
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                  |
            | Calle Aduana, 29, MADRID |
        And I should not see the text "About the Additional Dwelling Supplement"
        And I should not see the text "ADS?"

        # Tenant
        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        And I click on the "Next" button
        Then I should receive the message "Who is the tenant can't be blank"
        When I check "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Tenant details" page

        And I click on the "Next" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Telephone number can't be blank"
        And I should receive the message "National Insurance Number (NINO) or an alternate reference must be provided"
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"

        # Allow spanish phone number
        And I enter "+34629629629" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I click on the "Tenant does not have NINO" text
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field
        And I click on the "Next" button
        Then I should see the "Tenant address" page
        When I click on the "Next" button
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click the "Next" button
        Then I should see the "Tenant's contact address" page
        When I click on the "Next" button
        Then I should receive the message "Should we use a different address for future correspondence in relation to this return can't be blank"
        When I check "No" radio button
        And I click the "Next" button
        Then I should see the "Tenant details" page

        Then I should see the "Is the tenant connected to the landlord?" page
        When I click on the "Next" button
        Then I should receive the message "Is the tenant connected to the landlord can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button

        Then I should see the "Tenant details" page
        When I click on the "Next" button
        Then I should see the text "Is the tenant acting as a trustee or representative partner for tax purposes can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button

        Then I should see the "Return Summary" page
        Then I should see the text "Mr firstname surname"
        Then I should see the text "Royal Mail, LUTON, LU1 1AA"
        Then I should see the text "A private individual"
        Then I should see the text "Edit row"


        # add new tenant
        When I click on the "Add a new tenant" link

        Then I should see the "About the new tenant" page
        When I check "A private individual" radio button
        And I click on the "Next" button

        Then I should see the "New tenant details" page
        And I click on the "Next" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Telephone number can't be blank"
        And I should receive the message "National Insurance Number (NINO) or an alternate reference must be provided"
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"

        # Allow spanish phone number
        And I enter "+34629629629" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "AB323456C" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button

        Then I should see the "New tenant address" page
        When I click on the "Next" button
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click the "Next" button

        Then I should see the "New tenant's contact address" page
        When I click on the "Next" button
        Then I should receive the message "Should we use a different address for future correspondence in relation to this return can't be blank"
        When I check "No" radio button
        And I click the "Next" button

        Then I should see the "Is the new tenant connected to the landlord?" page
        When I click on the "Next" button
        Then I should receive the message "Is the new tenant connected to the landlord can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button

        Then I should see the "New tenant details" page
        When I click on the "Next" button
        Then I should see the text "Is the new tenant acting as a trustee or representative partner for tax purposes can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button

        Then I should see the "Return Summary" page
        Then I should see the text "Mr firstname surname"
        Then I should see the text "Royal Mail, LUTON, LU1 1AA"
        Then I should see the text "A private individual"
        Then I should see the text "Edit row"

        # Transaction
        When I click on the "Add" link with id "add_transaction_calculation"

        Then I should see the "About the dates" page
        When I enter "2019-08-02" in the "Effective date of transaction" field
        And I enter "2019-08-03" in the "Relevant date" field
        And I enter "2019-08-03" in the "Date of contract or conclusion of missives" field
        And I enter "2019-10-10" in the "Lease start date" field
        And I enter "2023-10-08" in the "Lease end date" field
        And I click on the "Next" button

        Then I should see the "Linked Transactions" page
        # linked-transactions - select no to get positive calculation results
        When I check "No" radio button
        And I click on the "Next" button

        Then I should see the "About the lease values" page
        # about the lease_values rental years
        When I enter "350000" in the "How much was the rent for the first year (inc VAT)?" field
        And I click on the "Next" button

        Then I should see the "About the lease values" page
        When I check the "No" radio button
        # Rental years
        Then I should see the text "Year 4"
        When I enter "350100" in the "returns_lbtt_lbtt_return_yearly_rents_1_rent" field
        And I enter "360200" in the "returns_lbtt_lbtt_return_yearly_rents_2_rent" field
        And I enter "370200" in the "returns_lbtt_lbtt_return_yearly_rents_3_rent" field
        And I enter "340200" in the "returns_lbtt_lbtt_return_yearly_rents_0_rent" field
        And I click on the "Next" button

        Then I should see the "About the lease values" page
        When I check "Yes" radio button
        When I enter "352000" in the "Premium amount (inc VAT)" field
        And I click on the "Next" button

        Then I should see the "About the lease values" page
        # relevant_rent
        When I enter "351000" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Next" button

        Then I should see the "Calculated Net Present Value (NPV)" page
        And I should not see the text "for linked transactions"
        # NPV calculated tax
        And I should see the text "1303005.42" in field "Net Present Value (NPV)"
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the transaction                                  | Edit            |
            | What is the property type for this transaction?        | Non-residential |
            | Effective date of transaction                          | 03 August 2019  |
            | Lease start date                                       | 10 October 2019 |
            | Lease end date                                         | 08 October 2023 |
            | What is the relevant rent amount for this transaction? | £351000.00      |
            | Premium amount (inc VAT)                               | £352000.00      |
            | Net Present Value (NPV)                                | £1303005.42     |
            | Are there any linked transactions?                     | No              |

        # Calculation happened after the transaction section
        And the table of data is displayed
            | About the calculation          | Edit      |
            | LBTT tax liability on rent     | £11530.00 |
            | LBTT tax liability on premium  | £7600.00  |
            | Total tax payable              | £19130.00 |
            | Amount already paid            | £0.00     |
            | Amount payable for this return | £19130.00 |

        When I click the "Submit return" button
        Then I should see the "Repayment details" page
        When I check "No" radio button
        And I click on the "Next" button

        Then I should see the "Payment and submission" page
        When I check "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button

        And I click the "Submit return" button
        Then I should see the text "Your return has been submitted"
        And I should see the text "Transaction reference"
        And I should see the regex "RS\d{7}[a-zA-Z]{4}"
        And the table of data is displayed
            | Title number               | ABN 1234                                            |
            | Property address           | Calle Aduana, 29, MADRID, Alicante, Espana, EH1 1BE |
            | Tenant                     | Mr firstname surname                                |
            | Description of transaction | Assignation                                         |
            | Effective date             | 02/08/2019                                          |

    Scenario: Party wizard for lbtt conveyance return as organisation registered with Companies House

        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        And I check "Conveyance or transfer" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        #Registered company
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page
        When I check "An organisation registered with Companies House" radio button
        And I click on the "Next" button

        Then I should see the "Registered company" page
        And click on the "Find Company" button
        Then I should receive the message "This can't be blank"
        And I should receive the message "This is too short (minimum is 8 characters)"
        And enter "0123" in the "Company number" field
        And click on the "Find Company" button
        Then I should receive the message "This is too short (minimum is 8 characters)"
        And enter "0123456789" in the "Company number" field
        And click on the "Find Company" button
        Then I should receive the message "This is too long (maximum is 8 characters)"
        And enter "00000001" in the "Company number" field
        And click on the "Find Company" button
        Then I should receive the message "This returns no company"
        And enter "" in the "Company number" field
        When click on the "Next" button

        Then I should receive the message "This can't be blank"
        And I should receive the message "This is too short (minimum is 8 characters)"
        And I should receive the message "A company must be chosen"
        When enter "09338960" in the "Company number" field
        And click on the "Find Company" button

        Then I should see the text "NORTHGATE PUBLIC SERVICES LIMITED" in field "company_company_name"
        And I should see the text "Peoplebuilding 2 Peoplebuilding Estate" in field "company_address_line1"
        And I should see the text "Maylands Avenue" in field "company_address_line2"
        And I should see the text "Hemel Hempstead" in field "company_locality"
        And I should see the text "Hertfordshire" in field "company_county"
        And I should see the text "HP2 4NW" in field "company_postcode"
        When I click on the "Next" button

        Then I should see the "Contact details" page
        When I click on the "Next" button
        Then I should receive the message "Contact phone number can't be blank"
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Job title or position can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Postcode search should be used, or the address should be entered manually"
        When I enter "company" in the "Last name" field
        And I enter "Registered" in the "First name" field
        And I enter "Developer" in the "Job title or position" field
        And I enter "0123456789" in the "Contact phone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click on the "Next" button

        Then I should see the "Buyer details" page
        When I click on the "Next" button
        Then I should receive the message "Is the buyer connected to the seller can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button

        Then I should see the "Buyer details" page
        When I click on the "Next" button
        Then I should see the text "Is the buyer acting as a trustee or representative partner for tax purposes can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button

        Then I should see the "Return Summary" page
        And I should see the text "NORTHGATE PUBLIC SERVICES LIMITED"

    Scenario: Saving draft for conveyance
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page
        And I check the "Conveyance or transfer" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        And I click on the "Save draft" button

        Then I should see the "Return saved" page
        And I should see the text "Your tax return has been saved so that you can return to either complete or cancel it."
        And I should see the text "It has not been submitted to Revenue Scotland."
        And I should see the regex "Your return reference is RS\d{7}[a-zA-Z]{4}\."
        And I should see the text "Back to return summary"
        And I should see the text "Go to dashboard"
        # Check save draft works and you can go back and save again
        When I click on the "Back" link
        Then I should see the "Return Summary" page
        When I click on the "Save draft" button
        Then I should see the "Return saved" page
        And I should see the regex "Your return reference is RS\d{7}[a-zA-Z]{4}\."

    Scenario: Saving draft for lease return
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page

        And I check the "3 year lease review" radio button
        And I click on the "Next" button
        Then I should see the "Return reference number" page
        When I enter "RS1234567ABCD" in the "What was the original return reference" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        And I click on the "Save draft" button

        Then I should see the "Return saved" page
        And I should see the text "Your tax return has been saved so that you can return to either complete or cancel it."
        And I should see the text "It has not been submitted to Revenue Scotland."
        And I should see the regex "Your return reference is RS\d{7}[a-zA-Z]{4}\."

    Scenario: Calculate, declaration and submit a conveyance return for a tax payer
        Given I have signed in "ADAM.PORTAL-TEST" and password "Password1!"
        When I click on the "Create LBTT return" link
        And I check "Conveyance or transfer" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # Agent
        When I click on the "Amend" link
        Then I should see the "Agent details" page
        And I select "Mr" from the "Title"

        # Other combination of Uk phone number
        And I enter "01908 264 500ext442" in the "Telephone number" field
        And I click on the "Next" button
        Then I should see the "Agent address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Return Summary" page

        # Property
        When I click on the "Add" link with id "add_property"
        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"

        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Next" button
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page

        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # Buyer
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page
        When I check "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Buyer details" page

        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"

        # Other combination of Uk phone number with extension
        And I enter "0115 9210200 #1234" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I click on the "Buyer does not have NINO" text
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field
        And I click on the "Next" button
        Then I should see the "Buyer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Buyer's contact address" page

        When I check "Yes" radio button
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Buyer details" page

        When I check "Yes" radio button
        And I click the "Next" button
        Then I should see the "Buyer details" page
        And I should see the text "Is the buyer acting as a trustee or representative partner for tax purposes?"

        When I check "Yes" radio button
        And I click the "Next" button
        Then I should see the "Return Summary" page

        # Seller
        When I click on the "Add a seller" link
        Then I should see the "About the seller" page

        When I check "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Seller details" page

        When I enter "seller surname" in the "Last name" field
        And I enter "seller firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I click on the "Next" button
        Then I should see the "Seller address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Return Summary" page

        # Transaction
        When I click on the "Add" link with id "add_transaction_calculation"
        Then I should see the "About the transaction" page

        When I check "Residential" radio button
        And I click on the "Next" button
        Then I should see the "About the dates" page

        When I enter "2019-08-02" in the "Effective date of transaction" field
        And I enter "2019-08-03" in the "Relevant date" field
        And I enter "2019-08-03" in the "Date of contract or conclusion of missives" field
        And I click on the "Next" button
        Then I should see the "About the transaction" page

        When I check "returns_lbtt_lbtt_return_previous_option_ind_n" radio button
        And I check "returns_lbtt_lbtt_return_exchange_ind_n" radio button
        And I check "returns_lbtt_lbtt_return_uk_ind_n" radio button
        And I click on the "Next" button
        Then I should see the "Linked Transactions" page

        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "About the transaction" page

        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "Reliefs on this transaction" page

        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "About future events" page

        When I check "returns_lbtt_lbtt_return_contingents_event_ind_n" radio button
        And I click on the "Next" button
        Then I should see the "About the conveyance or transfer" page
        And I should not see the text "Linked transaction consideration"

        When I enter "1234565" in the "Total consideration" field
        And I enter "0" in the "VAT amount" field
        And I enter "0" in the "Non-chargeable consideration" field
        And I enter "1234565" in the "Total consideration remaining" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # No ADS
        When I should not see the text "About the Additional Dwelling Supplement (ADS)"

        # Calculate
        When I click on the "Edit" link with id "edit_calculation"
        Then I should see the "Calculated tax" page
        And I should see the text "106497" in field "LBTT calculated"
        And I should see the text "0" in field "Total LBTT reliefs claimed"
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the calculation      | Edit       |
            | LBTT calculated            | £106497.00 |
            | Total LBTT reliefs claimed | £0         |
            | Total tax payable          | £106497.00 |
        And I should not see the text "ADS calculated"
        And I should not see the text "Total ADS reliefs claimed"
        And I should not see the text "Total liability"

        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page
        And I should not see the text "Direct Debit"
        And I should not see the text "I, the agent for the buyer(s), confirm that I have authority to deal with all matters relating to this transaction on behalf of my client(s)"
        And I should see the text "I, the buyer, declare that this return is, to the best of my knowledge, correct and complete."

        When I click on the "Submit return" button
        Then I should see the text "How are you paying can't be blank"
        And I should see the text "The declaration must be accepted"

    Scenario: Public user can do an LBTT return
        When I go to the "returns/lbtt/public_landing" page
        Then I should see the "To complete this return, you will need the following information:" page

        When I click on the "Create LBTT lease review" link
        Then I should see the "About the return" page

        When I check "3 year lease review" radio button
        And I click on the "Next" button
        Then I should see the "Return reference number" page

        When I enter "RS1234567ABAB" in the "What was the original return reference" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        And I should not see the text "Contact details for this return"
        And I should not see the text "Save draft"

        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        When I check "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Tenant details" page
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        # Allow intenational phone number
        And I enter "+12 123456789" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I click on the "Tenant does not have NINO" text
        And I select "ID Card" from the "Type of ID"
        And I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I enter "1" in the "Reference number of the ID" field

        And I click on the "Next" button
        Then I should see the "Tenant address" page
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Tenant's contact address" page
        When I check "No" radio button
        And I click the "Next" button
        Then I should see the "Tenant details" page
        When I check "No" radio button
        And I click the "Next" button
        Then I should see the "Tenant details" page

        When I check "Yes" radio button
        And I click the "Next" button
        Then I should see the "Return Summary" page

        When I click on the "add_property" link
        Then I should see the "Property address" page
        When I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        When I click on the "add_transaction_calculation" link
        Then I should see the "About the dates" page
        When I enter "2019-08-02" in the "Effective date of transaction" field
        And I enter "2019-08-03" in the "Relevant date" field
        And I enter "2019-08-03" in the "Date of contract or conclusion of missives" field
        And I enter "2019-08-03" in the "Lease start date" field
        And I enter "2019-08-03" in the "Lease end date" field
        And I click on the "Next" button
        Then I should see the "Linked Transactions" page
        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "About the lease values" page
        And I click on the "Next" button
        Then I should receive the message "How much was the rent for the first year (inc VAT) is not a number"
        When I enter "1234" in the "How much was the rent for the first year (inc VAT)?" field
        And I click on the "Next" button
        Then I should see the "About the lease values" page
        When I click on the "Next" button
        Then I should receive the message "Is this the same value for all rental years can't be blank"
        When I check "Yes" radio button
        And I click on the "Next" button
        Then I should see the "About the lease values" page
        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "About the lease values" page
        When I enter "123" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Next" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        When I enter "100" in the "Net Present Value (NPV)" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # check the amount already paid question is asked (specific to 'LEASEREV','ASSIGN', 'TERMINATE' (and amends)
        When I click on the "Edit" link with id "edit_calculation"
        Then I should see the "Calculated tax" page
        And I enter "100" in the "Amount already paid" field
        And I click on the "Next" button
        Then I should see the "Calculated tax" page
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # submit
        When I click on the "Submit return" button
        And I check "No" radio button
        And I click the "Next" button
        Then I should see the "Payment and submission" page
        And I should not see the text "Direct Debit"
        And I should not see the text "I, the agent for the buyer"
        And I should see the text "I, the tenant, declare that this return is, to the best of my knowledge, correct and complete."

        When I check the "BACS" radio button
        And I check "returns_lbtt_lbtt_return_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the "Your return has been submitted" page
        And I should see the text "Transaction reference"
        And I should see the regex "RS\d{7}[a-zA-Z]{4}"
        And the table of data is displayed
            | Title number               | ABN 1234                                                         |
            | Property address           | First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE |
            | Tenant                     | Mr firstname surname                                             |
            | Description of transaction | 3 year lease review                                              |
            | Effective date             | 02/08/2019                                                       |

    Scenario: Lease return transaction wizard through to calculate, declaration and submit

        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page

        # Data gets retained when going back to About the return page and going next
        When I check the "Conveyance or transfer" radio button
        And I click on the "Next" button
        And I click on the "Add" link with id "add_property"
        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button

        And I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Next" button
        # Back in the Summary page
        And I check the "Yes" radio button
        And I click on the "Next" button
        Then I should see the text "First Scotrail Ltd, EDINBURGH, EH1 1BE"
        # Back in the About the return page
        When I click on the "Back" link
        And if available, click the confirmation dialog
        Then I should see the "About the return" page
        And the radio button "Conveyance or transfer" should be selected

        # Data is cleaned when we select a new return type
        When I check "Lease" radio button
        And I check "Conveyance or transfer" radio button
        And I click on the "Next" button
        Then I should see the text "First Scotrail Ltd, EDINBURGH, EH1 1BE"

        When I click on the "Back" link
        And if available, click the confirmation dialog
        And I check the "Lease" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        And I should not see the text "First Scotrail Ltd, EDINBURGH, EH1 1BE"

        # pre-calculate validation
        When I click on the "Submit return" button
        Then I should see the text "Please fill in the 'About the transaction' section"
        And I should see the text "Please fill at least one property details"
        And I should see the text "Please fill at least one landlord details"
        And I should see the text "Please fill at least one tenant details"

        # Agent
        When I click on the "Amend" link
        Then I should see the "Agent details" page
        And I select "Mr" from the "Title"
        And I enter "0123456789" in the "Telephone number" field
        And I enter "my agent ref" in the "Agent reference (optional)" field
        And I click on the "Next" button
        Then I should see the "Agent address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Return Summary" page

        # Property
        When I click on the "Add" link with id "add_property"
        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"

        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Next" button
        # No does ADS apply page for non-conveyance returns
        Then I should see the "Return Summary" page
        # Verify entered details on return summary page do not include ADS
        And I should see the text "Edit row"
        And the table of data is displayed
            | Address                                |
            | First Scotrail Ltd, EDINBURGH, EH1 1BE |
        And I should not see the text "About the Additional Dwelling Supplement"
        And I should not see the text "ADS?"

        # Tenant
        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        And I click on the "Next" button
        Then I should receive the message "Who is the tenant can't be blank"
        When I check the "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Tenant details" page

        And I click on the "Next" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Telephone number can't be blank"
        And I should receive the message "National Insurance Number (NINO) or an alternate reference must be provided"
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "AB123456C" in the "National Insurance Number (NINO)" field
        And I click on the "Tenant does not have NINO" text
        And I select "ID Card" from the "Type of ID"
        And I click on the "Next" button
        Then I should receive the message "Country where ID was issued can't be blank"
        And I should receive the message "Reference number of the ID can't be blank"
        When I enter "" in the "National Insurance Number (NINO)" field
        And I select "Choose from list" from the "Type of ID"
        And I enter "1" in the "Reference number of the ID" field
        And I click on the "Next" button
        Then I should receive the message "Type of ID can't be blank"
        And I should receive the message "Country where ID was issued can't be blank"
        When I enter "ENGLAND" in the "Country where ID was issued" select or text field
        And I select "ID Card" from the "Type of ID"
        And I click on the "Next" button

        Then I should see the "Tenant address" page
        When I click on the "Next" button
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click the "Next" button
        Then I should see the "Tenant's contact address" page
        When I click on the "Next" button
        Then I should receive the message "Should we use a different address for future correspondence in relation to this return can't be blank"
        When I check "No" radio button
        And I click the "Next" button
        Then I should see the "Tenant details" page

        Then I should see the "Is the tenant connected to the landlord?" page
        When I click on the "Next" button
        Then I should receive the message "Is the tenant connected to the landlord can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button

        Then I should see the "Tenant details" page
        When I click on the "Next" button
        Then I should see the text "Is the tenant acting as a trustee or representative partner for tax purposes can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button

        Then I should see the "Return Summary" page
        Then I should see the text "Mr firstname surname"
        Then I should see the text "Royal Mail, LUTON, LU1 1AA"
        Then I should see the text "A private individual"
        Then I should see the text "Edit row"

        # Landlord
        When I click on the "Add a landlord" link
        Then I should see the "About the landlord" page
        And I click on the "Next" button
        Then I should receive the message "Who is the landlord can't be blank"
        When I check "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Landlord details" page
        And I click on the "Next" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        When I enter "surname" in the "Last name" field
        And I enter "lanlord firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I click on the "Next" button
        Then I should see the "Landlord address" page
        When I click on the "Next" button
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click the "Next" button
        Then I should see the "Return Summary" page
        And I should see the text "Mr lanlord firstname surname"
        And I should see the text "Royal Mail, LUTON, LU1 1AA"
        And I should see the text "A private individual"
        And I should see the text "Edit row"

        # Edit landlord
        When I click on the 2 nd "Edit row" link
        Then I should see the "About the landlord" page
        Then the radio button "A private individual" should be selected

        When I click on the "Next" button
        Then I should see the "Landlord details" page
        And I should see the text "surname" in field "Last name"
        And I should see the text "lanlord firstname" in field "First name"

        When I enter "lanlord surname" in the "Last name" field
        And I click on the "Next" button
        Then I should see the "Landlord address" page
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"

        When I click the "Next" button
        Then I should see the "Return Summary" page
        And I should see the text "Mr lanlord firstname lanlord surname"

        # Delete them
        When I click on the 2 nd "Delete row" link
        And if available, click the confirmation dialog
        Then I should see the "Return Summary" page
        And I should not see the text "landlord firstname surname"
        And I should not see the text "report this error"

        # Add them again
        When I click on the "Add a landlord" link
        And I check "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Landlord details" page

        When I enter "landlord-surname" in the "Last name" field
        And I enter "lanlord firstname" in the "First name" field
        And I select "Mrs" from the "Title"
        And I click on the "Next" button
        Then I should see the "Landlord address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I click the "Next" button
        Then I should see the "Return Summary" page

        # Transaction
        When I click on the "Add" link with id "add_transaction_calculation"
        Then I should see the "About the transaction" page

        When I click on the "Next" button
        Then I should receive the message "What is the property type for this transaction can't be blank"
        When I check "Residential" radio button
        And I click on the "Next" button
        Then I should see the "About the dates" page

        When I click on the "Next" button
        Then I should receive the message "Effective date of transaction can't be blank"
        And I should receive the message "Relevant date can't be blank"
        And I should receive the message "Date of contract or conclusion of missives can't be blank"
        And I should receive the message "Lease start date can't be blank"
        And I should receive the message "Lease end date can't be blank"

        When I enter "2019-08-02" in the "Effective date of transaction" field
        And I enter "2019-08-03" in the "Relevant date" field
        And I enter "2019-08-03" in the "Date of contract or conclusion of missives" field
        And I enter "2019-10-10" in the "Lease start date" field
        And I enter "2019-10-05" in the "Lease end date" field
        And I click on the "Next" button
        Then I should receive the message "Lease start date must be BEFORE lease end date"
        And I should receive the message "Lease end date must be AFTER lease start date"

        And I enter "2023-10-08" in the "Lease end date" field
        And I click on the "Next" button

        Then I should see the "About the transaction" page
        And I click on the "Next" button
        Then I should receive the message "Is the transaction linked to a previous option agreement can't be blank"
        And I should receive the message "Does the transaction include any element of exchange or part exchange can't be blank"
        And I should receive the message "Is this transaction part of a number of other transactions elsewhere in the UK, but outside Scotland can't be blank"
        And I check "returns_lbtt_lbtt_return_previous_option_ind_y" radio button
        And I check "returns_lbtt_lbtt_return_exchange_ind_y" radio button
        And I check "returns_lbtt_lbtt_return_uk_ind_y" radio button
        And I click on the "Next" button

        Then I should see the "Linked Transactions" page

        # linked-transactions - select no to get positive calculation results
        When I click on the "Next" button
        Then I should receive the message "Are there any linked transactions can't be blank"
        When I check "No" radio button
        And I click on the "Next" button
        Then I should see the "Reliefs on this transaction" page

        # reliefs on transaction
        When I click on the "Next" button
        Then I should receive the message "Is relief being claimed for this transaction can't be blank"
        When I check "Yes" radio button
        When I enter "208" in the "returns_lbtt_lbtt_return_non_ads_relief_claims_0_relief_amount" field
        And I select "Friendly societies relief" from the "returns_lbtt_lbtt_return_non_ads_relief_claims_0_relief_type"
        And I click on the "Next" button
        Then I should see the "About the lease values" page

        # about the lease_values rental years
        And I click on the "Next" button
        Then I should receive the message "How much is the rent for the first year (inc VAT) can't be blank"
        When I enter "invalid" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Next" button
        Then I should receive the message "How much is the rent for the first year (inc VAT) is not a number"
        When I enter "-1234" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Next" button
        Then I should receive the message "How much is the rent for the first year (inc VAT) must be greater than or equal to 0"
        When I enter "1234.56789" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Next" button
        Then I should receive the message "How much is the rent for the first year (inc VAT) must be a number to 2 decimal places"
        When I enter "1000000000000000000" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Next" button
        Then I should receive the message "How much is the rent for the first year (inc VAT) must be less than 1000000000000000000"
        When I enter "350000" in the "How much is the rent for the first year (inc VAT)?" field
        And I click on the "Next" button
        Then I should see the "About the lease values" page

        When I click on the "Next" button
        Then I should receive the message "Is this the same value for all rental years can't be blank"
        # Validation for rental years
        When I check the "No" radio button
        # Rental years
        Then I should see the text "Year 4"
        And I should not see the text "Year 5"
        When I click on the "Next" button
        Then I should receive the message "Please fill in the rent for all of the rental years"
        When I enter "350000" in the "returns_lbtt_lbtt_return_yearly_rents_0_rent" field
        When I enter "Hello" in the "returns_lbtt_lbtt_return_yearly_rents_1_rent" field
        And I click on the "Next" button
        Then I should receive the message "Invalid rental details year 2"
        And I should receive the message "Missing rental details year 3"
        And I should receive the message "Missing rental details year 4"
        When I enter "350100" in the "returns_lbtt_lbtt_return_yearly_rents_1_rent" field
        And I enter "360200" in the "returns_lbtt_lbtt_return_yearly_rents_2_rent" field
        And I enter "370200" in the "returns_lbtt_lbtt_return_yearly_rents_3_rent" field
        And I click on the "Next" button
        # Going back to the about the dates page to set the years
        And I click on the "Back" link
        And I click on the "Back" link
        And I click on the "Back" link
        And I click on the "Back" link
        And I click on the "Back" link
        And I click on the "Back" link
        Then I should see the "About the dates" page
        # Deducted two years
        When I enter "2021-10-08" in the "Lease end date" field
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        Then I should see the "About the lease values" page
        And I should see the text "Year 2"
        And I should not see the text "Year 3"
        # Then back to rental years page to re-add the rental year values
        When I click on the "Back" link
        And I click on the "Back" link
        And I click on the "Back" link
        And I click on the "Back" link
        And I click on the "Back" link
        And I enter "2023-10-08" in the "Lease end date" field
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        Then I should see the empty field "returns_lbtt_lbtt_return_yearly_rents_2_rent"
        And I should see the empty field "returns_lbtt_lbtt_return_yearly_rents_3_rent"
        And I should see the text "Year 3"
        And I should see the text "Year 4"
        And I should not see the text "Year 5"
        And I enter "32200" in the "returns_lbtt_lbtt_return_yearly_rents_2_rent" field
        And I enter "32200" in the "returns_lbtt_lbtt_return_yearly_rents_3_rent" field
        And I click on the "Next" button
        Then I should see the "About the lease values" page
        And I should not see the text "Premium for linked transactions"

        # Premium paid
        And I click on the "Next" button
        Then I should receive the message "Is a premium being paid can't be blank"
        When I check "Yes" radio button
        And I click on the "Next" button
        Then I should receive the message "Premium amount (inc VAT) can't be blank"
        When I enter "invalid" in the "Premium amount (inc VAT)" field
        And I click on the "Next" button
        Then I should receive the message "Premium amount (inc VAT) is not a number"
        When I enter "-1300" in the "Premium amount (inc VAT)" field
        And I click on the "Next" button
        Then I should receive the message "Premium amount (inc VAT) must be greater than or equal to 0"
        When I enter "1300.123456" in the "Premium amount (inc VAT)" field
        And I click on the "Next" button
        Then I should receive the message "Premium amount (inc VAT) must be a number to 2 decimal places"
        When I enter "1000000000000000000" in the "Premium amount (inc VAT)" field
        And I click on the "Next" button
        Then I should receive the message "Premium amount (inc VAT) must be less than 1000000000000000000"
        When I enter "352000" in the "Premium amount (inc VAT)" field
        And I click on the "Next" button
        Then I should see the "About the lease values" page

        # relevant_rent
        And I click on the "Next" button
        Then I should receive the message "What is the relevant rent amount for this transaction can't be blank"
        When I enter "invalid" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Next" button
        Then I should receive the message "What is the relevant rent amount for this transaction is not a number"
        When I enter "-12300" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Next" button
        Then I should receive the message "What is the relevant rent amount for this transaction must be greater than or equal to 0"
        When I enter "123.5600" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Next" button
        Then I should receive the message "What is the relevant rent amount for this transaction must be a number to 2 decimal places"
        When I enter "1000000000000000000" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Next" button
        Then I should receive the message "What is the relevant rent amount for this transaction must be less than 1000000000000000000"
        When I enter "351000" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Next" button
        Then I should see the "Calculated Net Present Value (NPV)" page
        And I should not see the text "for linked transactions"

        # NPV calculated tax
        And I should see the text "722089.34" in field "Net Present Value (NPV)"
        When I enter "" in the "Net Present Value (NPV)" field
        And I click on the "Next" button
        Then I should receive the message "Net Present Value (NPV) can't be blank"
        When I enter "invalid" in the "Net Present Value (NPV)" field
        And I click on the "Next" button
        Then I should receive the message "Net Present Value (NPV) is not a number"
        When I enter "-12101" in the "Net Present Value (NPV)" field
        And I click on the "Next" button
        Then I should receive the message "Net Present Value (NPV) must be greater than or equal to 0"
        When I enter "12.101" in the "Net Present Value (NPV)" field
        And I click on the "Next" button
        Then I should receive the message "Net Present Value (NPV) must be a number to 2 decimal places"
        And I enter "1000000000000000000" in the "Net Present Value (NPV)" field
        And I click on the "Next" button
        And I should receive the message "Net Present Value (NPV) must be less than 1000000000000000000"

        When I enter "353000" in the "Net Present Value (NPV)" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        And the table of data is displayed
            | About the transaction                                  | Edit            |
            | What is the property type for this transaction?        | Residential     |
            | Effective date of transaction                          | 02 August 2019  |
            | Relevant date                                          | 03 August 2019  |
            | Lease start date                                       | 10 October 2019 |
            | Lease end date                                         | 08 October 2023 |
            | What is the relevant rent amount for this transaction? | £351000.00      |
            | Premium amount (inc VAT)                               | £352000.00      |
            | Net Present Value (NPV)                                | £353000.00      |
            | Are there any linked transactions?                     | No              |
            | Is relief being claimed for this transaction?          | Yes             |

        # Calculation happened after the transaction section
        And the table of data is displayed
            | About the calculation         | Edit      |
            | LBTT tax liability on rent    | £2030.00  |
            | LBTT tax liability on premium | £11450.00 |
            | Total LBTT reliefs claimed    | £208.00   |
            | Total tax payable             | £13272.00 |

        # Edit calculation
        When I click on the "Edit" link with id "edit_calculation"
        Then I should see the "Calculated tax" page
        And I should see the text "2030" in field "LBTT tax liability on rent"
        And I should see the text "11450" in field "LBTT tax liability on premium"
        And I should see the text "208" in field "Total LBTT reliefs claimed"

        When I enter "" in the "LBTT tax liability on rent" field
        And I enter "" in the "LBTT tax liability on premium" field
        And I enter "abc" in the "Total LBTT reliefs claimed" field
        And I click on the "Next" button
        And I should receive the message "LBTT tax liability on rent can't be blank"
        And I should receive the message "LBTT tax liability on premium can't be blank"
        And I should receive the message "Total LBTT reliefs claimed is not a number"

        # Can change the values
        When I enter "38469" in the "LBTT tax liability on rent" field
        And I enter "18401" in the "LBTT tax liability on premium" field
        And I enter "100" in the "Total LBTT reliefs claimed" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the calculation         | Edit      |
            | LBTT tax liability on rent    | £38469.00 |
            | LBTT tax liability on premium | £18401.00 |
            | Total LBTT reliefs claimed    | £100.00   |
            | Total tax payable             | £56770.00 |

        When I click the "Submit return" button
        Then I should see the "Payment and submission" page
        When I click the "Submit return" button
        Then I should see the text "How are you paying can't be blank"
        And I should see the text "The authority declaration can't be blank"
        And I should see the text "The declaration must be accepted"
        And I should see the text "The review declaration must be accepted"
        And I should see the text "I, the agent of the tenant(s), having been authorised to complete this return on behalf of the tenant(s):"
        And I should see the text "I, the agent for the tenant(s), confirm that I have authority to deal with all matters relating to this transaction on behalf of my client(s)"
        And I should see the text "I, the agent of the tenant(s), confirm that I have made my client(s) aware of their obligation to submit a three-yearly lease review return, or an assignation or termination return if such an event occurs before the review date."

        When I check "returns_lbtt_lbtt_return_declaration" checkbox
        When I check "returns_lbtt_lbtt_return_lease_declaration" checkbox
        And I check the "BACS" radio button
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button

        And I click on the "Submit return" button
        Then I should see the text "Your return has been submitted"
        And I should see the text "Transaction reference"
        And I should see the regex "RS\d{7}[a-zA-Z]{4}"
        And the table of data is displayed
            | Title number                  | ABN 1234                                                         |
            | Property address              | First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE |
            | Tenant                        | Mr firstname surname                                             |
            | Description of transaction    | Lease                                                            |
            | Effective date                | 02/08/2019                                                       |
            | Agent reference (if provided) | my agent ref                                                     |

    Scenario: Submit a lease review through transaction wizard and claim repayment wizard
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link
        Then I should see the "About the return" page
        When I check the "3 year lease review" radio button
        And I click on the "Next" button
        Then I should see the "Return reference number" page

        When I click on the "Next" button
        Then I should receive the message "What was the original return reference format is invalid"
        When I enter "RSL123456" in the "What was the original return reference?" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # pre-calculate validation
        When I click on the "Submit return" button
        Then I should see the text "Please fill at least one tenant details"
        And I should see the text "Please fill at least one property details"
        And I should see the text "Please fill in the 'About the transaction' section"

        When I click on the "Amend" link
        Then I should see the "Agent details" page
        And I select "Mr" from the "Title"
        And I enter "0123456789" in the "Telephone number" field
        And I click on the "Next" button
        Then I should see the "Agent address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Return Summary" page

        When I click on the "Add a tenant" link
        Then I should see the "About the tenant" page
        When I check "A private individual" radio button
        And I click on the "Next" button
        Then I should see the "Tenant details" page
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I enter "0123456789" in the "Telephone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "AB123456C" in the "National Insurance Number (NINO)" field
        And I click on the "Next" button
        Then I should see the "Tenant address" page
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click the "Next" button
        Then I should see the "Tenant's contact address" page
        When I check "No" radio button
        And I click the "Next" button

        Then I should see the "Tenant details" page
        When I check "No" radio button
        And I click the "Next" button

        Then I should see the "Tenant details" page
        When I click on the "Next" button
        Then I should see the text "Is the tenant acting as a trustee or representative partner for tax purposes can't be blank"
        When I check "Yes" radio button
        And I click the "Next" button
        Then I should see the "Return Summary" page

        When I click on the "add_property" link
        Then I should see the "Property address" page
        When I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"
        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        When I click on the "add_transaction_calculation" link
        Then I should see the "About the dates" page
        And I click on the "Next" button
        Then I should receive the message "Effective date of transaction can't be blank"
        And I should receive the message "Relevant date can't be blank"
        And I should receive the message "Date of contract or conclusion of missives can't be blank"
        And I should receive the message "Lease start date can't be blank"
        And I should receive the message "Lease end date can't be blank"
        When I enter "2019-08-02" in the "Effective date of transaction" field
        And I enter "2019-08-03" in the "Relevant date" field
        And I enter "2019-08-03" in the "Date of contract or conclusion of missives" field
        And I enter "2019-08-03" in the "Lease start date" field
        And I enter "2028-08-03" in the "Lease end date" field
        And I click on the "Next" button

        Then I should see the "Linked Transactions" page
        When I click on the "Next" button
        Then I should receive the message "Are there any linked transactions can't be blank"
        When I check "Yes" radio button
        And I enter "1234" in the "returns_lbtt_lbtt_return_link_transactions_0_npv_inc" field
        And I enter "100" in the "returns_lbtt_lbtt_return_link_transactions_0_premium_inc" field
        And I click on the "Next" button

        Then I should see the "About the lease values" page
        And I click on the "Next" button
        Then I should receive the message "How much was the rent for the first year (inc VAT) is not a number"
        When I enter "1000" in the "How much was the rent for the first year (inc VAT)?" field
        And I click on the "Next" button

        Then I should see the "About the lease values" page
        When I click on the "Next" button
        Then I should receive the message "Is this the same value for all rental years can't be blank"
        When I check "No" radio button
        When I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_0_rent" field
        And I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_1_rent" field
        And I enter "0" in the "returns_lbtt_lbtt_return_yearly_rents_2_rent" field
        And I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_3_rent" field
        And I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_4_rent" field
        And I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_5_rent" field
        And I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_6_rent" field
        And I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_7_rent" field
        And I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_8_rent" field
        And I enter "20" in the "returns_lbtt_lbtt_return_yearly_rents_9_rent" field
        And I click on the "Next" button

        Then I should see the "About the lease values" page
        And I should see the text "100" in field "Premium for linked transactions"

        When I enter "" in the "Premium for linked transactions" field
        And I click on the "Next" button
        Then I should receive the message "Is a premium being paid can't be blank"
        And I should receive the message "Premium for linked transactions is not a number"
        When I check "Yes" radio button
        And I enter "-21" in the "Premium for linked transactions" field
        And I click on the "Next" button
        Then I should receive the message "Premium amount (inc VAT) is not a number"
        And I should receive the message "Premium for linked transactions must be greater than or equal to 0"
        And I enter "200" in the "Premium amount (inc VAT)" field
        And I enter "2001" in the "Premium for linked transactions" field
        And I click on the "Next" button

        Then I should see the "About the lease values" page
        And I click on the "Next" button
        Then I should receive the message "What is the relevant rent amount for this transaction is not a number"
        When I enter "22300" in the "What is the relevant rent amount for this transaction?" field
        And I click on the "Next" button
        Then I should see the "Calculated Net Present Value (NPV)" page

        # NPV
        And I should see the text "148.29" in field "Net Present Value (NPV)"
        And I should see the text "1234" in field "Net Present Value (NPV) for linked transactions"
        When I enter "" in the "Net Present Value (NPV)" field
        And I enter "" in the "Net Present Value (NPV) for linked transactions" field
        And I click on the "Next" button
        Then I should receive the message "Net Present Value (NPV) is not a number"
        And I should receive the message "Net Present Value (NPV) for linked transactions is not a number"
        When I enter "10000" in the "Net Present Value (NPV)" field
        And I enter "5000" in the "Net Present Value (NPV) for linked transactions" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # Check amount already paid validation and calculation
        When I click on the "Edit" link with id "edit_calculation"
        When I enter "" in the "Amount already paid" field
        And I click on the "Next" button
        And I should receive the message "Amount already paid can't be blank"
        When I enter "abc" in the "Amount already paid" field
        And I click on the "Next" button
        And I should receive the message "Amount already paid is not a number"
        When I enter "-100" in the "Amount already paid" field
        And I click on the "Next" button
        And I should receive the message "Amount already paid must be greater than or equal to 0"
        When I enter "100" in the "Amount already paid" field
        And I click on the "Next" button
        Then I should see the "Calculated tax" page

        # Check can change the values
        When I enter "38469" in the "LBTT tax liability on rent" field
        And I enter "18401" in the "LBTT tax liability on premium" field

        When I click on the "Next" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the calculation          | Edit      |
            | LBTT tax liability on rent     | £38469.00 |
            | LBTT tax liability on premium  | £18401.00 |
            | Total tax payable              | £56870.00 |
            | Amount already paid            | £100.00   |
            | Amount payable for this return | £56770.00 |

        When I click the "Submit return" button
        Then I should see the "Repayment details" page

        When I click on the "Next" button
        Then I should receive the message "Do you want to request a repayment from Revenue Scotland can't be blank"
        When I check "Yes" radio button
        And I click on the "Next" button
        Then I should see the "Claim repayment" page

        # it should be blank to start with
        When I click on the "Next" button
        Then I should receive the message "How much are you claiming for repayment is not a number"
        When I enter "-750" in the "How much are you claiming for repayment?" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming for repayment must be greater than or equal to 0"
        When I enter "750.000000" in the "How much are you claiming for repayment?" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming for repayment must be a number to 2 decimal places"
        When I enter "1000000000000000000" in the "How much are you claiming for repayment?" field
        And I click on the "Next" button
        Then I should receive the message "How much are you claiming for repayment must be less than 1000000000000000000"
        When I enter "750" in the "How much are you claiming for repayment?" field
        And I click on the "Next" button
        Then I should see the "Enter bank details" page

        # details should be blank to start with
        When I click on the "Next" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "RANDOM_text,256" in the "Name of the account holder" field
        And I enter "RANDOM_text,11" in the "Bank / building society account number" field
        And I enter "RANDOM_text,9" in the "Branch sort code" field
        And I enter "RANDOM_text,256" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the text "Bank / building society account number is not a number"
        And I should see the text "Bank / building society account number is the wrong length (should be 8 characters)"
        And I should see the text "Branch sort code is invalid"

        When I enter "Fred Flintstone" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Next" button

        Then I should see the "Declaration" page
        Then I should see the text "I, the agent for the tenant(s), confirm that the tenant(s) have authorised repayment to be made to these bank details"
        And I should see the text "I, the agent of the tenant(s), having been authorised to complete this claim on behalf of the tenant(s), certify that the tenant(s) has/have declared that the information provided in the claim is to the best of their knowledge, correct and complete, and confirm that the tenant(s) is/are eligible for the refund claimed"
        When I click on the "Next" button
        Then I should receive the message "The refund declaration must be accepted"
        And I should receive the message "The bank account declaration must be accepted"
        When I check "returns_lbtt_lbtt_return_repayment_declaration" checkbox
        And I check "returns_lbtt_lbtt_return_repayment_agent_declaration" checkbox
        And I click on the "Next" button
        Then I should see the "Payment and submission" page

        # payment and submission
        When I click on the "Submit return" button
        Then I should see the text "How are you paying can't be blank"
        And I should see the text "The declaration must be accepted"
        When I check the "Direct Debit" radio button
        And I check "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button

        And I click on the "Submit return" button
        Then I should see the text "Your return has been submitted"
        And I should see the text "Transaction reference"
        And I should see the regex "RS\d{7}[a-zA-Z]{4}"
        And the table of data is displayed
            | Title number               | ABN 1234                                                         |
            | Property address           | First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE |
            | Tenant                     | Mr firstname surname                                             |
            | Description of transaction | 3 year lease review                                              |
            | Effective date             | 02/08/2019                                                       |

    Scenario: Validate, calculate, declaration and submit a conveyance return
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Create LBTT return" link

        Then I should see the "About the return" page
        And I click on the "Next" button

        # Mandatory validation for selection of lbtt return type
        Then I should receive the message "Which return do you want to submit can't be blank"
        And I check the "Conveyance or transfer" radio button
        And I click on the "Next" button

        Then I should see the "Return Summary" page

        # pre-calculate validation
        When I click on the "Submit return" button
        Then I should see the text "Please fill in the 'About the transaction' section"
        And I should see the text "Please fill at least one property details"
        And I should see the text "Please fill at least one buyer details"
        And I should see the text "Please fill at least one seller details"

        # Agent
        And I should see the text "Portal User New Users"
        And I should see the text "Contact details for agent"
        When I click on the "Amend" link

        # Pre populate agent details
        Then I should see the "Agent details" page
        And I should see the text "Portal User" in field "First name"
        And I should see the text "New Users" in field "Last name"
        And I should see the text "noreply@northgateps.com" in field "Email"
        And I should see the text "07700900321" in field "Telephone number"

        # Clear the fields to check mandatory Validation
        When I enter "" in the "First name" field
        And I enter "" in the "Last name" field
        And I enter "" in the "Email" field
        And I enter "" in the "Telephone number" field
        And I click on the "Next" button
        Then I should receive the message "First name can't be blank"
        And I should receive the message "Last name can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Telephone number can't be blank"

        # validation on email
        And I enter "x.com" in the "Email" field
        When I click on the "Next" button
        Then I should receive the message "Email is invalid"

        # re enter details
        And I select "Mr" from the "Title"
        And I enter "Portal User" in the "First name" field
        And I enter "New Users" in the "Last name" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "07700900321" in the "Telephone number" field

        When I click on the "Next" button
        Then I should see the "Agent address" page

        # address pre populated
        And I should see the text "2 Park Lane" in field "address_address_line1"
        And I should see the text "Garden Village" in field "address_address_line2"
        And I should see the text "NORTHTOWN" in field "address_town"
        And I should see the text "RG1 1PB" in field "address_postcode"
        And I click on the "Next" button

        Then I should see the "Return Summary" page
        And I should see the text "Mr Portal User New Users"

        # Property
        When I click on the "Add" link with id "add_property"
        And I enter "EH1 1BE" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "First Scotrail Ltd, Waverley Railway Station, EDINBURGH, EH1 1BE" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button
        Then I should see the sub-title "Provide property details"

        When I select "Aberdeen City" from the "Local authority"
        And I select "ABN" from the "returns_lbtt_property_title_code"
        And I enter "1234" in the "returns_lbtt_property_title_number" field
        And I click on the "Next" button
        Then I should see the "Does Additional Dwelling Supplement (ADS) apply to this transaction?" page

        When I check the "Yes" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # ADS
        When I click on the "Add" link with id "add_ads"
        Then I should see the "Additional Dwelling Supplement (ADS)" page

        When I check the "Yes" radio button
        And I click on the "Next" button
        And I enter "40503" in the "Amount of ADS liability from new main residence" field
        And I enter "40751" in the "Total consideration liable to ADS" field
        And I click on the "Next" button
        Then I should see the text "Does the buyer intend to sell their main residence within 18 months?"

        When I check the "Yes" radio button
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I click on the "Next" button
        Then I should see the "Reliefs on ADS consideration" page

        When I check the "No" radio button
        And I click on the "Next" button
        Then I should see the "Return Summary" page

        # Buyer as organisation
        When I click on the "Add a buyer" link
        Then I should see the "About the buyer" page
        And I click on the "Next" button
        Then I should receive the message "Who is the buyer can't be blank"

        When I check the "An other organisation" radio button
        And I click on the "Next" button
        Then I should see the "Organisation details" page
        And I click on the "Next" button
        Then I should receive the message "Type of organisation can't be blank"

        When I check the "Other" radio button
        And I click on the "Next" button
        Then I should receive the message "Organisation description can't be blank"

        When I check the "Club" radio button
        And I click on the "Next" button

        Then I should see the sub-title "Club details"
        When I click on the "Next" button
        Then I should receive the message "What country's law is the organisation governed by can't be blank"
        And I should receive the message "Name can't be blank"
        And I should receive the message "Postcode search should be used, or the address should be entered manually"
        When I enter "club name" in the "Name" field
        And I enter "ALBANIA" in the "What country's law is the organisation governed by" select or text field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click on the "Next" button

        Then I should see the "Contact details" page
        And I click on the "Next" button
        Then I should receive the message "Contact phone number can't be blank"
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Job title or position can't be blank"
        And I should receive the message "Email can't be blank"
        And I should receive the message "Postcode search should be used, or the address should be entered manually"

        #invalid contact email and phone number
        When I enter "012" in the "Contact phone number" field
        And I enter "noreplynorthgateps.com" in the "Email" field
        And I click on the "Next" button
        Then I should receive the message "Contact phone number is invalid"
        And I should receive the message "Email is invalid"

        When I enter "member" in the "Last name" field
        And I enter "club" in the "First name" field
        And I enter "Developer" in the "Job title or position" field
        And I enter "0123456789" in the "Contact phone number" field
        And I enter "noreply@northgateps.com" in the "Email" field
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click on the "Next" button

        Then I should see the "Buyer details" page
        When I click on the "Next" button
        Then I should see the text "Is the buyer connected to the seller can't be blank"
        When I check the "Yes" radio button
        And I click on the "Next" button

        Then I should see the "Buyer details" page
        When I click on the "Next" button
        Then I should see the text "Is the buyer acting as a trustee or representative partner for tax purposes can't be blank"
        When I check the "Yes" radio button
        And I click on the "Next" button

        Then I should see the "Return Summary" page
        And I should see the text "club name"
        And I should see the text "Club"

        # Seller as A private individual
        When I click on the "Add a seller" link
        Then I should see the "About the seller" page

        When I check the "A private individual" radio button
        And I click on the "Next" button

        Then I should see the "Seller details" page
        And I click on the "Next" button
        And I should receive the message "Last name can't be blank"
        And I should receive the message "First name can't be blank"
        When I enter "surname" in the "Last name" field
        And I enter "firstname" in the "First name" field
        And I select "Mr" from the "Title"
        And I click on the "Next" button

        Then I should see the "Seller address" page
        When I click on the "Next" button
        Then I should receive the message "Postcode search should be used, or the address should be entered manually"
        And I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find Address" button
        And I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And if available, click the "Select" button
        And I should see the text "Royal Mail" in field "address_address_line1"
        And I should see the text "Luton Delivery Office 9-11" in field "address_address_line2"
        And I should see the text "Dunstable Road" in field "address_address_line3"
        And I should see the text "LUTON" in field "address_town"
        And I should see the text "LU1 1AA" in field "address_postcode"
        And I click on the "Next" button

        Then I should see the "Return Summary" page
        Then I should see the text "Mr firstname surname"
        Then I should see the text "Royal Mail, LUTON, LU1 1AA"
        Then I should see the text "A private individual"
        Then I should see the text "Edit row"

        # Transaction wizard and validation

        And I click on the "Add" link with id "add_transaction_calculation"
        Then I should see the "About the transaction" page
        And I click on the "Next" button
        Then I should receive the message "What is the property type for this transaction can't be blank"
        And I check the "Residential" radio button
        And I click on the "Next" button

        Then I should see the "About the dates" page
        And I click on the "Next" button
        Then I should receive the message "Effective date of transaction can't be blank"
        And I should receive the message "Relevant date can't be blank"
        And I should receive the message "Date of contract or conclusion of missives can't be blank"
        When I enter "2019-08-02" in the "Effective date of transaction" field
        And I enter "2019-08-03" in the "Relevant date" field
        And I enter "2019-08-03" in the "Date of contract or conclusion of missives" field
        And I click on the "Next" button

        Then I should see the "About the transaction" page
        And I click on the "Next" button
        Then I should receive the message "Is the transaction linked to a previous option agreement can't be blank"
        And I should receive the message "Does the transaction include any element of exchange or part exchange can't be blank"
        And I should receive the message "Is this transaction part of a number of other transactions elsewhere in the UK, but outside Scotland can't be blank"
        And I check the "returns_lbtt_lbtt_return_previous_option_ind_y" radio button
        And I check the "returns_lbtt_lbtt_return_exchange_ind_y" radio button
        And I check the "returns_lbtt_lbtt_return_uk_ind_y" radio button
        And I click on the "Next" button

        Then I should see the "Linked Transactions" page
        When I click on the "Next" button
        Then I should receive the message "Are there any linked transactions can't be blank"
        When I check the "Yes" radio button
        Then I should not see the button with text "Delete row"
        And I click on the "Next" button
        Then I should receive the message "At least one record must be entered"

        When I enter "hello world" in the "returns_lbtt_lbtt_return[link_transactions][0][return_reference]" field
        And I click on the "Add row" button
        Then I should see the button with text "Delete row"
        When I enter "12340000000000000000000000000000000000000000000000000000" in the "returns_lbtt_lbtt_return_link_transactions_1_consideration_amount" field
        And I click on the "Add row" button
        And I enter "abc" in the "returns_lbtt_lbtt_return_link_transactions_2_consideration_amount" field
        And I click on the "Next" button
        Then I should receive the message "Missing transaction details row 1"
        And I should receive the message "Invalid transaction details row 2"
        And I should receive the message "Invalid transaction details row 3"

        When I enter "0" in the "returns_lbtt_lbtt_return_link_transactions_0_consideration_amount" field
        And I enter "200" in the "returns_lbtt_lbtt_return_link_transactions_1_consideration_amount" field
        And I enter "300" in the "returns_lbtt_lbtt_return_link_transactions_2_consideration_amount" field
        And I click on the "Next" button
        Then I should see the "About the transaction" page

        When I click on the "Next" button
        Then I should receive the message "Is the transaction part of the sale of a business can't be blank"
        When I check the "Yes" radio button
        And I click on the "Next" button
        Then I should receive the message "Does the sale include any of the following must have one option ticked"
        When I check "Goodwill" checkbox
        And I click on the "Next" button

        Then I should see the "Reliefs on this transaction" page
        # check ADS options have been filtered out
        And "returns_lbtt_lbtt_return_ads_relief_claims_0_relief_type" should not contain the option "ADS - Family units"
        When I click on the "Next" button
        Then I should receive the message "Is relief being claimed for this transaction can't be blank"
        When I check the "Yes" radio button
        And I click on the "Next" button
        Then I should receive the message "At least one record must be entered"
        When I check the "Yes" radio button
        Then I should not see the button with text "Delete row"
        When I enter "2088" in the "returns_lbtt_lbtt_return_non_ads_relief_claims_0_relief_amount" field
        And I select "Friendly societies relief" from the "returns_lbtt_lbtt_return_non_ads_relief_claims_0_relief_type"
        And I click on the "Add row" button
        Then I should see the button with text "Delete row"

        When I enter "1456" in the "returns_lbtt_lbtt_return_non_ads_relief_claims_1_relief_amount" field
        And I select "Friendly societies relief" from the "returns_lbtt_lbtt_return_non_ads_relief_claims_1_relief_type"
        And I click on the "Next" button

        Then I should receive the message "A relief type can only be used once on a return"
        And I select "Lighthouses relief" from the "returns_lbtt_lbtt_return_non_ads_relief_claims_1_relief_type"

        And I click on the "Next" button

        Then I should see the "About future events" page
        When I click on the "Next" button
        Then I should receive the message "Does any part of your consideration depend on future events, like planning permission can't be blank"
        When I check the "returns_lbtt_lbtt_return_contingents_event_ind_y" radio button
        And I click on the "Next" button
        Then I should receive the message "Have you applied to pay on a deferred basis can't be blank"
        When I check the "returns_lbtt_lbtt_return_deferral_agreed_ind_y" radio button
        And I click on the "Next" button
        Then I should receive the message "Revenue Scotland deferral reference can't be blank"
        When I enter "1234" in the "Revenue Scotland deferral reference" field
        And I click on the "Next" button

        Then I should see the "About the conveyance or transfer" page
        And I should see the text "500" in field "Linked transaction consideration"

        When I enter "" in the "Linked transaction consideration" field
        And I click on the "Next" button
        Then I should receive the message "Total consideration is not a number"
        And I should receive the message "VAT amount is not a number"
        And I should receive the message "Linked transaction consideration is not a number"
        And I should receive the message "Non-chargeable consideration is not a number"
        And I should receive the message "Total consideration remaining is not a number"
        When I enter "1234567" in the "Total consideration" field
        And I enter "12345" in the "VAT amount" field
        And I enter "1245" in the "Linked transaction consideration" field
        And I enter "123" in the "Non-chargeable consideration" field
        And I enter "999999" in the "Total consideration remaining" field
        And I click on the "Next" button

        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the transaction                              | Edit           |
            | What is the property type for this transaction?    | Residential    |
            | Effective date of transaction                      | 02 August 2019 |
            | Relevant date                                      | 03 August 2019 |
            | Are there any linked transactions?                 | Yes            |
            | Is the transaction part of the sale of a business? | Yes            |
            | Is relief being claimed for this transaction?      | Yes            |
            | Total consideration remaining                      | £999999.00     |

        # Calculate
        When I click on the "Edit" link with id "edit_calculation"
        Then I should see the "Calculated tax" page
        And I should see the text "106525" in field "LBTT calculated"
        And I should see the text "1630" in field "ADS calculated"
        And I should see the text "3544" in field "Total LBTT reliefs claimed"

        # Can change the values
        When I enter "38469" in the "LBTT calculated" field
        And I enter "18401" in the "ADS calculated" field
        And I enter "100" in the "Total LBTT reliefs claimed" field
        And I click on the "Next" button
        Then I should see the "Return Summary" page
        And the table of data is displayed
            | About the calculation      | Edit      |
            | LBTT calculated            | £38469.00 |
            | ADS calculated             | £18401.00 |
            | Total liability            | £56870.00 |
            | Total LBTT reliefs claimed | £100.00   |
            | Total ADS reliefs claimed  | £0.00     |
            | Total tax payable          | £56770.00 |

        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page
        When I click on the "Submit return" button
        Then I should see the text "How are you paying can't be blank"
        And I should see the text "The authority declaration can't be blank"
        And I should see the text "The declaration must be accepted"
        And I should see the text "Direct Debit"
        And I should see the text "I, the agent for the buyer(s), confirm that I have authority to deal with all matters relating to this transaction on behalf of my client(s)"
        And I should see the text "I, the agent of the buyer(s), having been authorised to complete this return on behalf of the buyer(s):"


        When I check the "Direct Debit" radio button
        And I check "returns_lbtt_lbtt_return_declaration" checkbox
        And I check the "returns_lbtt_lbtt_return_authority_ind_y" radio button
        And I click on the "Submit return" button
        Then I should see the text "Your Land and Buildings Transaction Tax return has now been submitted."
        And I click on the "Send secure message" link
        Then I should see the "New message" page

