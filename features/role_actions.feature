# features/role_actions.feature

Feature: Roles and Actions
  As a user
  I only want access to the pages and links that I'm permitted to use

  # Note: You must check access to the actual page as well as the link being present
  # as users can by pass the link and use the URL directly. We don't need actual data as they
  # authorisation should kick in before they data is processed
  Scenario: Has not got access to anything
    Given I have signed in "portal.no.access" and password "Password1!"
    Then I should see the "Dashboard" page
    When I click on the "Account details" link

    Then I should see the "Sign up details" page
    And I should not see a link with text "Update"
    And I should not see a link with text "Create or update users"
    When I go to the "account/edit-basic" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "account/edit-address" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "dashboard" page
    Then I should not see the button with text "Create new message"
    And I should not see the button with text "Create LBTT return"
    And I should not see the button with text "Create SLfT return"
    And I should not see a link with text "Continue"
    And I should not see a link with text "Download PDF"
    And I should not see a link with text "Delete"

    When I go to the "dashboard/messages/new" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "returns/lbtt/summary" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "returns/slft/summary" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "dashboard/dashboard_returns/1-1-LBTT-RS/load" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "dashboard/dashboard_returns/1-1-SLFT-RS/load" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "dashboard/dashboard_returns/1-1-LBTT-RS/download-pdf" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "dashboard/dashboard_returns/1-1-LBTT-RS/download-receipt" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "claim/claim_payments/claim_reason?new=true&reference=RS&srv_code=LBTT&tare_refno=1&version=1" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "returns/lbtt/save_draft" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "returns/slft/save_draft" page
    Then I should see the text "You are not authorised to view this page"

    When I go to the "claim/claim_payments/claim_reason" page
    Then I should see the text "You are not authorised to view this page"

  Scenario: Has limited access to some actions
    Given I have signed in "PORTAL.NO.ACCESS" and password "Password1!"
    Then I should see the "Dashboard" page
    And I should not see a link with text "Continue"
    Then I should not see a link with text "Delete"
    When I click on the "All returns" link
    Then I should not see a link with text "Continue"
    Then I should not see a link with text "Delete"
    Then I should not see a link with text "Claim"

  Scenario: Read only access to messages
    Given I have signed in "PORTAL.NO.ACCESS" and password "Password1!"
    When I click on the "All messages" link
    Then I should see the "Messages" page
    And I click on the 1 st "View" link
    Then I should see the "Message full details" page
    And I should not see the button with text "Reply"
    When I go to the "dashboard/messages/new" page
    Then I should see the text "You are not authorised to view this page"
