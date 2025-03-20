# feature/messages.feature

Feature: Secure Communication
    As a registered user
    I want to be able to have a secure messaging communication
    So that I can View a list of messages, send new message, View a message in full details and reply to messages

    Scenario: Upload and download a file attachment
        Given I have signed in "PORTAL.WASTE.NEW" and password "Password1!"
        # Uploading a file when creating a new message
        When I click on the "Create new message" menu item
        Then I should see the "New message" page
        And I should see the text "You will be able to upload documents on the next page"
        And "Subject" should contain the option "General question"
        And "Subject" should contain the option "Application for bad debt relief"
        And "Subject" should not contain the option "ADS repayment submission confirmation"
        And I should not see the text "Agent / your reference"

        # Filling up the rest of the required fields
        When I select "Application for bad debt relief" from the "Subject"
        And I enter "RS1009000TEST" in the "Reference" field
        And I enter "Upload file test" in the "Message title" field
        And I enter "Hello world" in the "Message body" field
        And I click on the "Continue" button
        Then I should see the "Upload your supporting file" page

        When I upload "testdocx.docx" to "dashboard_message_resource_item_default_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (optional)" field
        And I click on the "Continue" button
        Then I should see the "Send message" page
        And I should see a link to the file "testdocx.docx"
        And I should see the text "This is a docx file"

        # Checking the remove file is working
        And I click on the "Delete file" button
        Then I should see the "Send message" page
        And I should not see a link with text "This is a docx file"
        And I should not see the text "This is a docx file"

        # # Uploading a valid jpg attachment
        When I click on the "Add a file" link
        Then I should see the "Upload your supporting file" page
        When I upload "testjpg.jpg" to "dashboard_message_resource_item_default_file_data"
        And I click on the "Continue" button
        Then I should see the "Send message" page
        And I should see a link to the file "testjpg.jpg"
        When I click on the "Delete file" button
        Then I should see the "Send message" page
        And I should not see a link to the file "testjpg.jpg"

        # # Uploading a valid jpeg attachment
        When I click on the "Add a file" link
        Then I should see the "Upload your supporting file" page
        When I upload "testjpeg.jpeg" to "dashboard_message_resource_item_default_file_data"
        And I click on the "Continue" button
        Then I should see the "Send message" page
        And I should see a link to the file "testjpeg.jpeg"
        When I click on the "Delete file" button
        Then I should see the "Send message" page
        And I should not see a link to the file "testjpeg.jpeg"

        # # Uploading file with file size that is too big
        When I click on the "Add a file" link
        Then I should see the "Upload your supporting file" page
        When I upload "testimage_over_size_limit.jpg" to "dashboard_message_resource_item_default_file_data" and continue via the browser
        Then I should receive the message "File should be less than 15 mb" on the browser

        # # Uploading invalid file type
        When I upload "testtxt_invalid_file_type.txt" to "dashboard_message_resource_item_default_file_data"
        And I click on the "Continue" button
        Then I should see the "Upload your supporting file" page
        And I should receive the message "Invalid file type"

        # # Uploading a valid docx attachment
        When I upload "testdocx.docx" to "dashboard_message_resource_item_default_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (optional)" field
        And I click on the "Continue" button
        Then I should see the "Send message" page
        And I should see a link to the file "testdocx.docx"

        # # File uploads on the confirmation page of messages
        When I click on the "Send Message" button
        Then I should see the "Thank you for your secure message" page

        When I click on the "Finish" button
        Then I should see the "Messages" page

        # # Checking to see that the uploaded files from both the new and confirmation pages are there
        When I click on the 1 st "View" link
        Then I should see the "Message details" page
        And I should see the text "File uploaded"
        And I should see the text "Application for bad debt relief"
        And I should see a link to the file "testdocx.docx"
        Then the table of data is displayed
            | File uploaded | Description         |
            | testdocx.docx | This is a docx file |

        # # Downloading the file
        When I click on the 1 st "testdocx.docx" link to download a file
        Then I should see the downloaded content "testdocx.docx"
        And I should see the "Message details" page

    # Index page tests
    # TODO: RSTP-1615, this test case is commented out as it keeps failing
    # will convert it to a mock test
    # it keeps failing due to the order of messsges keep changing from the bo call
    # Scenario: View list of all messages
    #     Given I have signed in
    #     Then I should see the "Dashboard" page
    #     And I should see the sub-title "Unread messages"
    #     When I click on the "Find messages" link
    #     Then I should see the "Messages" page
    #     When I enter "RS2000001AAAA" in the "Reference" field
    #     Then I click on the "Find" button
    #     And I should see the "Messages" page
    #     And the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
    #         | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |                                                         |
    #         | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |

    #     # Search based on alt reference in list of messages
    #     When I enter "PORTAL.ONE" in the "Reference" field
    #     Then I click on the "Find" button
    #     And I should see the "Messages" page
    #     And the table of data is displayed
    #         | Date & time      | Name            | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
    #         | 23/03/2019 15:16 | Portal User One | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #         | 22/03/2019 11:13 | Portal User One | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |

    #     When I select "Oldest" from the "Sort by"
    #     And I clear the "Reference" field
    #     And I click on the "Find" button
    #     Then the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
    #         | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |                                                         |
    #         | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #     # validate the mark as read/unread functions

    #     When I click on the 2 nd "View" link
    #     Then I should see the "Message details" page
    #     And I should see the button with text "Mark as unread"
    #     And I should not see the button with text "Mark as read"

    #     When I click on the "Back" link
    #     Then I should see the "Messages" page
    #     And I enter "RS2000001AAAA" in the "Reference" field
    #     And I select "Oldest" from the "Sort by"
    #     And I click on the "Find" button
    #     And the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
    #         | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | Yes  | View     | Body for Test Message 1 Response                        |
    #         | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |

    #     When I click on the 2 nd "View" link
    #     Then I should see the "Message details" page
    #     And I should see the button with text "Mark as unread"
    #     And I should not see the button with text "Mark as read"
    #     And I should see a link with text "Previous message"
    #     And I should see a link with text "1"
    #     And I should see a link with text "2"
    #     And I should see a link with text "3"
    #     And I should not see a link with text "5"
    #     And I should see the text "5"
    #     And I should see a link with text "4"
    #     And I should see a link with text "Next message"
    #     And I should see a link with text "View all"
    #     And the table of data is displayed
    #         | Date & time      | Name                  | Message title                      | Reference     | Subject                          | Attachment | Read | Action_1         | Action_2                                                |
    #         | 23/03/2019 15:18 | Revenue Scotland Test | Test Message 3 - Reply to Response | RS2000001AAAT | General question                 | No         | Yes  | View             |                                                         |
    #         | 23/03/2019 15:17 | Revenue Scotland Test | Test Message 2 - Reply to Response | RS2000001AAAT | Portal message subject populated | No         | No   | View             |                                                         |
    #         | 23/03/2019 15:16 | Portal User One       | Test Message 1 - Reply to Response | RS2000001AAAA | General question                 | No         | Sent | View             | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #         | 23/03/2019 09:13 | Revenue Scotland      | Test Message 1 - Response          | RS2000001AAAA | General question                 | No         | Yes  | Selected message |                                                         |
    #         | 22/03/2019 11:13 | Portal User One       | Test Message 1                     | RS2000001AAAA | General question                 | No         | Sent | View             | Body for Test Message 1                                 |

    #     Then I should see the "Message details" page
    #     When I click on the "Next message" link
    #     Then I should see the "Message details" page
    #     Then I should not see a link with text "Next message"
    #     Then I should see the "Message details" page
    #     And I should see a link with text "Previous message"
    #     And the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject                          | Attachment | Read | Action_1 | Action_2                                                |
    #         | 23/03/2019 15:18 | Revenue Scotland | Test Message 3 - Reply to Response | RS2000001AAAT | General question                 | No         | No   | View     |                                                         |
    #         | 23/03/2019 15:17 | Revenue Scotland | Test Message 2 - Reply to Response | RS2000001AAAT | Portal message subject populated | No         | Yes  | View     |                                                         |
    #         | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question                 | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question                 | No         | Yes  | View     | Body for Test Message 1 Response                        |
    #         | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question                 | No         | Sent | View     | Selected message                                        |

    #     When I click on the "Previous message" link
    #     Then I should see the "Message details" page
    #     Then I should see a link with text "Next message"
    #     And I should see a link with text "Previous message"
    #     And the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject                          | Attachment | Read | Action_1         | Action_2                                                |
    #         | 23/03/2019 15:18 | Revenue Scotland | Test Message 3 - Reply to Response | RS2000001AAAT | General question                 | No         | No   | View             |                                                         |
    #         | 23/03/2019 15:17 | Revenue Scotland | Test Message 2 - Reply to Response | RS2000001AAAT | Portal message subject populated | No         | Yes  | View             |                                                         |
    #         | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question                 | No         | Sent | View             | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question                 | No         | Yes  | Selected message |                                                         |
    #         | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question                 | No         | Sent | View             | Body for Test Message 1                                 |

    #     When I click on the "Previous message" link
    #     Then I should see the "Message details" page
    #     And I click on the "Previous message" link
    #     Then I should see the "Message details" page
    #     Then I should see a link with text "Next message"
    #     And I should see a link with text "Previous message"
    #     And the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1         | Action_2                         |
    #         | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | Selected message |                                  |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | Yes  | View             | Body for Test Message 1 Response |
    #         | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View             | Body for Test Message 1          |

    #     When I click on the "Next message" link
    #     Then I should see a link with text "Next message"
    #     And I should see a link with text "Previous message"
    #     And I click on the "Previous message" link
    #     Then I should see the "Message details" page
    #     And I click on the "Previous message" link
    #     Then I should see the "Message details" page

    #     When I click on the "Mark as unread" button
    #     Then I should see the "Message details" page
    #     And I should not see the button with text "Mark as unread"
    #     And I should see the button with text "Mark as read"
    #     And the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
    #         | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | Yes  | Yes      |                                                         |
    #         | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |


    #     When I click on the "Mark as read" button
    #     Then I should see the "Message details" page
    #     And I should see the button with text "Mark as unread"
    #     And I should not see the button with text "Mark as read"

    #     When I click on the "Mark as unread" button
    #     Then I should see the "Message details" page

    #     When I click on the "Back" link
    #     Then I should see the "Messages" page
    #     And I enter "RS2000001AAAA" in the "Reference" field
    #     And I select "Oldest" from the "Sort by"
    #     And I click on the "Find" button
    #     And the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
    #         | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |                                                         |
    #         | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |

    #     When I click on the 3 rd "View" link
    #     Then I should see the "Message details" page
    #     And I click on the "5" link
    #     Then I should see the "Message details" page
    #     And I should see the button with text "Mark as unread"
    #     And I should not see the button with text "Mark as read"
    #     When I click on the "Mark as unread" button
    #     Then I should see the "Message details" page
    #     And I should not see the button with text "Mark as unread"

    #     When I click on the "Previous message" link
    #     Then I should see the "Message details" page
    #     When I click on the "Previous message" link
    #     Then I should see the "Message details" page
    #     When I click on the "Previous message" link
    #     Then I should see the "Message details" page
    #     And I should see the button with text "Mark as unread"
    #     And I should see a link with text "Previous message"
    #     When I click on the "Mark as unread" button
    #     When I click on the "View message number RS2000001AAAT" link
    #     Then I should see the "Message details" page
    #     And I should see the button with text "Mark as unread"
    #     And I should see a link with text "Previous message"
    #     When I click on the "Mark as unread" button
    #     Then I should see the "Message details" page
    #     And I should not see the button with text "Mark as unread"

    #     When I click on the "Dashboard" menu item
    #     Then I should see the "Dashboard" page
    #     And I should see the sub-title "Unread messages"
    #     When I click on the "Find messages" link
    #     Then I should see the "Messages" page
    #     And I should see the "Messages" page

    #     When I enter "RS2000001AAA" in the "Reference" field
    #     Then I click on the "Find" button
    #     And the table of data is displayed
    #         | Date & time      | Name             | Message title                      | Reference     | Subject                          | Attachment | Read | Action_1 | Action_2 |
    #         | 23/03/2019 15:18 | Revenue Scotland | Test Message 3 - Reply to Response | RS2000001AAAT | General question                 | No         | No   | View     |          |
    #         | 23/03/2019 15:17 | Revenue Scotland | Test Message 2 - Reply to Response | RS2000001AAAA | Portal message subject populated | No         | No   | View     |          |
    #         | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question                 | No         | No   | View     |          |

    #     And I should not see the text "Recalled message"

    # Show page tests
    Scenario: View a message in full details with the list of related messages and a related message
        Given I have signed in
        When I click on the "Find messages" link
        Then I should see the "Messages" page
        When I enter "RS2000001AAAA" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Messages" page
        And I should see a link with text "Create a new message about RS2000001AAAA"

        When I click on the "Create a new message about RS2000001AAAA" link
        Then I should see the "New message" page
        And I should see the text "RS2000001AAAA" in field "Reference"
        And I should see the text "HS/XXX/TH/CO99999.0001" in field "Agent / your reference"

        When I click on the "Back" link
        And if available, click the confirmation dialog
        Then I should see the "Messages" page

        When I click on the "View" link of the first entry displayed
        Then I should see the "Message details" page
        And I should see the text "Name"
        And I should see the text "Portal User One"

        And I should see the text "Date & time"
        And I should see the text "23/03/2019 15:16"

        And I should see the text "Subject"
        And I should see the text "General question"

        And I should see the text "Reference"
        And I should see the text "RS2000001AAAA"

        And I should see the text "Message title"
        And I should see the text "Test Message 1 - Reply to Response"

        And I should see the text "Message body"
        And I should see the text "Body for Test Message 1"
        And I should see the text "Reply to Response"

        And I should see the text "Related messages"
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1         | Action_2                                                |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | Selected message | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View             |                                                         |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View             | Body for Test Message 1                                 |

        # This is showing all the details of the message that is related to the previous message
        When I click on the 2 nd "View" link
        Then I should see the "Message details" page
        And I should see the text "Portal User One"
        And I should see the text "23/03/2019 09:13"
        And I should see the text "General question"
        And I should see the text "RS2000001AAAA"
        And I should see the text "Test Message 1"
        And I should see the text "Body for Test Message 1"

        And I should see the text "Related messages"
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1         | Action_2                                                |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View             | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | Selected message |                                                         |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View             | Body for Test Message 1                                 |
        When I click on the "Back" link
        Then I should see the "Messages" page

    # New page: Replying to messages
    Scenario: Reply to a message carry over some information from the previous message to a new empty message
        Given I have signed in
        When I click on the "Find messages" link
        Then I should see the "Messages" page
        When I enter "RS2000001AAAA" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Messages" page

        When I click on the "View" link of the first entry displayed
        Then I should see the "Message details" page

        When I click on the "Reply" link
        Then I should see the "Reply to message" page
        And I should see the text "General question"
        # NOTE: "SMSUBT001" is the code for the select value of "General question"
        And I should see the text "RS2000001AAAA" in field "Reference"
        And I should see the text "Test Message 1 - Reply to Response" in field "Message title"
        And I should see the empty field "Message body"


    # New page: Sending of new message
    Scenario: Create a new message and check for incorrect data inputs
        Given I have signed in "PORTAL.NEW.USERS" and password "Password1!"
        When I click on the "Find messages" link
        Then I should see the "Messages" page

        # This shows the New Message page with the empty fields
        When I click on the "Create new message" menu item
        Then I should see the "New message" page
        And I should see the empty field "Subject"
        And I should see the empty field "Reference"
        And I should see the empty field "Message title"
        And I should see the empty field "Message body"

        # No fields have data
        When I click on the "Continue" button
        Then I should receive the message "Subject can't be blank"
        And I should receive the message "Message title can't be blank"
        And I should receive the message "Message body can't be blank"
        And I should receive the message "Subject can't be blank"
        And I should receive the message "Reference can't be blank"

        # All fields except the drop-down subject select has data
        When I enter "1234567890" in the "Reference" field
        And I enter "This is my title" in the "Message title" field
        And I enter "This is my message" in the "Message body" field
        And I click on the "Continue" button
        Then I should receive the message "Subject can't be blank"

        # All fields except the message title field has data
        When I select "Query a penalty" from the "Subject"
        And I clear the "Message title" field
        And I click on the "Continue" button
        Then I should receive the message "Message title can't be blank"


        # All fields except the message body field has data
        When I select "Query a penalty" from the "Subject"
        And I enter "This is my title" in the "Message title" field
        And I clear the "Message body" field
        And I click on the "Continue" button
        Then I should receive the message "Message body can't be blank"

        # All fields except the reference field has data
        When I select "Query a penalty" from the "Subject"
        And I enter "This is my message" in the "Message body" field
        And I clear the "Reference" field
        And I click on the "Continue" button
        Then I should receive the message "Reference can't be blank"

        Then I should see the "New message" page

        # Correct data is now being entered
        When I select "General question" from the "Subject"
        And I enter "RANDOM_REFERENCE_NAME,10,UPCASE" in the "Reference" field
        And I enter "My title" in the "Message title" field
        And I enter "Hello this is my text" in the "Message body" field
        And I click on the "Continue" button
        Then I should see the "Upload your supporting file" page
        When I click on the "Continue" button
        Then I should see the "Send message" page

        When I click on the "Send Message" button
        Then I should see the "Thank you for your secure message" page
        And I click on the "Finish" button
        Then I should see the "Messages" page

        When I enter "RANDOM_REFERENCE_NAME" in the "Reference" field
        And I click on the "Find" button
        And I wait for 3 seconds
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time | Name                  | Message title | Reference             | Subject          | Attachment | Read | Action_1 |
            | NOW_DATE    | Portal User New Users | My title      | RANDOM_REFERENCE_NAME | General question | No         | Sent | View     |

        # Reply to a message gets shown in list of messages
        # Now I'm in looking at the Messages page
        When I click on the "View" link of the first entry displayed
        Then I should see the "Message details" page
        # Now I'm in looking at the Message's full details page
        When I click on the "Reply" link
        Then I should see the "Reply to message" page
        # # Now I'm in looking at the New messages page
        When I enter "Here is my test text" in the "Message body" field
        And I enter "My response title" in the "Message title" field
        And I click on the "Continue" button
        Then I should see the "Upload your supporting file" page
        And I click on the "Continue" button
        Then I should see the "Send message" page

        When I click on the "Send Message" button
        Then I should see the "Thank you for your secure message" page
        And I click on the "Finish" button
        Then I should see the "Messages" page
        When I enter "RANDOM_REFERENCE_NAME" in the "Reference" field
        And I click on the "Find" button
        And I wait for 3 seconds
        Then I should see the "Messages" page
        Then the table of data is displayed
            | Date & time | Name                  | Message title     | Reference             | Subject          | Attachment | Read | Action_1 |
            | NOW_DATE    | Portal User New Users | My response title | RANDOM_REFERENCE_NAME | General question | No         | Sent | View     |
            | NOW_DATE    | Portal User New Users | My title          | RANDOM_REFERENCE_NAME | General question | No         | Sent | View     |
        # Show dependent message
        When I click on the "View" link of the first entry displayed
        Then I should see the "Message details" page
        And the table of data is displayed
            | Date & time | Name                  | Message title     | Reference             | Subject          | Attachment | Read | Action_1         |
            | NOW_DATE    | Portal User New Users | My title          | RANDOM_REFERENCE_NAME | General question | No         | Sent | View             |
            | NOW_DATE    | Portal User New Users | My response title | RANDOM_REFERENCE_NAME | General question | No         | Sent | Selected message |


    Scenario: Message filtering only shows the data that I want to see
        Given I have signed in
        When I click on the "Find messages" link
        Then I should see the "Messages" page

        When I open the "Show more filter options" summary item
        Then I should see the "Messages" page
        And I enter "RS2000001AAAA" in the "Reference" field
        And I enter "RANDOM_text,256" in the "Sent by" field
        And I click on the "Find" button
        Then I should receive the message "Sent by is too long (maximum is 255 characters)"

        When I open the "Show more filter options" summary item
        Then I should see the "Messages" page
        When I enter "USER ONE" in the "Sent by" field
        And I click on the "Find" button
        And I wait for 3 seconds
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name            | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
            | 23/03/2019 15:16 | Portal User One | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
            | 22/03/2019 11:13 | Portal User One | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |

        When I open the "Show more filter options" summary item
        Then I should see the "Messages" page
        And I clear the "Sent by" field
        And I select "Received" from the "Sent / received"
        When I enter "RS2000001AAAA" in the "Reference" field
        Then I should see the "Messages" page
        And I click on the "Find" button
        And I wait for 3 seconds
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name             | Message title             | Reference     | Subject          | Attachment | Read | Action_1 | Action_2 |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response | RS2000001AAAA | General question | No         | No   | View     |          |
        And I should not see the text "Test Message 1 - Reply to Response"

        When I open the "Show more filter options" summary item
        Then I should see the "Messages" page
        And I select "Sent" from the "Sent / received"
        And I click on the "Find" button
        And I wait for 3 seconds
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name            | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 15:16 | Portal User One | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 22/03/2019 11:13 | Portal User One | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |
        And I should not see the text "Test Message 1 - Response"

        When I open the "Show more filter options" summary item
        Then I should see the "Messages" page
        And I select "" from the "Sent / received"
        And I select "General question" from the "Subject"
        And I click on the "Find" button
        And I wait for 3 seconds
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |                                                         |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |

        When I open the "Show more filter options" summary item
        Then I should see the "Messages" page
        And I select "" from the "Subject"
        And I enter "RS2000001AAAA" in the "Reference" field
        And I click on the "Find" button
        And I wait for 3 seconds
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                                                |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     | <p>Body for Test Message 1</p> <p>Reply to Response</p> |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |                                                         |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1                                 |

        When I enter "RS2000001AAAA" in the "Reference" field
        And I enter "22-03-2019" in the "Created date from" date field
        And I click on the "Find" button
        And I wait for 3 seconds
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name            | Message title  | Reference     | Subject          | Attachment | Read | Action_1 | Action_2                |
            | 22/03/2019 11:13 | Portal User One | Test Message 1 | RS2000001AAAA | General question | No         | Sent | View     | Body for Test Message 1 |

    Scenario: Message filtering validation
        Given I have signed in
        When I click on the "Find messages" link
        Then I should see the "Messages" page

        When I enter "RANDOM_STRING,31" in the "Reference" field
        And I click on the "Find" button
        Then I should receive the message "Reference is too long"

    Scenario: For SAT the selected enrolment reference should be pre populated
        When I go to the "Login" page
        And I enter "portal.sat.users" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Select your SAT registration" page
        And I should see the text "Which of your SAT registrations do you wish to view?"

        When I click on the "Continue" button
        Then I should see the "Select your SAT registration" page
        And I should not see the text "Create new message"
        And I should see the text "Which of your SAT registrations do you wish to view can't be blank"
        When I check the "SAT1000000VVVV Black Sands Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button
        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page

        When I click on the "Create new message" menu item
        Then I should see the "New message" page
        And I should see the text "New message"
        And I should see the text "SAT1000000VVVV" in field "Reference"

        When I click on the "Cancel" menu item
        And if available, click the confirmation dialog
        Then I should see the "Dashboard" page
        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page
        And I click on the "Find messages" link
        Then I should see the "Messages" page
        And I should see the "Messages : SAT1000000VVVV Black Sands Group" page
        And I should see a link with text "Create a new message about SAT1000000VVVV"

        When I click on the "Create a new message about SAT1000000VVVV" link
        Then I should see the text "New message"
        And I should see the text "SAT1000000VVVV" in field "Reference"
        And I enter "This is my title" in the "Message title" field
        And I enter "This is my message" in the "Message body" field

        And I select "General question" from the "Subject"
        And I click on the "Continue" button

        Then I should see the "Upload your supporting file" page
        And I click on the "Continue" button
        Then I should see the "Send message" page

        When I click on the "Send Message" button
        Then I should see the "Thank you for your secure message" page

    Scenario: For SAT the selected enrolment reference I should only see messsges related to that reference
        When I go to the "Login" page
        And I enter "portal.sat.users" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Select your SAT registration" page
        And I should see the text "Which of your SAT registrations do you wish to view?"

        When I click on the "Continue" button
        Then I should see the "Select your SAT registration" page
        And I should not see the text "Create new message"
        And I should see the text "Which of your SAT registrations do you wish to view can't be blank"
        When I check the "SAT1000000VVVV Black Sands Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button
        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page
        When I click on the "Find messages" link
        Then I should see the "Messages" page
        And I should see the "Messages : SAT1000000VVVV Black Sands Group" page

        When I enter "RS10000006BHDH" in the "Reference" field
        Then I click on the "Find" button
        And I wait for 3 seconds
        And I should see the "Messages : SAT1000000VVVV Black Sands Group" page
        And the table of data is displayed
            | Date & time      | Name             | Message title              | Reference      | Subject                       | Attachment | Read | Action_1 |
            | 11/02/2025 08:48 | Revenue Scotland | Claim receipt confirmation | RS10000006BHDH | Claim Submission confirmation | No         | No   | View     |
            | 11/02/2025 06:18 | Revenue Scotland | Claim receipt confirmation | RS10000006BHDH | Claim Submission confirmation | No         | No   | View     |

        And I click on the 1 st "View" link
        Then I should see the "Message details" page
        And I should see the button with text "Mark as unread"
        And I should not see the button with text "Mark as read"

        When I click on the "Mark as unread" button
        Then I should see the "Message details" page
        And I should not see the button with text "Mark as unread"
        And I should see the button with text "Mark as read"

        And I click on the "Dashboard" menu item
        And I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page
        When I click on the "Find messages" link
        Then I should see the "Messages" page
        And I should see the "Messages : SAT1000000VVVV Black Sands Group" page

        When I enter "RS10000006BHDH" in the "Reference" field
        Then I click on the "Find" button
        And I wait for 3 seconds
        And I should see the "Messages : SAT1000000VVVV Black Sands Group" page
        And the table of data is displayed
            | Date & time      | Name             | Message title              | Reference      | Subject                       | Attachment | Read | Action_1 |
            | 11/02/2025 08:48 | Revenue Scotland | Claim receipt confirmation | RS10000006BHDH | Claim Submission confirmation | No         | No   | View     |
            | 11/02/2025 06:18 | Revenue Scotland | Claim receipt confirmation | RS10000006BHDH | Claim Submission confirmation | No         | No   | View     |

        When I click on the "Sign out" menu item
        Then I should see the "Sign in" page

        And I enter "portal.sat.users" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Select your SAT registration" page
        And I should see the text "Which of your SAT registrations do you wish to view?"

        When I check the "SAT1000000RPRP Marks & Spencer Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button
        Then I should see the "Dashboard : SAT1000000RPRP Marks & Spencer Group" page
        And I should not see the text "SAT1000000VVVV"
        And I should not see the text "Claim receipt confirmation"

        When I click on the "Create new message" menu item
        Then I should see the "New message" page
        And I should see the text "New message"
        And I should see the text "SAT1000000RPRP" in field "Reference"
        And I enter "This message should only be shown on SAT1000000RPRP" in the "Message title" field
        And I enter "This is my message" in the "Message body" field
        And I select "General question" from the "Subject"

        And I click on the "Continue" button

        Then I should see the "Upload your supporting file" page
        And I click on the "Continue" button
        Then I should see the "Send message" page

        When I click on the "Send Message" button
        Then I should see the "Thank you for your secure message" page

        When I click on the "Dashboard" menu item
        Then I should see the "Dashboard : SAT1000000RPRP Marks & Spencer Group" page
        And the table of data is displayed
            | Date & time | Name | Message title | Reference | Subject | Attachment | Read | Action_1 |
        And I should not see the text "SAT1000000VVVV"
        And I should not see the text "Claim receipt confirmation"


        When I click on the "Sign out" menu item
        Then I should see the "Sign in" page
        And I enter "portal.sat.users" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Select your SAT registration" page
        And I should see the text "Which of your SAT registrations do you wish to view?"

        When I click on the "Continue" button
        Then I should see the "Select your SAT registration" page
        And I should not see the text "Create new message"
        And I should see the text "Which of your SAT registrations do you wish to view can't be blank"
        When I check the "SAT1000000VVVV Black Sands Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button
        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page
        And I should not see the text "SAT1000000RPRP"
        And I should not see the text "This message should only be shown on SAT1000000RPRP"

    Scenario: For SAT user should only see the messages linked to that enrolment reference
        When I go to the "Login" page
        And I enter "portal.sat.users" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Select your SAT registration" page
        And I should see the text "Which of your SAT registrations do you wish to view?"

        When I click on the "Continue" button
        Then I should see the "Select your SAT registration" page
        And I should not see the text "Create new message"
        And I should see the text "Which of your SAT registrations do you wish to view can't be blank"
        When I check the "SAT1000000VVVV Black Sands Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        And I click on the "Continue" button
        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page

        When I click on the "Create new message" menu item
        Then I should see the "New message" page
        And I should see the text "New message"
        And I should see the text "SAT1000000VVVV" in field "Reference"

        When I click on the "Cancel" menu item
        And if available, click the confirmation dialog
        Then I should see the "Dashboard" page

        # When I click on the "Dashboard" menu item
        Then I should see the "Dashboard : SAT1000000VVVV Black Sands Group" page
        And I click on the "Find messages" link
        Then I should see the "Messages" page
        And I should see the "Messages : SAT1000000VVVV Black Sands Group" page

        When I enter "SAT1000000VVVV" in the "Reference" field
        Then I click on the "Find" button
        And I wait for 3 seconds
        And I should see the "Messages : SAT1000000VVVV Black Sands Group" page
        And the table of data is displayed
            | Name | Message title | Reference | Subject | Attachment | Read | Action_1 |
            |      |               |           |         |            |      |          |
        # | Portal User SAT Users | This is my title | SAT1000000VVVV | Notification | No         | Sent | View     |
        And I should not see the text "SAT1000000RPRP"
        And I should not see the text "This message should only be shown on SAT1000000RPRP"

        When I enter "SAT1000000RPRP" in the "Reference" field
        Then I click on the "Find" button
        And I should see the "Messages : SAT1000000VVVV Black Sands Group" page
        And I should not see the text "This message should only be shown on SAT1000000RPRP"

        When I click on the "Sign out" menu item
        Then I should see the "Sign in" page
        And I enter "portal.sat.users" in the "Username" field
        And I enter "Password1!" in the "Password" field
        And I click on the "Sign in" button

        Then I should see the "Select your SAT registration" page
        When I check the "SAT1000000RPRP Marks & Spencer Group" radio button in answer to the question "Which of your SAT registrations do you wish to view?"
        Then I click on the "Continue" button
        And I should see the "Dashboard : SAT1000000RPRP Marks & Spencer Group" page

        When I click on the "Find messages" link
        Then I should see the "Messages" page
        And I should see the "Messages : SAT1000000RPRP Marks & Spencer Group" page
        And I should not see the text "This message should only be shown on SAT1000000VVVV"

        When I enter "SAT1000000VVVV" in the "Reference" field
        Then I click on the "Find" button
        And the table of data is displayed
            | Name | Message title | Reference | Subject | Attachment | Read | Action_1 |
            |      |               |           |         |            |      |          |