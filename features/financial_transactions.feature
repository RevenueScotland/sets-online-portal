# feature/financial_transactions.feature

Feature: Financial transaction
    As a registered user
    I want to be able to see my financial transaction and the related transaction with it
    So that I can view a list of transaction, view a transaction in full details with their related transactions

    # Index page tests
    Scenario: View list of all transactions
        Given I have signed in
        Then I should see the "Dashboard" page
        When I click on the "All transactions" link
        Then I should see the "All transactions" page
        And I should see the text "Filter transactions by:"
        And I should see the empty field "Reference"

        When I click on the "Show more filter options" text
        Then I should see the empty field "Amount"
        And I should see the empty field "Created date"
        And I should see the empty field "Effective date"
        And the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount   | Balance |              |
            | 10/01/2019   | 10/01/2019     | RS200001AAAAA | LBTT Residential Tax            | £1000.00 | £100.00 | View related |
            | 11/01/2019   | 11/01/2019     |               | Cheque                          | £-900.00 | £0.00   | View related |
            | 01/01/2019   | 01/01/2019     | RS200001AAAAA | LBTT 1st Failure to Make Return | £100.00  | £100.00 | View related |

    Scenario: Filter the transactions and see only the items that I want to see
        Given I have signed in
        When I click on the "All transactions" link
        Then I should see the "All transactions" page

        When I click on the "Show more filter options" text
        And I enter "1000" in the "Amount" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Created date | Effective date | Reference     | Description          | Amount   | Balance |              |
            | 10/01/2019   | 10/01/2019     | RS200001AAAAA | LBTT Residential Tax | £1000.00 | £100.00 | View related |
        # And I should see the empty field "Created date"

        When I enter "2019-01-11" in the "Created date" field
        And I enter "" in the "Amount" field
        And I enter "" in the "Amount from (min)" field
        And I enter "" in the "Amount to (max)" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Created date | Effective date | Reference | Description | Amount   | Balance |              |
            | 11/01/2019   | 11/01/2019     |           | Cheque      | £-900.00 | £0.00   | View related |

        And I should see the "All transactions" page

        And I enter "" in the "Created date" field
        And I enter "" in the "Created date to" field
        And I enter "" in the "Created date from" field
        And I enter "2019-01-01" in the "Effective date" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Created date | Effective date | Reference     | Description                     | Amount  | Balance |              |
            | 01/01/2019   | 01/01/2019     | RS200001AAAAA | LBTT 1st Failure to Make Return | £100.00 | £100.00 | View related |


        # View the related financial transaction of a transaction with it's details carried over
        When I click on the "Dashboard" link
        And I click on the "All transactions" link
        Then I should see the "All transactions" page
        When I enter "RS200001AAAAA" in the "Reference" field
        And I click on the "Find" button
        And I click on the "View related" link of the first entry displayed
        Then I should see the "Financial transaction" page


        And I should see the text "Created date"
        And I should see the text "10/01/2019"

        And I should see the text "Effective date"
        And I should see the text "10/01/2019"

        And I should see the text "Reference"
        And I should see the text "RS200001AAAAA"

        And I should see the text "Description"
        And I should see the text "LBTT Residential Tax"

        And I should see the text "Amount"
        And I should see the text "1000.00"

        And I should see the text "Balance"
        And I should see the text "100.00"

        And I should see the text "Related financial transactions"
        And the table of data is displayed
            | Created date | Effective date | Description | Allocated amount | Original amount |
            | 11/01/2019   | 11/01/2019     | Cheque      | £0.00            | £-900.00        |

    Scenario: Filtering validation
        Given I have signed in
        When I click on the "All transactions" link
        Then I should see the "All transactions" page

        When I enter "RANDOM_STRING,31" in the "Reference" field
        And I click on the "Find" button
        Then I should receive the message "Reference is too long"

        When I click on the "Show more filter options" text
        When I enter "RANDOM_STRING,31" in the "Amount to (max)" field
        And I click on the "Find" button
        Then I should receive the message "Amount to (max) is invalid"
        Then I should receive the message "Amount to (max) is too long (maximum is 20 characters)"
