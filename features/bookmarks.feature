Feature: Bookmarks

    As a registered or unauthenticated user
    I want to be able to bookmark a page
    So that I can come back to the system

    If a user book marks a page part way through a wizard then they cannot go back to that page as
    they have no saved state/details. We therefore direct them to a suitable starting page rather
    than get an unexpected error. Note that in the tests you need to start a new session/scenario
    in most cases as otherwise the when then creates a stored object that means the bookmark on the
    next step goes to the page rather than get redirected

    Scenario: Registration - bookmark for first page
        When I go to the "accounts/registration/account_for" page
        Then I should see the "Sign up to file tax returns" page

    Scenario: Registration - bookmarks for second page
        When I go to the "accounts/registration/company_registered" page
        Then I should see the "Sign up to file tax returns" page

    Scenario: LBTT return - unauthenticated - bookmarks fo sub wizards
        # Agent
        When I go to the "returns/lbtt/agent_details?party_id=new" page
        Then I should see the "To complete this return, you will need the following information:" page
        When I go to the "returns/lbtt/agent_address" page
        Then I should see the "To complete this return, you will need the following information:" page
        # Buyer (also covers sellers)
        When I go to the "returns/lbtt/about_the_party/new?party_type=BUYER" page
        Then I should see the "To complete this return, you will need the following information:" page
        When I go to the "returns/lbtt/party_details" page
        Then I should see the "To complete this return, you will need the following information:" page
        # Property
        When I go to the "returns/lbtt/property_address/new" page
        Then I should see the "To complete this return, you will need the following information:" page
        When I go to the "returns/lbtt/about_the_property" page
        Then I should see the "To complete this return, you will need the following information:" page
        # Transaction
        When I go to the "returns/lbtt/property-type" page
        Then I should see the "To complete this return, you will need the following information:" page
        When I go to the "returns/lbtt/transaction-dates" page
        Then I should see the "To complete this return, you will need the following information:" page
        # Calculation
        When I go to the "returns/lbtt/calculation" page
        Then I should see the "To complete this return, you will need the following information:" page
        When I go to the "returns/lbtt/transaction-dates" page
        Then I should see the "To complete this return, you will need the following information:" page

    Scenario: LBTT return - authenticated - bookmarks fo sub wizards
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        # Agent
        When I go to the "returns/lbtt/agent_details?party_id=new" page
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/agent_address" page
        Then I should see the "Dashboard" page
        # Buyer (also covers sellers)
        When I go to the "returns/lbtt/about_the_party/new?party_type=BUYER" page
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/party_details" page
        Then I should see the "Dashboard" page
        # Property
        When I go to the "returns/lbtt/property_address/new" page
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/about_the_property" page
        Then I should see the "Dashboard" page
        # Transaction
        When I go to the "returns/lbtt/property-type" page
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/transaction-dates" page
        Then I should see the "Dashboard" page
        # Calculation
        When I go to the "returns/lbtt/calculation" page
        Then I should see the "Dashboard" page
        When I go to the "returns/lbtt/transaction-dates" page
        Then I should see the "Dashboard" page

    Scenario: SLFT return - bookmark to period sub wizard first page
        Given I have signed in "portal.waste.new" and password "Password1!"
        When I go to the "returns/slft/transaction_period" page
        Then I should see the "Return summary" page

    Scenario: SLFT return - bookmark to period sub wizard second page
        Given I have signed in "portal.waste.new" and password "Password1!"
        When I go to the "returns/slft/transaction_new_non_disposal" page
        Then I should see the "Return summary" page

    Scenario: SLFT return - bookmarks to sites
        Given I have signed in "portal.waste.new" and password "Password1!"
        # Period
        When I go to the "returns/slft/site_waste_summary/97" page
        Then I should see the "Return summary" page
        When I go to the "returns/slft/waste_description/new" page
        Then I should see the "Return summary" page
        When I go to the "returns/slft/waste_tonnage" page
        Then I should see the "Return summary" page

    Scenario: SLFT return - bookmark to first credit page
        Given I have signed in "portal.waste.new" and password "Password1!"
        When I go to the "returns/slft/credit_environmental" page
        Then I should see the "Return summary" page

    Scenario: SLFT return - bookmark to second credit page
        Given I have signed in "portal.waste.new" and password "Password1!"
        When I go to the "returns/slft/credit_bad_debt" page
        Then I should see the "Return summary" page

    Scenario: Repayment Request - bookmark to first page
        When I go to the "claim/claim_payments/return_reference_number" page
        Then I should see the "Claim a repayment of Additional Dwelling Supplement" page

    Scenario: Repayment Request - bookmark to second page
        When I go to the "applications/slft/application_type" page
        Then I should see the "Online SLfT application form" page
