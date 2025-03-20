Feature: SAT Returns
  As a authenticated user
  I want to be able to make Sat return

  Scenario: Sat return user is able to select the return period and see the site data

    # login and make the return
    Given I have signed in "PORTAL.SAT.ONE" and password "Password1!"
    Then I should see the "Dashboard : SAT1000000TVTV Kevin Peterson Partnership" page
    When I click on the "Create SAT return" menu item
    Then I should see the "What accounting period is this return for?" page
    And I should see the text "SAT period"

    # Mandatory validation for SAT period and select the period
    When I click on the "Continue" button
    Then I should receive the message "SAT period can't be blank"
    And I select "01/08/2024 to 31/08/2024" from the "returns_sat_sat_return_sat_period"
    And I click on the "Continue" button

    # Validate the summary page data has loaded from the back office and the page validation
    Then I should see the "Return Summary" page
    And I should see the text "Return period"
    And I should see the text "Before leaving the return, save your changes by clicking on the ‘save draft’ button. Any unsaved changes will be lost."
    And the table of data is displayed
      | SAT period | 01/08/2024 to 31/08/2024 |

    And I should see the text "Registered site list"
    And the table of data is displayed
      | Company                    | Site  | Period start | Period end | Nil submission | Taxable tonnage | Exempt tonnage | Tax due | Tax credits | Tax payable |
      | Kevin Peterson Partnership | Site1 | 01/08/2024   | 31/08/2024 |                |                 |                |         |             |             |
      | Kevin Peterson Partnership | Site2 | 01/08/2024   | 31/08/2024 |                |                 |                |         |             |             |

    And I should see a link with text "Add SAT details"
    And I should see the button with text "Save draft"
    And I should see the button with text "Calculate"
    And I should not see the text "No registered sites for this period, please contact Revenue Scotland"
    And I click on the "Calculate" button
    Then I should see the text "There's an error somewhere in the sat details section for a site(s) - please review the sat details section for a site(s) section of the return and update it"


    # Change the period to the one with no sites and validate the screen
    When I click on the "Back" link
    And if available, click the confirmation dialog
    Then I should see the "What accounting period is this return for?" page
    And I should see the text "01/08/2024 to 31/08/2024"
    And I select "01/07/2024 to 31/07/2024" from the "returns_sat_sat_return_sat_period"
    And I click on the "Continue" button

    Then I should see the "Return Summary" page
    And I should see the text "Return period"
    And I should not see the text "Before leaving the return, save your changes by clicking on the ‘save draft’ button. Any unsaved changes will be lost."
    And the table of data is displayed
      | SAT period | 01/08/2024 to 31/08/2024 |
    And I should see the text "No registered sites for this period, please contact Revenue Scotland"
    And I should not see the button with text "Save draft"
    And I should not see the button with text "Calculate"

    # Log out
    When I click on the "Cancel" menu item
    And if available, click the confirmation dialog
    Then I should see the "Dashboard" page
    And I click on the "Sign out" menu item
    Then I should see the text "Sign in"

    # Login to the user with no periods to validate the screen data
    When I enter "PORTAL.SAT.USERS" in the "Username" field
    And I enter "Password1!" in the "Password" field
    And I click on the "Sign in" button
    Then I should see the "Select your SAT registration" page
    And I check the "SAT1000000RPRP Marks & Spencer Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
    And I click on the "Continue" button

    Then I should see the "Dashboard : SAT1000000RPRP Marks & Spencer Group" page

    # Try to make the SAT return
    When I click on the "Create SAT return" menu item
    Then I should see the "What accounting period is this return for?" page
    And I should see the text "There are no outstanding returns due or relevant return periods"
    And I should not see the button with text "Continue"

  Scenario: Check Validation, Save and Retrieve Draft SAT Return
    Given I have signed in "portal.sat.one" and password "Password1!"
    Then I should see the "Dashboard : SAT1000000TVTV Kevin Peterson Partnership" page
    When I click on the "Create SAT return" menu item
    Then I should see the "What accounting period is this return for?" page
    And I should see the text "SAT period"

    # Mandatory validation for SAT period and select the period
    When I click on the "Continue" button
    Then I should receive the message "SAT period can't be blank"
    And I select "01/08/2024 to 31/08/2024" from the "returns_sat_sat_return_sat_period"
    And I click on the "Continue" button

    # Validate the summary page data has loaded from the back office
    Then I should see the "Return Summary" page
    And I should see the text "Return period"
    And I should see the text "Before leaving the return, save your changes by clicking on the ‘save draft’ button. Any unsaved changes will be lost."
    And the table of data is displayed
      | SAT period | 01/08/2024 to 31/08/2024 |

    And I should see the text "Registered site list"
    And the table of data is displayed
      | Company                    | Site  | Period start | Period end | Nil submission | Taxable tonnage | Exempt tonnage | Tax due | Tax credits | Tax payable |
      | Kevin Peterson Partnership | Site1 | 01/08/2024   | 31/08/2024 |                |                 |                |         |             |             |
      | Kevin Peterson Partnership | Site2 | 01/08/2024   | 31/08/2024 |                |                 |                |         |             |             |

    And I should see a link with text "Add SAT details"
    And I should see the button with text "Save draft"
    And I should see the button with text "Calculate"
    And I should not see the text "No registered sites for this period, please contact Revenue Scotland"

    # Set the Nil Submission true
    When I click on the 1 st "Add SAT details" link
    Then I should see the "Aggregate Activity?" page
    And I check the "No" radio button in answer to the question "Do you have aggregate activity/tax credits you wish to submit for this site for this period?"
    When I click on the "Continue" button
    Then I should see the "Return Summary" page

    And I should see the text "Registered site list"
    And the table of data is displayed
      | Company                    | Site  | Period start | Period end | Nil submission | Taxable tonnage | Exempt tonnage | Tax due | Tax credits | Tax payable |
      | Kevin Peterson Partnership | Site1 | 01/08/2024   | 31/08/2024 | Y              |                 |                |         |             |             |
      | Kevin Peterson Partnership | Site2 | 01/08/2024   | 31/08/2024 |                |                 |                |         |             |             |

    # Set Period including validation checks
    When I click on the 1 st "Add SAT details" link
    Then I should see the "Aggregate Activity?" page
    And I check the "Yes" radio button in answer to the question "Do you have aggregate activity/tax credits you wish to submit for this site for this period?"
    When I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And I should see the sub-title "SAT details summary for Site1 for period 01/08/2024 to 31/08/2024"
    And I should not see the button with text "Save draft"
    And I should see a link with text "Return summary"

    When I click on the "Add taxable aggregate" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I click on the "Continue" button
    Then I should see the text "Aggregate type can't be blank"
    And I should see the text "Type of commercial exploitation can't be blank"
    When I select "Sand/Gravel" from the "Aggregate type"
    And I select "Used for Construction" from the "Type of commercial exploitation"
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site1" page
    And I should see the sub-title "Provide the following aggregate tonnages"
    # Go back and check a form still has data
    When I click on the "Back" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see "Sand/Gravel" in the "Aggregate type" select or text field
    And I should see "Used for Construction" in the "Type of commercial exploitation" select or text field
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site1" page
    And I should see the sub-title "Provide the following aggregate tonnages"

    # Fill in Taxable aggregate tonnage with validation check
    When I click on the "Continue" button
    Then I should see the text "Exploited tonnage can't be blank"
    And I should see the text "Water discount tonnage can't be blank"
    And I should see the text "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement can't be blank"
    When I check the "No" radio button in answer to the question "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement?"
    And I enter "abc" in the "Exploited tonnage" field
    And I enter "abc" in the "Water discount tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the taxable tonnage for Site1" page
    And I should see the text "Exploited tonnage is not a number"
    And I should see the text "Water discount tonnage is not a number"
    When I enter "1000000000000000000" in the "Exploited tonnage" field
    And I enter "1000000000000000000" in the "Water discount tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the taxable tonnage for Site1" page
    And I should see the text "Exploited tonnage must be less than 1000000000000000000"
    And I should see the text "Water discount tonnage must be less than 1000000000000000000"
    When I enter "-343.60" in the "Exploited tonnage" field
    And I enter "-225.88" in the "Water discount tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the taxable tonnage for Site1" page
    And I should see the text "Exploited tonnage must be greater than or equal to 0"
    And I should see the text "Water discount tonnage must be greater than or equal to 0"
    When I enter "124.65" in the "Exploited tonnage" field
    And I enter "98.88" in the "Water discount tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Type of commercial exploitation | Exploited tonnage | Water tonnage | Alternative Weighing Method | Taxable tonnage | Rate  | Tax due |
      | Sand/Gravel | Used for Construction           | 124.65            | 98.88         | N                           | 25.77           | £2.03 | £52.31  |
      | Total       |                                 | 124.65            |               |                             | 25.77           |       | £52.31  |

    When I click on the "Add taxable aggregate" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I click on the "Continue" button
    When I select "Rock" from the "Aggregate type"
    And I select "Agreement To Supply" from the "Type of commercial exploitation"
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site1" page
    And I should see the sub-title "Provide the following aggregate tonnages"
    When I enter "220.55" in the "Exploited tonnage" field
    And I enter "0" in the "Water discount tonnage" field
    And I check the "Yes" radio button in answer to the question "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement?"
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Type of commercial exploitation | Exploited tonnage | Water tonnage | Alternative Weighing Method | Taxable tonnage | Rate  | Tax due |
      | Sand/Gravel | Used for Construction           | 124.65            | 98.88         | N                           | 25.77           | £2.03 | £52.31  |
      | Rock        | Agreement To Supply             | 220.55            | 0.0           | Y                           | 220.55          | £2.03 | £447.71 |
      | Total       |                                 | 345.2             |               |                             | 246.32          |       | £500.02 |

    When I click on the 1 st "Edit row" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see "Sand/Gravel" in the "Aggregate type" select or text field
    And I should see "Used for Construction" in the "Type of commercial exploitation" select or text field
    When I select "Removed from Site" from the "Type of commercial exploitation"
    And I click on the "Continue" button
    Then I should see the "Details of the taxable tonnage for Site1" page
    And I should see the text "124.65" in field "Exploited tonnage"
    And I should see the text "98.88" in field "Water discount tonnage"
    And the radio button "No" should be selected in answer to the question "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement?"
    When I check the "Yes" radio button in answer to the question "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement?"
    And I enter "224.36" in the "Water discount tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the taxable tonnage for Site1" page
    And I should see the text "Water discount tonnage cannot be greater than exploited tonnage"
    When I enter "32.12" in the "Water discount tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Type of commercial exploitation | Exploited tonnage | Water tonnage | Alternative Weighing Method | Taxable tonnage | Rate  | Tax due |
      | Sand/Gravel | Removed from Site               | 124.65            | 32.12         | Y                           | 92.53           | £2.03 | £187.83 |
      | Rock        | Agreement To Supply             | 220.55            | 0             | Y                           | 220.55          | £2.03 | £447.71 |
      | Total       |                                 | 345.2             |               |                             | 313.08          |       | £635.54 |

    When I click on the 1 st "Delete row" link
    And if available, click the confirmation dialog
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type  | Type of commercial exploitation | Exploited tonnage | Water tonnage | Alternative Weighing Method | Taxable tonnage | Rate  | Tax due |
      | Rock  | Agreement To Supply             | 220.55            | 0             | Y                           | 220.55          | £2.03 | £447.71 |
      | Total |                                 | 220.55            |               |                             | 220.55          |       | £447.71 |

    # Carry on with filling in the return
    # Fill in exempt aggregate details with validation check
    When I click on the "Add exempt aggregate" link
    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I click on the "Continue" button
    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the text "Exempt aggregate type can't be blank"
    And I should see the text "Description of exemption can't be blank"
    And I should see the text "Exempt tonnage can't be blank"
    When I select "Sand" from the "Exempt aggregate type"
    And I select "Consists wholly of the spoil of coal, lignite, slate or a relevant substance" from the "Description of exemption"
    And I enter "abc" in the "Exempt tonnage" field
    And I click on the "Continue" button

    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the text "Exempt tonnage is not a number"
    When I enter "1000000000000000000" in the "Exempt tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the text "Exempt tonnage must be less than 1000000000000000000"
    When I enter "-256.78" in the "Exempt tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the text "Exempt tonnage must be greater than or equal to 0"
    When I enter "145.67" in the "Exempt tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Exempt description                                                           | Exempt tonnage |
      | Sand/Gravel | Consists wholly of the spoil of coal, lignite, slate or a relevant substance | 145.67         |
      | Total       |                                                                              | 145            |

    When I click on the "Add exempt aggregate" link
    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I select "Rock" from the "Exempt aggregate type"
    And I select "Creating, restoring, improving or maintaining waterways" from the "Description of exemption"
    And I enter "368.59" in the "Exempt tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Exempt description                                                           | Exempt tonnage |
      | Sand/Gravel | Consists wholly of the spoil of coal, lignite, slate or a relevant substance | 145.67         |
      | Rock        | Creating, restoring, improving or maintaining waterways                      | 368.59         |
      | Total       |                                                                              | 514            |

    When I click on the 2 nd "Edit row" link
    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    And I should see "Sand/Gravel" in the "Exempt aggregate type" select or text field
    And I should see "Consists wholly of the spoil of coal, lignite, slate or a relevant substance" in the "Description of exemption" select or text field
    And I should see the text "145.67" in field "Exempt tonnage"
    When I enter "156.87" in the "Exempt tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Exempt description                                                           | Exempt tonnage |
      | Sand/Gravel | Consists wholly of the spoil of coal, lignite, slate or a relevant substance | 156.87         |
      | Rock        | Creating, restoring, improving or maintaining waterways                      | 368.59         |
      | Total       |                                                                              | 525            |

    When I click on the 3 rd "Delete row" link
    And if available, click the confirmation dialog
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Exempt description                                                           | Exempt tonnage |
      | Sand/Gravel | Consists wholly of the spoil of coal, lignite, slate or a relevant substance | 156.87         |
      | Total       |                                                                              | 156            |

    # Go back and check a form still has data
    When I click on the "Add tax credit" link
    Then I should see the "Details of the tax credit for Site1" page
    When I click on the "Continue" button
    Then I should see the "Details of the tax credit for Site1" page
    And I should see the text "Aggregate type can't be blank"
    And I should see the text "Description of tax credit can't be blank"
    And I should see the text "Does this tax credit relate to a transaction in the current period can't be blank"
    When I select "Rock" from the "Aggregate type"
    And I select "Exported outwith UK" from the "Description of tax credit"
    And I check the "Yes" radio button in answer to the question "Does this tax credit relate to a transaction in the current period?"
    And I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    And I should see the text "01/08/2024 to 31/08/2024" in field "Return period the transaction relating to this tax credit is in"
    And field "Return period the transaction relating to this tax credit is in" should be readonly
    # Go back and check a form still has data
    When I click on the "Back" link
    Then I should see the "Details of the tax credit for Site1" page
    And I should see "Rock" in the "Aggregate type" select or text field
    And I should see "Exported outwith UK" in the "Description of tax credit" select or text field
    And the radio button "Yes" should be selected in answer to the question "Does this tax credit relate to a transaction in the current period?"
    When I check the "No" radio button in answer to the question "Does this tax credit relate to a transaction in the current period?"
    And I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    When I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    And I should see the text "Return period the transaction relating to this tax credit is in can't be blank"
    And I should see the text "Tonnage can't be blank"
    When I select "RS10000001RPTS - 01/06/2024 to 30/06/2024" from the "Return period the transaction relating to this tax credit is in"
    And I enter "abc" in the "Tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    And I should see the text "Tonnage is not a number"
    When I enter "1000000000000000000" in the "Tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    And I should see the text "Tonnage must be less than 1000000000000000000"
    When I enter "-243" in the "Tonnage" field
    And I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    And I should see the text "Tonnage must be greater than or equal to 0"
    When I enter "4285" in the "Tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type  | Tax credit Description | Return relates to | Period relates to        | Tonnage | Rate  | Credit amount |
      | Rock  | Exported outwith UK    | RS10000001RPTS    | 01/06/2024 to 30/06/2024 | 4285    | £2.03 | £8,698.55     |
      | Total |                        |                   |                          |         |       | £8,698.55     |

    When I click on the "Add tax credit" link
    Then I should see the "Details of the tax credit for Site1" page
    When I select "Sand/Gravel" from the "Aggregate type"
    And I select "Disposed of" from the "Description of tax credit"
    And I check the "Yes" radio button in answer to the question "Does this tax credit relate to a transaction in the current period?"
    And I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    When I should see the text "01/08/2024 to 31/08/2024" in field "Return period the transaction relating to this tax credit is in"
    And I enter "3000" in the "Tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Tax credit Description | Return relates to | Period relates to        | Tonnage | Rate  | Credit amount |
      | Rock        | Exported outwith UK    | RS10000001RPTS    | 01/06/2024 to 30/06/2024 | 4285    | £2.03 | £8,698.55     |
      | Sand/Gravel | Disposed of            |                   | 01/08/2024 to 31/08/2024 | 3000    | £2.03 | £6,090.00     |
      | Total       |                        |                   |                          |         |       | £14,788.55    |

    When I click on the "Return summary" link
    Then I should see the "Return Summary" page
    And I click on the "Calculate" button
    And I should see the text "There's an error somewhere in the sat details section for a site(s) - please review the sat details section for a site(s) section of the return and update it"
    And I should see a link with text "Edit SAT details"

    When I click on the 1 st "Add SAT details" link
    Then I should see the "Aggregate Activity?" page
    And I check the "Yes" radio button in answer to the question "Do you have aggregate activity/tax credits you wish to submit for this site for this period?"
    When I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And I should see the sub-title "SAT details summary for Site2 for period 01/08/2024 to 31/08/2024"

    When I click on the "Add taxable aggregate" link
    Then I should see the "Details of the taxable aggregate for Site2" page
    When I select "Sand/Gravel" from the "Aggregate type"
    And I select "Used for Construction" from the "Type of commercial exploitation"
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site2" page

    When I click on the "Continue" button
    When I enter "524" in the "Exploited tonnage" field
    And I enter "120" in the "Water discount tonnage" field
    And I check the "No" radio button in answer to the question "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement?"
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Type of commercial exploitation | Exploited tonnage | Water tonnage | Alternative Weighing Method | Taxable tonnage | Rate  | Tax due |
      | Sand/Gravel | Used for Construction           | 524               | 120           | N                           | 404             | £2.03 | £820.12 |
      | Total       |                                 | 524               |               |                             | 404             |       | £820.12 |

    When I click on the "Return summary" link
    Then I should see the "Return Summary" page
    And I click on the "Calculate" button
    Then I should see the "Bad debt credit claim" page
    When I click on the "Continue" button
    Then I should see the text "Do you have any claims to make in relation to bad debt can't be blank"
    And I check the "No" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
    When I click on the "Continue" button

    Then I should see the "Calculated tax liability" page
    And I should see the text "If these figures are not as expected then click back and update the relevant details in the return"
    And I should see the text "1267.83" in field "Total tax due"
    And I should see the text "14788.55" in field "Total credit"
    And I should see the text "-13521.00" in field "Tax payable"

    When I click on the "Continue" button
    Then I should see the "Repayment details" page
    And I click on the "Continue" button
    Then I should see the text "Do you want to request a repayment from Revenue Scotland can't be blank"

    When I check the "No" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"
    Then I click on the "Continue" button
    And I should see the "Payment and submission" page

    When I click on the "Back" link
    Then I should see the "Repayment details" page
    And I check the "Yes" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"

    When I click on the "Continue" button
    Then I should see the text "How much are you claiming from Revenue Scotland can't be blank"
    And I enter "-500" in the "How much are you claiming from Revenue Scotland?" field

    When I click on the "Continue" button
    Then I should see the text "How much are you claiming from Revenue Scotland must be greater than or equal to 0"
    And I enter "500" in the "How much are you claiming from Revenue Scotland?" field

    When I click on the "Continue" button
    Then I should see the "Enter bank details" page
    And I click on the "Continue" button
    Then I should see the text "Name of the account holder can't be blank"
    And I should see the text "Bank / building society account number can't be blank"
    And I should see the text "Branch sort code can't be blank"
    And I should see the text "Name of bank / building society can't be blank"

    When I enter "Thomas John Smith" in the "Name of the account holder" field
    And I enter "11552495" in the "Bank / building society account number" field
    And I enter "12-34-56" in the "Branch sort code" field
    And I enter "Natwest bank PLC" in the "Name of bank / building society" field

    When I click on the "Continue" button
    Then I should see the "Declaration" page
    And I click on the "Continue" button
    Then I should see the text "I, the taxpayer, declare that this claim is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the repayment claimed, or I, the representative of the taxpayer certify that the taxpayer has declared that this claim is to the best of the taxpayer's knowledge correct and complete, and confirm they are eligible for the repayment claimed must be accepted"
    When I check the "I, the taxpayer, declare that this claim is, to the best of my knowledge, correct and complete, and confirm that I am eligible for the repayment claimed, or I, the representative of the taxpayer certify that the taxpayer has declared that this claim is to the best of the taxpayer's knowledge correct and complete, and confirm they are eligible for the repayment claimed" checkbox
    And I click on the "Continue" button
    Then I should see the "Payment and submission" page
    And I should see the text "If you give false information, you may face penalties and/or prosecution"
    And I click on the "Submit return" button
    Then I should see the "Payment and submission" page
    And I should see the text "There is a problem"
    And I should see the text "How are you paying can't be blank"
    And I should see the text "I, the taxpayer declare that the return is to the best of my knowledge correct and complete or, I the representative of the taxpayer certify that the taxpayer has declared that the information provided in the return is to the best of the taxpayer's knowledge correct and complete. must be accepted"
    And I should see the text "Direct Debit"
    And I check the "BACS" radio button in answer to the question "How are you paying?"
    And I check the "I, the taxpayer declare that the return is to the best of my knowledge correct and complete or, I the representative of the taxpayer certify that the taxpayer has declared that the information provided in the return is to the best of the taxpayer's knowledge correct and complete." checkbox

  Scenario: Sat return user is able to amend a return

    # login and make the return
    Given I have signed in "PORTAL.SAT.THREE" and password "Password1!"
    Then I should see the "Dashboard : SAT1000000ZFES Harry Peterson Partnership" page
    When I click on the 1 st "Find returns" link
    Then I should see the "Returns : SAT1000000ZFES Harry Peterson Partnership" page
    And I select "Filed" from the "dashboard_dashboard_return_filter_return_status"
    And I enter "RS10000001RPTQ" in the "Return reference" field
    And I click on the "Find" button
    Then the table of data is displayed
      | Return reference | Your reference | Submitted date | Description             | Version | Balance | Status       |
      | RS10000001RPTQ   |                | 25/06/2024     | 01/06/2024 - 30/06/2024 | 1       | £0.00   | Filed (Paid) |


    When I click on the "Amend" link
    Then I should see the "Return Summary" page

    When I click on the 1 st "Add SAT details" link
    Then I should see the "Aggregate Activity?" page
    And I check the "No" radio button in answer to the question "Do you have aggregate activity/tax credits you wish to submit for this site for this period?"
    When I click on the "Continue" button
    Then I should see the "Return Summary" page

    When I click on the 2 nd "Add SAT details" link
    Then I should see the "Aggregate Activity?" page
    And I check the "No" radio button in answer to the question "Do you have aggregate activity/tax credits you wish to submit for this site for this period?"
    When I click on the "Continue" button
    Then I should see the "Return Summary" page

    And I click on the "Calculate" button
    Then I should see the "Bad debt credit claim" page
    And I check the "No" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
    When I click on the "Continue" button
    Then I should see the "Calculated tax liability" page
    When I click on the "Continue" button
    Then I should see the "Repayment details" page
    And I check the "No" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"
    When I click on the "Continue" button
    Then I should see the "Amendment reason" page
    And I should see the text "Tell us why you are amending this return"
    And I should see the empty field "Tell us why you are amending this return"
    When I click on the "Continue" button
    Then I should see the text "Tell us why you are amending this return can't be blank"
    When I enter "RANDOM_text,501" in the "Tell us why you are amending this return" field
    And I click on the "Continue" button
    Then I should see the text "Tell us why you are amending this return is too long (maximum is 500 characters)"
    When I enter "RANDOM_text,150" in the "Tell us why you are amending this return" field
    And I click on the "Continue" button
    Then I should see the "Payment and submission" page

  # Loads sat return from draft (mocked) to validate the submission page
  # And to validate the dd warning for amendement
  @mock_sat_load_return_draft
  Scenario: Load sat return and submit the return (mocked)
    Given I have signed in "VALID.USER" and password "valid.password"
    Then I should see the "Dashboard" page
    When I go to the "dashboard/dashboard_returns/1338-1-SAT-RS/load" page
    Then I should see the "Return Summary" page
    And the table of data is displayed
      | SAT period | 01/08/2024 to 31/08/2024 |

    And I should see the text "Registered site list"
    And the table of data is displayed
      | Company                    | Site  | Period start | Period end | Nil submission | Taxable tonnage | Exempt tonnage | Tax due   | Tax credits | Tax payable |
      | Kevin Peterson Partnership | Site1 | 01/08/2024   | 31/08/2024 |                | 500             | 0              | £1,015.00 | £1,015.00   | £1,015.00   |
      | Kevin Peterson Partnership | Site2 | 01/08/2024   | 31/08/2024 |                | 500             | 0              | £1,015.00 | £1,015.00   | £1,015.00   |

    When I click on the "Calculate" button
    Then I should see the "Bad debt credit claim" page
    And I check the "No" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
    When I click on the "Continue" button
    Then I should see the "Calculated tax liability" page
    And I should see the text "2030.00" in field "Total tax due"
    And I should see the text "0.00" in field "Total credit"
    And I should see the text "2030.00" in field "Tax payable"

    When I click on the "Continue" button
    Then I should see the "Payment and submission" page
    And I should not see the text "Direct Debit"
    And I check the "BACS" radio button in answer to the question "How are you paying?"
    And I check the "I, the taxpayer declare that the return is to the best of my knowledge correct and complete or, I the representative of the taxpayer certify that the taxpayer has declared that the information provided in the return is to the best of the taxpayer's knowledge correct and complete." checkbox

    When I click on the "Submit return" button
    Then I should see the "Your return has been submitted" page
    And I should see the text "Your reference number is"
    And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
    And I should store the generated value with id "notification_banner_reference"
    And I should see the text "The submission date is NOW_DATE"
    And I should see the text "Payment is due no later than filing date, which is 30 days after the end of the relevant accounting period. If the return is submitted close to the filing date you must ensure that full payment reaches us no later than the filing date for the return."
    And I should see the text "If the return has been filed or amended after the 30 day period, then payment is due immediately."
    And I should see the text "You have stated that you are going to pay by BACS. Details on how to make payments can be found on our website."
    And I should see the text "Interest is chargeable on any outstanding tax that is not paid by the filing date. If the return is submitted late you may be liable to a penalty. If tax is paid late, interest is chargeable and you may also become liable to a penalty. Further guidance on interest and penalties is available on our website."
    And I should see the text "If you have any queries about this return, you can contact Revenue Scotland by sending a secure message or by calling the support desk on 03000 200 310."

    When I go to the "dashboard/dashboard_returns/1338-2-SAT-RS/load" page
    Then I should see the "Return Summary" page
    And the table of data is displayed
      | SAT period | 01/08/2024 to 31/08/2024 |
    And I click on the "Calculate" button
    Then I should see the "Bad debt credit claim" page
    When I check the "No" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
    When I click on the "Continue" button

    Then I should see the "Calculated tax liability" page
    And I should see the text "2030.00" in field "Total tax due"
    And I should see the text "0.00" in field "Total credit"
    And I should see the text "2030.00" in field "Tax payable"

    When I click on the "Continue" button
    Then I should see the "Repayment details" page
    And I check the "No" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"

    When I click on the "Continue" button
    Then I should see the "Amendment reason" page
    And I should see the empty field "Tell us why you are amending this return"
    And I enter "RANDOM_text,150" in the "Tell us why you are amending this return" field

    When I click on the "Continue" button
    Then I should see the "Payment and submission" page
    And I should see the text "Direct Debit is unavailable on this return as the previous submission did not use Direct Debt"
    And the checkbox "BACS" should be checked

  # Loads sat return from final (mocked) to validate the amendment submission page
  @mock_sat_load_return_final
  Scenario: Load sat return and submits the amended return (mocked)
    Given I have signed in "VALID.USER" and password "valid.password"
    Then I should see the "Dashboard" page
    When I go to the "dashboard/dashboard_returns/1339-2-SAT-RS/load" page
    Then I should see the "Return Summary" page
    And the table of data is displayed
      | SAT period | 01/08/2024 to 31/08/2024 |

    And I should see the text "Registered site list"
    And the table of data is displayed
      | Company                    | Site  | Period start | Period end | Nil submission | Taxable tonnage | Exempt tonnage | Tax due   | Tax credits | Tax payable |
      | Kevin Peterson Partnership | Site1 | 01/08/2024   | 31/08/2024 |                | 500             | 0              | £1,015.00 | £1,015.00   | £1,015.00   |
      | Kevin Peterson Partnership | Site2 | 01/08/2024   | 31/08/2024 |                | 500             | 0              | £1,015.00 | £1,015.00   | £1,015.00   |

    When I click on the "Calculate" button
    Then I should see the "Bad debt credit claim" page
    And I check the "No" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
    When I click on the "Continue" button
    Then I should see the "Calculated tax liability" page
    And I should see the text "2030.00" in field "Total tax due"
    And I should see the text "0.00" in field "Total credit"
    And I should see the text "2030.00" in field "Tax payable"

    When I click on the "Continue" button
    Then I should see the "Repayment details" page
    And I check the "No" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"

    When I click on the "Continue" button
    Then I should see the "Amendment reason" page
    And I should see the empty field "Tell us why you are amending this return"
    And I enter "RANDOM_text,150" in the "Tell us why you are amending this return" field

    When I click on the "Continue" button
    Then I should see the "Payment and submission" page
    And the checkbox "Direct Debit" should be checked
    And I check the "BACS" radio button in answer to the question "How are you paying?"
    And I should not see the text "Direct Debit is unavailable on this return as the previous submission did not use Direct Debt"
    And I check the "I, the taxpayer declare that the return is to the best of my knowledge correct and complete or, I the representative of the taxpayer certify that the taxpayer has declared that the information provided in the return is to the best of the taxpayer's knowledge correct and complete." checkbox

    When I click on the "Submit return" button
    Then I should see the "Your return has been submitted" page
    And I should see the text "Your reference number is"
    And I should see the text "%r{RS\d{7}[a-zA-Z]{4}}"
    And I should see the text "The submission date is NOW_DATE"
    And I should see the text "Payment is due no later than filing date, which is 30 days after the end of the relevant accounting period. If the return is submitted close to the filing date you must ensure that full payment reaches us no later than the filing date for the return."
    And I should see the text "If the return has been filed or amended after the 30 day period, then payment is due immediately."
    And I should see the text "You have stated that you are going to pay by BACS. Details on how to make payments can be found on our website."
    And I should see the text "Interest is chargeable on any outstanding tax that is not paid by the filing date. If the return is submitted late you may be liable to a penalty. If tax is paid late, interest is chargeable and you may also become liable to a penalty. Further guidance on interest and penalties is available on our website."
    And I should see the text "If you have any queries about this return, you can contact Revenue Scotland by sending a secure message or by calling the support desk on 03000 200 310."

  # Loads sat return from draft (mocked) to validate the bad debt credit details page
  @mock_sat_load_return_draft
  Scenario: Load sat return and validate bad debt returns
    Given I have signed in "VALID.USER" and password "valid.password"
    Then I should see the "Dashboard" page
    When I go to the "dashboard/dashboard_returns/1338-1-SAT-RS/load" page
    Then I should see the "Return Summary" page
    And the table of data is displayed
      | SAT period | 01/08/2024 to 31/08/2024 |

    And I should see the text "Registered site list"
    And the table of data is displayed
      | Company                    | Site  | Period start | Period end | Nil submission | Taxable tonnage | Exempt tonnage | Tax due   | Tax credits | Tax payable |
      | Kevin Peterson Partnership | Site1 | 01/08/2024   | 31/08/2024 |                | 500             | 0              | £1,015.00 | £1,015.00   | £1,015.00   |
      | Kevin Peterson Partnership | Site2 | 01/08/2024   | 31/08/2024 |                | 500             | 0              | £1,015.00 | £1,015.00   | £1,015.00   |

    When I click on the "Calculate" button
    Then I should see the "Bad debt credit claim" page
    And I check the "Yes" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
    When I click on the "Continue" button

    # Validate the bad credit detail fields and acceptance
    Then I should see the 'Bad debt credit claim details' page
    When I click on the "Continue" button
    Then I should see the text "Bad debt credit claim amount can't be blank"
    Then I should see the text "Bad debt credit claim description can't be blank"
    Then I should see the text 'I, the taxpayer confirm that the requirements to claim a bad debt tax credit have been met or, I the representative of the taxpayer certify that the taxpayer has confirmed that the requirements to claim a bad debt tax credit have been met.'

    # Validate the bad credit amount field
    When I enter "1000000000000000000" in the "Bad debt credit claim amount" field
    And I enter "RANDOM_text,200" in the "Bad debt credit claim description" field
    And I check the "I, the taxpayer confirm that the requirements to claim a bad debt tax credit have been met or, I the representative of the taxpayer certify that the taxpayer has confirmed that the requirements to claim a bad debt tax credit have been met." checkbox
    When I click on the "Continue" button
    Then I should see the text 'Bad debt credit claim amount must be less than 1000000000000000000'

    # Validate the bad credit detail description field which has an upper limit of 3000 characters
    When I enter "1500" in the "Bad debt credit claim amount" field
    And I enter "RANDOM_text,3001" in the "Bad debt credit claim description" field
    And I check the "I, the taxpayer confirm that the requirements to claim a bad debt tax credit have been met or, I the representative of the taxpayer certify that the taxpayer has confirmed that the requirements to claim a bad debt tax credit have been met." checkbox
    When I click on the "Continue" button
    Then I should see the text 'Bad debt credit claim description is too long (maximum is 3000 characters)'

    # Validate the form acceptance
    When I enter "1500" in the "Bad debt credit claim amount" field
    And I enter "RANDOM_text,200" in the "Bad debt credit claim description" field
    # And I check the "I, the taxpayer, or I the representative of the taxpayer, confirm that all the requirements to claim a bad debt credit have been met." checkbox
    When I uncheck the "I, the taxpayer confirm that the requirements to claim a bad debt tax credit have been met or, I the representative of the taxpayer certify that the taxpayer has confirmed that the requirements to claim a bad debt tax credit have been met." checkbox
    And I click on the "Continue" button
    Then I should see the text 'I, the taxpayer confirm that the requirements to claim a bad debt tax credit have been met or, I the representative of the taxpayer certify that the taxpayer has confirmed that the requirements to claim a bad debt tax credit have been met. must be accepted'

    # Redirect upon valid submission
    When I enter "1500" in the "Bad debt credit claim amount" field
    And I enter "RANDOM_text,200" in the "Bad debt credit claim description" field
    And I check the "I, the taxpayer confirm that the requirements to claim a bad debt tax credit have been met or, I the representative of the taxpayer certify that the taxpayer has confirmed that the requirements to claim a bad debt tax credit have been met." checkbox
    And I click on the "Continue" button
    Then I should see the "Calculated tax liability" page

  Scenario: Submitting a SAT return for split period with different tax rates
    Given I have signed in "PORTAL.SAT.TAXPAYER" and password "Password1!"
    Then I should see the "Dashboard : SAT1000000KGLM Jim And James Group" page
    When I click on the 1 st "Find returns" link
    Then I should see the "Returns : SAT1000000KGLM Jim And James Group" page
    When I select "Filed" from the "dashboard_dashboard_return_filter_return_status"
    And I enter "RS10000001GLVD" in the "Return reference" field
    Then I should see the "Returns : SAT1000000KGLM Jim And James Group" page
    When I click on the "Find" button
    Then I should see the text "RS10000001GLVD"

    When I click on the "Amend" link
    Then I should see the "Return Summary" page

    # Validate the summary page data has loaded from the back office
    And I should see the "Return Summary" page
    And I should see the text "Return period"
    And I should see the text "Before leaving the return, save your changes by clicking on the ‘save draft’ button. Any unsaved changes will be lost."
    And the table of data is displayed
      | SAT period | 01/12/2024 to 28/02/2025 |
    And I should see the text "Registered site list"
    And I should see a link with text "Edit SAT details"
    And I should see the button with text "Save draft"
    And I should see the button with text "Calculate"
    And I should not see the text "No registered sites for this period, please contact Revenue Scotland"

    # Adding data for site1 and first breakdown period
    When I click on the 1 st "Edit SAT details" link
    Then I should see the "SAT details summary" page
    And I should see the sub-title "SAT details summary for Site1 for period 01/12/2024 to 31/12/2024"
    And I should see a link with text "Return summary"

    # Clearing out existing data to submit new taxable aggregate details
    When I click on the 1 st "Delete all" link
    And if available, click the confirmation dialog
    Then I should see the "SAT details summary" page

    # Clearing out existing data to submit new exempt aggregate details
    When I click on the 2 nd "Delete all" link
    And if available, click the confirmation dialog
    Then I should see the "SAT details summary" page

    # Clearing out existing data to submit new tax credit details
    When I click on the 3 rd "Delete all" link
    And if available, click the confirmation dialog
    Then I should see the "SAT details summary" page

    When I click on the "Add taxable aggregate" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I select "Sand/Gravel" from the "Aggregate type"
    And I select "Used for Construction" from the "Type of commercial exploitation"
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site1" page
    And I should see the sub-title "Provide the following aggregate tonnages"
    # Go back and check a form still has data
    When I click on the "Back" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see "Sand/Gravel" in the "Aggregate type" select or text field
    And I should see "Used for Construction" in the "Type of commercial exploitation" select or text field
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site1" page
    And I should see the sub-title "Provide the following aggregate tonnages"

    # Fill in Taxable aggregate tonnage
    When I check the "No" radio button in answer to the question "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement?"
    And I enter "1280" in the "Exploited tonnage" field
    And I enter "180" in the "Water discount tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Type of commercial exploitation | Exploited tonnage | Water tonnage | Alternative Weighing Method | Taxable tonnage | Rate  | Tax due |
      | Sand/Gravel | Used for Construction           | 1280              | 180           | N                           | 1100            | £2.03 | £2,233  |
      | Total       |                                 | 1280              |               |                             | 1100            |       | £2,233  |

    When I click on the "Add taxable aggregate" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I click on the "Continue" button
    When I select "Rock" from the "Aggregate type"
    And I select "Agreement To Supply" from the "Type of commercial exploitation"
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site1" page
    And I should see the sub-title "Provide the following aggregate tonnages"
    When I enter "220.55" in the "Exploited tonnage" field
    And I enter "0" in the "Water discount tonnage" field
    And I check the "Yes" radio button in answer to the question "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement?"
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Type of commercial exploitation | Exploited tonnage | Water tonnage | Alternative Weighing Method | Taxable tonnage | Rate  | Tax due   |
      | Sand/Gravel | Used for Construction           | 1280              | 180           | N                           | 1100            | £2.03 | £2,233    |
      | Rock        | Agreement To Supply             | 220.55            | 0             | Y                           | 220.55          | £2.03 | £447.71   |
      | Total       |                                 | 1500.55           |               |                             | 1320.55         |       | £2,680.71 |

    # Carry on with filling in the return
    # Fill in exempt aggregate details with validation check
    When I click on the "Add exempt aggregate" link
    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I click on the "Continue" button
    Then I should see the "Details of the exempt aggregate for Site1" page
    When I select "Sand" from the "Exempt aggregate type"
    And I select "Consists wholly of the spoil of coal, lignite, slate or a relevant substance" from the "Description of exemption"
    Then I should see the "Details of the exempt aggregate for Site1" page
    When I enter "1458.67" in the "Exempt tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Exempt description                                                           | Exempt tonnage |
      | Sand/Gravel | Consists wholly of the spoil of coal, lignite, slate or a relevant substance | 1458.67        |
      | Total       |                                                                              | 1458           |

    # Go back and check a form still has data
    When I click on the "Add tax credit" link
    Then I should see the "Details of the tax credit for Site1" page
    When I select "Rock" from the "Aggregate type"
    And I select "Exported outwith UK" from the "Description of tax credit"
    Then I should see the "Details of the tax credit for Site1" page
    When I check the "Yes" radio button in answer to the question "Does this tax credit relate to a transaction in the current period?"
    And I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    And I should see the text "01/12/2024 to 31/12/2024" in field "Return period the transaction relating to this tax credit is in"
    And field "Return period the transaction relating to this tax credit is in" should be readonly
    When I enter "4285" in the "Tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type  | Tax credit Description | Return relates to | Period relates to        | Tonnage | Rate  | Credit amount |
      | Rock  | Exported outwith UK    |                   | 01/12/2024 to 31/12/2024 | 4285    | £2.03 | £8,698.55     |
      | Total |                        |                   |                          |         |       | £8,698.55     |

    When I click on the "Return summary" link
    Then I should see the "Return Summary" page

    # Adding data for site1 and second breakdown period
    When I click on the 2 nd "Edit SAT details" link
    Then I should see the "SAT details summary" page
    And I should see the sub-title "SAT details summary for Site1 for period 01/01/2025 to 28/02/2025"
    And I should see a link with text "Return summary"

    # Clearing out existing data to submit new taxable aggregate details
    When I click on the 1 st "Delete all" link
    And if available, click the confirmation dialog
    Then I should see the "SAT details summary" page

    # Clearing out existing data to submit new exempt aggregate details
    When I click on the 2 nd "Delete all" link
    And if available, click the confirmation dialog
    Then I should see the "SAT details summary" page

    # Clearing out existing data to submit new tax credit details
    When I click on the 3 rd "Delete all" link
    And if available, click the confirmation dialog
    Then I should see the "SAT details summary" page

    When I click on the "Add taxable aggregate" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I select "Rock" from the "Aggregate type"
    And I select "Agreement To Supply" from the "Type of commercial exploitation"
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site1" page
    And I should see the sub-title "Provide the following aggregate tonnages"
    # Go back and check a form still has data
    When I click on the "Back" link
    Then I should see the "Details of the taxable aggregate for Site1" page
    And I should see "Rock" in the "Aggregate type" select or text field
    And I should see "Agreement To Supply" in the "Type of commercial exploitation" select or text field
    Then I click on the "Continue" button
    And I should see the "Details of the taxable tonnage for Site1" page
    And I should see the sub-title "Provide the following aggregate tonnages"

    # Fill in Taxable aggregate tonnage
    When I check the "No" radio button in answer to the question "Is any part of the Aggregate Activity subject to an Alternative Weighing Method Agreement?"
    And I enter "1490" in the "Exploited tonnage" field
    And I enter "210" in the "Water discount tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type  | Type of commercial exploitation | Exploited tonnage | Water tonnage | Alternative Weighing Method | Taxable tonnage | Rate  | Tax due |
      | Rock  | Agreement To Supply             | 1490              | 210           | N                           | 1280            | £2.10 | £2,688  |
      | Total |                                 | 1490              |               |                             | 1280            |       | £2,688  |

    # Carry on with filling in the return
    # Fill in exempt aggregate details
    When I click on the "Add exempt aggregate" link
    Then I should see the "Details of the exempt aggregate for Site1" page
    And I should see the sub-title "Provide the following aggregate details"
    When I click on the "Continue" button
    Then I should see the "Details of the exempt aggregate for Site1" page
    When I select "Sand/Gravel" from the "Exempt aggregate type"
    And I select "Creating, restoring, improving or maintaining waterways" from the "Description of exemption"
    Then I should see the "Details of the exempt aggregate for Site1" page
    When I enter "100" in the "Exempt tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Exempt description                                      | Exempt tonnage |
      | Sand/Gravel | Creating, restoring, improving or maintaining waterways | 100            |
      | Total       |                                                         | 100            |

    # Go back and check a form still has data
    When I click on the "Add tax credit" link
    Then I should see the "Details of the tax credit for Site1" page
    When I select "Sand/Gravel" from the "Aggregate type"
    And I select "Excepted Process Applied" from the "Description of tax credit"
    Then I should see the "Details of the tax credit for Site1" page
    When I check the "Yes" radio button in answer to the question "Does this tax credit relate to a transaction in the current period?"
    And I click on the "Continue" button
    Then I should see the "Details of the tax credit tonnage for Site1" page
    And I should see the text "01/01/2025 to 28/02/2025" in field "Return period the transaction relating to this tax credit is in"
    And field "Return period the transaction relating to this tax credit is in" should be readonly
    When I enter "569" in the "Tonnage" field
    And I click on the "Continue" button
    Then I should see the "SAT details summary" page
    And the table of data is displayed
      | Type        | Tax credit Description   | Return relates to | Period relates to        | Tonnage | Rate  | Credit amount |
      | Sand/Gravel | Excepted Process Applied |                   | 01/01/2025 to 28/02/2025 | 569     | £2.10 | £1,194.90     |
      | Total       |                          |                   |                          |         |       | £1,194.90     |

    When I click on the "Return summary" link
    Then I should see the "Return Summary" page

    When I click on the "Calculate" button
    Then I should see the "Bad debt credit claim" page
    And I check the "No" radio button in answer to the question "Do you have any claims to make in relation to bad debt?"
    When I click on the "Continue" button
    Then I should see the "Calculated tax liability" page
    And I should see the text "If these figures are not as expected then click back and update the relevant details in the return"
    And I should see the text "5368.71" in field "Total tax due"
    And I should see the text "9893.45" in field "Total credit"
    And I should see the text "-4525.00" in field "Tax payable"

    When I click on the "Continue" button
    Then I should see the "Repayment details" page
    And I click on the "Continue" button
    Then I should see the text "Do you want to request a repayment from Revenue Scotland can't be blank"

    When I check the "No" radio button in answer to the question "Do you want to request a repayment from Revenue Scotland?"
    And I click on the "Continue" button
    Then I should see the "Amendment reason" page
    And I should see the text "Tell us why you are amending this return"
    When I enter "Test" in the "Tell us why you are amending this return" field
    And I click on the "Continue" button
    And I should see the "Payment and submission" page
    When I check the "BACS" radio button in answer to the question "How are you paying?"
    And I check the "I, the taxpayer declare that the return is to the best of my knowledge correct and complete or, I the representative of the taxpayer certify that the taxpayer has declared that the information provided in the return is to the best of the taxpayer's knowledge correct and complete." checkbox
    Then I should see the "Payment and submission" page

    When I click on the "Submit return" button
    Then I should see the "Your return has been submitted" page
