# feature/errorss.feature

Feature: Errors
    As a user
    If something goes wrong
    I want to see an error page

    # Do not remove @wip as puts ERROR in log file which Jenkins will recognise as a test failure.
    # Helpful for error page development though.  DO NOT COMMIT WITH @wip removed or commented out!
    @wip
    @mock_lbtt_serious_back_office_error
    Scenario: Serious error page
        Given I have signed in "VALID.USER" and password "valid.password"
        Then I should see the "Dashboard" page
        When I go to the "dashboard/dashboard_returns/251-1-LBTT-RS/load" page
        Then I should see the "Something has gone wrong" page
        And I should see the text "%r{To report this error quote : \d\d\d\d\d}"