Feature: Slft applications
    As a unauthenticated user
    I want to be able to make a public SLfT application

    Scenario: Slft application with Landfill Operator - Weigh bridge application - multiple site

        # Check signed in user does not have access
        Given I have signed in
        When I go to the "applications/slft/public_landing" page
        Then I should see the "Dashboard" page
        When I go to the "applications/slft/applicant_type?new=true" page
        Then I should see the "Dashboard" page
        When I go to the "applications/slft/existing_agreement" page
        Then I should see the "Dashboard" page

        # Now test with public user
        Given I have signed out
        When I go to the "applications/slft/public_landing" page
        Then I should see the "Online SLfT application form" page
        When I click on the "Continue" link

        Then I should see the "What is your role in the application?" page
        When I click on the "Continue" button
        Then I should receive the message "Select the relevant option that describes your role can't be blank"
        When I check the "Landfill operator" radio button in answer to the question "Select the relevant option that describes your role"
        And I click on the "Continue" button

        Then I should see the "Choose required application" page
        When I click on the "Continue" button
        Then I should receive the message "What application are you completing can't be blank"
        When I check the "Application for an alternative weighing method" radio button in answer to the question "What application are you completing?"
        And I click on the "Continue" button

        Then I should see the "Review or new application" page
        When I click on the "Continue" button
        Then I should receive the message "Is there an existing agreement can't be blank"
        When I check the "Yes" radio button in answer to the question "Is this application a review of an existing agreement?"
        And I click on the "Continue" button
        Then I should receive the message "Existing agreement number can't be blank"
        When I check the "No" radio button in answer to the question "Is this application a review of an existing agreement?"
        And I click on the "Continue" button

        Then I should see the "Landfill operator details" page
        When I click on the "Continue" button
        Then I should receive the message "Organisation name can't be blank"
        And I should receive the message "SLfT registration Number can't be blank"
        And I should receive the message "Telephone number can't be blank"
        And I should receive the message "Email address can't be blank"

        When I enter "Organisation name" in the "Organisation name" field
        And I enter "SLFT-LO-00001" in the "SLfT registration Number" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "test@gmail.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Landfill operator address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Landfill operator address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Landfill operator address" page

        When I click on the "Continue" button
        Then I should see the "Landfill sites" page
        When I click on the "Continue" button
        Then I should receive the message "Please fill in at least one site"
        And I should see a link with text "Add site"

        When I click on the "Add site" link
        Then I should see the "Landfill site details" page

        When I click on the "Back" link
        Then I should see the "Landfill sites" page

        When I click on the "Continue" button
        Then I should receive the message "Please fill in at least one site"
        And I should not see a link with text "Edit"
        And I should not see a link with text "Remove"
        And I should see a link with text "Add site"

        When I click on the "Add site" link
        Then I should see the "Landfill site details" page

        When I click on the "Continue" button
        Then I should receive the message "SEPA licence number can't be blank"
        And I should receive the message "Site name can't be blank"

        When I enter "12345678" in the "SEPA licence number" field
        And I enter "First site" in the "Site name" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I click on the "Back" link
        Then I should see the "Landfill site details" page

        When I click on the "Back" link
        Then I should see the "Landfill sites" page

        When I click on the "Continue" button
        Then I should receive the message "There's an error somewhere in the site First site - please review the site First site section of the return and update it"
        And I should see a link with text "Edit"
        And I should see a link with text "Remove"

        When I click on the "Edit" link
        Then I should see the "Landfill site details" page

        When I click on the "Continue" button
        Then I should see the "Site address" page
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page

        When I click on the "Continue" button
        Then I should see the "Landfill sites" page

        And the table of data is displayed
            | SEPA licence number | Site name  |
            | 12345678            | First site |

        And I should see a link with text "Edit"
        And I should see a link with text "Remove"
        And I should see a link with text "Add site"

        When I click on the "Add site" link

        Then I should see the "Landfill site details" page
        When I enter "121212" in the "SEPA licence number" field
        And I enter "Second site name" in the "Site name" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I enter "NP7 8LB" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Grosmont Wood Farm, Grosmont, ABERGAVENNY, NP7 8LB" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page

        When I click on the "Continue" button
        Then I should see the "Landfill sites" page

        And the table of data is displayed
            | SEPA licence number | Site name        |
            | 12345678            | First site       |
            | 121212              | Second site name |

        And I should see a link with text "Edit"
        And I should see a link with text "Remove"
        And I should see a link with text "Add site"

        When I click on the 2 nd "Remove" link
        And if available, click the confirmation dialog
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name  |
            | 12345678            | First site |
        And I should see a link with text "Add site"

        When I click on the "Edit" link
        Then I should see the "Landfill site details" page
        When I enter "123456789" in the "SEPA licence number" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I click on the "Back" link
        Then I should see the "Landfill site details" page

        When I click on the "Back" link
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name  |
            | 123456789           | First site |

        When I click on the "Edit" link
        Then I should see the "Landfill site details" page
        When I enter "1234567" in the "SEPA licence number" field
        And I enter "Changed site name" in the "Site name" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name         |
            | 1234567             | Changed site name |

        When I click on the "Continue" button

        Then I should see the "Supporting documentation" page

        When I check the "Other" checkbox
        And I click on the "Continue" button
        Then I should receive the message "Other description can't be blank"

        When I enter "A description for the hidden Other text field" in the "applications_slft_applications_supporting_document_other_description" field
        And I click on the "Continue" button
        Then I should see the "Declaration" page
        When I click on the "Back" link
        Then I should see the "Supporting documentation" page
        And I should see the text "A description for the hidden Other text field" in field "applications_slft_applications_supporting_document_other_description"

        When I uncheck the "Other" checkbox
        And I click on the "Continue" button

        Then I should see the "Declaration" page
        When I click on the "Submit" button

        Then I should see the "Declaration" page
        And I should receive the message "The declaration must be accepted"
        And I should receive the message "The requirement to notify declaration must be accepted"
        And I should receive the message "Full name can't be blank"
        And I should receive the message "Job title or position can't be blank"
        And I should receive the message "Telephone can't be blank"
        And I should receive the message "Email address can't be blank"

        When I enter "Organisation name" in the "Full name" field
        And I enter "12345678" in the "Job title or position" field
        And I enter "0123456789" in the "Telephone" field
        And I enter "test@gmail.com" in the "Email address" field
        And I check the "applications_slft_applications_declaration" checkbox
        And I check the "applications_slft_applications_change_declaration" checkbox
        And I click on the "Submit" button

        Then I should see the "Your application has been sent to Revenue Scotland" page

        # test case to download Receipt on last application submit page
        When I click on the "Download details of application" link to download a file
        Then I should see the downloaded "CASE" content of "SLFT"

        # test case to check upload, download and remove multiple supporting document functionality

        # Click "Upload document" button without selecting a file
        When I click on the "Upload file" button
        Then I should see the "Your application has been sent to Revenue Scotland" page
        And I should receive the message "File can't be blank"

        # Upload document
        When I upload "testjpg.jpg" to "applications_slft_applications_resource_item_default_file_data"
        And I enter "Other - This is a docx file" in the "Description of the uploaded file (optional)" field
        And I click on the "Upload file" button
        Then I should see the "Your application has been sent to Revenue Scotland" page
        And I should see a link to the file "testjpg.jpg"

        # Upload one more document
        When I upload "testdocx.docx" to "applications_slft_applications_resource_item_default_file_data"
        And I enter "Other - This is a docx file" in the "Description of the uploaded file (optional)" field
        And I click on the "Upload file" button
        Then I should see the "Your application has been sent to Revenue Scotland" page
        And I should see a link to the file "testdocx.docx"

        # Remove document
        And I click on the 1 st "Delete file" button
        Then I should see the "Your application has been sent to Revenue Scotland" page
        And I should not see a link to the file "testjpg.jpg"

        # Download document
        When I click on the "testdocx.docx" link to download a file
        Then I should see the downloaded content "testdocx.docx"

    Scenario: Slft application with Landfill Operator - Non disposal area

        When I go to the "applications/slft/public_landing" page
        Then I should see the "Online SLfT application form" page

        When I click on the "Continue" link
        Then I should see the "What is your role in the application?" page

        When I check the "Landfill operator" radio button in answer to the question "Select the relevant option that describes your role"
        And I click on the "Continue" button
        Then I should see the "Choose required application" page

        When I check the "Application for an alternative weighing method" radio button in answer to the question "What application are you completing?"
        And I click on the "Continue" button
        Then I should see the "Review or new application" page

        When I check the "No" radio button in answer to the question "Is this application a review of an existing agreement?"
        And I click on the "Continue" button
        Then I should see the "Landfill operator details" page

        When I click on the "Back" link
        Then I should see the "Review or new application" page

        When I click on the "Back" link
        Then I should see the "Choose required application" page

        When I check the "Application for a non-disposal area" radio button in answer to the question "What application are you completing?"
        And I click on the "Continue" button
        Then I should see the "Review or new application" page

        When I click on the "Continue" button
        Then I should receive the message "Is there an existing agreement can't be blank"

        When I check the "No" radio button in answer to the question "Is this application a review of an existing agreement?"
        And I click on the "Continue" button
        Then I should see the "Landfill operator details" page

        When I enter "Organisation name" in the "Organisation name" field
        And I enter "SLFT-LO-00001" in the "SLfT registration Number" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "test@gmail.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Landfill operator address" page

        When I click on the "Back" link
        Then I should see the "Landfill operator details" page
        When I click on the "Back" link
        Then I should see the "Review or new application" page
        When I click on the "Back" link
        Then I should see the "Choose required application" page
        When I click on the "Continue" button
        Then I should see the "Review or new application" page

        When I click on the "Continue" button
        Then I should see the "Landfill operator details" page
        And I should see the text "Organisation name" in field "Organisation name"
        And I should see the text "SLFT-LO-00001" in field "SLfT registration Number"
        And I should see the text "0123456789" in field "Telephone number"
        And I should see the text "test@gmail.com" in field "Email"

        When I click on the "Continue" button
        Then I should see the "Landfill operator address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Landfill operator address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Landfill operator address" page
        When I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And I should see a link with text "Add site"

        When I click on the "Add site" link
        Then I should see the "Landfill site details" page
        When I enter "12345678" in the "SEPA licence number" field
        And I enter "First site" in the "Site name" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page
        When I click on the "Continue" button
        Then I should see the "Non-disposal area site details" page

        When I click on the "Continue" button
        Then I should receive the message "Specify the intended use of the area(s) to which material will be temporarily deposited can't be blank"
        And I should receive the message "Estimated timescale can't be blank"
        And I should receive the message "Type of waste can't be blank"
        And I should receive the message "Confirm the start date for the non-disposal area(s) can't be blank"

        When I enter "12345678" in the "Specify the intended use of the area(s) to which material will be temporarily deposited" field
        And I enter "12345678" in the "Provide the length of time the material will be temporarily stored" field
        And I enter "12345678" in the "Provide the types of material to be temporarily stored (i.e. EWC and waste description)" field
        And I enter "08-08-2020" in the "Confirm the start date for the non-disposal area(s)" date field
        And I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name  |
            | 12345678            | First site |
        And I should see a link with text "Edit"
        And I should see a link with text "Remove"
        And I should see a link with text "Add site"

        When I click on the "Continue" button
        Then I should see the "Supporting documentation" page

        When I check the "Other" checkbox
        And I enter "A description for the hidden Other text field" in the "applications_slft_applications_supporting_document_other_description" field
        And I click on the "Continue" button
        Then I should see the "Declaration" page

        When I enter "Organisation name" in the "Full name" field
        And I enter "12345678" in the "Job title or position" field
        And I enter "0123456789" in the "Telephone" field
        And I enter "test@gmail.com" in the "Email address" field
        And I check the "applications_slft_applications_declaration" checkbox
        And I check the "applications_slft_applications_change_declaration" checkbox
        And I click on the "Submit" button
        Then I should see the "Your application has been sent to Revenue Scotland" page

    Scenario: Slft application with Landfill Operator - Restoration notification

        When I go to the "applications/slft/public_landing" page
        Then I should see the "Online SLfT application form" page

        When I click on the "Continue" link
        Then I should see the "What is your role in the application?" page
        When I check the "Landfill operator" radio button in answer to the question "Select the relevant option that describes your role"
        And I click on the "Continue" button
        Then I should see the "Choose required application" page

        When I check the "Restoration notification" radio button in answer to the question "What application are you completing?"
        And I click on the "Continue" button
        Then I should see the "Review or new application" page
        When I check the "No" radio button in answer to the question "Is this application a review of an existing agreement?"
        And I click on the "Continue" button
        Then I should see the "Landfill operator details" page

        When I enter "Organisation name" in the "Organisation name" field
        And I enter "SLFT-LO-00001" in the "SLfT registration Number" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "test@gmail.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Landfill operator address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Landfill operator address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Landfill operator address" page
        When I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And I should see a link with text "Add site"

        When I click on the "Add site" link
        Then I should see the "Landfill site details" page
        When I enter "12345678" in the "SEPA licence number" field
        And I enter "First site" in the "Site name" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page
        When I click on the "Continue" button
        Then I should see the "Site restoration details" page
        And I should see the text "Provide an estimate of the total tonnage and specific type of material required to restore the area(s) included in the agreement"
        And I should not see the button with text "Delete row"

        When I click on the "Continue" button
        Then I should receive the message "Is this a part or full site restoration can't be blank"
        And I should receive the message "Estimated timescale can't be blank"
        And I should receive the message "Type of waste can't be blank"
        And I should receive the message "Estimated tonnage can't be blank"

        When I check the "Full" radio button in answer to the question "Is this a part or full site restoration?"
        And I enter "12345678" in the "Provide an estimate of the timescale for the restoration exercise" field
        And I click on the "Continue" button
        Then I should receive the message "Type of waste can't be blank"
        And I should receive the message "Estimated tonnage can't be blank"

        When I enter "Plastic" in the "applications_slft_sites_applications_slft_wastes_0_type_of_waste" field
        And I enter "123" in the "applications_slft_sites_applications_slft_wastes_0_estimated_tonnage" field
        And I click on the "Add row" button
        Then I should see at least one button with text "Delete row"

        When I enter "bio degradable" in the "applications_slft_sites_applications_slft_wastes_1_type_of_waste" field
        And I enter "678" in the "applications_slft_sites_applications_slft_wastes_1_estimated_tonnage" field
        And I click on the 1 st "Delete row" button
        Then I should not see the button with text "Delete row"

        When I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name  |
            | 12345678            | First site |
        And I should see a link with text "Edit"
        And I should see a link with text "Remove"
        And I should see a link with text "Add site"

        When I click on the "Continue" button
        Then I should see the "Supporting documentation" page

        When I check the "Details of how you have calculated the total of site restoration material" checkbox
        And I click on the "Continue" button
        Then I should see the "Declaration" page

        When I enter "Organisation name" in the "Full name" field
        And I enter "12345678" in the "Job title or position" field
        And I enter "0123456789" in the "Telephone" field
        And I enter "test@gmail.com" in the "Email address" field
        And I check the "applications_slft_applications_declaration" checkbox
        And I check the "applications_slft_applications_change_declaration" checkbox
        And I click on the "Submit" button
        Then I should see the "Your application has been sent to Revenue Scotland" page

    Scenario: Slft application with Landfill Operator - Water discounted
        When I go to the "applications/slft/public_landing" page
        Then I should see the "Online SLfT application form" page
        When I click on the "Continue" link
        Then I should see the "What is your role in the application?" page
        When I check the "Landfill operator" radio button in answer to the question "Select the relevant option that describes your role"
        And I click on the "Continue" button
        Then I should see the "Choose required application" page
        When I check the "Application to receive water discounted waste" radio button in answer to the question "What application are you completing?"
        And I click on the "Continue" button
        Then I should see the "Review or new application" page
        When I check the "No" radio button in answer to the question "Is this application a review of an existing agreement?"
        And I click on the "Continue" button
        Then I should see the "Landfill operator details" page

        When I enter "Organisation name" in the "Organisation name" field
        And I enter "SLFT-LO-00001" in the "SLfT registration Number" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "test@gmail.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Landfill operator address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Landfill operator address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Landfill operator address" page
        When I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And I should see a link with text "Add site"

        When I click on the "Add site" link
        Then I should see the "Landfill site details" page
        When I enter "12345678" in the "SEPA licence number" field
        And I enter "First site" in the "Site name" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page
        When I click on the "Continue" button
        Then I should see the "Site waste details" page
        And I should see the text "Enter details of the types of waste that you will receive at the site and state whether they will contribute to leachate"

        When I click on the "Continue" button
        Then I should receive the message "Will the waste undergo further treatment at the landfill site to reduce the water content can't be blank"

        When I enter "No" in the "Will the waste undergo further treatment at the landfill site to reduce the water content" field
        And I click on the "Continue" button
        Then I should receive the message "Type of waste can't be blank"
        And I should receive the message "Final destination can't be blank"
        And I should receive the message "Use can't be blank"

        When I enter "Plastic" in the "applications_slft_sites_applications_slft_wastes_0_type_of_waste" field
        And I enter "Bracknell" in the "applications_slft_sites_applications_slft_wastes_0_final_destination" field
        And I enter "use " in the "applications_slft_sites_applications_slft_wastes_0_use" field
        And I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name  |
            | 12345678            | First site |
        And I should see a link with text "Edit"
        And I should see a link with text "Remove"
        And I should see a link with text "Add site"

        When I click on the "Continue" button
        Then I should see the "Waste producer details" page

        When I click on the "Continue" button
        Then I should receive the message "Organisation name can't be blank"
        And I should receive the message "Telephone number can't be blank"
        And I should receive the message "Email address can't be blank"

        When I enter "Waste organisation" in the "Organisation name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "waste@gmail.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Waste producer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Waste producer address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Waste producer address" page
        When I click on the "Continue" button
        Then I should see the "Declarations" page

        When I enter "Full Name" in the "Full name" field
        And I enter "12345678" in the "Job title or position" field
        And I enter "0123456789" in the "Telephone" field
        And I enter "fullname@gmail.com" in the "Email address" field
        And I check the "applications_slft_applications_declaration" checkbox
        And I click on the "Submit" button
        Then I should see the "Your application has been sent to Revenue Scotland" page

    Scenario: Slft application with Waste producer - Water discounted for multiple sites and multiple case reference
        When I go to the "applications/slft/public_landing" page
        Then I should see the "Online SLfT application form" page

        When I click on the "Continue" link
        Then I should see the "What is your role in the application?" page
        When I check the "Waste producer" radio button in answer to the question "Select the relevant option that describes your role"
        And I click on the "Continue" button
        Then I should see the "Water discount renewal, review or new" page

        When I click on the "Continue" button
        Then I should receive the message "Is there an existing agreement can't be blank"
        When I check the "Yes" radio button in answer to the question "Does this form relate to an existing water discount agreement?"
        And I click on the "Continue" button
        Then I should receive the message "Existing agreement number can't be blank"
        And I should receive the message "Is this a renewal or review of an existing water discount agreement can't be blank"

        When I check the "Review" radio button in answer to the question "Is this a renewal or review of an existing water discount agreement?"
        And I enter "12345678" in the "Provide the previously approved water discount agreement number" field
        And I click on the "Continue" button
        Then I should see the "Waste producer details" page

        When I click on the "Continue" button
        Then I should receive the message "Organisation name can't be blank"
        And I should receive the message "Telephone number can't be blank"
        And I should receive the message "Email address can't be blank"

        When I enter "Waste organisation" in the "Organisation name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "waste@gmail.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Waste producer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Waste producer address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Waste producer address" page
        When I click on the "Continue" button
        Then I should see the "About the waste water" page

        When I click on the "Continue" button
        Then I should receive the message "Choose the relevant options below which describes how the water to be discounted relates to the waste can't be blank"

        When I check the "The water in the waste is present because it has been used for extraction of minerals" radio button in answer to the question "Choose the relevant options below which describes how the water to be discounted relates to the waste"
        And I click on the "Continue" button
        Then I should see the "Banned liquid waste" page

        When I click on the "Continue" button
        Then I should receive the message "None of the waste material is a liquid waste and banned from landfill sites must be accepted"
        When I check the "applications_slft_applications_not_banned_waste" checkbox
        And I click on the "Continue" button
        Then I should see the "Tell us about the waste" page

        When I click on the "Continue" button
        Then I should receive the message "What type of waste is produced can't be blank"
        And I should receive the message "How is the waste produced can't be blank"
        And I should receive the message "How is water added can't be blank"
        When I enter "liquid waste" in the "What type of waste is produced" field
        And I enter "Wastes may be generated during the extraction of raw materials" in the "How is the waste produced" field
        And I enter "piping the water" in the "How is water added" field
        And I click on the "Continue" button
        Then I should see the "Tell us about the water content" page

        When I click on the "Continue" button
        And I should receive the message "Is there naturally occurring water in the waste can't be blank"
        And I should receive the message "What is the water content of the waste can't be blank"
        Then I should receive the message "What is the added water content can't be blank"

        When I check the "Yes" radio button in answer to the question "Is there naturally occurring water in the waste?"
        And I enter "102" in the "What is the water content of the waste" field
        And I enter "102" in the "What is the added water content" field
        And I click on the "Continue" button
        Then I should receive the message "What percentage is naturally occurring can't be blank"
        And I should receive the message "What is the water content of the waste must be less than 100"
        And I should receive the message "What is the added water content must be less than 100"

        When I check the "No" radio button in answer to the question "Is there naturally occurring water in the waste?"
        And I enter " 5" in the "What is the water content of the waste" field
        And I enter "5" in the "What is the added water content" field
        And I click on the "Continue" button
        Then I should see the "Water treatment" page

        When I click on the "Continue" button
        Then I should receive the message "If yes, what treatment have you undertaken can't be blank"
        And I should receive the message "If no, what reasons are there for treatment not to have been possible can't be blank"
        When I enter "Yes, Sewage treatment" in the "If yes, what treatment have you undertaken" field
        And I enter "--" in the "If no, what reasons are there for treatment not to have been possible" field
        And I click on the "Continue" button
        Then I should see the "Start date" page

        When I click on the "Continue" button
        Then I should receive the message "Provide the date the agreement should start from can't be blank"
        When I enter "08-08-2020" in the "Provide the date the agreement should start from" date field
        And I click on the "Continue" button
        Then I should see the "Landfill sites" page

        When I click on the "Continue" button
        Then I should receive the message "Please fill in at least one site"
        And I should see a link with text "Add site"

        When I click on the "Add site" link
        Then I should see the "Landfill site details" page
        When I click on the "Continue" button
        Then I should receive the message "SEPA licence number can't be blank"
        And I should receive the message "Site name can't be blank"
        And I should receive the message "Landfill operator can't be blank"
        And I should receive the message "Landfill operator SLfT registration number can't be blank"

        When I enter "12345678" in the "SEPA licence number" field
        And I enter "First site" in the "Site name" field
        And I enter "John" in the "Landfill operator" field
        And I enter "SLFT-LO-00001" in the "Landfill operator SLfT registration number" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page
        When I click on the "Continue" button
        Then I should see the "Separate mailing address for landfill operator" page
        When I click on the "Continue" button
        Then I should receive the message "Does the landfill site operator have a separate mailing address can't be blank"
        When I check the "No" radio button in answer to the question "Does the landfill site operator have a separate mailing address?"
        And I click on the "Continue" button
        Then I should see the "Site waste details" page

        When I click on the "Continue" button
        Then I should receive the message "Provide an estimate of the weight in tonnes which will be sent to this site annually can't be blank"
        And I should receive the message "Type of waste can't be blank"
        When I enter "Liquid Waste" in the "What type of waste will be sent to this site" field
        And I enter " 12" in the "Provide an estimate of the weight in tonnes which will be sent to this site annually" field
        And I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name  | Landfill operator | Landfill operator SLfT registration number |
            | 12345678            | First site | John              | SLFT-LO-00001                              |
        And I should see a link with text "Add site"

        When I click on the "Add site" link
        Then I should see the "Landfill site details" page
        When I enter "9876543" in the "SEPA licence number" field
        And I enter "Second site" in the "Site name" field
        And I enter "Mark" in the "Landfill operator" field
        And I enter "SLFT-LO-00002" in the "Landfill operator SLfT registration number" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I enter "NP7 8LB" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Grosmont Wood Farm, Grosmont, ABERGAVENNY, NP7 8LB" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page
        When I click on the "Continue" button
        Then I should see the "Separate mailing address for landfill operator" page
        When I check the "No" radio button in answer to the question "Does the landfill site operator have a separate mailing address?"
        And I click on the "Continue" button
        Then I should see the "Site waste details" page

        When I enter "Solid Waste" in the "What type of waste will be sent to this site" field
        And I enter "11" in the "Provide an estimate of the weight in tonnes which will be sent to this site annually" field
        And I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name   | Landfill operator | Landfill operator SLfT registration number |
            | 12345678            | First site  | John              | SLFT-LO-00001                              |
            | 9876543             | Second site | Mark              | SLFT-LO-00002                              |

        When I click on the "Add site" link
        Then I should see the "Landfill site details" page
        When I enter "8976182" in the "SEPA licence number" field
        And I enter "Third site" in the "Site name" field
        And I enter "Steve" in the "Landfill operator" field
        And I enter "12345" in the "Landfill operator SLfT registration number" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I enter "RG30 6XT" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "9 Rydal Avenue, Tilehurst, READING, RG30 6XT" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page
        When I click on the "Continue" button
        Then I should see the "Separate mailing address for landfill operator" page

        When I check the "No" radio button in answer to the question "Does the landfill site operator have a separate mailing address?"
        And I click on the "Continue" button
        Then I should see the "Site waste details" page
        When I enter "plastic" in the "What type of waste will be sent to this site" field
        And I enter "88" in the "Provide an estimate of the weight in tonnes which will be sent to this site annually" field
        And I click on the "Continue" button
        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name   | Landfill operator | Landfill operator SLfT registration number |
            | 12345678            | First site  | John              | SLFT-LO-00001                              |
            | 9876543             | Second site | Mark              | SLFT-LO-00002                              |
            | 8976182             | Third site  | Steve             | 12345                                      |

        When I click on the "Continue" button
        Then I should see the "Supporting documentation" page
        When I click on the "Continue" button
        Then I should see the "Supporting documentation" page
        And I should receive the message "Evidence of the water content (naturally and added) of the waste must be accepted"
        When I check the "Evidence of the water content (naturally and added) of the waste (mandatory)" checkbox
        And I click on the "Continue" button
        Then I should see the "Declaration" page

        When I enter "Organisation name" in the "Full name" field
        And I enter "12345678" in the "Job title or position" field
        And I enter "0123456789" in the "Telephone" field
        And I enter "test@gmail.com" in the "Email address" field
        And I check the "applications_slft_applications_declaration" checkbox
        And I check the "applications_slft_applications_change_declaration" checkbox
        And I click on the "Submit" button
        Then I should see the "Your application has been sent to Revenue Scotland" page
        # Test case to check how many case references are generated for this scenario
        And I should store the generated value with id "notification_banner_reference"
        And I should see 3 generated values in "notification_banner_reference"
        And I should see the text "%r{CMSS\d{8}, CMSS\d{8}, and CMSS\d{8}}"

        # test case to download Receipt on last application submit page
        When I click on the "Download details of application" link to download a file
        Then I should see the downloaded "CASE" content of "SLFT"

        # test case to check upload, download and remove multiple supporting document functionality

        # Upload document
        When I upload "testjpg.jpg" to "applications_slft_applications_resource_item_default_file_data"
        And I enter "Other - This is a docx file" in the "Description of the uploaded file (optional)" field
        And I click on the "Upload file" button
        Then I should see the "Your application has been sent to Revenue Scotland" page
        And I should see a link to the file "testjpg.jpg"

        # Upload one more document
        When I upload "testdocx.docx" to "applications_slft_applications_resource_item_default_file_data"
        And I enter "Other - This is a docx file" in the "Description of the uploaded file (optional)" field
        And I click on the "Upload file" button
        Then I should see the "Your application has been sent to Revenue Scotland" page
        And I should see a link to the file "testdocx.docx"

        # Remove document
        When I click on the 1 st "Delete file" button
        Then I should see the "Your application has been sent to Revenue Scotland" page
        And I should not see a link to the file "testjpg.jpg"

        # Download document
        When I click on the "testdocx.docx" link to download a file
        Then I should see the downloaded content "testdocx.docx"

    # This scenario is of type Waste producer - Water discounted
    #    Two sites are added with same SLft registration number for both
    #    Back office will return only one case reference number
    Scenario: Slft application with Waste producer - Water discounted for multiple sites and single case reference
        When I go to the "applications/slft/public_landing" page
        Then I should see the "Online SLfT application form" page
        When I click on the "Continue" link

        Then I should see the "What is your role in the application?" page
        When I check the "Waste producer" radio button in answer to the question "Select the relevant option that describes your role"
        And I click on the "Continue" button

        Then I should see the "Water discount renewal, review or new" page
        When I check the "No" radio button in answer to the question "Does this form relate to an existing water discount agreement?"
        And I click on the "Continue" button

        Then I should see the "Waste producer details" page
        When I enter "Waste organisation" in the "Organisation name" field
        And I enter "0123456789" in the "Telephone number" field
        And I enter "waste@gmail.com" in the "Email" field
        And I click on the "Continue" button
        Then I should see the "Waste producer address" page

        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Waste producer address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Waste producer address" page
        When I click on the "Continue" button
        Then I should see the "About the waste water" page
        When I check the "The water has been added to the waste for transportation to disposal" radio button in answer to the question "Choose the relevant options below which describes how the water to be discounted relates to the waste"
        And I click on the "Continue" button

        Then I should see the "Banned liquid waste" page
        When I check the "applications_slft_applications_not_banned_waste" checkbox
        And I click on the "Continue" button

        Then I should see the "Tell us about the waste" page
        When I enter "liquid waste" in the "What type of waste is produced" field
        And I enter "Wastes may be generated during the extraction of raw materials" in the "How is the waste produced" field
        And I enter "piping the water" in the "How is water added" field
        And I click on the "Continue" button

        Then I should see the "Tell us about the water content" page
        When I check the "No" radio button in answer to the question "Is there naturally occurring water in the waste?"
        And I enter "5" in the "What is the water content of the waste" field
        And I enter "5" in the "What is the added water content" field
        And I click on the "Continue" button

        Then I should see the "Water treatment" page
        When I enter "No, was not sure which tratment to apply" in the "If no, what reasons are there for treatment not to have been possible" field
        And I click on the "Continue" button

        Then I should see the "Start date" page
        When I enter "08-08-2020" in the "Provide the date the agreement should start from" date field
        And I click on the "Continue" button

        Then I should see the "Landfill sites" page
        And I should see a link with text "Add site"
        When I click on the "Add site" link

        Then I should see the "Landfill site details" page
        When I enter "12345678" in the "SEPA licence number" field
        And I enter "First site" in the "Site name" field
        And I enter "John" in the "Landfill operator" field
        And I enter "SLFT-LO-00001" in the "Landfill operator SLfT registration number" field
        And I click on the "Continue" button

        Then I should see the "Site address" page
        When I enter "LU1 1AA" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Royal Mail, Luton Delivery Office 9-11, Dunstable Road, LUTON, LU1 1AA" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page

        When I click on the "Continue" button
        Then I should see the "Separate mailing address for landfill operator" page
        When I check the "No" radio button in answer to the question "Does the landfill site operator have a separate mailing address?"
        And I click on the "Continue" button

        Then I should see the "Site waste details" page
        When I enter "Liquid Waste" in the "What type of waste will be sent to this site" field
        And I enter "12" in the "Provide an estimate of the weight in tonnes which will be sent to this site annually" field
        And I click on the "Continue" button

        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name  | Landfill operator | Landfill operator SLfT registration number |
            | 12345678            | First site | John              | SLFT-LO-00001                              |


        And I should see a link with text "Add site"
        When I click on the "Add site" link

        Then I should see the "Landfill site details" page
        When I enter "9876543" in the "SEPA licence number" field
        And I enter "Second site" in the "Site name" field
        And I enter "Mark" in the "Landfill operator" field
        And I enter "SLFT-LO-00001" in the "Landfill operator SLfT registration number" field
        And I click on the "Continue" button
        Then I should see the "Site address" page

        When I enter "NP7 8LB" in the "address_summary_postcode" field
        And I click on the "Find address" button
        Then I should see the "Site address" page
        When I select "Grosmont Wood Farm, Grosmont, ABERGAVENNY, NP7 8LB" from the "search_results"
        And I click on the "Use this address" button when available
        Then I should see the "Site address" page

        When I click on the "Continue" button
        Then I should see the "Separate mailing address for landfill operator" page
        When I check the "No" radio button in answer to the question "Does the landfill site operator have a separate mailing address?"
        And I click on the "Continue" button

        Then I should see the "Site waste details" page
        When I enter "Solid Waste" in the "What type of waste will be sent to this site" field
        And I enter "11" in the "Provide an estimate of the weight in tonnes which will be sent to this site annually" field
        And I click on the "Continue" button

        Then I should see the "Landfill sites" page
        And the table of data is displayed
            | SEPA licence number | Site name   | Landfill operator | Landfill operator SLfT registration number |
            | 12345678            | First site  | John              | SLFT-LO-00001                              |
            | 9876543             | Second site | Mark              | SLFT-LO-00001                              |

        And I click on the "Continue" button

        Then I should see the "Supporting documentation" page
        # Check that evidence of water is content is mandatory even though other items checked
        When I check the "Results of the analysis referred to in your approval letter (Review/Renew only)" checkbox
        And I click on the "Continue" button
        Then I should see the "Supporting documentation" page
        And I should receive the message "Evidence of the water content (naturally and added) of the waste must be accepted"
        When I check the "Evidence of the water content (naturally and added) of the waste (mandatory)" checkbox
        And I click on the "Continue" button

        Then I should see the "Declaration" page
        When I enter "Organisation name" in the "Full name" field
        And I enter "12345678" in the "Job title or position" field
        And I enter "0123456789" in the "Telephone" field
        And I enter "test@gmail.com" in the "Email address" field
        And I check the "applications_slft_applications_declaration" checkbox
        And I check the "applications_slft_applications_change_declaration" checkbox
        And I click on the "Submit" button

        Then I should see the "Your application has been sent to Revenue Scotland" page
        # Test case to check how many case references are generated for this scenario
        And I should store the generated value with id "notification_banner_reference"
        And I should see 1 generated values in "notification_banner_reference"
