Feature: Patient Documents & Files
  As a clinician on the Wabi web app
  I want to upload, view, download and delete a patient's documents
  So that intake paperwork, assessments, insurance cards and records are on file.

  # Source of truth for labels/messages:
  #   lib/features/clinic/intake/widgets/patient_files_modal.dart  (Patient Files modal)
  #   lib/features/clinic/intake/widgets/intake_shared_types.dart  (showPatientFilesModal)
  #   lib/features/clinic/intake/widgets/intake_form_fields.dart / intake_forms_panel.dart (intake inline upload)
  #   lib/features/clinic/intake/data/patient_tabs.dart (Documents tab, id 13)
  #
  # TWO upload paths exist with DIFFERENT behaviour:
  #  (A) Patient Files modal ("Documents" tab) — picker is FileType.any, allowMultiple,
  #      with NO client-side extension or size restriction. Enforcement is server-side.
  #  (B) Intake-form inline upload ("Document Uploads" field) — picker RESTRICTS to
  #      [pdf, jpg, jpeg, png, doc, docx] and DISPLAYS "Accepted file formats:
  #      JPG, PNG, PDF, DOC, DOCX. Maximum 2.5MB per file." The 2.5MB text is
  #      DISPLAY-ONLY; grep found NO client-side 2.5MB enforcement in this path.

  Background:
    Given I am logged in to the Wabi clinician web app as an Owner
    And I open an existing patient's profile
    And I open the "Documents" tab (the Patient Files modal)
    And the modal title reads "Patient Files"

  # ---------------------------------------------------------------------------
  # Read / structure
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Patient Files modal shows the file table and folders
    Then the table has the column headers "Name", "Folder", "Size" and "Date"
    And the folder sidebar lists "All Files", "Intake Documents", "Assessment Reports", "Insurance Cards", "Authorization", "Session Notes", "Medical Records", "Consent Forms" and "Other"
    And the subtitle shows "<patient> • N files"

  @positive
  Scenario: Search files by name
    When I type into the "Search files..." field
    Then the table narrows to files whose name matches

  # ---------------------------------------------------------------------------
  # Upload — Patient Files modal (path A)
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Upload a single file
    When I click "Upload" and choose one valid file
    Then I see the toast "1 file uploaded"
    And the file appears in the table

  @positive @edge
  Scenario: Upload multiple files at once
    When I click "Upload" and choose 3 valid files
    Then I see the toast "3 files uploaded"

  @edge
  Scenario: Partial upload reports how many succeeded
    Given one of the selected files fails server-side
    When I click "Upload" and choose 3 files
    Then I see the toast "2 of 3 files uploaded"

  @negative
  Scenario: Upload failure shows an error toast
    Given the upload endpoint returns an error
    When I click "Upload" and choose a file
    Then I see an error toast beginning with "Upload failed:"

  @data @positive
  Scenario Outline: Common document types upload through the modal
    When I upload a "<type>" file via the Patient Files modal
    Then the file is accepted and listed

    Examples:
      | type |
      | PDF  |
      | JPG  |
      | PNG  |
      | DOCX |
      | XLSX |
      | CSV  |

  # ---------------------------------------------------------------------------
  # Upload — Intake inline field (path B) — restricted picker
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Intake document field states accepted formats and size
    When I view the "Document Uploads" section on an intake form
    Then the field label reads "Upload ASD Diagnosis / Psych Eval"
    And the helper text reads "Accepted file formats: JPG, PNG, PDF, DOC, DOCX. Maximum 2.5MB per file."
    And the button reads "Choose File"

  @data @positive
  Scenario Outline: Intake picker only offers allowed extensions
    When I open the "Choose File" picker on the intake document field
    Then only files of type "<allowed>" can be selected

    Examples:
      | allowed |
      | pdf     |
      | jpg     |
      | jpeg    |
      | png     |
      | doc     |
      | docx    |

  @negative
  Scenario: Intake upload requires Basic Information to be saved first
    Given the patient's Basic Information has not been saved
    When I try to upload on the intake document field
    Then I see "Please save patient Basic Information before uploading documents."

  @positive
  Scenario: Intake upload success message
    When I upload one valid file on the intake document field
    Then I see "Uploaded 1 document successfully."

  @negative @edge
  Scenario: Intake document service unavailable
    Given the document service is not available
    When I upload on the intake document field
    Then I see "Document service not available."

  # ---------------------------------------------------------------------------
  # Size / security boundaries (documented gaps)
  # ---------------------------------------------------------------------------

  @security @negative
  Scenario: Oversized file (> 2.5MB) is not blocked client-side
    When I choose a 5MB file on the intake document field
    Then the client does NOT block it on the "Maximum 2.5MB per file" rule
    And enforcement, if any, must come from the server
    # NOTE: documents a real gap — the 2.5MB limit is display-only in the source.

  @security @negative
  Scenario: Executable/script upload is not filtered by the Patient Files modal
    When I choose a file such as "malware.exe" or "run.sh" in the Patient Files modal
    Then the picker (FileType.any) does not restrict it client-side
    And the app relies on the server to reject unsafe types
    # NOTE: documents a real gap — no client-side type allow-list on path A.

  @security @edge
  Scenario: Filename with script content is treated as literal text
    When I upload a file named "<script>alert(1)</script>.pdf"
    Then its name renders as literal text in the table and does not execute

  @edge
  Scenario: Duplicate file name is allowed (no client-side dedupe)
    Given a file named "report.pdf" already exists
    When I upload another file named "report.pdf"
    Then both entries are listed
    # NOTE: no client-side duplicate-name guard exists.

  # ---------------------------------------------------------------------------
  # View / preview
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Preview a file
    Given the table has at least one file
    When I click the "Preview" icon on a row
    Then the preview panel opens showing the file with a "Back to files" control
    And I can click "Open" or "Open in new tab"

  @edge
  Scenario: Preview falls back when inline rendering is unavailable
    Given a file cannot be previewed inline
    Then I see a fallback badge ("PDF" / "IMAGE" / "FILE") with caption "Preview not available"
    And an "Open in new tab" action

  # ---------------------------------------------------------------------------
  # Download
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Download a file
    When I click the "Download" action on a row
    Then the file opens/downloads via its signed URL
    And no toast is shown

  # ---------------------------------------------------------------------------
  # Delete
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Delete a file with confirmation
    Given the table has a file named "report.pdf"
    When I click the "Delete" action on that row
    Then a dialog titled "Delete File" asks "Are you sure you want to delete "report.pdf"?"
    When I click "Delete"
    Then I see the toast "File deleted"
    And "report.pdf" is removed from the table

  @negative
  Scenario: Cancelling the delete keeps the file
    When I open the "Delete File" dialog and click "Cancel"
    Then the file remains in the table

  @negative
  Scenario: Delete failure shows an error toast
    Given the delete endpoint returns an error
    When I confirm deleting a file
    Then I see the toast "Could not delete the file. Please try again."

  # ---------------------------------------------------------------------------
  # Empty state
  # ---------------------------------------------------------------------------

  @edge
  Scenario: Empty file list
    Given the patient has no files
    Then I see "No files found"

  # ---------------------------------------------------------------------------
  # Permissions / isolation
  # ---------------------------------------------------------------------------

  @permission @positive
  Scenario: RBTs can access the Documents tab
    Given I am logged in as an RBT
    When I open a patient's profile
    Then the "Documents" tab is available
    # RBTs are limited to Profile, Scheduling, Communication and Documents.

  @permission @negative @security
  Scenario: Insurance-card upload is restricted to higher roles
    Given I am logged in as an RBT
    Then I cannot view or upload in the "Insurance Card" section
    # canViewInsuranceCard is BCBA/Owner/Admin only, not RBT.

  @security
  Scenario: Files are isolated per patient
    Given patient A has a file "confidential.pdf"
    When I open patient B's Documents
    Then patient A's files do not appear for patient B
