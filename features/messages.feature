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
        And I should see the text "You will be able to upload more documents on the next page"
        And "Subject" should contain the option "General question"
        And "Subject" should contain the option "Application for bad debt relief"
        And "Subject" should not contain the option "ADS repayment submission confirmation"
        When I upload "testdocx.docx" to "dashboard_message_resource_item_default_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (optional)" field
        And I click on the "Upload file" button
        Then I should see the "New message" page
        And I should see a link to the file "testdocx.docx"
        And I should see the text "This is a docx file"

        # Filling up the rest of the required fields
        When I select "Application for bad debt relief" from the "Subject"
        And I enter "RS1009000TEST" in the "Reference" field
        And I enter "Upload file test" in the "Message title" field
        And I enter "Hello world" in the "Message body" field
        # Checking the remove file is working
        And I click on the "Delete file" button
        Then I should see the "New message" page
        And I should not see a link with text "This is a docx file"
        And I should not see the text "This is a docx file"

        # Uploading a valid jpg attachment
        When I upload "testjpg.jpg" to "dashboard_message_resource_item_default_file_data"
        And I click on the "Upload file" button
        Then I should see the "New message" page
        And I should see a link to the file "testjpg.jpg"
        When I click on the "Delete file" button
        Then I should see the "New message" page
        And I should not see a link to the file "testjpg.jpg"

        # Uploading a valid jpeg attachment
        When I upload "testjpeg.jpeg" to "dashboard_message_resource_item_default_file_data"
        And I click on the "Upload file" button
        Then I should see the "New message" page
        And I should see a link to the file "testjpeg.jpeg"
        When I click on the "Delete file" button
        Then I should see the "New message" page
        And I should not see a link to the file "testjpeg.jpeg"

        # Uploading file with file size that is too big
        When I upload "testimage_over_size_limit.jpg" to "dashboard_message_resource_item_default_file_data" on the browser
        Then I should receive the message "File should be less than 10 mb" on the browser

        # Uploading invalid file type
        When I upload "testtxt_invalid_file_type.txt" to "dashboard_message_resource_item_default_file_data"
        And I click on the "Upload file" button
        Then I should see the "New message" page
        And I should receive the message "Invalid file type"

        # Uploading a valid docx attachment
        When I upload "testdocx.docx" to "dashboard_message_resource_item_default_file_data"
        And I enter "This is a docx file" in the "Description of the uploaded file (optional)" field
        And I click on the "Upload file" button
        Then I should see the "New message" page
        And I should see a link to the file "testdocx.docx"

        # File uploads on the confirmation page of messages
        When I click on the "Send message" button
        Then I should see the "Thank you for your secure message" page

        When I upload "testdoc.doc" to "dashboard_message_resource_item_default_file_data"
        And I enter "This is a doc file" in the "Description of the uploaded file (optional)" field
        And I click on the "Upload file" button
        Then I should see the "Thank you for your secure message" page
        And I should see the text "testdoc.doc"
        And I should see the text "This is a doc file"
        # we need to wait for the remove file to process there is no +ve check to use
        When I click on the "Delete file" button
        Then I should see the "Thank you for your secure message" page
        Then I should not see the text "testdoc.doc"
        And I should not see the text "This is a doc file"

        # Uploading file with file size that is too big
        When I upload "testimage_over_size_limit.jpg" to "dashboard_message_resource_item_default_file_data" on the browser
        Then I should receive the message "File should be less than 10 mb" on the browser

        # Uploading invalid file type
        When I upload "testtxt_invalid_file_type.txt" to "dashboard_message_resource_item_default_file_data"
        And I click on the "Upload file" button
        Then I should see the "Thank you for your secure message" page
        And I should receive the message "Invalid file type"

        # Upload valid file types
        When I upload "testpng with space.png" to "dashboard_message_resource_item_default_file_data"
        And I enter "Test png image file" in the "Description of the uploaded file (optional)" field
        And I click on the "Upload file" button
        Then I should see the "Thank you for your secure message" page
        And I should see a link to the file "testpng with space.png"
        And I should see the text "Test png image file"

        And the table of data is displayed
            | File uploaded              | Description         |             |
            | %r{testpng with space.png} | Test png image file | Delete file |

        When I click on the "Finish" button
        Then I should see the "Messages" page

        # Checking to see that the uploaded files from both the new and confirmation pages are there
        When I click on the 1 st "View" link
        Then I should see the "Message details" page
        And I should see the text "File uploaded"
        And I should see the text "Application for bad debt relief"
        And I should see a link to the file "testdocx.docx"
        Then the table of data is displayed
            | File uploaded              | Description         |
            | testdocx.docx              | This is a docx file |
            | %r{testpng with space.png} | Test png image file |

        # Downloading the file
        When I click on the 1 st "testpng with space.png" link to download a file
        Then I should see the downloaded content "testpng with space.png"
        And I should see the "Message details" page

    # Index page tests
    Scenario: View list of all messages
        Given I have signed in
        Then I should see the "Dashboard" page
        And I should see the sub-title "Unread messages"
        When I click on the "Find messages" link
        Then I should see the "Messages" page
        When I enter "RS2000001AAAA" in the "Reference" field
        Then I click on the "Find" button
        And I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |
        When I select "Oldest" from the "Sort by"
        And I click on the "Find" button
        Then the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |
        # validate the mark as read/unread functions

        When I click on the 2 nd "View" link
        Then I should see the "Message details" page
        And I should see the button with text "Mark as unread"
        And I should not see the button with text "Mark as read"

        When I click on the "Back" link
        Then I should see the "Messages" page
        And I enter "RS2000001AAAA" in the "Reference" field
        And I select "Oldest" from the "Sort by"
        And I click on the "Find" button
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | Yes  | View     |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |

        When I click on the 2 nd "View" link
        Then I should see the "Message details" page
        And I should see the button with text "Mark as unread"
        And I should not see the button with text "Mark as read"

        When I click on the "Mark as unread" button
        Then I should see the "Message details" page
        And I should not see the button with text "Mark as unread"
        And I should see the button with text "Mark as read"

        When I click on the "Mark as read" button
        Then I should see the "Message details" page
        And I should see the button with text "Mark as unread"
        And I should not see the button with text "Mark as read"

        When I click on the "Mark as unread" button
        Then I should see the "Message details" page
        And I should not see the button with text "Mark as unread"
        And I should see the button with text "Mark as read"

        When I click on the "Back" link
        Then I should see the "Messages" page
        And I enter "RS2000001AAAA" in the "Reference" field
        And I select "Oldest" from the "Sort by"
        And I click on the "Find" button
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |

        When I click on the 1 st "View" link
        Then I should see the "Message details" page
        And I should not see the button with text "Mark as unread"
        And I should not see the button with text "Mark as read"



    # Show page tests
    Scenario: View a message in full details with the list of related messages and a related message
        Given I have signed in
        When I click on the "Find messages" link
        Then I should see the "Messages" page
        When I enter "RS2000001AAAA" in the "Reference" field
        And I click on the "Find" button
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
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1         |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | Selected message |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View             |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View             |

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
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1         |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View             |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | Selected message |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View             |
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
        Then I should see the "New message" page
        And "Subject" should contain the option "General question"
        And "Subject" should not contain the option "Application for bad debt relief"
        And "Subject" should contain the option "ADS repayment submission confirmation"
        # NOTE: "SMSUBT001" is the code for the select value of "General question"
        And I should see the text "SMSUBT001>$<MESSAGE_SUBJECT>$<SYS>$<RSTU" in field "Subject"
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
        When I click on the "Send message" button
        Then I should receive the message "Subject can't be blank"
        And I should receive the message "Message title can't be blank"
        And I should receive the message "Message body can't be blank"
        And I should receive the message "Subject can't be blank"
        And I should receive the message "Reference can't be blank"

        # All fields except the drop-down subject select has data
        When I enter "1234567890" in the "Reference" field
        And I enter "This is my title" in the "Message title" field
        And I enter "This is my message" in the "Message body" field
        And I click on the "Send message" button
        Then I should receive the message "Subject can't be blank"

        # All fields except the message title field has data
        When I select "Query a penalty" from the "Subject"
        And I clear the "Message title" field
        And I click on the "Send message" button
        Then I should receive the message "Message title can't be blank"


        # All fields except the message body field has data
        When I select "Query a penalty" from the "Subject"
        And I enter "This is my title" in the "Message title" field
        And I clear the "Message body" field
        And I click on the "Send message" button
        Then I should receive the message "Message body can't be blank"

        # All fields except the reference field has data
        When I select "Query a penalty" from the "Subject"
        And I enter "This is my message" in the "Message body" field
        And I clear the "Reference" field
        And I click on the "Send message" button
        Then I should receive the message "Reference can't be blank"

        Then I should see the "New message" page

        # Correct data is now being entered
        When I select "General question" from the "Subject"
        And I enter "RANDOM_REFERENCE_NAME,10,UPCASE" in the "Reference" field
        And I enter "My title" in the "Message title" field
        And I enter "Hello this is my text" in the "Message body" field
        And I click on the "Send message" button
        Then I should see the "Thank you for your secure message" page
        And I click on the "Finish" button
        Then I should see the "Messages" page

        When I enter "RANDOM_REFERENCE_NAME" in the "Reference" field
        And I click on the "Find" button
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
        Then I should see the "New message" page
        # Now I'm in looking at the New messages page
        When I enter "Here is my test text" in the "Message body" field
        And I enter "My response title" in the "Message title" field
        And I click on the "Send message" button
        Then I should see the "Thank you for your secure message" page
        And I click on the "Finish" button
        Then I should see the "Messages" page
        When I enter "RANDOM_REFERENCE_NAME" in the "Reference" field
        And I click on the "Find" button
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
        And I enter "RS2000001AAAA" in the "Reference" field
        And I enter "RANDOM_text,256" in the "Sent by" field
        And I click on the "Find" button
        Then I should receive the message "Sent by is too long (maximum is 255 characters)"

        When I open the "Show more filter options" summary item
        And I enter "USER ONE" in the "Sent by" field
        And I click on the "Find" button
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name            | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 15:16 | Portal User One | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 22/03/2019 11:13 | Portal User One | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |

        When I open the "Show more filter options" summary item
        And I clear the "Sent by" field
        And I select "Received" from the "Sent / received"
        And I enter "RS2000001AAAA" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name             | Message title             | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response | RS2000001AAAA | General question | No         | No   | View     |
        And I should not see the text "Test Message 1 - Reply to Response"

        When I open the "Show more filter options" summary item
        And I select "Sent" from the "Sent / received"
        And I click on the "Find" button
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name            | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 15:16 | Portal User One | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 22/03/2019 11:13 | Portal User One | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |
        And I should not see the text "Test Message 1 - Response"

        When I open the "Show more filter options" summary item
        And I select "" from the "Sent / received"
        And I select "General question" from the "Subject"
        And I click on the "Find" button
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |

        When I open the "Show more filter options" summary item
        And I select "" from the "Subject"
        And I enter "RS2000001AAAA" in the "Reference" field
        And I click on the "Find" button
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name             | Message title                      | Reference     | Subject          | Attachment | Read | Action_1 |
            | 23/03/2019 15:16 | Portal User One  | Test Message 1 - Reply to Response | RS2000001AAAA | General question | No         | Sent | View     |
            | 23/03/2019 09:13 | Revenue Scotland | Test Message 1 - Response          | RS2000001AAAA | General question | No         | No   | View     |
            | 22/03/2019 11:13 | Portal User One  | Test Message 1                     | RS2000001AAAA | General question | No         | Sent | View     |

        When I enter "RS2000001AAAA" in the "Reference" field
        And I enter "22-03-2019" in the "Created date from" date field
        And I click on the "Find" button
        Then I should see the "Messages" page
        And the table of data is displayed
            | Date & time      | Name            | Message title  | Reference     | Subject          | Attachment | Read | Action_1 |
            | 22/03/2019 11:13 | Portal User One | Test Message 1 | RS2000001AAAA | General question | No         | Sent | View     |

    Scenario: Message filtering validation
        Given I have signed in
        When I click on the "Find messages" link
        Then I should see the "Messages" page

        When I enter "RANDOM_STRING,31" in the "Reference" field
        And I click on the "Find" button
        Then I should receive the message "Reference is too long"