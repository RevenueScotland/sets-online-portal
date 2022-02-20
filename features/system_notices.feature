# features/system_notices.feature

Feature: System Notices
    As a user
    I want to see messages from the admininistrators
    So that I know when the system may be down or other important information

    Scenario: Check if notification banner is available on the login page
        When I go to the "Login" page
        Then I should receive the message "All - This is a test notice. More information"
        And I should receive the message "Portal- This is a test notice. More information"
        And I should not receive the message "All - This is a test notice with expired date"
        And I should not receive the message "All - This is a test notice with complete indicator is Y"

    Scenario: Check if notification banner is available on the claim payment page
        When I go to the "claim/claim_payments/public_claim_landing" page
        Then I should see the "Claim a repayment of Additional Dwelling Supplement" page

        And I should receive the message "Repayment Request - This is a test notice without a URL"
        And I should receive the message "All - This is a test notice. More information"
        And I should not receive the message "All - This is a test notice with expired date"
        And I should not receive the message "All - This is a test notice with complete indicator is Y"

    Scenario: Check if notification banner is available on the lease review page
        When I go to the "returns/lbtt/public_landing" page
        Then I should see the "To complete this return, you will need the following information" page

        And I should receive the message "LBTT Lease Review - This is a test notice with a full stop and a space. More information"
        And I should receive the message "All - This is a test notice. More information"
        And I should not receive the message "All - This is a test notice with expired date"
        And I should not receive the message "All - This is a test notice with complete indicator is Y"

    Scenario: Check if notification banner is available on th SLFT applications page
        When I go to the "applications/slft/public_landing" page
        Then I should see the "Online SLfT application form" page

        And I should receive the message "SLFT application - This is a test notice with a full stop. More information"
        And I should receive the message "All - This is a test notice. More information"
        And I should not receive the message "All - This is a test notice with expired date"
        And I should not receive the message "All - This is a test notice with complete indicator is Y"

