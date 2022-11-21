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
            | RS1008003OKAY    | Q3 2019     | 3       | Download PDF | Download waste details | Delete                 | Ongoing Enquiry |
            | RS1008002WAUW    | Q4 2019     | 1       | Continue     | Download PDF           | Download waste details | Delete          |
            | RS100002AAAAA    | Q2 2022     | 1       | Continue     | Download PDF           | Download waste details | Delete          |
        And I should see the sub-title "Outstanding balance"
        And the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance  | Status        | Action_1     | Action_2     | Action_3               | Action_4 | Action_5 |
            | RS100001AAAAA    | 01/07/2022     | Q1 2022     | 2       | £1000.00 | Filed (Debit) | Transactions | Download PDF | Download waste details | Amend    | Message  |
        # Check old version of the return is not shown
        And I should not see the text "Q1 2018"
        And I should not see the text "19/06/2022"

        When I click on the "All returns" link
        Then I should see the "All returns" page
        And the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance  | Status        | Action_1     | Action_2               | Action_3     | Action_4        | Action_5        |
            | RS1008003OKAY    |                | Q3 2019     | 3       | £0.00    | Draft         | Download PDF | Download waste details | Delete       | Ongoing Enquiry |                 |
            | RS1008002WAUW    |                | Q4 2019     | 1       | £0.00    | Draft         | Download PDF | Download waste details | Continue     | Delete          |                 |
            | RS100002AAAAA    |                | Q2 2022     | 1       | £0.00    | Draft         | Download PDF | Download waste details | Continue     | Delete          |                 |
            | RS1008003OKAY    | 01/07/2022     | Q3 2019     | 2       | £0.00    | Filed (Paid)  | Download PDF | Download waste details | Transactions | Message         | Ongoing Enquiry |
            | RS1008001HALO    | 01/07/2022     | Q1 2016     | 2       | £0.00    | Filed (Paid)  | Download PDF | Download waste details | Transactions | Claim           | Message         |
            | RS100001AAAAA    | 01/07/2022     | Q1 2022     | 2       | £1000.00 | Filed (Debit) | Download PDF | Download waste details | Transactions | Amend           | Message         |
            | RS1008004HMMM    | 19/06/2022     | Q2 2019     | 1       | £0.00    | Filed (Paid)  | Download PDF | Download waste details | Transactions | Amend           | Message         |
        And I should not see the text "Q1 2018"

    # Index page tests
    Scenario: Check draft stops amend link being shown
        Given I have signed in
        Then I should see the "Dashboard" page
        And the table of data is displayed
            | Return reference | Your reference          | Description            | Version | Action_1 | Action_2     | Action_3 |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 | Conveyance or transfer | 2       | Continue | Download PDF | Delete   |
        And I should not see a link with text "Download waste details"

        When I click on the "All returns" link
        Then I should see the "All returns" page
        And the table of data is displayed
            # Note we only use partial references in those with \ as the code inserts a zero width space to allow breaking
            | Return reference | Your reference          | Submitted date | Description            | Version | Balance | Status        | Action_1     | Action_2     | Action_3 | Action_4      |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 |                | Conveyance or transfer | 2       | £0.00   | Draft         | Download PDF | Continue     | Delete   |               |
            | RS3000004DDDD    | ABcC                    | 01/07/2022     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Amend    | Message       |
            | RS2000004DDDD    | ABcC                    | 01/07/2022     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Amend    | Message       |
            | RS2000001AAAA    | CO99999.0001            | 01/07/2022     | Conveyance or transfer | 1       | £200.00 | Filed (Debit) | Download PDF | Transactions | Message  | Draft Present |
            | RS3000003EEEE    | XXXXX02-99              | 01/10/2019     | Lease                  | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
            | RS2000003BBBB    | XXXXX02-99              | 01/06/2020     | Lease                  | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
            | RS3000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
            | RS2000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid)  | Download PDF | Transactions | Claim    | Message       |
        And I should not see a link with text "Download waste details"
        When I enter "b" in the "Your reference" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Your reference          | Submitted date | Description            | Version | Balance | Status       | Action_1     | Action_2     | Action_3 | Action_4 |
            | RS2000001AAAA    | AAAA BB DDDDFFFF 9999.2 |                | Conveyance or transfer | 2       | £0.00   | Draft        | Download PDF | Continue     | Delete   |          |
            | RS3000004DDDD    | ABcC                    | 01/07/2022     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Amend    | Message  |
            | RS2000004DDDD    | ABcC                    | 01/07/2022     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Amend    | Message  |
            | RS3000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Claim    | Message  |
            | RS2000002AAAA    | ABcC                    | 01/07/2017     | Conveyance or transfer | 1       | £0.00   | Filed (Paid) | Download PDF | Transactions | Claim    | Message  |

    Scenario: Filter data to list down all that's needed to be seen
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        When I click on the "All returns" link
        Then I should see the "All returns" page
        And I open the "Show more filter options" summary item
        When I enter "09-01-2099" in the "Submitted from date" date field
        And I click on the "Find" button
        Then I should see the text "There are no returns to be shown..."

        When I open the "Show more filter options" summary item
        And I clear the "Submitted from date" field
        And I select "Draft" from the "Return status"
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance | Status | Action_1     | Action_2               | Action_3 | Action_4        | Action_5 |
            | RS1008003OKAY    |                | Q3 2019     | 3       | £0.00   | Draft  | Download PDF | Download waste details | Delete   | Ongoing Enquiry |          |
            | RS1008002WAUW    |                | Q4 2019     | 1       | £0.00   | Draft  | Download PDF | Download waste details | Continue | Delete          |          |
            | RS100002AAAAA    |                | Q2 2022     | 1       | £0.00   | Draft  | Download PDF | Download waste details | Continue | Delete          |          |

        When I click on the "Dashboard" link
        Then I should see the "Dashboard" page
        When I click on the "All returns" link
        Then I should see the "All returns" page
        When I enter "RS1008003OKAY" in the "Return reference" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance | Status       | Action_1     | Action_2               | Action_3     | Action_4        | Action_5        |
            | RS1008003OKAY    |                | Q3 2019     | 3       | £0.00   | Draft        | Download PDF | Download waste details | Delete       | Ongoing Enquiry |                 |
            | RS1008003OKAY    | 01/07/2022     | Q3 2019     | 2       | £0.00   | Filed (Paid) | Download PDF | Download waste details | Transactions | Message         | Ongoing Enquiry |
        And I should see the text "1-2"

        When I open the "Show more filter options" summary item
        And I check the "Include previous versions" checkbox
        And I enter "RS1008003Okay" in the "Return reference" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Submitted date | Description | Version | Balance | Status       | Action_1     | Action_2               | Action_3        | Action_4        | Action_5        |
            | RS1008003OKAY    |                | Q3 2019     | 3       | £0.00   | Draft        | Download PDF | Download waste details | Delete          | Ongoing Enquiry |                 |
            | RS1008003OKAY    | 01/07/2022     | Q3 2019     | 2       | £0.00   | Filed (Paid) | Download PDF | Download waste details | Transactions    | Message         | Ongoing Enquiry |
            | RS1008003OKAY    | 19/06/2022     | Q3 2019     | 1       | £0.00   | Filed (Paid) | Download PDF | Download waste details | Ongoing Enquiry |                 |                 |

        When I open the "Show more filter options" summary item
        And I enter "20191111-01-09" in the "Submitted from date" field
        And I click on the "Find" button
        Then I should see the text "Submitted from date is invalid"

    Scenario: Checking access
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        Then I should see the text "Create SLfT return"
        And I should not see the text "Create LBTT return"
        When I click on the "Sign out" link

        Then I should see the text "Sign in"
        And I have signed in
        Then I should see the text "Create LBTT return"
        And I should not see the text "Create SLfT return"

    Scenario: Checking action links are correctly shown for specific type of returns
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        # A draft return
        When I click on the "All returns" link
        And I enter "RS100002AAAAA" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Draft"
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        And I should see a link with text "Continue"
        And I should see a link with text "Delete"
        And I should not see a link with text "Transactions"
        And I should not see a link with text "Message"
        And I should not see a link with text "Amend"

        # A latest filed return that is over 12 months old
        When I enter "RS1008001HalO" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed (Paid)"
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
        And I enter "RS100001AAAAA" in the "Return reference" field
        And I select "Filed" from the "Return status"
        And I click on the "Find" button
        Then I should see the text "Filed (Debit)"
        And I should see the text "Q1 2022"
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        And I should see a link with text "Transactions"
        And I should see a link with text "Amend"
        And I should see a link with text "Message"
        And I should not see a link with text "Continue"
        And I should not see a link with text "Delete"

        # An old version of a filed return
        When I open the "Show more filter options" summary item
        And I enter "19-06-2022" in the "Submitted from date" date field
        And I enter "19-06-2022" in the "Submitted to date" date field
        And I check the "Include previous versions" checkbox
        And I click on the "Find" button
        Then I should see the text "Filed (Debit)"
        And I should see a link with text "Download PDF"
        And I should see a link with text "Download waste details"
        And I should not see a link with text "Transactions"
        And I should not see a link with text "Amend"
        And I should not see a link with text "Message"
        And I should not see a link with text "Continue"

    Scenario: Filtering validation
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        When I click on the "All returns" link
        Then I should see the "All returns" page

        When I enter "RANDOM_STRING,31" in the "Return reference" field
        And I click on the "Find" button
        Then I should receive the message "Return reference is too long"

        When I open the "Show more filter options" summary item
        And I enter "RANDOM_STRING,256" in the "Description" field
        And I click on the "Find" button
        Then I should receive the message "Description is too long"
