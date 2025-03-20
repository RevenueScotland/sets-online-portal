# feature/financial_transactions.feature

Feature: Financial transaction
    As a registered user
    I want to be able to see my financial transaction and the related transaction with it
    So that I can view a list of transaction, view a transaction in full details with their related transactions

    Uncheck the transactions for my returns check box and Outstanding balance checkbox then search should return
    all the transactions for that account

    Change the value in the sort by dropdown and search result should be displayed as per the new sort order

    # Index page tests
    Scenario: View list of transactions
        Given I have signed in
        Then I should see the "Dashboard" page
        When I click on the "Find transactions" link
        Then I should see the "Transactions" page
        And the checkbox "Only transactions for my returns" should be checked
        And the checkbox "Only transactions with an outstanding balance" should be checked
        And I should see the empty field "Reference"
        And I should see the "Most recent" option selected in "Sort by"

        When I open the "Show more filter options" summary item
        Then I should see the "Transactions" page
        And I should see the empty field "Amount"
        And I should see the empty field "Created date"
        And I should see the empty field "Effective date"
        And I should not see the text "List of transactions"

        When I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount    | Balance |              |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00   | £100.00 | View related |
            | 10/01/2019   | 10/01/2019     | RS2000001AAAA | LBTT Residential Tax            | £1,000.00 | £100.00 | View related |

        When I uncheck the "Only transactions for my returns" checkbox
        And I uncheck the "Only transactions with an outstanding balance" checkbox
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount    | Balance |              |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00   | £100.00 | View related |
            | 11/01/2019   | 11/01/2019     |               | Cheque                          | £-900.00  | £0.00   | View related |
            | 10/01/2019   | 10/01/2019     | RS2000001AAAA | LBTT Residential Tax            | £1,000.00 | £100.00 | View related |

        When I select "Amount : Low - High" from the "Sort by"
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount    | Balance |              |
            | 11/01/2019   | 11/01/2019     |               | Cheque                          | £-900.00  | £0.00   | View related |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00   | £100.00 | View related |
            | 10/01/2019   | 10/01/2019     | RS2000001AAAA | LBTT Residential Tax            | £1,000.00 | £100.00 | View related |

    Scenario: Filter the transactions and see only the items that I want to see
        Given I have signed in
        When I click on the "Find transactions" link
        Then I should see the "Transactions" page

        When I select "Conveyance or transfer" from the "Return type"
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount    | Balance |              |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00   | £100.00 | View related |
            | 10/01/2019   | 10/01/2019     | RS2000001AAAA | LBTT Residential Tax            | £1,000.00 | £100.00 | View related |

        When I select "Penalties issued, negative values denotes cancelled penalties" from the "Transaction group"
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount  | Balance |              |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00 | £100.00 | View related |

        Given I have signed in
        When I click on the "Find transactions" link
        Then I should see the "Transactions" page

        When I open the "Show more filter options" summary item
        Then I should see the "Transactions" page
        And I enter " 1000" in the "Amount" field
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description          | Amount    | Balance |              |
            | 10/01/2019   | 10/01/2019     | RS2000001AAAA | LBTT Residential Tax | £1,000.00 | £100.00 | View related |

        Given I have signed in
        When I click on the "Find transactions" link
        Then I should see the "Transactions" page

        When I uncheck the "Only transactions for my returns" checkbox
        And I uncheck the "Only transactions with an outstanding balance" checkbox
        And I open the "Show more filter options" summary item
        Then I should see the "Transactions" page
        And I enter "-900 " in the "Amount" field
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference | Description | Amount   | Balance |              |
            | 11/01/2019   | 11/01/2019     |           | Cheque      | £-900.00 | £0.00   | View related |

        When I open the "Show more filter options" summary item
        Then I should see the "Transactions" page
        And I enter "11-01-2019" in the "Created date" date field
        And I clear the "Amount" field
        And I clear the "Amount from (min)" field
        And I clear the "Amount to (max)" field
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference | Description | Amount   | Balance |              |
            | 11/01/2019   | 11/01/2019     |           | Cheque      | £-900.00 | £0.00   | View related |

        When I open the "Show more filter options" summary item
        Then I should see the "Transactions" page
        And I clear the "Created date" field
        And I clear the "Created date to" field
        And I clear the "Created date from" field
        And I enter "01-01-2019" in the "Effective date" date field
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount  | Balance |              |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00 | £100.00 | View related |


        # View the related financial transaction of a transaction with it's details carried over
        When I click on the "Dashboard" menu item
        Then I should see the "Dashboard" page
        And I should see a link with text "Find transactions"
        When I click on the "Find transactions" link
        Then I should see the "Transactions" page

        When I select "Oldest" from the "Sort by"
        And I enter "RS2000001AAAA" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Transactions" page
        Then the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount    | Balance |              |
            | 10/01/2019   | 10/01/2019     | RS2000001AAAA | LBTT Residential Tax            | £1,000.00 | £100.00 | View related |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00   | £100.00 | View related |

        When I click on the "View related" link of the first entry displayed
        Then I should see the "Financial transaction" page
        And I should see the text "Created date"
        And I should see the text "10/01/2019"
        And I should see the text "Effective date"
        And I should see the text "10/01/2019"
        And I should see the text "Reference"
        And I should see the text "RS2000001AAAA"
        And I should see the text "Description"
        And I should see the text "LBTT Residential Tax"
        And I should see the text "Amount"
        And I should see the text "£1,000.00"
        And I should see the text "Balance"
        And I should see the text "£100.00"
        And I should see the text "Related financial transactions"
        And the table of data is displayed
            | Created date | Effective date | Description | Allocated | Original |
            |              |                |             | amount    | amount   |
            | 11/01/2019   | 11/01/2019     | Cheque      |           | £-900.00 |

    Scenario: Filtering validation
        Given I have signed in
        When I click on the "Find transactions" link
        Then I should see the "Transactions" page

        When I enter "RANDOM_STRING,31" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And I should receive the message "Reference is too long"

        When I open the "Show more filter options" summary item
        Then I should see the "Transactions" page
        When I enter "1,000" in the "Amount to (max)" field
        And I enter "1.234" in the "Amount from (min)" field
        And I enter "one thousand" in the "Amount" field
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And I should receive the message "Reference is too long"
        And I should receive the message "Amount to (max) is not a number"
        And I should receive the message "Amount from (min) must be a number to 2 decimal places"
        And I should receive the message "Amount is not a number"

        When I open the "Show more filter options" summary item
        Then I should see the "Transactions" page
        When I enter "-1000000000000000000" in the "Amount to (max)" field
        And I enter "150" in the "Amount from (min)" field
        And I enter "1234567890123456789" in the "Amount" field
        And I click on the "Find" button
        Then I should see the "Transactions" page
        And I should receive the message "Reference is too long"
        And I should receive the message "Amount to (max) must be greater than -1000000000000000000"
        And I should receive the message "Amount must be less than 1000000000000000000"

    Scenario: SAT users should only see transactions for the enrolment they have access to
        Given I have signed in "PORTAL.SAT.ONE" and password "Password1!"
        Then I should see the "Dashboard : SAT1000000TVTV Kevin Peterson Partnership" page
        And the table of data is displayed
            | Return reference | Your reference | Description             | Version |
            | RS11000000TVTV   |                | 01/07/2024 - 31/07/2024 | 1       |
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description             | Version | Balance | Status        |
            | RS10000001RPTS   |                | 25/06/2024     | 01/07/2024 - 31/07/2024 | 1       | £150.00 | Filed (Debit) |
        And I click on the "Find transactions" link
        Then I should see the "Transactions" page
        And the checkbox "Only transactions with an outstanding balance" should be checked

        When I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Effective date | Description             | Amount  | Balance |              |
            | 10/01/2024   | 10/01/2024     | RS10000002ZPTS | Scottish Aggregates Tax | £150.00 | £150.00 | View related |
            | 10/01/2024   | 10/01/2024     | RS10000001RPTS | Scottish Aggregates Tax | £150.00 | £150.00 | View related |

        When I check the "Only transactions for my returns" checkbox
        Then I click on the "Find" button
        Then I should see the "Transactions" page
        And the table of data is displayed
            | Created date | Effective date | Effective date | Description             | Amount  | Balance |              |
            | 10/01/2024   | 10/01/2024     | RS10000001RPTS | Scottish Aggregates Tax | £150.00 | £150.00 | View related |
        And I should not see the text "RS10000002ZPTS"

        When I click on the "View related" link
        Then I should see the "Financial transaction" page
        And I should see the text "Created date"
        And I should see the text "10/01/2024"
        And I should see the text "Effective date"
        And I should see the text "10/01/2024"
        And I should see the text "Reference"
        And I should see the text "RS10000001RPTS"
        And I should see the text "Description"
        And I should see the text "Scottish Aggregates Tax"
        And I should see the text "Amount"
        And I should see the text "£150.00"
        And I should see the text "Balance"
        And I should see the text "£150.00"

    Scenario: Checking for a SAT return submitted for one enrolment is not visible to the other enrolments linked to that user
        Given I have signed in "PORTAL.SAT.ONE" and password "Password1!"
        Then I should see the "Dashboard : SAT1000000TVTV Kevin Peterson Partnership" page
        And the table of data is displayed
            | Return reference | Your reference | Submitted date | Description             | Version | Balance | Status        |
            | RS11000000TVTV   |                | 25/06/2024     | 01/07/2024 - 31/07/2024 | 1       | £150.00 | Filed (Debit) |
        When I click on the "Find transactions" link
        Then I should see the "Transactions : SAT1000000TVTV Kevin Peterson Partnership" page
        When I enter "RS10000001RPTS" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Transactions : SAT1000000TVTV Kevin Peterson Partnership" page
        And the table of data is displayed
            | Created date | Effective date | Effective date | Description             | Amount  | Balance |              |
            | 10/01/2024   | 10/01/2024     | RS10000001RPTS | Scottish Aggregates Tax | £150.00 | £150.00 | View related |

        When I click on the "Sign out" menu item
        Then I should see the text "Sign in"
        When I enter "PORTAL.SAT.USERS" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the "Select your SAT registration" page
        And I check the "SAT1000000RPRP Marks & Spencer Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button

        Then I should see the "Dashboard : SAT1000000RPRP Marks & Spencer Group" page
        When I click on the "Find transactions" link
        Then I should see the "Transactions : SAT1000000RPRP Marks & Spencer Group" page
        When I enter "RS10000001RPTS" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Transactions : SAT1000000RPRP Marks & Spencer Group" page
        And I should not see the text "Continue"

        And I enter "RS10000006AAFC" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Transactions : SAT1000000RPRP Marks & Spencer Group" page
        And the table of data is displayed
            | Created date | Effective date | Effective date | Description             | Amount  | Balance |              |
            | 10/04/2024   | 10/04/2024     | RS10000006AAFC | Scottish Aggregates Tax | £240.00 | £240.00 | View related |

        When I uncheck the "Only transactions with an outstanding balance" checkbox
        And I click on the "Find" button
        Then I should see the "Transactions : SAT1000000RPRP Marks & Spencer Group" page
        And the table of data is displayed
            | Created date | Effective date | Effective date | Description             | Amount  | Balance |              |
            | 10/04/2024   | 10/04/2024     | RS10000006AAFC | Scottish Aggregates Tax | £240.00 | £240.00 | View related |

        When I click on the "Sign out" menu item
        Then I should see the text "Sign in"
        When I enter "PORTAL.SAT.USERS" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button
        Then I should see the "Select your SAT registration" page
        And I check the "SAT1000000VVVV Black Sands Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button

        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page
        When I click on the "Find transactions" link
        Then I should see the "Transactions : SAT1000000VVVV Black Sands Group" page
        When I enter "RS10000006AAFC" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Transactions : SAT1000000VVVV Black Sands Group" page
        And the table of data is displayed
            | Created date | Effective date | Effective date | Description | Amount | Balance |
        And I should not see the text "Continue"
