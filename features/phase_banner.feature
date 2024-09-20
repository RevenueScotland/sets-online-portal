# features/phase_banner.feature

Feature: Phase banner
  As a user
  I want to be able to provide feedback regardless of the screen I am on or if I am logged in or not
  So that I can offer my improvements to revenue scotland

  Scenario: the phase banner is shown on the landing pages
    When I go to the "returns/lbtt/public_landing" page
    Then I should see the "To complete this return, you will need the following information:" page
    And I should see a phase banner with the text "Give feedback (opens in a new window) about this service" and a link to "feedback (opens in a new window)"

    When I go to the "claim/claim_payments/public_claim_landing" page
    Then I should see the "Claim a repayment of Additional Dwelling Supplement" page
    And I should see a phase banner with the text "Give feedback (opens in a new window) about this service" and a link to "feedback (opens in a new window)"

    When I go to the "applications/slft/public_landing" page
    Then I should see the "Online SLfT application form" page
    And I should see a phase banner with the text "Give feedback (opens in a new window) about this service" and a link to "feedback (opens in a new window)"

    When I go to the "login" page
    Then I should see the "Sign in" page
    And I should see a phase banner with the text "Give feedback (opens in a new window) about this service" and a link to "feedback (opens in a new window)"

    And I have signed in "PORTAL.NEW.USERS" and password "Password1!"
    Then I should see the "Dashboard" page
    And I should see a phase banner with the text "Give feedback (opens in a new window) about this service" and a link to "feedback (opens in a new window)"
    When I click on the "Find messages" link
    Then I should see the "Messages" page
    And I should see a phase banner with the text "Give feedback (opens in a new window) about this service" and a link to "feedback (opens in a new window)"
    And I click on the "Sign out" menu item

    Then I should see the "Sign in" page
    And I have signed in "portal.waste.new" and password "Password1!"
    And I click on the "Create SLfT return" menu item
    And I should see the "Return summary" page
    And I should see a phase banner with the text "Give feedback (opens in a new window) about this service" and a link to "feedback (opens in a new window)"
    And I click on the "Cancel" menu item
