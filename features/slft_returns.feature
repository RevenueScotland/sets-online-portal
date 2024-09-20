# feature/slft_returns.feature

Feature: SLfT Returns
    As a user
    I want to be able to make a SLfT return

    Scenario: Check Validation, Save and Retrieve Draft SLFT Return
        Given I have signed in "portal.waste.new" and password "Password1!"
        When I click on the "Create SLfT return" menu item
        Then I should see the "Return summary" page
        #Calculate and Check
        When I click on the "Calculate" button
        Then I should receive the message "Please fill in the 'Return period' section"
        And  I should receive the message "Please fill in the 'Credits claimed' section"

        #Set Period including validation checks
        Then I click on the "Add return period" link
        Then I should see the "What accounting period is this return for?" page
        When I click on the "Continue" button
        Then I should see the text "year can't be blank"
        And I should see the text "quarter can't be blank"
        When I check the "April to June (Quarter 1)" radio button in answer to the question "SLfT quarter"
        And I click on the "Continue" button
        Then I should see the text "year can't be blank"
        When I select "2018/19" from the "year"
        And I click on the "Continue" button
        Then I should see the "Non disposal area information" page
        When I click on the "Continue" button
        Then I should see the text "non-disposal area on any of your sites can't be blank"
        When I check the "No" radio button in answer to the question "Have you designated a new non-disposal area on any of your sites?"
        And I click on the "Continue" button
        When I click on the "Continue" button
        Then I should see the text "Have you ceased to operate a non-disposal area on any of your sites can't be blank"
        And I check the "No" radio button in answer to the question "Have you ceased to operate a non-disposal area on any of your sites?"
        And I click on the "Continue" button
        Then I should see the "Return summary" page

        When I click on the "Edit return period" link
        Then I should see the "What accounting period is this return for?" page
        When I click on the "Continue" button
        Then I should see the "Non disposal area information" page
        And I should see the text "Have you designated a new non-disposal area on any of your sites?"
        When I check the "Yes" radio button in answer to the question "Have you designated a new non-disposal area on any of your sites?"
        And I click on the "Continue" button
        Then I should see the text "Tell us which sites have a new non disposal area can't be blank"
        When I enter "RANDOM_text,4001" in the "Tell us which sites have a new non disposal area" field
        And I click on the "Continue" button
        Then I should see the text "Tell us which sites have a new non disposal area is too long"
        When I enter "Some really good sites" in the "Tell us which sites have a new non disposal area" field
        And I click on the "Continue" button
        Then I should see the "Non disposal area information" page
        And I should see the text "Have you ceased to operate a non-disposal area on any of your sites?"
        When I check the "Yes" radio button in answer to the question "Have you ceased to operate a non-disposal area on any of your sites?"
        And I click on the "Continue" button
        Then I should see the text "Tell us which sites you have removed a non-disposal area from can't be blank"
        When I enter "RANDOM_text,4001" in the "Tell us which sites you have removed a non-disposal area from" field
        And I click on the "Continue" button
        Then I should see the text "Tell us which sites you have removed a non-disposal area from is too long"
        When I enter "Some really bad sites" in the "Tell us which sites you have removed a non-disposal area from" field
        And I click on the "Continue" button
        Then I should see the "Return summary" page

        # Save Draft and re-load this means that by checking the mandatory validatoon
        # we can check if any of the other fields have been defaulted by the save draft process
        # also check the text on the page at this point so we don't need to bother later
        And I click on the "Save draft" button
        Then I should see the "Return saved" page
        And I should see the text "Your tax return has been saved so that you can return to either complete or cancel it."
        And I should see the text "It has not been submitted to Revenue Scotland."
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        Then I should store the generated value with id "notification_banner_reference"
        And I should see a link with text "Go to dashboard"
        When I click on the "Go to dashboard" link
        # Download tests for slft pdf and slft waste (.zip) on the dashboard home page
        Then I should see the "Dashboard" page
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        When I click on the 1 st "Download waste details" link to download a file
        Then I should see the downloaded "WASTE" content of "SLFT" by looking up "notification_banner_reference"
        When I click on the 1 st "Download PDF" link to download a file
        Then I should see the downloaded "PDF" content of "SLFT" by looking up "notification_banner_reference"
        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page

        # Download tests for slft pdf and slft waste (.zip) on the all returns page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        When I click on the 1 st "Download waste details" link to download a file
        Then I should see the downloaded "WASTE" content of "SLFT" by looking up "notification_banner_reference"
        When I click on the 1 st "Download PDF" link to download a file
        Then I should see the downloaded "PDF" content of "SLFT" by looking up "notification_banner_reference"

        And I should see a link with text "Continue"
        And I click on the 1 st "Continue" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            | Return period                                                        | Edit return period        |
            | SLfT year                                                            | 2018/19                   |
            | SLfT quarter                                                         | April to June (Quarter 1) |
            | Have you designated a new non-disposal area on any of your sites?    | Y                         |
            | Have you ceased to operate a non-disposal area on any of your sites? | Y                         |


        # Carry on with filling in the return
        # Fill in Credit Details with validation check
        When I click on the "Add credit details" link
        Then I should see the "Environmental credit" page
        When I click on the "Continue" button
        Then I should see the "Environmental credit" page
        And I should see the text "Are you claiming a credit in relation to an environmental contribution can't be blank"
        When I check the "Yes" radio button in answer to the question "Are you claiming a credit in relation to an environmental contribution?"
        And I click on the "Continue" button
        Then I should see the "Environmental credit" page
        And I should see the text "Contribution to environmental bodies can't be blank"
        And I should see the text "Credit claimed in relation to the contribution can't be blank"
        When I enter "1000000000000000000" in the "Contribution to environmental bodies" field
        And I enter "1000000000000000000" in the "Credit claimed in relation to the contribution" field
        And I click on the "Continue" button
        Then I should see the "Environmental credit" page
        And I should see the text "Contribution to environmental bodies must be less than 1000000000000000000"
        And I should see the text "Credit claimed must be less than the specified percentage of the contribution to environmental bodies"
        When I enter "abc" in the "Contribution to environmental bodies" field
        And I enter "abc" in the "Credit claimed in relation to the contribution" field
        And I click on the "Continue" button
        Then I should see the "Environmental credit" page
        And I should see the text "Contribution to environmental bodies is not a number"
        And I should see the text "Credit claimed in relation to the contribution is not a number"
        When I enter "0" in the "Contribution to environmental bodies" field
        And I enter "0" in the "Credit claimed in relation to the contribution" field
        And I click on the "Continue" button
        Then I should see the "Environmental credit" page
        And I should see the text "Contribution to environmental bodies must be greater than 0"
        And I should see the text "Credit claimed in relation to the contribution must be greater than 0"

        When I enter " 555.12 " in the "Contribution to environmental bodies" field
        And I enter " 499.62 " in the "Credit claimed in relation to the contribution" field
        And I click on the "Continue" button
        Then I should see the "Environmental credit" page
        And I should see the text "Credit claimed must be less than the specified percentage of the contribution to environmental bodies"
        And I should see the text "555.12" in field "Contribution to environmental bodies"
        And I should see the text "499.62" in field "Credit claimed in relation to the contribution"

        When I enter "59.3" in the "Credit claimed in relation to the contribution" field
        And I click on the "Continue" button
        Then I should see the "Bad debt credit" page
        When I click on the "Continue" button
        Then I should see the text "Do you have any claims to make in relation to bad debt can't be blank"
        When I check the "Yes" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
        And I enter "abc" in the "Bad debt claim amount" field
        And I click on the "Continue" button
        Then I should see the "Bad debt credit" page
        And I should see the text "Bad debt claim amount is not a number"
        When I check the "Yes" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
        And I enter "-123.44" in the "Bad debt claim amount" field
        And I click on the "Continue" button
        Then I should see the "Bad debt credit" page
        And I should see the text "Bad debt claim amount must be greater than 0"
        When I enter " 7123 " in the "Bad debt claim amount" field
        And I click on the "Continue" button
        Then I should see the "Permanent removal credit" page

        When I click on the "Continue" button
        Then I should see the "Permanent removal credit" page
        And I should see the text "Are you claiming a credit for permanent removal can't be blank"
        When I check the "Yes" radio button in answer to the question "Are you claiming a credit for permanent removal?"
        And I enter "abc.22" in the "Permanent removal claim amount" field
        And I click on the "Continue" button
        Then I should see the "Permanent removal credit" page
        And I should see the text "Permanent removal claim amount is not a number"
        When I enter "0" in the "Permanent removal claim amount" field
        And I click on the "Continue" button
        Then I should see the "Permanent removal credit" page
        And I should see the text "Permanent removal claim amount must be greater than 0"
        When I enter " 564.22 " in the "Permanent removal claim amount" field
        And I click on the "Continue" button
        Then I should see the "Return summary" page
        And I should see the text "Edit credit details"

        # Check both tables of data exist (ie nothing's been lost)
        And the table of data is displayed
            | Return period                                                        | Edit return period        |
            | SLfT year                                                            | 2018/19                   |
            | SLfT quarter                                                         | April to June (Quarter 1) |
            | Have you designated a new non-disposal area on any of your sites?    | Y                         |
            | Have you ceased to operate a non-disposal area on any of your sites? | Y                         |
        And the table of data is displayed
            | Credits claimed                                | Edit credit details |
            | Contribution to environmental bodies           | £555.12             |
            | Credit claimed in relation to the contribution | £59.30              |
            | Bad debt claim amount                          | £7,123.00           |
            | Permanent removal claim amount                 | £564.22             |
        # Go back and check a form still has data
        When I click on the "Edit credit details" link
        Then I should see the "Environmental credit" page
        And I should see the text "555.12" in field "Contribution to environmental bodies"
        And I enter "1234" in the "Contribution to environmental bodies" field
        When I click on the "Continue" button
        # Check the formatted amount is shown
        Then I should see the "Bad debt credit" page
        And I should see the text "7123" in field "Bad debt claim amount"

        When I check the "No" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
        And I click on the "Continue" button
        Then I should see the "Permanent removal credit" page
        When I click on the "Continue" button
        Then I should see the "Return summary" page

        # Check the data doesn't show but the previous stuff does
        And the table of data is displayed
            | Credits claimed                                         | Edit credit details |
            | Contribution to environmental bodies                    | £1,234.00           |
            | Credit claimed in relation to the contribution          | £59.30              |
            | Do you have any claims to make in relation to bad debt? | No                  |
            | Permanent removal claim amount                          | £564.22             |

        # Check clicking 'No' has hidden/deleted the data
        And I should not see the text "Bad debt claim amount"
        And I should not see the text "7123.00"

        #Set Waste Details with validation check
        # Test the waste details entry
        And I should see the text "Waste Site 1"

        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        When I click on the "Add new waste type" link
        Then I should see the "Details of the waste for Waste Site 1" page
        And I should see the sub-title "Provide the following waste details"
        When I click on the "Continue" button
        Then I should see the "Details of the waste for Waste Site 1" page
        And I should see the text "EWC code can't be blank"
        And I should see the text "Description of waste can't be blank"
        And I should see the text "Geographical area can't be blank"
        And I should see the text "Management method can't be blank"
        And I should see the text "Has this waste been moved out of a non-disposal area (NDA)"

        When I enter "RANDOM_text,256" in the "Description of waste" field
        And I click on the "Continue" button
        Then I should see the "Details of the waste for Waste Site 1" page
        And I should receive the message "Description of waste is too long (maximum is 255 characters)"

        When I enter "05 01 02 Desalter sludges" in the "EWC code" select or text field
        Then I wait for 2 seconds
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check the "Yes" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I enter "icky goo" in the "Description of waste" field
        And I should see "05 01 02 Desalter sludges" in the "EWC code" select or text field
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the sub-title "Provide tonnage details for this waste type"

        # They each have the same validation so check each combination in one go
        When I enter "aa" in the "Standard tonnage" field
        And I enter "0.213" in the "Lower tonnage" field
        And I enter "cc" in the "Exempt tonnage" field
        And I enter "-4" in the "Water discount tonnage" field
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should receive the message "Standard tonnage is not a number"
        And I should receive the message "Lower tonnage must be a number to 2 decimal places"
        And I should receive the message "Water discount tonnage must be greater than or equal to 0"

        When I enter "10" in the "Standard tonnage" field
        And I enter "4" in the "Lower tonnage" field
        And I enter "13" in the "Exempt tonnage" field
        And I enter "aa" in the "Water discount tonnage" field
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should receive the message "Exempt tonnage cannot be set when other tonnages are set"
        And I should receive the message "Standard tonnage cannot be set when other tonnages are set"
        And I should receive the message "Lower tonnage cannot be set when other tonnages are set"
        And I should receive the message "Water discount tonnage is not a number"

        When I enter "0" in the "Standard tonnage" field
        And I enter "0" in the "Lower tonnage" field
        And I enter "13" in the "Exempt tonnage" field
        And I enter "11" in the "Water discount tonnage" field
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should receive the message "Water discount tonnage cannot be set when exempt tonnage is set"

        When I enter " 0 " in the "Water discount tonnage" field
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the sub-title "Why is some tonnage exempt?"

        # Click on back link to check if the page data is retained
        When I click on the "Back" link
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the sub-title "Provide tonnage details for this waste type"

        When I click on the "Back" link
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the sub-title "Provide the following waste details"
        And I should see "05 01 02 Desalter sludges" in the "EWC code" select or text field
        And I should see the text "icky goo" in field "Description of waste"
        And I should see "Falkirk" in the "returns_slft_waste_lau_code" select or text field
        And I should see "Landfill" in the "returns_slft_waste_fmme_method" select or text field
        And the radio button "Yes" should be selected in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"

        When I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the sub-title "Provide tonnage details for this waste type"
        And I should see the text "0" in field "Standard tonnage"
        And I should see the text "0" in field "Lower tonnage"
        And I should see the text "13" in field "Exempt tonnage"
        And I should see the text "0" in field "Water discount tonnage"
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the sub-title "Why is some tonnage exempt?"

        When I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the text "NDA can't be blank"
        And I should see the text "Restoration can't be blank"
        And I should see the text "Other can't be blank"
        And I should see the text "NDA or restoration or other must be selected"

        When I check the "Yes" radio button in answer to the question "NDA"
        Then I should see the empty field "NDA tonnage"
        When I check the "Yes" radio button in answer to the question "Restoration"
        Then I should see the empty field "Restoration tonnage"
        When I check the "Yes" radio button in answer to the question "Other"
        Then I should see the empty field "Other tonnage"

        # They each have the same validation so check each combination in one go
        And I enter "aa" in the "NDA tonnage" field
        And I enter "0.415" in the "Restoration tonnage" field
        And I enter "-1" in the "Other tonnage" field
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the text "NDA tonnage is not a number"
        And I should see the text "Restoration tonnage must be a number to 2 decimal places"
        And I should see the text "Other tonnage must be greater than 0"


        When I check the "No" radio button in answer to the question "NDA"
        And I check the "No" radio button in answer to the question "Restoration"
        And I enter " 12.3 " in the "Other tonnage" field
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the text "Description of other exemption reason can't be blank"
        And I should see the text "The total tonnage 12.3 of these exemptions must be equal to the exempt tonnage of 13"
        When I enter "RANDOM_text,256" in the "Description of other exemption reason" field
        And I enter "13" in the "Other tonnage" field
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        And I should see the text "Description of other exemption reason is too long"
        And I enter "my other exemption reason" in the "Description of other exemption reason" field
        And I click on the "Continue" button

        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code          | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 02/icky goo | 0             | 0                | 13             | 0             | 13            |

        When I click on the "Add new waste type" link
        Then I should see the "Details of the waste for Waste Site 1" page
        And I should see the sub-title "Provide the following waste details"

        When I enter "06 13 04 Wastes from asbestos processing" in the "EWC code" select or text field
        And I enter "don't breath it" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check the "Yes" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I click on the "Continue" button
        Then I should see the "Details of the 06 13 04 waste for Waste Site 1" page
        And I should see the sub-title "Provide tonnage details for this waste type"
        When I click on the "Continue" button
        # check 0 is seen as empty
        Then I should see the "Details of the 06 13 04 waste for Waste Site 1" page
        And I should see the text "Standard tonnage or the lower or exempt tonnage must be entered"
        When I enter "0" in the "Standard tonnage" field
        And I click on the "Continue" button
        Then I should see the "Details of the 06 13 04 waste for Waste Site 1" page
        And I should see the text "Standard tonnage or the lower or exempt tonnage must be entered"

        # Select tonnage AND water tonnage
        And I enter "18.45" in the "Lower tonnage" field
        And I enter " 8 " in the "Water discount tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page

        # Add a value less than 1
        When I click on the "Add new waste type" link
        Then I should see the "Details of the waste for Waste Site 1" page
        And I should see the sub-title "Provide the following waste details"
        When I enter "08 01 15 Aqueous sludges containing paint or varnish containing organic solvent or other" in the "EWC code" select or text field
        And I enter "something else" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check the "Yes" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I click on the "Continue" button
        Then I should see the "Details of the 08 01 15 waste for Waste Site 1" page
        And I should see the sub-title "Provide tonnage details for this waste type"
        When I enter " 0.78 " in the "Standard tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page

        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 02/icky goo        | 0             | 0                | 13             | 0             | 13            |
            | 06 13 04/don't breath it | 18.45         | 0                | 0              | 8             | 10.45         |
            | 08 01 15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        When I click on the "Add new waste type" link
        Then I should see the "Details of the waste for Waste Site 1" page
        When I enter "05 01 02 Desalter sludges" in the "EWC code" select or text field
        And I enter "it gets worse" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Recycled" from the "Management method"
        And I check the "No" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        When I enter "1" in the "Standard tonnage" field
        And I enter "1" in the "Water discount tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 02/icky goo        | 0             | 0                | 13             | 0             | 13            |
            | 05 01 02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 06 13 04/don't breath it | 18.45         | 0                | 0              | 8             | 10.45         |
            | 08 01 15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        # This line will cause a fail if the order is wrong so this tests waste entries are orderd by EWC code correctly
        When I click on the 1 st "Edit row" link
        Then I should see the "Details of the 05 01 02 waste for Waste Site 1" page
        When I enter "06 13 05 Soot" in the "EWC code" select or text field
        And I click on the "Continue" button
        And I should see the "Details of the 06 13 05 waste for Waste Site 1" page
        And I click on the "Continue" button
        Then I should see the "Details of the 06 13 05 waste for Waste Site 1" page
        And I should see the text "Why is some tonnage exempt?"
        When I click on the "Continue" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 06 13 04/don't breath it | 18.45         | 0                | 0              | 8             | 10.45         |
            | 06 13 05/icky goo        | 0             | 0                | 13             | 0             | 13            |
            | 08 01 15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |
        And I should not see the text "05 01 03"

        When I click on the "Back" link

        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 13      | 23      |
            | Waste Site 2 | 0             | 0             | 0       | 0       |
            | Total        | 10            | 0             | 13      | 23      |

        # Check that the sites are refreshed when the quarter is changed
        When I set a period of "2017/18" and "October to December (Quarter 3)"
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 13      | 23      |
            | Total        | 10            | 0             | 13      | 23      |
        And I should not see the text "Waste Site 2"

        When I set a period of "2018/19" and "October to December (Quarter 3)"
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 13      | 23      |
            | Waste Site 2 | 0             | 0             | 0       | 0       |
            | Total        | 10            | 0             | 13      | 23      |

        When I click on the 1 st "Add waste details" link
        Then the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 06 13 04/don't breath it | 18.45         | 0                | 0              | 8             | 10.45         |
            | 06 13 05/icky goo        | 0             | 0                | 13             | 0             | 13            |
            | 08 01 15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        When I click on the 3 rd "Delete row" link
        Then if available, click the confirmation dialog
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 06 13 04/don't breath it | 18.45         | 0                | 0              | 8             | 10.45         |
            | 08 01 15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        When I click on the "Return summary" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 0       | 10      |
            | Waste Site 2 | 0             | 0             | 0       | 0       |
            | Total        | 10            | 0             | 0       | 10      |

        When I click on the 2 nd "Add waste details" link
        And I click on the "Add new waste type" link
        Then I should see the "Details of the waste for Waste Site 2" page
        And I should see the sub-title "Provide the following waste details"
        And I enter "05 01 02 Desalter sludges" in the "EWC code" select or text field
        And I enter "it gets worse" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Recycled" from the "Management method"
        And I check the "No" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I click on the "Continue" button
        Then I should see the "Details of the 05 01 02 waste for Waste Site 2" page
        And I should see the sub-title "Provide tonnage details for this waste type"
        When I enter "13" in the "Standard tonnage" field
        And I enter "1" in the "Water discount tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code               | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 02/it gets worse | 0             | 13               | 0              | 1             | 12            |
        And I should not see the text "icky goo"

        # add an exemption with other description that can be checked when draft is restored
        When I click on the "Add new waste type" link
        Then I should see the sub-title "Provide the following waste details"
        When I enter "01 01 01 Wastes from mineral metalliferous excavation" in the "EWC code" select or text field
        And I enter "exempt other line" in the "Description of waste" field
        And I select "Fife" from the "Geographical area"
        And I select "Incinerated" from the "Management method"
        And I check the "No" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I click on the "Continue" button
        Then I should see the sub-title "Provide tonnage details for this waste type"

        When I enter "11.24" in the "Exempt tonnage" field
        And I click on the "Continue" button

        Then I should see the sub-title "Why is some tonnage exempt?"
        When I check the "No" radio button in answer to the question "NDA"
        And I check the "No" radio button in answer to the question "Restoration"
        And I check the "Yes" radio button in answer to the question "Other"
        And I enter "11.24" in the "Other tonnage" field
        And I enter "my other exemption reason" in the "Description of other exemption reason" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code                   | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 01 01 01/exempt other line | 0             | 0                | 11.24          | 0             | 11.24         |
            | 05 01 02/it gets worse     | 0             | 13               | 0              | 1             | 12            |

        # Note save draft is used to reload the page again, so when the back link is clicked, the flow of pages should still be correct.
        When I click on the "Save draft" button
        And I click on the "Back" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 0       | 10      |
            | Waste Site 2 | 0             | 12            | 11      | 12      |
            | Total        | 10            | 12            | 11      | 22      |

        # Check that the sites moved to the removed sites list and it appears when teh quarter is changes
        # Note due to the way the test works the two tables don't test that they are separate but included for understanding
        When I set a period of "2017/18" and "October to December (Quarter 3)"
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 0       | 10      |
            | Total        | 10            | 0             | 0       | 10      |
        And I should see the text "Removed site list"
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 2 | 0             | 12            | 11      | 12      |

        When I set a period of "2018/19" and "October to December (Quarter 3)"
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 0       | 10      |
            | Waste Site 2 | 0             | 12            | 11      | 12      |
            | Total        | 10            | 12            | 11      | 22      |
        And I should not see the text "Removed site list"

        #Calculate and Check
        When I click on the "Calculate" button

        Then I should see the "Calculated tax liability" page
        And I should see the text "1095.4" in field "Total tax due"
        And I should see the text "623.52" in field "Total credit"
        And I should see the text "471" in field "Total payable"

        When I click on the "Back" link

        #Save Draft we don't need to check the page again as we did that earlier
        And I click on the "Save draft" button
        Then I should see the "Return saved" page
        Then I should store the generated value with id "notification_banner_reference"
        # Load that return for amending
        When I click on the "Dashboard" menu item
        Then I should see the "Dashboard" page

        When I click on the "Sign out" menu item
        Then I should see the "Sign in" page
        When I have signed in "portal.waste.new" and password "Password1!"
        Then I should see the "Dashboard" page
        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page
        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "Returns" page
        When I click on the "Continue" link
        Then I should see the "Return summary" page

        And the table of data is displayed
            | Return period                                                        | Edit return period              |
            | SLfT year                                                            | 2018/19                         |
            | SLfT quarter                                                         | October to December (Quarter 3) |
            | Have you designated a new non-disposal area on any of your sites?    | Y                               |
            | Have you ceased to operate a non-disposal area on any of your sites? | Y                               |

        And the table of data is displayed
            | Credits claimed                                         | Edit credit details |
            | Contribution to environmental bodies                    | £1,234.00           |
            | Credit claimed in relation to the contribution          | £59.30              |
            | Do you have any claims to make in relation to bad debt? | No                  |
            | Permanent removal claim amount                          | £564.22             |

        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 0       | 10      |
            | Waste Site 2 | 0             | 12            | 11      | 12      |
            | Total        | 10            | 12            | 11      | 22      |

        #Amend Draft to update waste
        When I click on the "Edit credit details" link
        Then I should see the "Environmental credit" page
        And I should see the text "1234" in field "Contribution to environmental bodies"
        And I should see the text "59.3" in field "Credit claimed in relation to the contribution"
        When I check the "No" radio button in answer to the question "Are you claiming a credit in relation to an environmental contribution?"
        And I click on the "Continue" button
        Then I should see the "Bad debt credit" page
        And the radio button "No" should be selected in answer to the question "Do you have any claims to make in relation to bad debt?"
        When I click on the "Continue" button
        Then I should see the "Permanent removal credit" page
        And I should see the text "564.22" in field "Permanent removal claim amount"
        When I check the "No" radio button in answer to the question "Are you claiming a credit for permanent removal?"
        And I click on the "Continue" button
        Then I should see the "Return summary" page

        # Check details for waste site 1
        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        And the table of data is displayed
            | EWC code                 | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 02/it gets worse   | 0             | 1                | 0              | 1             | 0             |
            | 06 13 04/don't breath it | 18.45         | 0                | 0              | 8             | 10            |
            | 08 01 15/something else  | 0             | 0.78             | 0              | 0             | 0.78          |

        When I click on the "Back" link
        # Given the data involved we don't need to step through each individual line as the key data is displayed above
        # and the exemption check below checks for the header fields
        Then I should see the "Return summary" page

        # Check values for waste site 2
        When I click on the 2 nd "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 2"

        And the table of data is displayed
            | EWC code                   | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 01 01 01/exempt other line | 0             | 0                | 11.24          | 0             | 11.24         |
            | 05 01 02/it gets worse     | 0             | 12               | 0              | 1             | 12            |

        # check details of the first line
        When I click on the 1 st "Edit" link
        Then I should see the "Details of the 01 01 01 waste for Waste Site 2" page
        And I should see the sub-title "Provide the following waste details"
        And I should see "01 01 01 Wastes from mineral metalliferous excavation" in the "EWC code" select or text field
        And I should see the text "exempt other line" in field "Description of waste"
        And I should see the "Fife" option selected in "Geographical area"
        And I should see the "Incinerated" option selected in "Management method"
        And the radio button "No" should be selected in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        When I click on the "Continue" button
        Then I should see the "Details of the 01 01 01 waste for Waste Site 2" page
        And I should see the sub-title "Provide tonnage details for this waste type"
        And I should see the text "11.24" in field "Exempt tonnage"
        When I click on the "Continue" button

        Then I should see the "Details of the 01 01 01 waste for Waste Site 2" page
        And I should see the sub-title "Why is some tonnage exempt?"
        And the radio button "No" should be selected in answer to the question "NDA"
        And the radio button "No" should be selected in answer to the question "Restoration"
        And the radio button "Yes" should be selected in answer to the question "Other"
        And I should see the text "11.24" in field "Other tonnage"
        And I should see the text "my other exemption reason" in field "Description of other exemption reason"
        When I click on the "Continue" button
        Then I should see the "Waste details summary" page

        When I click on the "Back" link
        Then I should see the "Return summary" page

        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 10            | 0             | 0       | 11      |
            | Waste Site 2 | 0             | 12            | 11      | 23      |
            | Total        | 10            | 12            | 11      | 34      |

        # Begin calculation part
        When I click on the "Calculate" button
        Then I should see the "Calculated tax liability" page
        And I should see the text "1095.4" in field "Total tax due"
        And I should see the text "0" in field "Total credit"
        And I should see the text "1095" in field "Total payable"

        When I click on the "Continue" button
        Then I should see the "Payment and submission" page
        And I should see the text "Your credit claimed cannot be more than 90% of your qualifying contribution for the accounting period and must not exceed 5.6% of your SLFT liability in the contribution year"
        And I should see the text "If you give false information, you may face penalties and/or prosecution"
        # Verify the fpay_method information has been cleared
        And the radio button "BACS" should not be selected
        And the radio button "Cheque" should not be selected
        # Check we can't submit without picking a payment method
        When I click on the "Submit return" button
        Then I should see the "Payment and submission" page
        And I should receive the message "How are you paying can't be blank"
        And I should receive the message "The declaration must be accepted"

        When I check the "BACS" radio button in answer to the question "How are you paying?"
        And I check the "returns_slft_slft_return_declaration" checkbox
        When I click on the "Back" link
        Then I should see the "Calculated tax liability" page
        When I click on the "Back" link
        #Save Draft
        And I click on the "Save draft" button
        Then I should see the "Return saved" page

    @mock_slft_load_one_site_details
    Scenario:  Load SLFT sites with no sites (mocked)
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "dashboard/dashboard_returns/960-1-SLFT-RS/load" page
        Then I should see the "Return summary" page

    # Loads SLfT amend with multiple sites and repayment/ without repayment
    @mock_slft_load_amend
    Scenario: Amend SLFT Return with repayment and submit (mocked)
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "dashboard/dashboard_returns/960-1-SLFT-RS/load" page
        Then I should see the "Return summary" page

        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        When I click on the 2 nd "Edit" link
        Then I should see the "Details of the 03 02 02 waste for Waste Site 1" page
        And I should see the sub-title "Provide the following waste details"

        When I click on the "Continue" button
        Then I should see the "Details of the 03 02 02 waste for Waste Site 1" page
        And I should see the sub-title "Provide tonnage details for this waste type"

        When I click on the "Continue" button
        Then I should see the "Details of the 03 02 02 waste for Waste Site 1" page
        And I should see the sub-title "Why is some tonnage exempt?"
        When I check the "No" radio button in answer to the question "NDA"
        And I check the "No" radio button in answer to the question "Restoration"
        And I check the "Yes" radio button in answer to the question "Other"
        And I enter "18" in the "Other tonnage" field
        When I click on the "Continue" button

        Then I should see the "Waste details summary" page
        Then the table of data is displayed
            | EWC code              | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 01 03 04/er batteries | 0             | 100              | 0              | 3             | 97            |
            | 03 02 02/Aciiiiiiid   | 0             | 0                | 18             | 0             | 18            |

        When I click on the "Back" link
        Then I should see the "Return summary" page
        # correct and complete waste details for site 2
        When I click on the 2 nd "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 2"
        Then the table of data is displayed
            | EWC code            | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 01 03 07/Aciiiiiiid | 10            | 0                | 0              | 1             | 9             |

        When I click on the 1 st "Edit" link
        Then I should see the "Details of the 01 03 07 waste for Waste Site 2" page
        And I should see the sub-title "Provide the following waste details"

        When I click on the "Continue" button
        Then I should see the sub-title "Provide tonnage details for this waste type"

        When I click on the "Continue" button
        Then I should see the "Waste details summary" page
        Then the table of data is displayed
            | EWC code            | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 01 03 07/Aciiiiiiid | 10            | 0                | 0              | 1             | 9             |

        When I click on the "Back" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 0             | 97            | 18      | 115     |
            | Waste Site 2 | 9             | 0             | 0       | 9       |
            | Total        | 9             | 97            | 18      | 124     |

        # Begin calculation part
        When I click on the "Calculate" button
        Then I should see the "Calculated tax liability" page
        And I should see the text "8880" in field "Total tax due"
        And I should see the text "9" in field "Total credit"
        And I should see the text "8871" in field "Total payable"

        When I click on the "Continue" button
        Then I should see the "Repayment details" page

        # Repayment screen
        When I click on the "Continue" button
        Then I should see the text "Do you want to request a repayment from Revenue Scotland can't be blank"

        # without repayment
        When I check the "No" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page

        When I click on the "Back" link

        # with repayment
        When I check the "Yes" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"
        And I click on the "Continue" button
        Then I should see the text "How much are you claiming from Revenue Scotland can't be blank"
        When I enter "aaa" in the "How much are you claiming from Revenue Scotland?" field
        And I click on the "Continue" button
        Then I should see the text "How much are you claiming from Revenue Scotland is not a number"
        When I enter "-34" in the "How much are you claiming from Revenue Scotland?" field
        And I click on the "Continue" button
        Then I should see the text "How much are you claiming from Revenue Scotland must be greater than 0"
        When I enter "100.56" in the "How much are you claiming from Revenue Scotland?" field
        And I click on the "Continue" button
        Then I should see the "Enter bank details" page

        When I click on the "Continue" button
        Then I should see the text "Name of the account holder can't be blank"
        And I should see the text "Bank / building society account number can't be blank"
        And I should see the text "Branch sort code can't be blank"
        And I should see the text "Name of bank / building society can't be blank"

        When I enter "RANDOM_text,153" in the "Name of the account holder" field
        And I enter "RANDOM_text,11" in the "Bank / building society account number" field
        And I enter "85-96-88-7" in the "Branch sort code" field
        And I enter "RANDOM_text,256" in the "Name of bank / building society" field
        And I click on the "Continue" button
        Then I should see the text "Name of the account holder is too long (maximum is 152 characters)"
        And I should see the text "Bank / building society account number must be 8 digits long"
        And I should see the text "Branch sort code must be in the format 99-99-99"

        When I enter "Fred Flintstone with a long name" in the "Name of the account holder" field
        And I enter "12345678" in the "Bank / building society account number" field
        And I enter "10-11-12" in the "Branch sort code" field
        And I enter "Natwest" in the "Name of bank / building society" field
        And I click on the "Continue" button
        Then I should see the "Declaration" page
        And I should see the text "I am eligible for the refund claimed"

        # Repayment declaration
        When I click on the "Continue" button
        Then I should see the "Declaration" page
        And I should receive the message "I am eligible for the refund claimed must be accepted"

        When I check the "returns_slft_slft_return_rrep_bank_auth_ind" checkbox
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page
        And I should see the text "I, the taxpayer, confirm that this return is, to the best of my knowledge, correct and complete"

        # go back and check we can choose to not do a repayment and instead go straight to the normal payment/submit page
        When I click on the "Back" link
        Then I should see the "Declaration" page
        When I click on the "Back" link
        Then I should see the "Enter bank details" page
        When I click on the "Back" link
        Then I should see the "Repayment details" page
        And I check the "No" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"
        And I click on the "Continue" button
        Then I should see the "Payment and submission" page

    # Loads draft ie no repayment page
    @mock_slft_load_submit_draft
    Scenario: Amend SLFT Return with no repayment and submit (mocked)
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "dashboard/dashboard_returns/960-1-SLFT-RS/load" page
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 100           | 90            | 10      | 200     |
            | Waste Site 2 | 100           | 0             | 18      | 118     |
            | Total        | 200           | 90            | 28      | 318     |

        # Begin calculation part
        # the loaded data is bogus and clicking calculate revalidates the model
        When I click on the "Calculate" button
        Then I should receive the message "There's an error somewhere in the credits claimed - please review the credits claimed section of the return and update it"
        And I should receive the message "There's an error somewhere in the waste details with EWC code 03 02 02/Aciiiiiiid for Waste Site 1 - please review the waste details with EWC code 03 02 02/Aciiiiiiid for Waste Site 1 section of the return and update it"
        And I should receive the message "There's an error somewhere in the waste details with EWC code 01 03 07/Aciiiiiiid for Waste Site 2 - please review the waste details with EWC code 01 03 07/Aciiiiiiid for Waste Site 2 section of the return and update it"
        And I should receive the message "There's an error somewhere in the credits claimed - please review the credits claimed section of the return and update it"

        # Go back and correct credit claimed wizard
        When I click on the "Edit credit details" link
        Then I should see the "Environmental credit" page

        When I check the "No" radio button in answer to the question "Are you claiming a credit in relation to an environmental contribution?"
        And I click on the "Continue" button
        Then I should see the "Bad debt credit" page

        When I check the "No" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
        And I click on the "Continue" button
        Then I should see the "Permanent removal credit" page

        When I check the "No" radio button in answer to the question "Are you claiming a credit for permanent removal?"
        And I click on the "Continue" button
        Then I should see the "Return summary" page

        # correct and complete waste details for site 1
        # As there are values missing next doesn't move on
        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        When I click on the 2 nd "Edit row" link
        Then I should see the sub-title "Provide the following waste details"

        When I click on the "Continue" button
        Then I should see the sub-title "Provide tonnage details for this waste type"

        When I enter "0" in the "Exempt tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page

        # check saving draft repeatedly from site summary doesn't lose the tare_reference
        When I click on the "Save draft" button
        Then I should see the text "Your reference number is"
        And I should see the text "RS1000947STMD"
        # repeat
        When I click on the "Save draft" button
        Then I should see the text "Your reference number is"
        And I should see the text "RS1000947STMD"

        # Back to the summary
        When I click on the "Back" link
        Then I should see the "Return summary" page

        # Correct site 2 data
        When I click on the 2 nd "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 2"

        When I click on the "Edit row" link
        And I should see the sub-title "Provide the following waste details"
        When I click on the "Continue" button
        Then I should see the sub-title "Provide tonnage details for this waste type"

        When I enter "0" in the "Exempt tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page

        When I click on the "Back" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 100           | 90            | 0       | 190     |
            | Waste Site 2 | 100           | 0             | 0       | 100     |
            | Total        | 200           | 90            | 0       | 290     |

        # Check save draft works and you can go back
        When I click on the "Save draft" button
        Then I should see the "Return saved" page
        And I should see the text "Your reference number is"
        And I should see the text "RS1000947STMD"
        And I should see the text "Back to return summary"
        And I should see the text "Go to dashboard"
        When I click on the "Back to return summary" link
        Then I should see the "Return summary" page

        # Begin calculation part
        When I click on the "Calculate" button
        Then I should see the "Calculated tax liability" page
        And I should see the text "8880" in field "Total tax due"
        And I should see the text "9" in field "Total credit"
        And I should see the text "8871" in field "Total payable"

        When I click on the "Continue" button
        Then I should see the "Payment and submission" page
        # Verify the fpay_method has been stored
        And the radio button "BACS" should be selected in answer to the question "How are you paying?"
        And the radio button "Cheque" should not be selected

        When I check the "BACS" radio button in answer to the question "How are you paying?"
        And I check the "returns_slft_slft_return_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the text "Your amendment to your Scottish Landfill tax return RS1000947STMD has now been submitted."
        And I should see the text "The submission date is NOW_DATE"

        When I click on the "Send secure message" link
        Then I should see the "New message" page

        # Check we can't resubmit
        When I go to the "returns/slft/declaration" page
        Then I should see the "Payment and submission" page
        When I check the "returns_slft_slft_return_declaration" checkbox
        And I click on the "Submit return" button
        Then I should see the "Payment and submission" page
        And I should receive the message "This return has already been submitted. If you are unsure that the return has been submitted, save a draft version and check on the dashboard"


    Scenario: About rounding down waste site value
        # About the transaction
        Given I have signed in "portal.waste.new" and password "Password1!"
        When I click on the "Create SLfT return" menu item
        Then I should see the "Return summary" page
        When I set a period of "2018/19" and "October to December (Quarter 3)"
        Then I should see the "Return summary" page

        And I should see the text "Waste Site 1"

        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        When I click on the "Add new waste type" link
        Then I should see the sub-title "Provide the following waste details"

        When I enter "05 01 03 Tank bottom sludges" in the "EWC code" select or text field
        And I enter "icky goo" in the "Description of waste" field
        And I select "EU" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check the "Yes" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I click on the "Continue" button
        Then I should see the sub-title "Provide tonnage details for this waste type"

        When I enter "5.9" in the "Standard tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code          | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 03/icky goo | 0             | 5.9              | 0              | 0             | 5.9           |

        When I click on the "Add new waste type" link
        Then I should see the sub-title "Provide the following waste details"

        When I enter "01 04 99 Wastes not otherwise specified" in the "EWC code" select or text field
        And I enter "icky goo2" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check the "Yes" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I click on the "Continue" button
        Then I should see the sub-title "Provide tonnage details for this waste type"

        When I enter "5.9" in the "Standard tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code           | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 03/icky goo  | 0             | 5.9              | 0              | 0             | 5.9           |
            | 01 04 99/icky goo2 | 0             | 5.9              | 0              | 0             | 5.9           |
        When I click on the "Return summary" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 0             | 11            | 0       | 11      |
            | Waste Site 2 | 0             | 0             | 0       | 0       |
            | Total        | 0             | 11            | 0       | 11      |

        When I click on the 1 st "Add waste details" link
        Then I should see the "Waste details summary" page
        And I should see the text "Waste details summary for Waste Site 1"

        When I click on the "Add new waste type" link
        Then I should see the sub-title "Provide the following waste details"

        When I enter "05 01 03 Tank bottom sludges" in the "EWC code" select or text field
        And I enter "icky goo" in the "Description of waste" field
        And I select "Falkirk" from the "Geographical area"
        And I select "Landfill" from the "Management method"
        And I check the "Yes" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
        And I click on the "Continue" button
        Then I should see the sub-title "Provide tonnage details for this waste type"

        When I enter "4.22" in the "Lower tonnage" field
        And I enter "1.19" in the "Water discount tonnage" field
        And I click on the "Continue" button
        Then I should see the "Waste details summary" page
        And the table of data is displayed
            | EWC code          | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
            | 05 01 03/icky goo | 4.22          | 0                | 0              | 1.19          | 3.03          |
        When I click on the "Return summary" link
        Then I should see the "Return summary" page
        And the table of data is displayed
            |              | Lower rate    | Standard rate | Exempt  | Total   |
            |              | tonnage (net) | tonnage (net) | tonnage | tonnage |
            | Waste Site 1 | 0             | 11            | 0       | 11      |
            | Waste Site 2 | 3             | 0             | 0       | 3       |
            | Total        | 3             | 11            | 0       | 14      |

    Scenario: Delete draft return

        Given I have signed in "portal.waste.new" and password "Password1!"
        When I click on the "Create SLfT return" menu item
        Then I should see the "Return summary" page

        When I set a period of "2017/18" and "October to December (Quarter 3)"
        Then I should see the "Return summary" page

        When I click on the "Save draft" button
        Then I should see the "Return saved" page
        And I should see the text "Your reference number is"
        And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
        Then I should store the generated value with id "notification_banner_reference"

        When I click on the "Go to dashboard" link
        Then I should see the "Dashboard" page

        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page

        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should see a link with text "Delete"

        When I click on the "Delete" link
        Then if available, click the confirmation dialog
        Then I should see the "Dashboard" page

        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page

        When I enter the stored value "notification_banner_reference" in field "Return reference"
        And I click on the "Find" button
        Then I should see the "Returns" page
        Then I should not see a link with text "Download PDF"