# Grounded in wabi-flutter-dev:
#   lib/features/clinic/intake/widgets/intake_form_fields.dart  (the 9 forms, fields, chips, dynamic blocks, e-signature)
#   lib/features/clinic/intake/widgets/intake_forms_panel.dart  (save/upload/auto-fill gates)
#   lib/features/clinic/intake/widgets/intake_upload_dialog.dart (Upload Document dialog)
# The 9 required BCBA intake forms (all "required: true" as sections; individual
# fields are optional): Client Information, Caregiver & Provider Info, ABA Therapy
# History, Challenging Behaviors, Education & Therapies, Medical History,
# Diagnosis & Documents, Availability & Concerns, Consent & Agreements.
# Repeating blocks cap at 10 rows. Save gate: "Please save patient Basic Information
# before saving intake forms." (also "...before uploading documents." / "...before auto-filling.")

Feature: Intake Forms (9 BCBA sections)
  As a clinician
  I want to complete the nine standardized intake forms for a patient
  So that the assessment and authorization workflow has the required clinical intake data.
  Every section is required to reach 9/9, but each field within is optional; saving
  any section first requires that the patient's Basic Information has been saved.

  Background:
    Given I am logged in as a clinician
    And the patient "Rujitha Kannan" has been created (Basic Information saved)
    When I open the "Intake Forms" tab
    Then I see the nine section rows including "Client Information" and "Consent & Agreements"

  # ── The "save Basic Information first" gate ───────────────────────────────
  @smoke @negative
  Scenario: Saving an intake section before Basic Information is blocked
    Given a brand-new patient whose Basic Information has NOT been saved (id "pending-intake")
    When I open the "Intake Forms" tab and try to save "Client Information"
    Then I see the error toast "Please save patient Basic Information before saving intake forms."

  @negative
  Scenario: Uploading a document before Basic Information is blocked
    Given a brand-new patient whose Basic Information has NOT been saved
    When I try to upload a document from an intake form
    Then I see the error toast "Please save patient Basic Information before uploading."

  @negative
  Scenario: Auto-filling from a document before Basic Information is blocked
    Given a brand-new patient whose Basic Information has NOT been saved
    When I trigger auto-fill from an uploaded document
    Then I see the error toast "Please save patient Basic Information before auto-filling."

  # ── Section completion indicators ────────────────────────────────────────
  @smoke @positive
  Scenario: Saving all nine sections drives the completion count to 9/9
    When I open and save each of the nine intake sections in turn
    Then each saved section shows a green completion checkmark
    And the intake progress reaches "9 / 9" completed
    And each save shows a "<Section> saved successfully" toast

  @positive @data
  Scenario Outline: Each section saves and can be re-saved (Save then Update)
    When I open "<section>", fill a representative field, and save
    Then I see the toast "<section> saved successfully"
    And re-opening "<section>" shows the saved values and a completed marker

    Examples:
      | section                  |
      | Client Information       |
      | Caregiver & Provider Info|
      | ABA Therapy History      |
      | Challenging Behaviors    |
      | Education & Therapies    |
      | Medical History          |
      | Diagnosis & Documents    |
      | Availability & Concerns  |
      | Consent & Agreements     |

  @edge
  Scenario: A section with all fields left blank still saves (fields optional)
    When I open "ABA Therapy History" and change nothing
    And I click "Save"
    Then the section saves successfully and is marked complete

  # ── 1. Client Information ────────────────────────────────────────────────
  @positive
  Scenario: Client Information gender dropdown offers four options
    When I open "Client Information"
    And I open the "Gender (Assigned)" dropdown
    Then the options are "Male", "Female", "Non-binary", "Prefer not to say"

  @positive
  Scenario: Fill Client Information address and family details
    When I open "Client Information"
    And I enter "Ruji" in "Preferred Name/Nickname"
    And I enter "English" in "Primary Language"
    And I enter "789 Elm St" in "Street Address"
    And I enter "Austin" in "City" and "TX" in "State" and "78704" in "Zip Code"
    And I click "Save"
    Then the section is marked complete

  # ── 2. Caregiver & Provider Info: exclusive chip multiselects ────────────
  @positive
  Scenario: "Best Day to Contact" is a multi-select chip group
    When I open "Caregiver & Provider Info"
    And I select the chips "Mon", "Wed" and "Fri" under "Best Day to Contact"
    Then all three chips are highlighted and stored comma-joined

  @positive @edge
  Scenario: Choosing "Any Day" clears all other day chips (exclusive item)
    Given I selected "Mon" and "Tue" under "Best Day to Contact"
    When I select the "Any Day" chip
    Then only "Any Day" remains selected

  @edge
  Scenario: Selecting a specific day after "Any Day" removes the exclusive chip
    Given "Any Day" is the only selected "Best Day to Contact" chip
    When I select "Thu"
    Then "Any Day" is deselected and "Thu" is selected

  @positive @edge
  Scenario: "Any Time" is the exclusive option for "Best Time to Contact"
    Given I selected "Morning (9am–12pm)" and "Evening (5pm–8pm)"
    When I select "Any Time"
    Then only "Any Time" remains selected

  # ── 3. ABA Therapy History ───────────────────────────────────────────────
  @positive
  Scenario: Capture prior ABA history
    When I open "ABA Therapy History"
    And I enter "Yes" in "Has child received ABA therapy before?"
    And I enter "6" in "Months of ABA Therapy" and "1" in "Years of ABA Therapy"
    And I enter "Austin ABA Center" in "Previous ABA Provider Name"
    And I click "Save"
    Then the section is marked complete

  # ── 4. Challenging Behaviors: repeating blocks (max 10) ───────────────────
  @positive
  Scenario: Fill the first challenging behavior with ABC fields
    When I open "Challenging Behaviors"
    Then the info box asks to include "Frequency, Duration, What causes the behavior, What stops the behavior"
    When I fill "Behavior Description", "Frequency", "Duration", "Antecedent (what happens right before)", "Consequence (what happens right after)", "What causes this behavior?" and "What stops this behavior?"
    And I click "Save"
    Then the section is marked complete

  @positive
  Scenario: Add and remove additional behavior blocks
    Given I am on "Challenging Behaviors" with "Challenging Behavior #1"
    When I click "Add Another Behavior"
    Then a "Challenging Behavior #2 (if applicable)" block with a remove (X) control appears
    When I remove "Challenging Behavior #2"
    Then only "Challenging Behavior #1" remains and its data is preserved

  @edge
  Scenario: The "Add Another Behavior" affordance disappears at 10 behaviors
    Given I am on "Challenging Behaviors"
    When I add behavior blocks until 10 exist
    Then "Add Another Behavior" is no longer shown

  @edge
  Scenario: Removing a middle behavior shifts later rows up without data loss
    Given behaviors #1, #2 and #3 each have distinct descriptions
    When I remove "Challenging Behavior #2"
    Then the former #3 becomes #2 with its description intact

  # ── 5. Education & Therapies ─────────────────────────────────────────────
  @positive
  Scenario: School and IEP details with a Yes/No dropdown
    When I open "Education & Therapies"
    And I select "Yes" for "Does your child attend school?"
    And I enter "Austin Elementary" in "Name of School" and "Pre-K" in "Grade"
    And I select "Yes" for "Does child have an IEP?"
    And I click "Save"
    Then the section is marked complete

  @positive
  Scenario: Upload an IEP document via the intake Upload dialog
    When I open "Education & Therapies"
    And I click "Choose File" for "Upload IEP Document"
    Then the "Upload Document" dialog opens with a "Document type" dropdown
    And it offers types including "Intake Documents" and "Insurance Cards"

  # ── 6. Medical History: medication repeating block ───────────────────────
  @positive
  Scenario: Record an allergy and a medication
    When I open "Medical History"
    And I enter "Peanuts" in "Allergy" and "Hives" in "Reaction/Comments"
    And I enter "Ritalin" in "Medication Name", "10mg" in "Dose" and "Daily" in "Frequency"
    And I click "Save"
    Then the section is marked complete

  @positive
  Scenario: Add and remove medication rows
    When I open "Medical History"
    And I click "Add Another Medication"
    Then a "Medication 2" row with a remove (X) control appears
    When I remove "Medication 2"
    Then only the first medication row remains

  @edge
  Scenario: Medication rows cap at 10
    Given I am on "Medical History"
    When I add medication rows until 10 exist
    Then "Add Another Medication" is no longer shown

  # ── 7. Diagnosis & Documents: diagnosis repeating block + upload ─────────
  @positive
  Scenario: Enter an ICD-10 diagnosis and date
    When I open "Diagnosis & Documents"
    And I enter "Yes" in "Does your child have an autism diagnosis?"
    And I enter "F84.0 - Autism Spectrum Disorder" in "Type of Diagnosis (ICD-10 Code)"
    And I enter "03/15/2022" in "Date of Diagnosis"
    And I click "Save"
    Then the section is marked complete

  @positive
  Scenario: Add a second diagnosis row
    Given I am on "Diagnosis & Documents"
    When I click "Add Another Diagnosis"
    Then a "Diagnosis 2" block labelled "ICD-10 Code" appears with a remove control

  @edge
  Scenario: Diagnosis rows cap at 10
    When I add diagnosis rows until 10 exist
    Then "Add Another Diagnosis" is no longer shown

  @edge
  Scenario: The document-upload note states accepted formats and size limit
    When I open "Diagnosis & Documents"
    Then I see "Accepted file formats: JPG, PNG, PDF, DOC, DOCX. Maximum 2.5MB per file."

  @negative @edge
  Scenario: Uploading a document over 2.5MB surfaces an upload-failure toast
    Given Basic Information is saved
    When I upload a 5MB "psych-eval.pdf" from the "Upload Document" dialog
    Then I see a toast starting "Upload failed:"

  @negative @security @data
  Scenario Outline: The Upload Document dialog restricts file types
    When I open the "Upload Document" dialog and pick from "Computer"
    Then only pdf, jpg, jpeg, png, doc, docx are selectable
    And a "<file>" is not selectable

    Examples:
      | file        |
      | script.js   |
      | archive.zip |
      | photo.gif   |
      | app.exe     |

  @edge
  Scenario: Google Drive and OneDrive sources are not yet available
    When I open the "Upload Document" dialog
    And I click "Google Drive"
    Then I see the info toast "Google Drive integration coming soon."
    When I click "OneDrive"
    Then I see the info toast "OneDrive integration coming soon."

  # ── 8. Availability & Concerns ───────────────────────────────────────────
  @positive
  Scenario: Enter weekly availability and areas of concern
    When I open "Availability & Concerns"
    And I enter "Mornings Only" in "General Availability"
    And I enter "9am-3pm" in "Monday" and "9am-3pm" in "Wednesday"
    And I enter "Behavioral, Communication" in "Areas of Concern"
    And I click "Save"
    Then the section is marked complete

  # ── 9. Consent & Agreements: checkboxes + e-signature ────────────────────
  @positive
  Scenario: Toggle all consent checkboxes on
    When I open "Consent & Agreements"
    And I check "I understand and agree to attend these sessions"
    And I check "I consent to ABA therapy services for my child"
    And I check "I acknowledge receipt of the HIPAA Notice of Privacy Practices"
    And I check "I authorize the clinic to contact my insurance for authorization"
    And I check "I permit sharing information with schools and other providers"
    Then each checked box turns emerald-highlighted

  @edge
  Scenario: Consent checkboxes persist their checked/unchecked state as true/false
    Given I checked "I consent to ABA therapy services for my child"
    When I save and reopen "Consent & Agreements"
    Then that checkbox remains checked (stored as "true")

  @negative @edge
  Scenario: Release of Information is optional; treatment/HIPAA consent should be required
    When I open "Consent & Agreements"
    Then "Release of Information (Optional)" is clearly optional
    And a compliant flow should require treatment consent, HIPAA acknowledgement and the signature before completion

  # ── E-signature: draw vs type ────────────────────────────────────────────
  @positive
  Scenario: Draw signature mode is the default
    When I open the "Electronic Signature" section
    Then I see "E-Signature Required"
    And the "Draw Signature" toggle is selected
    And the pad shows the "Sign here" placeholder with an "X" baseline

  @positive
  Scenario: Draw a signature and print the legal name
    Given I am in "Draw Signature" mode
    When I draw strokes on the signature pad
    And I enter "Priya Kannan" in "Print Full Legal Name"
    And I check "I agree that my electronic signature above is the legal equivalent of my handwritten signature."
    And I enter "02/15/2026" in "Date" and "Mother" in "Relationship to Child"
    And I click "Save"
    Then the drawn signature, name and agreement persist

  @positive
  Scenario: Clearing the drawn signature resets the pad
    Given I drew a signature
    When I click "Clear Signature"
    Then the pad returns to the "Sign here" placeholder

  @positive
  Scenario: Type signature mode shows a live preview
    When I select "Type Signature"
    And I enter "Priya Kannan" in "Type your full legal name as signature"
    Then a "Signature Preview" renders "Priya Kannan" in an italic script

  @negative @edge
  Scenario: The agreement checkbox should gate a valid signature
    Given I typed a signature name but left the legal-equivalent agreement unchecked
    Then the signature is not legally complete until the agreement box is checked

  @edge
  Scenario: Switching from draw to type does not silently keep drawn points as the signature
    Given I drew a signature in "Draw Signature" mode
    When I switch to "Type Signature" and clear the name
    Then no drawn-points payload is submitted as the typed signature

  # ── Cross-cutting negative / security / a11y ─────────────────────────────
  @security @data
  Scenario Outline: Free-text intake fields store injected markup as inert text
    When I enter "<payload>" in "Areas of Concern"
    And I save "Availability & Concerns"
    Then the payload is persisted/escaped as text and never executes

    Examples:
      | payload                          |
      | <script>alert(1)</script>        |
      | "><img src=x onerror=alert(1)>   |
      | {{7*7}}                          |

  @edge
  Scenario: Very long free-text does not break section save
    When I paste 10,000 characters into "Behavior Description"
    And I click "Save"
    Then the section saves or shows a backend length error, never a client crash

  @a11y
  Scenario: Chips, checkboxes and toggles expose their labels to assistive tech
    Then contact-day/time chips are focusable and labelled
    And each consent checkbox exposes its full statement as its accessible name
    And the "Draw Signature" / "Type Signature" toggles are labelled buttons

  @permission
  Scenario: Intake form completion is tracked per patient and survives tab switches
    Given I completed "Client Information" and "Medical History"
    When I switch to another tab and back to "Intake Forms"
    Then both remain marked complete (locally tracked and merged with backend state)
