# feature/messages.feature

Feature: Dashboard All Returns
    As a registered user
    I want to be able to see all of my returns from Dashboard
    So that I can view a list of returns, ammend, view and download it as pdf

    # Index page tests
    Scenario: View list of all returns
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        Then I should see the "Dashboard" page

        When I click on the "All returns" link
        Then I should see the "All returns" page
        And the table of data is displayed
            | Return reference | Submitted date | Description | Version | Return status |          |          |
            | RS100001AAAAA    | 03/07/2019     | Q1 2019     | 2       | Filed         | Download | Amend    |
            | RS100002AAAAA    |                | Q2 2019     | 1       | Draft         | Continue | Download |
            | RS1008001HALO    | 03/07/2019     | Q1 2016     | 2       | Filed         | Download | Amend    |
            | RS1008002WAUW    |                | Q4 2019     | 1       | Draft         | Continue | Download |
            | RS1008003OKAY    |                | Q3 2018     | 3       | Draft         | Continue | Download |
            | RS1008003OKAY    | 03/07/2019     | Q3 2018     | 2       | Filed         | Download | Amend    |
            | RS1008004HMMM    | 03/07/2019     | Q2 2019     | 1       | Filed         | Download | Amend    |

    Scenario: Filter data to list down all that's needed to be seen
        Given I have signed in 'PORTAL.WASTE' and password 'Password1!'
        When I click on the "All returns" link
        Then I should see the "All returns" page
        When I enter "2019-01-09" in the "Submitted date" field
        And I click on the "Find" button
        Then I should see the text "There are no returns to be shown..."

        When I enter "" in the "Submitted date" field
        And I click on the "Show more filter options" text
        And I select "Draft" from the "Return status"
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Submitted date | Description | Version | Return status |          |          |
            | RS100002AAAAA    |                | Q2 2019     | 1       | Draft         | Continue | Download |
            | RS1008002WAUW    |                | Q4 2019     | 1       | Draft         | Continue | Download |
            | RS1008003OKAY    |                | Q3 2018     | 3       | Draft         | Continue | Download |

        When I click on the "Dashboard" link
        And I click on the "All returns" link
        And I click on the "Show more filter options" text
        And I check the "Include previous versions" checkbox
        And I enter "RS1008003Okay" in the "Return reference" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Return reference | Submitted date | Description | Version | Return status |          |          |
            | RS1008003OKAY    | 03/07/2019     | Q3 2018     | 3       | Draft         | Continue | Download |
            | RS1008003OKAY    | 03/07/2019     | Q3 2018     | 2       | Filed         | Download | Amend    |
            | RS1008003OKAY    | 03/07/2019     | Q3 2018     | 1       | Filed         | Download | Amend    |

        When I enter "20191111-01-09" in the "Submitted date" field
        And I click on the "Find" button
        Then I should see the text "This is invalid"

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
        And I should see a link with text "Download"
        And I should see a link with text "Continue"
        And I should not see a link with text "Transactions"
        And I should not see a link with text "Message"
        And I should not see a link with text "Amend"

        # A latest filed return that is over 12 months old
        When I enter "RS1008001HalO" in the "Return reference" field
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see the text "Q1 2016"
        And I should see a link with text "Download"
        And I should see a link with text "Transactions"
        And I should see a link with text "Message"
        And I should not see a link with text "Amend"
        And I should not see a link with text "Continue"

        # A latest filed return that is under 12 months old
        When I click on the "Show more filter options" text
        And I enter "RS1008003Okay" in the "Return reference" field
        And I select "Filed" from the "Return status"
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see the text "Q3 2018"
        And I should see a link with text "Download"
        And I should see a link with text "Transactions"
        And I should see a link with text "Amend"
        And I should see a link with text "Message"
        And I should not see a link with text "Continue"

        # An old version of a filed return
        When I enter "2019-07-01" in the "Submitted date" field
        And I check the "Include previous versions" checkbox
        And I click on the "Find" button
        Then I should see the text "Filed"
        And I should see a link with text "Download"
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

        When I click on the "Show more filter options" text
        And I enter "RANDOM_STRING,256" in the "Description" field
        And I click on the "Find" button
        Then I should receive the message "Description is too long"
