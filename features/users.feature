# feature/users.feature

Feature: User Maintenance
    As a registered user
    I want to be able to maintain users on my account
    So that I can delegate my work

    Scenario: View list of users and check new user link
        Given I have signed in
        When I go to the "Account" page
        And I click on the "Create or update users" link
        Then I should see the "Account users" page
        When I filter on "Portal User One"
        And the table of data is displayed
            | Username   | Current | Name            | Email address           | Phone number |
            | PORTAL.ONE | Y       | Portal User One | noreply@northgateps.com |              |
        When I click on the "Create a new user for your account" link
        Then I should see the "New User" page

    Scenario: Check validation on create new user page
        Given I have signed in
        When I go to the "Users/New" page
        # user does not provide any data, check validation
        And I click on the "Create User" button
        #Then I should receive the message "Username can't be blank"
        And I should receive the message "Username is too short (minimum is 5 characters)"
        And I should receive the message "First name can't be blank"
        And I should receive the message "Last name can't be blank"
        And I should receive the message "Email address can't be blank"
        And I should receive the message "Password can't be blank"
        # entering invalid username, check validation
        When I enter "test" in the "Username" field
        And I click on the "Create User" button
        And I should receive the message "Username is too short (minimum is 5 characters)"
        # checking Phone number format
        When I enter "1234" in the "Phone number" field
        And I click on the "Create User" button
        And I should receive the message "Phone number is invalid"
        # entering invalid password, check validation
        When I enter "B1I6<12A65@AG0BHA:H?AA34??36I7C725;11?=;G1329B@11HG?8<8?I8B@21FEG>FDHH=FB664B;;27C@7706E8?H48E?6@<;ED2@<9@3D4:DHI>6>::E<HF1;?8II>:C=G78B:;:7FH5@D@>BA>699B0<28?HDG1F<=<90=FA==A<:9H:>58:55:<57CF@>@70;43<FA0611=8>" in the "Password" field
        And I click on the "Create User" button
        And I should receive the message "Password is too long (maximum is 200 characters)"
        # too long password
        When I enter "test123" in the "Password" field
        And I click on the "Create User" button
        # entering different email address and confirm email address
        When I enter "a@a.com" in the "Email address" field
        And I enter "b@b.com" in the "Confirm email address" field
        And I click on the "Create User" button
        Then I should receive the message "Email address does not match"
        # entering different email address and confirm email address
        When I enter "Password001" in the "Password" field
        And I enter "Password002" in the "Confirm password" field
        And I click on the "Create User" button
        Then I should receive the message "Password does not match"

    Scenario: Creating a new user
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I go to the "Account" page
        And I click on the "Create or update users" link
        And I click on the "Create a new user for your account" link
        Then I should see the "New User" page
        When I enter "RANDOM_USERNAME,10,UPCASE" in the "Username" field
        And I check the "Current" radio button
        And I enter "New User" in the "First name" field
        And I enter "RANDOM_SURNAME,10,UPCASE" in the "Last name" field
        And I enter "noreply@northgateps.com" in the "Email address" field
        And I enter "noreply@northgateps.com" in the "Confirm email address" field
        And I enter "0123456789" in the "Phone number" field
        And I enter "Testuser123!" in the "Password" field
        And I enter "Testuser123!" in the "Confirm password" field
        And I click on the "Create User" button
        Then I should see the "Account users" page
        When I filter on "RANDOM_SURNAME"
        And the table of data is displayed
            | Username        | Current | Name           | Email address           | Phone number |
            | RANDOM_USERNAME | Y       | RANDOM_SURNAME | noreply@northgateps.com | 0123456789   |

    Scenario: Filtering user based on full name and user is current user or not
        Given I have signed in
        When I go to the "Account" page
        And I click on the "Create or update users" link
        Then I should see the "Account users" page
        And the table of data is displayed
            | Username           | Current | Name                    | Email address           | Phone number |
            | PORTAL.ONE         | Y       | Portal User One         | noreply@northgateps.com |              |
            | PORTAL.TWO         | Y       | Portal User Two         | noreply@northgateps.com |              |
            | PORTAL.NON.CURRENT | N       | Portal User Non Current | noreply@northgateps.com |              |

        # incorrect name
        When I enter "Invalid user" in the "Name" field
        And I click on the "Find" button
        Then the data is not displayed in table
            | Username     | Name                |
            | Invalid user | Portal Invalid user |

        # correct full name and nothing selected from drop down
        When I enter "Portal User Two" in the "Name" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Username   | Current | Name            | Email address           | Phone number |
            | PORTAL.TWO | Y       | Portal User Two | noreply@northgateps.com |              |

        # select user is current or not from dropdown without entering full name
        When I select "No" from the "Current"
        And I enter " " in the "Name" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Username           | Current | Name                    | Email address           | Phone number |
            | PORTAL.NON.CURRENT | N       | Portal User Non Current | noreply@northgateps.com |              |

        # select both filter name and current dropdown
        When I enter "Portal User One" in the "Name" field
        And I select "Yes" from the "Current"
        And I click on the "Find" button
        Then the table of data is displayed
            | Username   | Current | Name            | Email address           | Phone number |
            | PORTAL.ONE | Y       | Portal User One | noreply@northgateps.com |              |

    Scenario: Updating a user without password
        Given I have signed in
        When I go to the "Account" page
        And I click on the "Create or update users" link
        And I filter on "Portal User Change Details"
        And I click on the "Edit row" link
        Then I should see the "Update User" page
        # select update user without entering remaining details
        When I enter " " in the "Confirm email address" field
        And I click on the "Update User" button
        Then I should receive the message "Email address does not match"
        # enter valid data and update the user details
        When I enter "Portal User1" in the "First name" field
        When I enter "Change Details1" in the "Last name" field
        When I enter "noreply@northgateps.com" in the "Confirm email address" field
        #again filter to check updated details
        When I click on the "Update User" button
        Then I should see the "Account users" page
        And I filter on "Portal User1 Change Details1"
        Then the table of data is displayed
            | Username              | Current | Name                         | Email address           | Phone number |
            | PORTAL.CHANGE@DETAILS | N       | Portal User1 Change Details1 | noreply@northgateps.com |              |

        #update details back to orginal
        And I filter on "Portal User1 Change Details1"
        When I click on the "Edit row" link
        Then I should see the "Update User" page
        When I enter "Portal User" in the "First name" field
        When I enter "Change Details" in the "Last name" field
        When I enter "noreply@northgateps.com" in the "Confirm email address" field
        When I click on the "Update User" button
        Then I should see the "Account users" page

    Scenario: Updating a user along with password
        Given I have signed in
        When I go to the "Account" page
        And I click on the "Create or update users" link
        And I filter on "Portal User Change Details"
        And I click on the "Edit row" link
        Then I should see the "Update User" page
        # enter valid data and update the user details
        When I enter "Portal User1" in the "First name" field
        When I enter "Change Details1" in the "Last name" field
        When I enter "noreply@northgateps.com" in the "Confirm email address" field
        # Generates a random password, 9 characters long
        And I enter "PASSWORD,9" in the "New password" and "Confirm new password" field
        #again filter to check updated details
        When I click on the "Update User" button
        Then I should see the "Account users" page
        And I filter on "Portal User1 Change Details1"
        Then the table of data is displayed
            | Username              | Current | Name                         | Email address           | Phone number |
            | PORTAL.CHANGE@DETAILS | N       | Portal User1 Change Details1 | noreply@northgateps.com |              |

        #update details back to orginal
        And I filter on "Portal User1 Change Details1"
        When I click on the "Edit row" link
        Then I should see the "Update User" page
        When I enter "Portal User" in the "First name" field
        When I enter "Change Details" in the "Last name" field
        When I enter "noreply@northgateps.com" in the "Confirm email address" field
        When I click on the "Update User" button
        Then I should see the "Account users" page

    Scenario: Updating user roles
        Given I have signed in
        When I go to the "Account" page
        And I click on the "Create or update users" link
        And I filter on "Portal User Change Details"
        And I click on the "Edit row" link
        Then I should see the "Update User" page
        # update user roles
        When I check the "Account Administrator" checkbox
        And I check the "Account Security Administrator" checkbox
        When I click on the "Update User" button
        Then I should see the "Account users" page
        #check if user roles are updated
        And I filter on "Portal User Change Details"
        And I click on the "Edit row" link
        Then the checkbox "Account Administrator" should be checked
        And the checkbox "Account Security Administrator" should be checked
        #update details back to original
        When I click on the "Back" link
        And I filter on "Portal User Change Details"
        And I click on the "Edit row" link
        When I uncheck the "Account Administrator" checkbox
        And I uncheck the "Account Security Administrator" checkbox
        When I click on the "Update User" button
        Then I should see the "Account users" page

    Scenario: User filtering validation
        Given I have signed in
        When I go to the "Account" page
        And I click on the "Create or update users" link

        When I enter "RANDOM_STRING,256" in the "Name" field
        And I click on the "Find" button
        Then I should receive the message "Name is too long"

    Scenario: User should not be able to create any subordinate users if they have no services
        Given I have signed in 'portal.no.services' and password 'Password1!'
        When I go to the "Account" page
        And I click on the "Create or update users" link

        Then I should not see a link with text "Create a new user for your account"