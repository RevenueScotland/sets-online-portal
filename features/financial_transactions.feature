# feature/financial_transactions.feature

Feature: Financial transaction
    As a registered user
    I want to be able to see my financial transaction and the related transaction with it
    So that I can view a list of transaction, view a transaction in full details with their related transactions

    # Index page tests
    Scenario: View list of all transactions
        Given I have signed in
        Then I should see the "Dashboard" page
        When I click on the "See all transactions" link
        Then I should see the "All transactions" page
        And I should see the empty field "Reference"

        When I open the "Show more filter options" summary item
        Then I should see the empty field "Amount"
        And I should see the empty field "Created date"
        And I should see the empty field "Effective date"
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount    | Balance |              |
            | 11/01/2019   | 11/01/2019     |               | Cheque                          | £-900.00  | £0.00   | View related |
            | 10/01/2019   | 10/01/2019     | RS2000001AAAA | LBTT Residential Tax            | £1,000.00 | £100.00 | View related |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00   | £100.00 | View related |

    Scenario: Filter the transactions and see only the items that I want to see
        Given I have signed in
        When I click on the "See all transactions" link
        Then I should see the "All transactions" page

        When I open the "Show more filter options" summary item
        And I enter " 1000" in the "Amount" field
        And I click on the "Find" button
        Then I should see the "All transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description          | Amount    | Balance |              |
            | 10/01/2019   | 10/01/2019     | RS2000001AAAA | LBTT Residential Tax | £1,000.00 | £100.00 | View related |

        Given I have signed in
        When I click on the "See all transactions" link
        Then I should see the "All transactions" page

        When I open the "Show more filter options" summary item
        And I enter "-900 " in the "Amount" field
        And I click on the "Find" button
        Then I should see the "All transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference | Description | Amount   | Balance |              |
            | 11/01/2019   | 11/01/2019     |           | Cheque      | £-900.00 | £0.00   | View related |

        When I open the "Show more filter options" summary item
        And I enter "11-01-2019" in the "Created date" date field
        And I clear the "Amount" field
        And I clear the "Amount from (min)" field
        And I clear the "Amount to (max)" field
        And I click on the "Find" button
        Then I should see the "All transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference | Description | Amount   | Balance |              |
            | 11/01/2019   | 11/01/2019     |           | Cheque      | £-900.00 | £0.00   | View related |

        When I open the "Show more filter options" summary item
        And I clear the "Created date" field
        And I clear the "Created date to" field
        And I clear the "Created date from" field
        And I enter "01-01-2019" in the "Effective date" date field
        And I click on the "Find" button
        Then I should see the "All transactions" page
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount  | Balance |              |
            | 01/01/2019   | 01/01/2019     | RS2000001AAAA | LBTT 1st Failure to Make Return | £100.00 | £100.00 | View related |


        # View the related financial transaction of a transaction with it's details carried over
        When I click on the "Dashboard" menu item
        Then I should see the "Dashboard" page
        And I should see a link with text "See all transactions"
        When I click on the "See all transactions" link
        Then I should see the "All transactions" page

        When I enter "RS2000001AAAA" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "All transactions" page
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
        When I click on the "See all transactions" link
        Then I should see the "All transactions" page

        When I enter "RANDOM_STRING,31" in the "Reference" field
        And I click on the "Find" button
        Then I should receive the message "Reference is too long"

        When I open the "Show more filter options" summary item
        When I enter "1,000" in the "Amount to (max)" field
        And I enter "1.234" in the "Amount from (min)" field
        And I enter "one thousand" in the "Amount" field
        And I click on the "Find" button
        Then I should receive the message "Reference is too long"
        And I should receive the message "Amount to (max) is not a number"
        And I should receive the message "Amount from (min) must be a number to 2 decimal places"
        And I should receive the message "Amount is not a number"

        When I open the "Show more filter options" summary item
        When I enter "-1000000000000000000" in the "Amount to (max)" field
        And I enter "150" in the "Amount from (min)" field
        And I enter "1234567890123456789" in the "Amount" field
        And I click on the "Find" button
        Then I should receive the message "Reference is too long"
        And I should receive the message "Amount to (max) must be greater than -1000000000000000000"
        And I should receive the message "Amount must be less than 1000000000000000000"

