# feature/slft_csv_file_upload.feature

Feature: SLfT CSV File Upload
  As a user
  I want to be able to upload CSV files

  Scenario: Check Validation
    Given I have signed in "portal.waste.new" and password "Password1!"
    When I click on the "Create SLfT return" menu item
    Then I should see the "Return summary" page
    When I set a period of "2018/19" and "October to December (Quarter 3)"
    Then I should see the "Return summary" page

    When I click on the 1 st "Add waste details" link
    Then I should see the "Waste details summary" page
    And I should see the text "Waste details summary for Waste Site 1"

    When I click on the "Upload file" button
    Then I should see the text "File can't be blank"
    And I should not see the text "Imported file contains validation errors. Correct these in the file, and the import the file again"

    When I upload "testdocx.docx" to "returns_slft_site_resource_item_default_file_data"
    And I click on the "Upload file" button
    Then I should see the text "Invalid file type"
    And I should not see the text "Imported file contains validation errors. Correct these in the file, and the import the file again"
    And I should not see the text "testdocx.docx"

    When I upload "test-not-a-csv-file.csv" to "returns_slft_site_resource_item_default_file_data"
    And I click on the "Upload file" button
    Then I should see the text "File is invalid CSV file: Illegal quoting in line 1"
    And I should not see the text "Imported file contains validation errors. Correct these in the file, and the import the file again"
    And I should not see the text "test-not-a-csv-file.csv"

    When I upload "test-csv-wrong-no-cols.csv" to "returns_slft_site_resource_item_default_file_data"
    And I click on the "Upload file" button
    Then I should see the text "File is invalid, greater than 60% of rows had the wrong number of columns"
    And I should not see the text "Imported file contains validation errors. Correct these in the file, and the import the file again"
    And I should not see the text "test-csv-wrong-no-cols.csv"

    When I upload "test-invalid-slft-waste-upload.csv" to "returns_slft_site_resource_item_default_file_data"
    And I click on the "Upload file" button
    Then I should see the text "Imported file contains validation errors. Correct these in the file, and the import the file again"
    And I should see the text "01 01 01/Entry 1 has the following errors: Standard tonnage cannot be set when other tonnages are set, Lower tonnage cannot be set when other tonnages are set, Water discount tonnage cannot exceed the waste tonnage"
    And I should see the text "01 03 99/Entry 2 has the following errors: Lower tonnage cannot be set when other tonnages are set, Exempt tonnage cannot be set when other tonnages are set, Water discount tonnage cannot be set when exempt tonnage is set"
    And I should see the text "16 01 03/Entry 3 has the following errors: Standard tonnage cannot be set when other tonnages are set, Exempt tonnage cannot be set when other tonnages are set"
    And I should see the text "10 13 12/Entry 4 has the following error: Description of other exemption reason can't be blank"
    And I should see the text "10 99 99/Invalid has the following errors: EWC code value of 10 99 99 is not allowed, Geographical area value of 0000 is not allowed, Management method value of XX is not allowed, Has this waste been moved out of a non-disposal area (NDA) value of X is not allowed"
    And I should see the text "04 02 16/Incomplete has the following errors: Geographical area can't be blank, Management method can't be blank, Has this waste been moved out of a non-disposal area (NDA) can't be blank, Standard tonnage or the lower or exempt tonnage must be entered"
    And I should not see the text "test-invalid-slft-waste-upload.csv"
    # Test errors are cleared
    When I upload "test-valid-slft-waste-upload.csv" to "returns_slft_site_resource_item_default_file_data"
    And I click on the "Upload file" button
    Then I should not see the text "Invalid file type"
    And I should not see the text "File can't be blank"
    And I should not see the text "File is invalid CSV file"
    And I should not see the text "File is invalid, greater than 60% of rows had errors"
    And I should not see the text "Imported file contains validation errors. Correct these in the file, and the import the file again"

  Scenario: Upload a valid file
    Given I have signed in "portal.waste.new" and password "Password1!"
    When I click on the "Create SLfT return" menu item
    Then I should see the "Return summary" page
    When I set a period of "2018/19" and "October to December (Quarter 3)"
    Then I should see the "Return summary" page

    When I click on the 1 st "Add waste details" link
    Then I should see the "Waste details summary" page
    And I should see the text "Waste details summary for Waste Site 1"

    When I upload "test-valid-slft-waste-upload.csv" to "returns_slft_site_resource_item_default_file_data"
    And I click on the "Upload file" button
    Then I should not see the text "Invalid file type"
    And I should not see the text "File can't be blank"
    And I should not see the text "File is invalid CSV file"
    And I should not see the text "File is invalid, greater than 60% of rows had errors"
    And the table of data is displayed
      | EWC code         | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
      | 01 01 01/Entry 1 | 0             | 150              | 0              | 40            | 110           |
      | 01 03 99/Entry 2 | 75            | 0                | 0              | 66            | 9             |
      | 10 13 12/Entry 5 | 0             | 0                | 40             | 0             | 40            |
      | 16 01 03/Entry 3 | 0             | 0                | 40             | 0             | 40            |
      | 19 08 11/Entry 4 | 100           | 0                | 0              | 0             | 100           |

    And I click on the "Upload file" button
    And I should see the text "File can't be blank"
    And the table of data is displayed
      | EWC code         | Lower tonnage | Standard tonnage | Exempt tonnage | Water tonnage | Total tonnage |
      | 01 01 01/Entry 1 | 0             | 150              | 0              | 40            | 110           |
      | 01 03 99/Entry 2 | 75            | 0                | 0              | 66            | 9             |
      | 10 13 12/Entry 5 | 0             | 0                | 40             | 0             | 40            |
      | 16 01 03/Entry 3 | 0             | 0                | 40             | 0             | 40            |
      | 19 08 11/Entry 4 | 100           | 0                | 0              | 0             | 100           |

    When I click on the 3 rd "Edit row" link
    Then I should see the "Details of the 10 13 12 waste for" page
    And I should see "10 13 12 Solid wastes from gas treatment containing hazardous substances" in the "EWC code" select or text field
    And I should see the text "Entry 5" in field "Description of waste"
    And I should see "Dundee" in the "Geographical area" select or text field
    And I should see "Landfill" in the "Management method" select or text field
    And the radio button "No" should be selected in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"

    When I click on the "Continue" button
    Then I should see the sub-title "Provide tonnage details for this waste type"
    And I should see the empty field "Standard tonnage"
    And I should see the empty field "Lower tonnage"
    And I should see the text "40" in field "Exempt tonnage"
    And I should see the empty field "Water discount tonnage"

    When I click on the "Continue" button
    Then I should see the sub-title "Why is some tonnage exempt?"
    And the radio button "Yes" should be selected in answer to the question "NDA"
    And I should see the text "20" in field "NDA tonnage"
    And the radio button "No" should be selected in answer to the question "Restoration"
    And the radio button "Yes" should be selected in answer to the question "Other"
    And I should see the text "20" in field "Other tonnage"
    And I should see the text "Some Reason" in field "Description of other exemption reason"

    When I click on the "Continue" button
    Then I should see the "Waste details summary" page

    When I click on the 4 th "Edit row" link
    Then I should see the "Details of the 16 01 03 waste for" page
    And I should see "16 01 03 End-of-life tyres" in the "EWC code" select or text field
    And I should see the text "Entry 3" in field "Description of waste"
    And I should see "Dundee" in the "Geographical area" select or text field
    And I should see "Landfill" in the "Management method" select or text field
    And the radio button "No" should be selected in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"

    When I click on the "Continue" button
    Then I should see the sub-title "Provide tonnage details for this waste type"
    And I should see the empty field "Standard tonnage"
    And I should see the empty field "Lower tonnage"
    And I should see the text "40" in field "Exempt tonnage"
    And I should see the empty field "Water discount tonnage"

    When I click on the "Continue" button
    Then I should see the sub-title "Why is some tonnage exempt?"
    And the radio button "No" should be selected in answer to the question "NDA"
    And the radio button "Yes" should be selected in answer to the question "Restoration"
    And I should see the text "40" in field "Restoration tonnage"
    And the radio button "No" should be selected in answer to the question "Other"

    When I click on the "Continue" button
    Then I should see the "Waste details summary" page
    When I click on the "Delete all waste types" link
    And if available, click the confirmation dialog
    Then I should see the "Waste details summary" page
    And I should not see the text "01 01 01/Entry 1"
    And I should not see the text "01 03 99/Entry 2"
    And I should not see the text "10 13 12/Entry 5"
    And I should not see the text "16 01 03/Entry 3"
    And I should not see the text "19 08 11/Entry 4"

    # Checks that we're loading the wizard pages correctly
    When I click on the "Add new waste type" link
    Then I should see the sub-title "Provide the following waste details"

    When I enter "06 13 04 Wastes from asbestos processing" in the "EWC code" select or text field
    And I enter "don't breath it" in the "Description of waste" field
    And I select "Falkirk" from the "Geographical area"
    And I select "Landfill" from the "Management method"
    And I check the "Yes" radio button in answer to the question "Has this waste been moved out of a non-disposal area (NDA)?"
    And I click on the "Continue" button

    And I enter "15" in the "Standard tonnage" field
    And I click on the "Continue" button
    Then I should see the "Waste details summary" page

    And I should see the text "06 13 04/don't breath it"
    When I click on the "Add new waste type" link
    Then I should see the "Details of the waste for Waste Site 1" page

    When I click on the "Back" link
    # The delete_all query string should not be retained
    Then I should see the text "06 13 04/don't breath it"

    When I click on the "Save draft" button
    Then I should see the "Waste details summary" page
    When I click on the "Add new waste type" link
    Then I should see the "Details of the waste for Waste Site 1" page

    When I click on the "Back" link
    # The save_draft query string should not be retained
    Then I should see the text "06 13 04/don't breath it"

    When I click on the "Upload file" button
    Then I should see the "Waste details summary" page
    And I click on the "Add new waste type" link
    Then I should see the "Details of the waste for Waste Site 1" page

    When I click on the "Back" link
    # The csv_upload query string should not be retained
    Then I should see the text "06 13 04/don't breath it"

    When I click on the "Back" link
    Then I should see the "Return summary" page