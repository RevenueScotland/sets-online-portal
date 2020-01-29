# feature/messages.feature

Feature: Secure Communication
    As a registered user
    I want to be able to have a secure messaging communication
    So that I can view a list of messages, send new message, view a message in full details and reply to messages

    # Index page tests
    Scenario: View list of all messages
        Given I have signed in
        When I click on the "All messages" link
        Then I should see the "Messages" page
        When I enter "RS200001AAAAA" in the "Reference" field
        Then I click on the "Find" button
        And the table of data is displayed
            | Date & time      | Name            | Message title                      | Reference     | Subject          | Attachment | Read |      |
            | 23/03/2019 15:16 | Portal User One | Test Message 1 - Reply to Response | RS200001AAAAA | General question | no         | sent | view |
            | 23/03/2019 09:13 | Portal User One | Test Message 1 - Response          | RS200001AAAAA | General question | no         | no   | view |
            | 22/03/2019 11:13 | Portal User One | Test Message 1                     | RS200001AAAAA | General question | no         | sent | view |

    # Show page tests
    Scenario: View a message in full details with the list of related messages and a related message
        Given I have signed in
        When I click on the "All messages" link
        Then I should see the "Messages" page
        And I enter "RS200001AAAAA" in the "Reference" field
        And I click on the "Find" button

        When I click on the "view" link of the first entry displayed
        Then I should see the "Message full details" page
        And I should see the text "Name"
        And I should see the text "Portal User One"

        And I should see the text "Date & time"
        And I should see the text "23/03/2019 15:16"

        And I should see the text "Subject"
        And I should see the text "General question"

        And I should see the text "Reference"
        And I should see the text "RS200001AAAAA"

        And I should see the text "Message title"
        And I should see the text "Test Message 1 - Reply to Response"

        And I should see the text "Message body"
        And I should see the text "Body for Test Message 1 Reply to Response"

        And I should see the text "Related Messages:"
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read |      |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS200001AAAAA | General question | no         | sent | view |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS200001AAAAA | General question | no         | no   | view |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS200001AAAAA | General question | no         | sent | view |

        # This is showing all the details of the message that is related to the previous message
        When I click on the 2 nd "view" link
        Then I should see the "Message full details" page
        And I should see the text "Portal User One"
        And I should see the text "23/03/2019"
        And I should see the text "General question"
        And I should see the text "RS200001AAAAA"
        And I should see the text "Test Message 1"
        And I should see the text "Body for Test Message 1"

        And I should see the text "Related Messages:"
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read |      |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS200001AAAAA | General question | no         | sent | view |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS200001AAAAA | General question | no         | no   | view |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS200001AAAAA | General question | no         | sent | view |
        When I click on the "Go to all messages" link
        Then I should see the "Messages" page

    # New page: Replying to messages
    Scenario: Reply to a message carry over some information from the previous message to a new empty message
        Given I have signed in
        When I click on the "All messages" link
        Then I should see the "Messages" page
        And I enter "RS200001AAAAA" in the "Reference" field
        And I click on the "Find" button

        When I click on the "view" link of the first entry displayed
        Then I should see the "Message full details" page

        When I click on the "Reply" button
        Then I should see the "New message" page
        # NOTE: "SMSUBT001" is the code for the select value of "General question"
        And I should see the text "SMSUBT001" in field "Subject"
        And I should see the text "RS200001AAAAA" in field "Reference"
        And I should see the text "Test Message 1 - Reply to Response" in field "Message title"
        And I should see the empty field "Message body"


    # New page: Sending of new message
    Scenario: Create a new message and check for incorrect data inputs
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "All messages" link
        Then I should see the "Messages" page

        # This shows the New Message page with the empty fields
        When I click on the "New Message" button
        Then I should see the "New message" page
        And I should see the empty field "Subject"
        And I should see the empty field "Reference"
        And I should see the empty field "Message title"
        And I should see the empty field "Message body"

        # No fields have data
        When I click on the "Next" button
        Then I should receive the message "This can't be blank"

        # All fields except the drop-down subject select has data
        When I enter "1234567890" in the "Reference" field
        And I enter "This is my title" in the "Message title" field
        And I enter "This is my message" in the "Message body" field
        And I click on the "Next" button
        Then I should receive the message "This can't be blank"

        # All fields except the message title field has data
        When I select "Query a penalty" from the "Subject"
        And I enter "" in the "Message title" field
        And I click on the "Next" button
        Then I should receive the message "This can't be blank"


        # All fields except the message body field has data
        When I select "Query a penalty" from the "Subject"
        And I enter "This is my title" in the "Message title" field
        And I enter "" in the "Message body" field
        And I click on the "Next" button
        Then I should receive the message "This can't be blank"

        # All fields except the reference field has data
        When I select "Query a penalty" from the "Subject"
        And I enter "This is my message" in the "Message body" field
        And I enter "" in the "Reference" field
        And I click on the "Next" button
        Then I should receive the message "This can't be blank"

        Then I should see the "New message" page

        # Correct data is now being entered
        When I select "General question" from the "Subject"
        And I enter "RANDOM_REFERENCE_NAME,10,UPCASE" in the "Reference" field
        And I enter "My title" in the "Message title" field
        And I enter "Hello this is my text" in the "Message body" field
        And I click on the "Next" button
        Then I should see the text "Thank you for your secure message."
        And I click on the "Continue" button

        Then I should see the "Messages" page

        When I enter "RANDOM_REFERENCE_NAME" in the "Reference" field
        Then the table of data is displayed
            | Date & time | Name                  | Message title | Reference             | Subject          | Attachment | Read |      |
            | NOW_DATE    | Portal User New Users | My title      | RANDOM_REFERENCE_NAME | General question | no         | sent | view |

        # Reply to a message gets shown in list of messages
        # Now I'm in looking at the Messages page
        When I click on the "view" link of the first entry displayed
        Then I should see the "Message full details" page
        # Now I'm in looking at the Message's full details page
        When I click on the "Reply" button
        Then I should see the "New message" page
        # Now I'm in looking at the New messages page
        When I enter "Here is my test text" in the "Message body" field
        And I enter "My response title" in the "Message title" field
        And I click on the "Next" button
        Then I should see the text "Thank you for your secure message."
        And I click on the "Continue" button
        Then I should see the "Messages" page
        Then the table of data is displayed
            | Date & time | Name                  | Message title     | Reference             | Subject          | Attachment | Read |      |
            | NOW_DATE    | Portal User New Users | My response title | RANDOM_REFERENCE_NAME | General question | no         | sent | view |
        # Show dependent message
        When I click on the "view" link of the first entry displayed
        Then I should see the "Message full details" page
        And the table of data is displayed
            | Date & time | Name                  | Message title | Reference             | Subject          | Attachment | Read |      |
            | NOW_DATE    | Portal User New Users | My title      | RANDOM_REFERENCE_NAME | General question | no         | sent | view |


    Scenario: Message filtering only shows the data that I want to see
        Given I have signed in
        When I click on the "All messages" link
        Then I should see the "Messages" page

        When I click on the "Show more filter options" text
        And I enter "RS200001AAAAA" in the "Reference" field
        And I enter "USER ONE" in the "Sent by" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Date & time      | Name            | Message title                      | Reference     | Subject          | Attachment | Read |      |
            | 23/03/2019 15:16 | Portal User One | Test Message 1 - Reply to Response | RS200001AAAAA | General question | no         | sent | view |
            | 22/03/2019 11:13 | Portal User One | Test Message 1                     | RS200001AAAAA | General question | no         | sent | view |

        When I enter "" in the "Sent by" field
        And I select "Received" from the "Type"
        And I enter "RS200001AAAAA" in the "Reference" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Date & time      | Name             | Message title             | Reference     | Subject          | Attachment | Read |      |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response | RS200001AAAAA | General question | no         | no   | view |
        And I should not see the text "Test Message 1 - Reply to Response"

        When I select "Sent" from the "Type"
        And I click on the "Find" button
        Then the table of data is displayed
            | Date & time      | Name            | Message title                      | Reference     | Subject          | Attachment | Read |      |
            | 23/03/2019 15:16 | Portal User One | Test Message 1 - Reply to Response | RS200001AAAAA | General question | no         | sent | view |
            | 22/03/2019 11:13 | Portal User One | Test Message 1                     | RS200001AAAAA | General question | no         | sent | view |
        And I should not see the text "Test Message 1 - Response"

        When I select "Choose from list" from the "Type"
        And I select "General question" from the "Subject"
        And I click on the "Find" button
        Then the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read |      |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS200001AAAAA | General question | no         | sent | view |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS200001AAAAA | General question | no         | no   | view |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS200001AAAAA | General question | no         | sent | view |

        When I select "Choose from list" from the "Subject"
        And I enter "RS200001AAAAA" in the "Reference" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read |      |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS200001AAAAA | General question | no         | sent | view |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS200001AAAAA | General question | no         | no   | view |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS200001AAAAA | General question | no         | sent | view |

        When I enter "RS200001AAAAA" in the "Reference" field
        And I enter "2019-03-22" in the "Created date from" field
        And I click on the "Find" button
        Then the table of data is displayed
            | Date & time      | Name            | Message title  | Reference     | Subject          | Attachment | Read |      |
            | 22/03/2019 11:13 | Portal User One | Test Message 1 | RS200001AAAAA | General question | no         | sent | view |

    Scenario: Message filtering validation
        Given I have signed in
        When I click on the "All messages" link
        Then I should see the "Messages" page

        When I enter "RANDOM_STRING,31" in the "Reference" field
        And I click on the "Find" button
        Then I should receive the message "Reference is too long"