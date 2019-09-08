# feature/slft_returns.feature

Feature: SLfT Returns
    As a user
    I want to be able to make a SLfT return

    Scenario: About the transaction, credits claimed, waste wizards and check the calculation
        # About the transaction
        Given I have signed in "portal.waste.new" and password "Password1!"
        When I click on the "Create SLfT return" link
        Then I should see the "Return summary" page
        Then I click on the "Add return period" link
        Then I should see the "What accounting period is this return for?" page
        When I click the "Next" button
        Then I should see the text "year can't be blank"
        And I should see the text "quarter can't be blank"
        When I select "2017/18" from the "year"
        And I check "July to September (Quarter 2)" radio button
        And I click on the "Next" button
        Then I should see the "Non disposal area information" page
        When I click on the "Next" button
        Then I should see the text "non-disposal area on any of your sites can't be blank"
        When I check "No" radio button
        And I click on the "Next" button
        When I click on the "Next" button
        Then I should see the text "Have you ceased to operate a non-disposal area on any of your sites can't be blank"
        And I check "No" radio button
        And I click on the "Next" button
        Then I should see the "Return summary" page

        When I click on the "Edit return period" link
        And I click on the "Next" button
        And I check "Yes" radio button
        And I click the "Next" button
        Then I should see the text "which sites have a new non disposal area can't be blank"
        When I enter "RANDOM_text,4001" in the "Tell us which sites have a new non disposal area" field
        And click on the "Next" button
        Then I should see the text "which sites have a new non disposal area is too long"
        And I enter "Some really good sites" in the "Tell us which sites have a new non disposal area" field
        And I click on the "Next" button
        And I check "Yes" radio button
        And I click the "Next" button
        Then I should see the text "removed a non-disposal area from can't be blank"
        When I enter "RANDOM_text,4001" in the "Tell us which sites you have removed a non-disposal area from" field
        And click on the "Next" button
        Then I should see the text "removed a non-disposal area from is too long"
        When I enter "Some really bad sites" in the "Tell us which sites you have removed a non-disposal area from" field
        And I click on the "Next" button
        Then I should see the "Return summary" page

        # Credits claimed wizard
        And I click on the "Add credit details" link
        Then I should see the "Environmental credit" page
        When I click the "Next" button
        Then I should see the text "Are you claiming a credit in relation to an environmental contribution can't be blank"
        When I check the "No" radio button
        And I click the "Next" button
        Then I should see the "Bad debt credit" page
        When I click the "Next" button
        Then I should see the text "Do you have any claims to make in relation to bad debt can't be blank"
        When I check the "No" radio button
        And I click the "Next" button
        Then I should see the "Permanent removal credit" page
        When I click the "Next" button
        And I click the "Next" button
        Then I should see the text "Are you claiming a credit for permanent removal can't be blank"
        When I check the "No" radio button
        And I click the "Next" button
        Then I should see the "Return summary" page

        When I click on the "Edit credit details" link
        And I check "Yes" radio button
        And I click the "Next" button
        Then I should see the text "Contribution to environmental bodies is not a number"
        And I should see the text "Credit claimed in relation to the contribution is not a number"
        And I enter "1000000000000000000" in the "Contribution to environmental bodies" field
        And I enter "abc" in the "Credit claimed in relation to the contribution" field
        And I click on the "Next" button
        Then I should see the text "Contribution to environmental bodies must be less than 1000000000000000000"
        And I should see the text "Credit claimed in relation to the contribution is not a number"
        And I enter "0" in the "Contribution to environmental bodies" field
        And I enter "0" in the "Credit claimed in relation to the contribution" field
        And I click on the "Next" button
        Then I should see the text "Contribution to environmental bodies must be greater than 0"
        And I should see the text "Credit claimed in relation to the contribution must be less than the contribution to environmental bodies"

        And I enter "555.1299999999" in the "Contribution to environmental bodies" field
        And I enter "555.13" in the "Credit claimed in relation to the contribution" field
        And I click the "Next" button
        Then I should see the text "Credit claimed in relation to the contribution must be less than the contribution to environmental bodies"

        When I enter "333.6" in the "Credit claimed in relation to the contribution" field
        And I click on the "Next" button
        And I check "Yes" radio button
        And I enter "abc" in the "Bad debt claim amount" field
        And I click on the "Next" button
        Then I should see the text "Bad debt claim amount is not a number"
        And I check "Yes" radio button
        And I enter "-123.44" in the "Bad debt claim amount" field
        And I click on the "Next" button
        Then I should see the text "Bad debt claim amount must be greater than 0"
        And I enter "7123" in the "Bad debt claim amount" field
        And I click on the "Next" button

        And I check "Yes" radio button
        And I enter "abc.22" in the "Permanent removal claim amount" field
        And I click on the "Next" button
        Then I should see the text "Permanent removal claim amount is not a number"
        And I enter "0" in the "Permanent removal claim amount" field
        And I click on the "Next" button
        Then I should see the text "Permanent removal claim amount must be greater than 0"
        And I enter "564.22" in the "Permanent removal claim amount" field
        And I click on the "Next" button
        Then I should see the "Return summary" page
        And I should see the text "Edit credit details"

        # Check both tables of data exist (ie nothing's been lost)
        And the table of data is displayed
            | Return period                                                        | Edit return period |
            | SLfT year                                                            | 2017/18            |
            | SLfT quarter                                                         | July to September  |
            | Have you designated a new non-disposal area on any of your sites?    | Y                  |
            | Have you ceased to operate a non-disposal area on any of your sites? | Y                  |
        And the table of data is displayed
            | Credits claimed                                | Edit credit details |
            | Contribution to environmental bodies           | £555.12             |
            | Credit claimed in relation to the contribution | £333.60             |
            | Bad debt claim amount                          | £7123.00            |
            | Permanent removal claim amount                 | £564.22             |

        # Go back and check a form still has data
        When I click on the "Edit credit details" link
        Then I should see the text "555.12" in field "Contribution to environmental bodies"
        And I enter "1234" in the "Contribution to environmental bodies" field
        When I click on the "Next" button
        # Check the formatted amount is shown
        Then I should see the text "7123.00" in field "Bad debt claim amount"

        When I check the "No" radio button
        And I click on the "Next" button
        And I click on the "Next" button
        Then I should see the "Return summary" page

        # Check the data doesn't show but the previous stuff does
        And the table of data is displayed
            | Credits claimed                                | Edit credit details |
            | Contribution to environmental bodies           | £1234.00            |
            | Credit claimed in relation to the contribution | £333.60             |
            | Permanent removal claim amount                 | £564.22             |

        # Check clicking 'No' has hidden/deleted the data
        And I should not see the text "Bad debt claim amount"
        And I should not see the text "7123"
        And I should not see the text "7123.00"

        # Test the waste details entry
        And I should see the text "Waste Site 1"

        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        When I click on the "Add new waste type" link
        Then I should see the "Details of waste" page
        When I click on the "Next" button
        Then I should see the text "EWC code can't be blank"
        Then I should see the text "Description of waste can't be blank"
        Then I should see the text "Geographical area can't be blank"
        Then I should see the text "Management method can't be blank"
        Then I should see the text "Has this waste been moved out of a non-disposal area (NDA)"
        Then I should see the text "Is it pre-treated can't be blank"

        When I enter "05-01-03 Tank bottom sludges" in the "EWC code" select or text field
        And I enter "icky goo" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check "returns_slft_waste_from_non_disposal_ind_y" radio button
        And I check "returns_slft_waste_pre_treated_ind_y" radio button
        And I click on the "Next" button
        Then I should see the text "Provide tonnage details for this waste type"

        # They each have the same validation so check each combination in one go
        When I enter "aa" in the "Standard tonnage" field
        And I enter "0.213" in the "Lower tonnage" field
        And I enter "cc" in the "Exempt tonnage" field
        And I enter "-4" in the "Water discount tonnage" field
        And I click on the "Next" button
        Then I should receive the message "Standard tonnage is not a number"
        And I should receive the message "Lower tonnage must be a number to 2 decimal places"
        And I should receive the message "Water discount tonnage must be greater than or equal to 0"

        When I enter "10" in the "Standard tonnage" field
        And I enter "4" in the "Lower tonnage" field
        And I enter "13" in the "Exempt tonnage" field
        And I enter "aa" in the "Water discount tonnage" field
        And I click on the "Next" button
        Then I should receive the message "Exempt tonnage cannot be set when other tonnages are set"
        And I should receive the message "Standard tonnage cannot be set when other tonnages are set"
        And I should receive the message "Lower tonnage cannot be set when other tonnages are set"
        And I should receive the message "Water discount tonnage is not a number"

        When I enter "0" in the "Standard tonnage" field
        And I enter "0" in the "Lower tonnage" field
        And I enter "13" in the "Exempt tonnage" field
        And I enter "11" in the "Water discount tonnage" field
        And I click on the "Next" button
        Then I should receive the message "Water discount tonnage cannot be set when exempt tonnage is set"

        When I enter "0" in the "Water discount tonnage" field
        And I click on the "Next" button
        Then I should see the text "Why is some tonnage exempt?"
        When I click on the "Next" button
        Then I should see the text "At least one reason must be filled in"

        When I check the "returns_slft_waste_nda_ex_yes_no_y" radio button
        And I check the "returns_slft_waste_restoration_ex_yes_no_y" radio button
        And I check the "returns_slft_waste_other_ex_yes_no_y" radio button

        # They each have the same validation so check each combination in one go
        And I enter "aa" in the "NDA tonnage" field
        And I enter "0.415" in the "Restoration tonnage" field
        And I enter "-1" in the "Other tonnage" field
        And I click on the "Next" button
        Then I should see the text "NDA tonnage is not a number"
        Then I should see the text "Restoration tonnage must be a number to 2 decimal places"
        Then I should see the text "Other tonnage must be greater than 0"

        When I check the "returns_slft_waste_nda_ex_yes_no_n" radio button
        And I check the "returns_slft_waste_restoration_ex_yes_no_n" radio button
        And I enter "13" in the "Other tonnage" field

        And I click on the "Next" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code          | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-03/icky goo | 0             | 0                | 13             | 0             | -13           |

        When I click on the "Add new waste type" link
        Then I should see the "Details of waste" page

        When I enter "06-13-04 Wastes from asbestos processing" in the "EWC code" select or text field
        And I enter "don't breath it" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check "returns_slft_waste_from_non_disposal_ind_y" radio button
        And I check "returns_slft_waste_pre_treated_ind_y" radio button
        And I click on the "Next" button
        Then I should see the text "Provide tonnage details for this waste type"
        And I should see the text "0" in field "Standard tonnage"
        And I should see the text "0" in field "Lower tonnage"
        And I should see the text "0" in field "Exempt tonnage"
        And I should see the text "0" in field "Water discount tonnage"

        When I click on the "Next" button
        Then I should see the text "Enter waste details"

        # Select tonnage AND water tonnage
        When I enter "0" in the "Standard tonnage" field
        And I enter "18.45" in the "Lower tonnage" field
        And I enter "0" in the "Exempt tonnage" field
        And I enter "8" in the "Water discount tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page

        # Add a value less than 1
        When I click on the "Add new waste type" link
        Then I should see the "Details of waste" page
        When I enter "08-01-15 Aqueous sludges containing paint or varnish containing organic solvent or other" in the "EWC code" select or text field
        And I enter "something else" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check "returns_slft_waste_from_non_disposal_ind_y" radio button
        And I check "returns_slft_waste_pre_treated_ind_y" radio button
        And I click on the "Next" button
        Then I should see the text "Provide tonnage details for this waste type"
        When I enter "0.78" in the "Standard tonnage" field
        And I enter "0" in the "Lower tonnage" field
        And I enter "0" in the "Exempt tonnage" field
        And I enter "0" in the "Water discount tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page

        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-03/icky goo        | 0             | 0                | 13             | 0             | -13           |
            | 06-13-04/don't breath it | 18.45         | 0                | 0              | 8             | 10.45         |
            | 08-01-15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        When I click on the "Add new waste type" link
        When I enter "05-01-02 Desalter sludges" in the "EWC code" select or text field
        And I enter "it gets worse" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Recycled" from the "Management method"
        And I check "returns_slft_waste_from_non_disposal_ind_n" radio button
        And I check "returns_slft_waste_pre_treated_ind_n" radio button
        And I click on the "Next" button
        Then I should see the text "Provide tonnage details for this waste type"
        When I enter "1" in the "Standard tonnage" field
        And I enter "0" in the "Exempt tonnage" field
        And I enter "1" in the "Water discount tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 05-01-03/icky goo        | 0             | 0                | 13             | 0             | -13           |
            | 06-13-04/don't breath it | 18.45         | 0                | 0              | 8             | 10            |
            | 08-01-15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        # This line will cause a fail if the order is wrong so this tests waste entries are orderd by EWC code correctly
        When I click on the 2 nd "Edit row" link
        And I enter "06-13-05 Soot" in the "EWC code" select or text field
        And I click on the "Next" button
        And I click on the "Next" button
        And I click on the "Next" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 06-13-04/don't breath it | 18.45         | 0                | 0              | 8             | 10            |
            | 06-13-05/icky goo        | 0             | 0                | 13             | 0             | -13           |
            | 08-01-15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |
        And I should not see the text "05-01-03"

        When I click on the "Back" link

        Then I should see the "Return summary" page
        And the table of data is displayed
            | Lower rate tonnage (net) | Standard rate tonnage (net) |
            | 10                       | 1                           |
            | 0                        | 0                           |

        When I click on the 1 st "Add waste details" link
        Then the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 06-13-04/don't breath it | 18.45         | 0                | 0              | 8             | 10            |
            | 06-13-05/icky goo        | 0             | 0                | 13             | 0             | -13           |
            | 08-01-15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        When I click on the 3 rd "Delete row" link
        Then if available, click the confirmation dialog
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 06-13-04/don't breath it | 18.45         | 0                | 0              | 8             | 10            |
            | 08-01-15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        When I click on the "Back to return summary" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            | Lower rate tonnage (net) | Standard rate tonnage (net) |
            | 10                       | 0                           |
            | 0                        | 0                           |

        When I click on the 2 nd "Add waste details" link
        And I click on the "Add new waste type" link
        And I enter "05-01-02 Desalter sludges" in the "EWC code" select or text field
        And I enter "it gets worse" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Recycled" from the "Management method"
        And I check the "returns_slft_waste_from_non_disposal_ind_n" radio button
        And I check the "returns_slft_waste_pre_treated_ind_n" radio button
        And I click on the "Next" button
        Then I should see the text "Provide tonnage details for this waste type"
        When I enter "13" in the "Standard tonnage" field
        And I enter "1" in the "Water discount tonnage" field
        And I enter "0" in the "Exempt tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code               | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-02/it gets worse | 0             | 13               | 0              | 1             | 12            |
        And I should not see the text "icky goo"

        When I click on the "Back" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            | Lower rate tonnage (net) | Standard rate tonnage (net) |
            | 10                       | 0                           |
            | 0                        | 12                          |

        # Begin calculation part
        When I click on the "calculate_return" button
        Then I should see the "Calculated tax liability" page
        And I should see the text "1060.2" in field "Total tax due"
        And I should see the text "897.82" in field "Total credit"
        And I should see the text "162" in field "Total payable"


    # Loads SLfT amend with multiple sites and repayment/ without repayment
    @mock_slft_load_amend
    Scenario: Load mock SLfT return details and calculate liability and check return and repayment and declaration
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "returns/slft/load/960-1" page
        Then I should see the "Return summary" page
        And the table of data is displayed
            | Return period                                                        | Edit return period        |
            | SLfT year                                                            | 2019/20                   |
            | SLfT quarter                                                         | April to June (Quarter 1) |
            | Have you designated a new non-disposal area on any of your sites?    | Y                         |
            | Have you ceased to operate a non-disposal area on any of your sites? | Y                         |
        And I should see the text "10000.00"
        And the table of data is displayed
            |              | Lower rate | Standard rate |
            | Waste Site 1 | 0          | 97            |
            | Waste Site 2 | 9          | 0             |

        # Begin calculation part
        When I click on the "Calculate" button
        Then I should see the "Calculated tax liability" page
        And I should see the text "8880" in field "Total tax due"
        And I should see the text "9" in field "Total credit"
        And I should see the text "8871" in field "Total payable"

        When I click on the "Next" button
        Then I should see the "Repayment details" page

        # Repayment screen
        When I click on the "Next" button
        Then I should see the text "Do you want to request a repayment from Revenue Scotland can't be blank"

        # without repayment
        When I check the "No" radio button
        And I click on the "Next" button
        Then I should see the "Payment and submission" page

        When I click on the "Back" link

        # with repayment
        When I check the "Yes" radio button
        And I click on the "Next" button
        Then I should see the text "How much are you claiming from Revenue Scotland is not a number"
        When I enter "aaa" in the "How much are you claiming from Revenue Scotland?" field
        And I click on the "Next" button
        Then I should see the text "How much are you claiming from Revenue Scotland is not a number"
        When I enter "-34" in the "How much are you claiming from Revenue Scotland?" field
        And I click on the "Next" button
        Then I should see the text "How much are you claiming from Revenue Scotland must be greater than 0"
        When I enter "100.56" in the "How much are you claiming from Revenue Scotland?" field
        And I click on the "Next" button
        Then I should see the "Enter bank details" page

        When I click on the "Next" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "RANDOM_text,256" in the "Name of the account holder" field
        And I enter "RANDOM_text,11" in the "Bank / building society account number" field
        And I enter "85-96-88-7" in the "Branch sort code" field
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
        And I should see the text "I am eligible for the refund claimed"

        # Repayment declaration
        When I click on the "Next" button
        Then I should see the text "am eligible for the refund claimed must be accepted"

        When I check "returns_slft_slft_return_rrep_bank_auth_ind" checkbox
        And I click on the "Next" button
        Then I should see the "Payment and submission" page
        And I should see the text "I, the taxpayer, confirm that this return is, to the best of my knowledge, correct and complete"

        # Actual declaration page
        When I click on the "Submit return" button
        Then I should see the text "How are you paying can't be blank"
        And I should see the text "The declaration must be accepted"

        # go back and check we can choose to not do a repayment and instead go straight to the normal payment/submit page
        When I click on the "Back" link
        And I click on the "Back" link
        And I click on the "Back" link
        And I check the "No" radio button
        And I click on the "Next" button
        Then I should see the "Payment and submission" page

    @mock_slft_load_one_site_details
    Scenario: Load mock SLfT data - only 1 sites - check still works
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "returns/slft/load/960-1" page
        Then I should see the "Return summary" page

        # check whole model validation passes ok
        When I click on the "calculate_return" button
        Then I should see the "Calculated tax liability" page

    @mock_slft_load_no_sites_details
    Scenario: Load mock SLfT data - no sites - check still works
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "returns/slft/load/960-1" page
        Then I should see the "Return summary" page

        # check whole model validation passes ok
        When I click on the "calculate_return" button
        Then I should see the "Calculated tax liability" page

    @mock_slft_load_submit_draft
    Scenario: mock Load draft, calculate and submit SLfT return details to check return and declaration
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "returns/slft/load/960-1" page
        Then I should see the "Return summary" page
        And the table of data is displayed
            | Return period                                                        | Edit return period        |
            | SLfT year                                                            | 2015/16                   |
            | SLfT quarter                                                         | April to June (Quarter 1) |
            | Have you designated a new non-disposal area on any of your sites?    | Y                         |
            | Have you ceased to operate a non-disposal area on any of your sites? | Y                         |
        And I should see the text "123.00"
        And the table of data is displayed
            |              | Lower rate | Standard rate |
            | Waste Site 1 | 90         | 90            |
            | Waste Site 2 | 82         | 0             |

        # the loaded data is bogus and clicking calculate revalidates the model
        When I click on the "calculate_return" button
        Then I should receive the message "Credits claimed has errors that need to be corrected, please edit it"
        And I should receive the message "Waste details with EWC code 03-02-02/Aciiiiiiid for Waste Site 1 has errors that need to be corrected, please edit it"
        And I should receive the message "Waste details with EWC code 01-03-07/Aciiiiiiid for Waste Site 2 has errors that need to be corrected, please edit it"
        And I should receive the message "Credits claimed has errors that need to be corrected, please edit it"

        # Go back and correct credit claimed wizard
        When I click on the "Edit credit details" link
        Then I should see the "Environmental credit" page
        When I check the "No" radio button
        And I click the "Next" button
        Then I should see the "Bad debt credit" page
        When I check the "No" radio button
        And I click the "Next" button
        Then I should see the "Permanent removal credit" page
        When I check the "No" radio button
        When I click the "Next" button
        Then I should see the "Return summary" page

        # correct and complete waste details for site 1
        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        When I click on the 2 nd "Edit row" link
        Then I should see the "Details of waste" page
        When I click on the "Next" button
        Then I should see the text "Provide the following waste details"

        When I enter "0" in the "Exempt tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page

        # check saving draft repeatedly from site summary doesn't lose the tare_reference
        When I click on the "Save draft" button
        Then I should see the text "Your return reference is RS1000947STMD"
        # repeat
        When I click on the "Save draft" button
        Then I should see the text "Your return reference is RS1000947STMD"

        # Back to the summary
        When I click on the "Back" link
        Then I should see the "Return summary" page

        # Correct site 2 data
        When I click on the 2 nd "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 2"

        When I click on the "Edit row" link
        Then I should see the "Details of waste" page
        When I click on the "Next" button
        Then I should see the text "Provide the following waste details"

        When I enter "0" in the "Exempt tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page
        And I click on the "Back" link
        Then I should see the "Return summary" page

        And the table of data is displayed
            |              | Lower rate | Standard rate |
            | Waste Site 1 | 100        | 90            |
            | Waste Site 2 | 100        | 0             |

        # Check save draft works and you can go back
        When I click on the "Save draft" button
        Then I should see the "Return saved" page
        And I should see the text "Your return reference is RS1000947STMD"
        And I should see the text "Back to return summary"
        And I should see the text "Go to dashboard"
        When I click on the "Back to return summary" link
        Then I should see the "Return summary" page

        # Begin calculation part
        When I click on the "calculate_return" button
        Then I should see the "Calculated tax liability" page
        And I should see the text "8880" in field "Total tax due"
        And I should see the text "9" in field "Total credit"
        And I should see the text "8871" in field "Total payable"

        When I click the "Next" button
        Then I should see the "Payment and submission" page

        # Verify the fpay_method information has been cleared
        And the radio button "BACS" should not be selected
        And the radio button "Cheque" should not be selected

        When I check "BACS" radio button
        And I check "returns_slft_slft_return_declaration" checkbox

        And I click the "Submit return" button
        Then I should see the text "Your amendment to your Scottish Landfill tax return RS1000947STMD has now been submitted."
        And I should see the text "The submission date is NOW_DATE"
        And I click on the "Send secure message" link
        Then I should see the "New message" page

    Scenario: About rounding down waste site value
        # About the transaction
        Given I have signed in "portal.waste.new" and password "Password1!"
        When I click on the "Create SLfT return" link
        Then I should see the "Return summary" page

        # Test the waste details entry
        And I should see the text "Waste Site 1"

        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        When I click on the "Add new waste type" link
        Then I should see the "Details of waste" page

        When I enter "05-01-03 Tank bottom sludges" in the "EWC code" select or text field
        And I enter "icky goo" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check "returns_slft_waste_from_non_disposal_ind_y" radio button
        And I check "returns_slft_waste_pre_treated_ind_y" radio button
        And I click on the "Next" button
        Then I should see the text "Provide tonnage details for this waste type"

        When I enter "5.9" in the "Standard tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code          | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-03/icky goo | 0             | 5.9              | 0              | 0             | 5.9           |

        When I click on the "Add new waste type" link
        Then I should see the "Details of waste" page

        When I enter "01-04-99 Wastes not otherwise specified" in the "EWC code" select or text field
        And I enter "icky goo2" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check "returns_slft_waste_from_non_disposal_ind_y" radio button
        And I check "returns_slft_waste_pre_treated_ind_y" radio button
        And I click on the "Next" button
        Then I should see the text "Provide tonnage details for this waste type"

        When I enter "5.9" in the "Standard tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code           | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-03/icky goo  | 0             | 5.9              | 0              | 0             | 5.9           |
            | 01-04-99/icky goo2 | 0             | 5.9              | 0              | 0             | 5.9           |
        When I click on the "Back to return summary" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            | Lower rate tonnage (net) | Standard rate tonnage (net) |
            | 0                        | 11                          |
            | 0                        | 0                           |

        # Test the waste details entry
        And I should see the text "Waste Site 2"

        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        When I click on the "Add new waste type" link
        Then I should see the "Details of waste" page

        When I enter "05-01-03 Tank bottom sludges" in the "EWC code" select or text field
        And I enter "icky goo" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check "returns_slft_waste_from_non_disposal_ind_y" radio button
        And I check "returns_slft_waste_pre_treated_ind_y" radio button
        And I click on the "Next" button
        Then I should see the text "Provide tonnage details for this waste type"

        When I enter "4.22" in the "Lower tonnage" field
        And I enter "1.19" in the "Water discount tonnage" field
        And I click on the "Next" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code          | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05-01-03/icky goo | 4.22          | 0                | 0              | 1.19          | 3.03          |
        When I click on the "Back to return summary" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            | Lower rate tonnage (net) | Standard rate tonnage (net) |
            | 0                        | 11                          |
            | 3                        | 0                           |
