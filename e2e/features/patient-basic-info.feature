# Grounded in wabi-flutter-dev:
#   lib/features/clinic/intake/widgets/basic_intake_panels.dart  (BasicInfoPanel, Diagnosis multi-select)
#   lib/features/clinic/intake/widgets/intake_shared_types.dart  (DateInput calendar: firstDate = now-120y, lastDate = now)
#   lib/features/clinic/intake/screens/new_patient_intake_screen.dart  (_complete save handler, duplicate dialog, toasts)
#   lib/utils/validators.dart  (Validators.name)
# Only First Name + Last Name are hard-validated on save. Every other field is optional.

Feature: Patient Profile — Basic Information
  As a clinician onboarding a new patient
  I want to capture patient demographics and parent/guardian details
  So that the patient record is created and the intake workflow can begin.
  Basic Information is the first ("*") required Profile section; saving it creates
  the patient record. Only First Name and Last Name are enforced; DOB, Gender,
  Diagnoses and all guardian fields are optional.

  Background:
    Given I am logged in as a clinician
    And I am on the "Patients" list
    When I click "New Patient"
    Then the "Patient Demographics" card titled "Basic patient information" is shown
    And the "Parent/Guardian Contact" card titled "Guardian and emergency contact details" is shown
    And the active Profile section is "Basic Information *"

  # ── Happy path ───────────────────────────────────────────────────────────
  @smoke @positive
  Scenario: Create a patient with only the required First and Last name
    When I enter "Rujitha" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I click "Save"
    Then I see the toast "Patient 'Rujitha Kannan' created successfully"
    And the "Basic Information" section shows a green completion checkmark
    And the "Patient Profile" counter reads "1 / 2 completed"

  @smoke @positive
  Scenario: Create a patient with full demographics and guardian details
    When I enter "Rujitha" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I pick "05/12/2018" in the "Date of Birth" calendar
    And I select "Female" from the "Gender" dropdown
    And I open the "Diagnoses (select all that apply)" field and check "ASD (Autism Spectrum Disorder)"
    And I enter "Priya" in the guardian "First Name"
    And I enter "Kannan" in the guardian "Last Name"
    And I select "Mother" from the "Relationship to Patient" dropdown
    And I enter "(555) 123-4567" in "Phone Number"
    And I enter "priya.kannan@example.com" in "Email Address"
    And I click "Save"
    Then I see the toast "Patient 'Rujitha Kannan' created successfully"

  @positive
  Scenario: Re-saving an existing patient shows the update toast, not the create toast
    Given a patient "Rujitha Kannan" has already been created in this session
    When I change "Phone Number" to "(555) 000-1111"
    And I click "Save"
    Then I see the toast "Patient updated successfully"
    And no duplicate-patient dialog is shown

  # ── Required-field validation (First / Last name) ────────────────────────
  @negative
  Scenario: Saving with both names empty is rejected
    When I leave "First Name" and "Last Name" empty
    And I click "Save"
    Then I see the validation error "First name and last name are required"
    And no patient record is created

  @negative
  Scenario: Saving with only First Name is rejected
    When I enter "Rujitha" in "First Name"
    And I leave "Last Name" empty
    And I click "Save"
    Then I see the validation error "First name and last name are required"

  @negative
  Scenario: Saving with only Last Name is rejected
    When I enter "Kannan" in "Last Name"
    And I leave "First Name" empty
    And I click "Save"
    Then I see the validation error "First name and last name are required"

  @negative @edge
  Scenario: Whitespace-only names count as empty
    When I enter "   " in "First Name"
    And I enter "   " in "Last Name"
    And I click "Save"
    Then I see the validation error "First name and last name are required"

  # ── Name-format validation matrix (Validators.name) ──────────────────────
  # Regex ^[a-zA-ZÀ-ÿ\s\-']+$ ; min length 2 after trim.
  @negative @data
  Scenario Outline: First-name format is rejected with the exact message
    When I enter "<first>" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I click "Save"
    Then I see the validation error "<message>"

    Examples:
      | first    | message                              |
      | R        | First name must be at least 2 characters |
      | R2       | First name should only contain letters   |
      | Ruj1tha  | First name should only contain letters   |
      | 12345    | First name should only contain letters   |
      | R@ji     | First name should only contain letters   |
      | Ruji_tha | First name should only contain letters   |
      | 🙂🙂     | First name should only contain letters   |

  @negative @data
  Scenario Outline: Last-name format is validated after First name passes
    When I enter "Rujitha" in "First Name"
    And I enter "<last>" in "Last Name"
    And I click "Save"
    Then I see the validation error "<message>"

    Examples:
      | last     | message                               |
      | K        | Last name must be at least 2 characters |
      | Kann4n   | Last name should only contain letters   |
      | 99       | Last name should only contain letters   |

  @positive @edge @data
  Scenario Outline: Valid unicode, hyphenated and apostrophe names are accepted
    When I enter "<first>" in "First Name"
    And I enter "<last>" in "Last Name"
    And I click "Save"
    Then no name validation error is shown
    And the patient is created

    Examples:
      | first      | last        |
      | José       | Muñoz       |
      | Anne-Marie | O'Brien     |
      | Zoë        | Åkerlund    |
      | Mary Jane  | Van Der Berg|

  @edge @security
  Scenario: A name containing HTML/script is rejected as non-letters (no injection)
    When I enter "<script>alert(1)</script>" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I click "Save"
    Then I see the validation error "First name should only contain letters"
    And no script executes on the page

  @edge @data
  Scenario Outline: Very long names are handled without truncation error
    When I enter a "<length>"-character alphabetic string in "First Name"
    And I enter "Kannan" in "Last Name"
    And I click "Save"
    Then the save either succeeds or surfaces a backend length error toast, never a client crash

    Examples:
      | length |
      | 256    |
      | 1000   |

  # ── Date of Birth (calendar DateInput; range now-120y .. today) ──────────
  @positive
  Scenario: DOB calendar opens to five years ago when the field is empty
    When I open the "Date of Birth" calendar with the field empty
    Then the calendar initial focus is roughly 5 years before today
    And future dates beyond today are not selectable

  @edge
  Scenario: DOB cannot be a future date via the picker
    When I open the "Date of Birth" calendar
    Then dates after today are disabled
    And the latest selectable date is today

  @edge
  Scenario: DOB cannot be more than 120 years in the past via the picker
    When I open the "Date of Birth" calendar
    Then dates before "01/01/<currentYear-120>" are disabled

  @positive @edge
  Scenario: A backend-hydrated ISO date is normalised to MM/DD/YYYY on display
    Given a patient whose stored date_of_birth is "2018-05-12"
    When I reopen Basic Information
    Then the "Date of Birth" field displays "05/12/2018" and never the ISO form

  @edge
  Scenario: Saving Basic Information with no DOB still succeeds (DOB optional)
    When I enter "Rujitha" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I leave "Date of Birth" empty
    And I click "Save"
    Then the patient is created without a date of birth

  # ── Gender dropdown ──────────────────────────────────────────────────────
  @positive @data
  Scenario Outline: Gender dropdown offers exactly Male and Female
    When I open the "Gender" dropdown
    Then the only options are "Male" and "Female"
    When I select "<gender>"
    Then the "Gender" trigger shows "<gender>"

    Examples:
      | gender |
      | Male   |
      | Female |

  @edge
  Scenario: Gender placeholder reads "Select gender" until a choice is made
    When I open Basic Information for a new patient
    Then the "Gender" dropdown shows the placeholder "Select gender"

  # ── Diagnoses multi-select dialog ────────────────────────────────────────
  @positive
  Scenario: Open the Diagnoses picker and select multiple curated diagnoses
    When I open the "Diagnoses (select all that apply)" field
    Then a dialog titled "Select diagnoses" opens showing "0 selected"
    When I check "ASD (Autism Spectrum Disorder)"
    And I check "ADHD"
    Then the header updates to "2 selected"
    And selected items float to the top of the list
    When I click "Done"
    Then the field trigger summarises "ADHD, ASD (Autism Spectrum Disorder)"

  @positive
  Scenario: Deselect a diagnosis by unchecking it
    Given the Diagnoses picker has "ADHD" and "Anxiety Disorder" checked
    When I uncheck "ADHD"
    Then the header reads "1 selected"

  @positive
  Scenario: Search filters the curated diagnosis list
    When I open the Diagnoses picker
    And I type "seizure" into "Search diagnoses…"
    Then only "Epilepsy / Seizure Disorder" remains visible

  @positive @edge
  Scenario: Add a custom free-text diagnosis
    When I open the Diagnoses picker
    And I type "Selective Mutism" into "Add custom diagnosis…"
    And I click "Add"
    Then "Selective Mutism" appears checked in the list
    And the "Add custom diagnosis…" field clears

  @negative @edge
  Scenario: A duplicate custom diagnosis is not added twice (case-insensitive)
    Given the Diagnoses picker shows curated option "ADHD"
    When I type "adhd" into "Add custom diagnosis…"
    And I click "Add"
    Then no second "adhd" row is added but "ADHD" becomes selected

  @edge
  Scenario: Adding an empty custom diagnosis is a no-op
    When I open the Diagnoses picker
    And I leave "Add custom diagnosis…" blank
    And I click "Add"
    Then no new row is added and the header count is unchanged

  @edge
  Scenario: Closing the picker with the X preserves selections
    Given the Diagnoses picker has "Down Syndrome" checked
    When I click the "Close" (X) icon
    Then the field trigger still summarises "Down Syndrome"

  # ── Guardian relationship "Other → specify" ──────────────────────────────
  @positive @data
  Scenario Outline: Standard relationships map straight into the field
    When I select "<relationship>" from the "Relationship to Patient" dropdown
    Then no "Please specify" input appears
    And the guardian relationship is stored as "<relationship>"

    Examples:
      | relationship |
      | Mother       |
      | Father       |
      | Brother      |
      | Sister       |

  @positive @edge
  Scenario: Choosing "Other" reveals a free-text "Please specify" input
    When I select "Other" from the "Relationship to Patient" dropdown
    Then an input labelled "Please specify" with hint "Enter relationship..." appears
    When I enter "Legal Guardian" in "Please specify"
    And I click "Save"
    Then the guardian relationship is stored as "Legal Guardian"

  @edge
  Scenario: Switching from "Other" back to a standard option clears the free text
    Given I selected "Other" and typed "Foster Parent" in "Please specify"
    When I select "Mother" from the "Relationship to Patient" dropdown
    Then the "Please specify" field is removed and its value is discarded

  # ── Guardian email / phone (optional, but format-checked when non-empty) ──
  @negative @data
  Scenario Outline: Guardian contact fields are validated for format when provided
    When I enter "Rujitha" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I enter "<value>" in "<field>"
    And I click "Save"
    Then a "<field>" format error may be surfaced as "<message>"

    Examples:
      | field         | value              | message                          |
      | Email Address | not-an-email       | Please enter a valid email address |
      | Email Address | user@@example.com  | Please enter a valid email address |
      | Email Address | user@example       | Please enter a valid email address |
      | Phone Number  | 12345              | Please enter a valid phone number  |
      | Phone Number  | abcdefghij         | Please enter a valid phone number  |

  @positive @data
  Scenario Outline: Well-formed guardian email and phone are accepted
    When I enter "Rujitha" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I enter "<email>" in "Email Address"
    And I enter "<phone>" in "Phone Number"
    And I click "Save"
    Then the patient is created without a contact format error

    Examples:
      | email                   | phone           |
      | priya.kannan@example.com| (555) 123-4567  |
      | a+tag@sub.domain.co     | +15125550000    |

  # ── Duplicate detection ──────────────────────────────────────────────────
  @negative @data
  Scenario: Creating a patient matching an existing one raises the duplicate dialog
    Given a patient "Rujitha Kannan" born "05/12/2018" already exists
    When I enter "Rujitha" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I pick "05/12/2018" in the "Date of Birth" calendar
    And I click "Save"
    Then a dialog titled "Possible Duplicate Found" appears
    And it states "A patient with similar information already exists:"
    And it lists up to 3 matches with name, DOB and guardian
    And it asks "Do you still want to create a new patient?"

  @edge
  Scenario: Cancelling the duplicate dialog aborts creation
    Given the "Possible Duplicate Found" dialog is shown
    When I click "Cancel"
    Then no new patient is created and I remain on the Basic Information form

  @edge @security
  Scenario: Confirming "Create Anyway" overrides the duplicate check for this record
    Given the "Possible Duplicate Found" dialog is shown
    When I click "Create Anyway"
    Then a second patient with the same name is created
    And subsequent saves in this session skip the duplicate check

  # ── Unsaved-changes / navigation ─────────────────────────────────────────
  @edge
  Scenario: Navigating to Insurance before saving Basic Info keeps entered values
    When I enter "Rujitha" in "First Name"
    And I enter "Kannan" in "Last Name"
    And I switch to the "Insurance Information" section without saving
    And I switch back to "Basic Information"
    Then "First Name" still shows "Rujitha" and "Last Name" still shows "Kannan"

  @edge @negative
  Scenario: Insurance and Co-Pay stay locked until Basic Information is saved
    Given I have not yet saved Basic Information
    Then Insurance and Co-Pay data cannot be persisted for a non-existent patient
    And attempting a dependent save is gated on creating the patient first

  # ── Accessibility ────────────────────────────────────────────────────────
  @a11y
  Scenario: Text inputs expose their placeholder as the accessible label
    Then the "First Name" input is reachable with accessible label "John"
    And the "Last Name" input is reachable with accessible label "Doe"
    And the "Phone Number" input is reachable with accessible label "(555) 123-4567"

  @a11y
  Scenario: Required Profile sections are marked with a trailing asterisk
    Then the section rows render "Basic Information *" and "Insurance Information *"
    And "Co-Pay Payment" has no asterisk (optional)
