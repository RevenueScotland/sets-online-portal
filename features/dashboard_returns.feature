# feature/dashboard_returns.feature

Feature: Dashboard All Returns
    As a registered user
    I want to be able to see all of my returns from Dashboard
    So that I can view the returns, amend, view and download it as pdf

    # Index page tests
    Scenario: View list of all returns
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        Then I should see the "Dashboard" page
        And I should see the sub-title "Draft returns"
        And the table of data is displayed
            | Return reference | Description | Version | Action_1     | Action_2               | Action_3               | Action_4        |
            | RS1008003OKAY    | Q3 2019     | 3       | Download PDF | Download waste details | Delete                 | Ongoing enquiry |
            | RS1008002WAUW    | Q4 2019     | 1       | Continue     | Download PDF           | Download waste details | Delete          |
            | RS100002AAAAA    | Q2 2024     | 1       | Continue     | Download PDF           | Download waste details | Delete          |
        And I should see the sub-title "Outstanding balance"
        And the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance   | Status        | Action_1     | Action_2     | Action_3               | Action_4 | Action_5 |
            | RS100001AAAAA    | 01/07/2024     | Q1 2024     | 2       | £1,000.00 | Filed (Debit) | Transactions | Download PDF | Download waste details | Amend    | Message  |
        # Check old version of the return is not shown
        And I should not see the text "Q1 2019"
        And I should not see the text "19/06/2023"

        When I click on the 2 nd "Find returns" link
        Then I should see the "Returns" page
        And the checkbox "Only returns with an outstanding balance" should be checked
        When I uncheck the "Only returns with an outstanding balance" checkbox
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance   | Status        | Action_1     | Action_2               | Action_3     | Action_4        | Action_5        |
            | RS1008003OKAY    |                | Q3 2019     | 3       |           | Draft         | Download PDF | Download waste details | Delete       | Ongoing enquiry |                 |
            | RS1008002WAUW    |                | Q4 2019     | 1       |           | Draft         | Download PDF | Download waste details | Continue     | Delete          |                 |
            | RS100002AAAAA    |                | Q2 2024     | 1       |           | Draft         | Download PDF | Download waste details | Continue     | Delete          |                 |
            | RS1008003OKAY    | 01/07/2024     | Q3 2019     | 2       | £0.00     | Filed (Paid)  | Download PDF | Download waste details | Transactions | Message         | Ongoing enquiry |
            | RS1008001HALO    | 01/07/2024     | Q1 2016     | 2       | £0.00     | Filed (Paid)  | Download PDF | Download waste details | Transactions | Claim           | Message         |
            | RS100001AAAAA    | 01/07/2024     | Q1 2024     | 2       | £1,000.00 | Filed (Debit) | Download PDF | Download waste details | Transactions | Amend           | Message         |
            | RS1008004HMMM    | 19/06/2024     | Q2 2019     | 1       | £0.00     | Filed (Paid)  | Download PDF | Download waste details | Transactions | Amend           | Message         |
        And I should not see the text "Q1 2019"

    # Index page tests
    Scenario: Check draft stops amend link being shown
        Given I have signed in
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference | Your reference          | Description            | Version | Action_1 | Action_2     | Action_3 |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 | Conveyance or transfer | 2       | Continue | Download PDF | Delete   |
        And I should not see a link with text "Download waste details"

        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page
        And the checkbox "Only my returns" should be checked
        And I should see "Draft" in the "Return status" select or text field
        When I uncheck the "Only my returns" checkbox
        And I select "" from the "Return status"
        And I click on the "Find" button
        Then the table of data is displayed
            # Note we only use partial references in those with \ as the code inserts a zero width space to allow breaking
            | Return reference | Your reference          | Submitted date | Description            | Version | Balance | Status        | Action_1     | Action_2     | Action_3 | Action_4      |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 |                | Conveyance or transfer | 2       |         | Draft         | Download PDF | Continue     | Delete   |               |
            | RS3000004DDDD    | ABcC                    | 01/07/2024     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Amend    | Message       |
            | RS2000004DDDD    | ABcC                    | 01/07/2024     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Amend    | Message       |
            | RS2000001HHHH    | AaBbCc                  | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Draft         | Download PDF | Continue     | Delete   |               |
            | RS2000001SSSS    | AaBbCc                  | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Amend    | Message       |
            | RS2000001AAAA    | CO99999.0001            | 01/07/2024     | Conveyance or transfer | 1       | £200.00 | Filed (Debit) | Download PDF | Transactions | Message  | Draft present |
            | RS2000003BBBB    | XXXXX02-99              | 01/06/2022     | Lease                  | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
            | RS3000003EEEE    | XXXXX02-99              | 01/10/2019     | Lease                  | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
            | RS3000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
        And I should not see a link with text "Download waste details"
        When I enter "b" in the "Your reference" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Your reference          | Submitted date | Description            | Version | Balance | Status       | Action_1     | Action_2     | Action_3 | Action_4 |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 |                | Conveyance or transfer | 2       |         | Draft        | Download PDF | Continue     | Delete   |          |
            | RS3000004DDDD    | ABcC                    | 01/07/2024     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Amend    | Message  |
            | RS2000004DDDD    | ABcC                    | 01/07/2024     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Amend    | Message  |
            | RS2000001HHHH    | AaBbCc                  | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Draft        | Download PDF | Continue     | Delete   |          |
            | RS2000001SSSS    | AaBbCc                  | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Amend    | Message  |
            | RS3000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Claim    | Message  |
            | RS2000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Claim    | Message  |
        When I clear the "Your reference" field
        And I select "Return reference" from the "Sort by"
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Your reference          | Submitted date | Description            | Version | Balance | Status        | Action_1     | Action_2     | Action_3 | Action_4      |
            | RS2000001AAAA    | CO99999.0001            | 01/07/2024     | Conveyance or transfer | 1       | £200.00 | Filed (Debit) | Download PDF | Transactions | Message  | Draft present |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 |                | Conveyance or transfer | 2       |         | Draft         | Download PDF | Continue     | Delete   |               |
            | RS2000001HHHH    | AaBbCc                  | 01/07/2024     | Conveyance or transfer | 1       | £0.00   | Draft         | Download PDF | Continue     | Delete   |               |
            | RS2000001SSSS    | AaBbCc                  | 01/07/2024     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Amend    | Message       |
            | RS2000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
            | RS2000003BBBB    | XXXXX02-99              | 01/06/2022     | Lease                  | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
            | RS2000004DDDD    | ABcC                    | 01/07/2024     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Amend    | Message       |
            | RS3000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
            | RS3000003EEEE    | XXXXX02-99              | 01/10/2019     | Lease                  | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |

    Scenario: Filter data to list down all that's needed to be seen
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page
        When I open the "Show more filter options" summary item
        Then I should see the "Returns" page
        And I enter "09-01-2099" in the "Submitted from date" date field
        And I select "" from the "Return status"
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should not see a link with text "Download PDF"

        When I open the "Show more filter options" summary item
        Then I should see the "Returns" page
        And I clear the "Submitted from date" field
        And I select "Draft" from the "Return status"
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance | Status | Action_1     | Action_2               | Action_3 | Action_4        | Action_5 |
            | RS1008003OKAY    |                | Q3 2019     | 3       |         | Draft  | Download PDF | Download waste details | Delete   | Ongoing enquiry |          |
            | RS1008002WAUW    |                | Q4 2019     | 1       |         | Draft  | Download PDF | Download waste details | Continue | Delete          |          |
            | RS100002AAAAA    |                | Q2 2024     | 1       |         | Draft  | Download PDF | Download waste details | Continue | Delete          |          |

        When I click on the "Dashboard" menu item
        Then I should see the "Dashboard" page
        And I should see the text "Find returns"
        And I should see the text "Find transactions"
        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page
        When I enter "RS1008003OKAY" in the "Return reference" field
        And I select "" from the "Return status"
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance | Status       | Action_1     | Action_2               | Action_3     | Action_4        | Action_5        |
            | RS1008003OKAY    |                | Q3 2019     | 3       |         | Draft        | Download PDF | Download waste details | Delete       | Ongoing enquiry |                 |
            | RS1008003OKAY    | 01/07/2024     | Q3 2019     | 2       | £0.00   | Filed (Paid) | Download PDF | Download waste details | Transactions | Message         | Ongoing enquiry |

        When I open the "Show more filter options" summary item
        Then I should see the "Returns" page
        And I check the "Include previous versions" checkbox
        And I enter "RS1008003Okay" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance | Status       | Action_1     | Action_2               | Action_3        | Action_4        | Action_5        |
            | RS1008003OKAY    |                | Q3 2019     | 3       |         | Draft        | Download PDF | Download waste details | Delete          | Ongoing enquiry |                 |
            | RS1008003OKAY    | 01/07/2024     | Q3 2019     | 2       | £0.00   | Filed (Paid) | Download PDF | Download waste details | Transactions    | Message         | Ongoing enquiry |
            | RS1008003OKAY    | 19/06/2024     | Q3 2019     | 1       | £0.00   | Filed (Paid) | Download PDF | Download waste details | Ongoing enquiry |                 |                 |

        When I open the "Show more filter options" summary item
        Then I should see the "Returns" page
        And I enter "20191111-01-09" in the "Submitted from date" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should see the text "Submitted from date is invalid"

    Scenario: Checking access
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        Then I should see the text "Create SLfT return"
        And I should not see the text "Create LBTT return"
        When I click on the "Sign out" menu item
        Then I should see the text "Sign in"
        And I have signed in
        Then I should see the text "Create LBTT return"
        And I should not see the text "Create SLfT return"

    Scenario: Checking for a SAT return is not visable to the other enrolments linked to that user
        Given I have signed in "PORTAL.SAT.ONE" and password "Password1!"
        Then I should see the "Dashboard : SAT1000000TVTV Kevin Peterson Partnership" page
        And I click on the 1 st "Find returns" link
        Then I should see the "Returns" page
        And I should see "Draft" in the "Return status" select or text field
        And I enter "RS11000000TVTV" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description             | Version | Balance | Status | Action_1 | Action_2     | Action_3 |
            | RS11000000TVTV   |                | 25/07/2024     | 01/07/2024 - 31/07/2024 | 1       |         | Draft  | Continue | Download PDF | Delete   |

        When I click on the "Sign out" menu item
        Then I should see the text "Sign in"
        When I enter "PORTAL.SAT.USERS" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the "Select your SAT registration" page
        And I check the "SAT1000000RPRP Marks & Spencer Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button

        Then I should see the "Dashboard : SAT1000000RPRP Marks & Spencer Group" page
        And I click on the 2 nd "Find returns" link
        Then I should see the "Returns" page
        And I select "Draft" from the "Return status"
        And I enter "RS11000000TVTV" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description | Version | Balance | Status | Action_1 | Action_2 | Action_3 |
        And I should not see the text "Continue"

        And I enter "RS1SAT1000000RPRP" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description | Version | Balance | Status | Action_1 | Action_2 | Action_3 |

        When I uncheck the "Only returns with an outstanding balance" checkbox
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference  | Your reference | Submitted date | Description             | Version | Balance | Status | Action_1 | Action_2     | Action_3 |
            | RS1SAT1000000RPRP |                | 25/07/2024     | 01/07/2024 - 31/07/2024 | 1       |         | Draft  | Continue | Download PDF | Delete   |

        When I click on the "Sign out" menu item
        Then I should see the text "Sign in"
        When I enter "PORTAL.SAT.USERS" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the "Select your SAT registration" page
        And I check the "SAT1000000VVVV Black Sands Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button

        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page
        And I click on the 2 nd "Find returns" link
        Then I should see the "Returns" page
        And I select "Draft" from the "Return status"
        And I enter "RS11000000TVTV" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description | Version | Balance | Status | Action_1 | Action_2 | Action_3 |
        And I should not see the text "Continue"

        And I enter "RS1SAT1000000RPRP" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description | Version | Balance | Status | Action_1 | Action_2 | Action_3 |
        And I should not see the text "Continue"

    Scenario: Search for a return that the enrolment is linked but the return is not linked to the party
        Given I have signed in 'PORTAL.SAT.ONE' and password 'Password1!'
        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page
        And I enter "RS11000000BSJA" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should see the text "Draft"
        And I should not see a link with text "Download PDF"
        And I should not see a link with text "Continue"
        And I should not see a link with text "Delete"
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description | Version | Balance | Status | Action_1 | Action_2 | Action_3 |

    # Index page tests
    Scenario: View list of all returns
        When I go to the "Login" page
        And I enter "PORTAL.SAT.USERS" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the "Select your SAT registration" page
        And I check the "SAT1000000RPRP Marks & Spencer Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button

        Then I should see the "Dashboard : SAT1000000RPRP Marks & Spencer Group" page
        And I should see the sub-title "Draft returns"
        And the table of data is displayed
            | Return reference  | Your reference | Description             | Version | Action_1 | Action_2     | Action_3 |
            | RS1SAT1000000RPRP |                | 01/07/2024 - 31/07/2024 | 1       | Continue | Download PDF | Delete   |
        And I should see the sub-title "Outstanding balance"
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description             | Version | Balance | Status        | Action_1     | Action_2     | Action_3 | Action_4 |
            | RS10000006AAFC   |                | 21/04/2024     | 01/04/2024 - 30/04/2024 | 1       | £240.00 | Filed (Debit) | Transactions | Download PDF | Amend    | Message  |

        When I click on the "Find transactions" link
        Then I should see the "Transactions : SAT1000000RPRP Marks & Spencer Group" page
        And the checkbox "Only transactions with an outstanding balance" should be checked
        When I enter "RS10000006AAFC" in the "Reference" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Created date | Effective date | Reference      | Description             | Amount  | Balance |              |
            | 10/04/2024   | 10/04/2024     | RS10000006AAFC | Scottish Aggregates Tax | £240.00 | £240.00 | View related |

        When I click on the "Dashboard" menu item
        Then I should see the "Dashboard" page
        When I click on the 1 st "Find returns" link
        Then I should see the "Returns : SAT1000000RPRP Marks & Spencer Group" page
        When I enter "RS10000006AAFC" in the "Return reference" field
        And I select "Filed" from the "Return status"
        And I click on the "Find" button
        Then I should see the "Returns : SAT1000000RPRP Marks & Spencer Group" page
        And the table of data is displayed
            | Return reference | Submitted date | Description             | Version | Balance | Status        | Action_1     | Action_2     | Action_3 | Action_4 |
            | RS10000006AAFC   | 21/04/2024     | 01/04/2024 - 30/04/2024 | 1       | £240.00 | Filed (Debit) | Transactions | Download PDF | Amend    | Messages |

    Scenario: Checking action links are correctly shown for specific type of returns
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        # A draft return
        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page
        And I should see "Draft" in the "Return status" select or text field
        And I enter "RS100002AAAAA" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should see the text "Draft"
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        And I should see a link with text "Continue"
        And I should see a link with text "Delete"
        And I should not see a link with text "Transactions"
        And I should not see a link with text "Message"
        And I should not see a link with text "Amend"

        # A latest filed return that is over 12 months old
        When I enter "RS1008001HalO" in the "Return reference" field
        And I select "" from the "Return status"
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should see the text "Filed (Paid)"
        And I should see the text "Q1 2016"
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        And I should see a link with text "Transactions"
        And I should see a link with text "Message"
        And I should not see a link with text "Amend"
        And I should not see a link with text "Continue"
        And I should not see the text "This return is no longer amendable, use the claim option"

        # A latest filed return that is under 12 months old
        When I open the "Show more filter options" summary item
        Then I should see the "Returns" page
        And I enter "RS100001AAAAA" in the "Return reference" field
        And I select "Filed" from the "Return status"
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should see the text "Filed (Debit)"
        And I should see the text "Q1 2024"
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        And I should see a link with text "Transactions"
        And I should see a link with text "Amend"
        And I should see a link with text "Message"
        And I should not see a link with text "Continue"
        And I should not see a link with text "Delete"

    Scenario: Filtering validation
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        When I click on the 2 nd "Find returns" link
        Then I should see the "Returns" page

        When I enter "RANDOM_STRING,31" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should receive the message "Return reference is too long"

        When I enter "RANDOM_STRING,4" in the "Return reference" field
        And I open the "Show more filter options" summary item
        Then I should see the "Returns" page
        And I enter "RANDOM_STRING,256" in the "Description" field
        And I click on the "Find" button
        Then I should see the "Returns" page
        And I should receive the message "Description is too long"

    Scenario: To verify that returns created or modified by user are visible on dashboard
        # Check if the Return created by the user is visible
        Given I have signed in 'PORTAL.ONE' and password 'Password1!'
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference | Your reference          | Description            | Version | Action_1 | Action_2     | Action_3 |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 | Conveyance or transfer | 2       | Continue | Download PDF | Delete   |

        # Check if the Return modified by the user is visible
        Given I have signed in 'PORTAL.TWO' and password 'Password2!'
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference | Your reference          | Description            | Version | Action_1 | Action_2     | Action_3 |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 | Conveyance or transfer | 2       | Continue | Download PDF | Delete   |
        # Check if the Return is not visible to this user on Dashboard
        Given I have signed in 'PORTAL.THREE' and password 'Password3!'
        Then I should see the "Dashboard" page
        And the data is not displayed in table
            | Return reference | Your reference          |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 |

    Scenario: To check the filtering of returns using lbtt user
        Given I have signed in 'PORTAL.ONE' and password 'Password1!'
        Then I should see the "Dashboard" page
        And I should see the sub-title "Draft returns"
        And the table of data is displayed
            | Return reference | Your reference          | Description            | Version | Action_1 | Action_2     | Action_3 |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 | Conveyance or transfer | 2       | Continue | Download PDF | Delete   |

        When I click on the 1 st "Find returns" link
        Then I should see the "Returns" page
        And I should see "Draft" in the "Return status" select or text field
        And the checkbox "Only my returns" should be checked

        When I select "" from the "Return status"
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference          | Submitted date | Description            | Version | Balance | Status        | Action_1     | Action_2     | Action_3 | Action_4      |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 |                | Conveyance or transfer | 2       |         | Draft         | Download PDF | Continue     | Delete   |               |
            | RS2000001AAAA    | CO99999.0001            | 01/07/2024     | Conveyance or transfer | 1       | £200.00 | Filed (Debit) | Download PDF | Transactions | Message  | Draft present |

        When I select "Lease (all types)" from the "Return type"
        And I uncheck the "Only my returns" checkbox
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description | Version | Balance | Status       | Action_1     | Action_2     | Action_3 | Action_4 |
            | RS2000003BBBB    | XXXXX02-99     | 01/06/2022     | Lease       | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Claim    | Message  |
            | RS3000003EEEE    | XXXXX02-99     | 01/10/2019     | Lease       | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Claim    | Message  |

        When I click on the "Dashboard" menu item
        Then I should see the "Dashboard" page
        And I should see a link with text "Find returns"
        And I should see a link with text "Find transactions"
        When I click on the 2 nd "Find returns" link
        Then I should see the "Returns" page
        And the checkbox "Only returns with an outstanding balance" should be checked
        And the checkbox "Only my returns" should be checked

        When I select "Filed" from the "Return status"
        And I uncheck the "Only my returns" checkbox
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description            | Version | Balance | Status        | Action_1     | Action_2     | Action_3 | Action_4      |
            | RS2000001AAAA    | CO99999.0001   | 01/07/2024     | Conveyance or transfer | 1       | £200.00 | Filed (Debit) | Download PDF | Transactions | Message  | Draft present |

        When I select "Draft" from the "Return status"
        And the checkbox "Only returns with an outstanding balance" should be checked
        And I click on the "Find" button
        Then I should see the "Returns" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description | Version | Balance | Status |