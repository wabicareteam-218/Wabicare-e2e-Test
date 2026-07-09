Feature: Patient Assessment workflow (Pre-Assessment → Meeting → Reporting)
  As a BCBA / clinician on the Wabi clinic web app (dev.wabicare.com)
  I want to run the 3-step assessment workflow for a patient
  So that a finalized assessment report drives the authorization + status lifecycle.

  # Grounded in wabi-flutter-dev:
  #   assessment_panels.dart  (AssessmentChecklistPanel, PreAssessmentChecksPanel,
  #                            AssessmentMeetingPanel, AssessmentMeetingContentPanel)
  #   assessment_report_panels.dart (CreatePatientAssessmentDialog, AssessmentFormsPanel)
  #   new_patient_intake_screen.dart (Assessment Reporting panel: _generateAIReport,
  #                            _saveReport, _finalizeReport, _updatePatientStatusOnAssessmentComplete)
  # Assessment step names (all required, shown with a red "*"):
  #   "Pre-Assessment Checklist", "Assessment Meeting", "Assessment Reporting"
  # Assessment status machine: scheduled → in_progress → pending_report → report_complete → completed
  # On report_complete/completed the patient status advances (see patient-status-lifecycle.feature).

  Background:
    Given I am logged in as a "BCBA" with an assigned patient
    And I open the patient intake workspace
    And I select the "Assessment" tab

  # ---------------------------------------------------------------------------
  # Pre-Assessment Checklist (Step 0)
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Assessment tab shows the three required workflow steps
    When the Assessment checklist panel renders
    Then I see the steps "Pre-Assessment Checklist", "Assessment Meeting" and "Assessment Reporting"
    And each step is marked required with a "*" until completed
    And the header shows "0 / 3 completed"

  @positive
  Scenario: Pre-Assessment checklist auto-reflects existing intake data
    Given the patient has completed intake forms, medical history and insurance
    When I open the "Pre-Assessment Checklist" step
    Then "Patient intake forms" is checked
    And "Medical history / ASD diagnosis" is checked
    And "Insurance verification" is checked
    And the optional rows "IEP document (if available)" and "Previous evaluation reports" are unchecked

  @positive
  Scenario: Manually toggle and save the pre-assessment checklist
    When I toggle "IEP document (if available)" complete
    Then the header shows "Unsaved changes"
    When I click "Save Checklist"
    Then I see the toast "Checklist saved successfully"
    And the "Unsaved changes" indicator disappears

  @negative
  Scenario: Saving the checklist with no assessment created fails gracefully
    Given no assessment record exists for the patient yet
    When I toggle a checklist item and click "Save Checklist"
    Then I see the error toast "Unable to save checklist - no assessment found"

  @edge
  Scenario: Required-item completion count updates on the Intake Documents Review card
    Given the "Intake Documents Review" card is visible
    Then it lists "Patient intake forms completed", "Medical history / diagnosis" and "Insurance information"

  @negative
  Scenario: Cannot schedule an assessment before required documents are ready
    Given the patient is missing insurance information
    When I view the schedule-assessment card
    Then it reads "Complete Intake Documents First"
    And the guidance text "Complete the intake documents above before scheduling an assessment." is shown

  @positive
  Scenario: Ready-to-schedule state appears once intake forms and insurance are present
    Given the patient has intake forms and insurance completed
    When I view the schedule-assessment card
    Then it reads "Ready to Schedule Assessment"
    And the "Schedule Assessment" button is enabled

  # ---------------------------------------------------------------------------
  # Creating the assessment record
  # ---------------------------------------------------------------------------

  @smoke @positive @data
  Scenario Outline: Create an assessment of each supported type
    When I click "New Assessment"
    And the "New Assessment" dialog opens
    And I select assessment type "<type>"
    And I click "Create Assessment"
    Then an assessment record is created with type "<type>"
    And the assessment appears with status "Scheduled"

    Examples:
      | type          |
      | Initial       |
      | Re-Auth       |
      | Annual Review |
      | FBA           |

  @negative
  Scenario: Create Assessment surfaces a service error inline in the dialog
    Given the assessment service is unavailable
    When I open the "New Assessment" dialog and click "Create Assessment"
    Then the dialog shows the inline error "Assessment service not available"
    And the dialog does not close

  @edge
  Scenario: Multiple assessments expose a date/type picker in the checklist header
    Given the patient has more than one assessment
    When I open the "Pre-Assessment Checklist" step
    Then a styled assessment selector dropdown lists each assessment by type and scheduled date

  # ---------------------------------------------------------------------------
  # Assessment Meeting (Step 1)
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Schedule an assessment meeting appointment
    Given an assessment record exists
    When I open the "Assessment Meeting" step
    And I click "New Appointment"
    And I create an assessment appointment for tomorrow at 9:00 AM
    Then I see the toast "Assessment appointment created"
    And the meeting appears in the "Assessment Meetings" table

  @positive @data
  Scenario Outline: Filter the Assessment Meetings table by status
    Given the "Assessment Meetings" table has meetings in multiple states
    When I click the "<filter>" filter chip
    Then only meetings with status "<filter>" are listed

    Examples:
      | filter    |
      | All       |
      | Scheduled |
      | Completed |

  @edge
  Scenario: Empty Assessment Meetings table shows guidance
    Given no assessment meetings exist for the patient
    When I open the "Assessment Meeting" step
    Then I see "No assessment meetings found"
    And I see "Schedule a new appointment to get started"

  @positive
  Scenario: Record meeting notes on an assessment meeting
    Given an assessment meeting exists
    When I open its "Meeting Notes" dialog
    And I enter observations in the notes field
    And I click "Save Notes"
    Then I see the toast "Meeting notes saved"

  @negative
  Scenario: Assessment Meeting step blocks when no assessment is selected
    Given no assessment record exists
    When I open the "Assessment Meeting" step
    Then I see "No Assessment Scheduled"
    And I see "Schedule an assessment meeting in the Pre-Assessment Checks step first."

  # ---------------------------------------------------------------------------
  # Assessment Reporting (Step 2) — AI generate, edit, finalize
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Generate an AI assessment report
    Given an assessment is "in_progress" with meeting data captured
    When I open the "Assessment Reporting" step
    And I click "AI Generate"
    Then I see the toast "Generating AI Report..."
    And the editor is populated with the generated report text

  @positive
  Scenario: Edit and save an AI-generated report draft
    Given a report draft has been generated
    When I edit the report body
    And I click "Save Report"
    Then I see the toast "Report saved"

  @negative
  Scenario: Save with no generated report is rejected
    Given the report editor is empty and no report has been generated
    When I click "Save Report"
    Then I see the error toast "Nothing to save — generate a report first"

  @negative
  Scenario: AI generation failure shows a friendly message
    Given the AI report endpoint returns a 500 error
    When I click "AI Generate"
    Then I see the error toast "AI report generation is temporarily unavailable. Please try again later."

  @negative
  Scenario: Finalize is disabled while the report editor is empty
    Given the report editor is empty
    Then the "Finalize Report" button is disabled

  @negative
  Scenario: Finalize before saving warns to save first
    Given a report has been typed but never saved to the backend
    When I click "Finalize Report"
    Then I see the error toast "Save the report before finalizing"

  @smoke @positive
  Scenario: Finalize a report completes the assessment and advances status
    Given a saved report draft exists with content
    When I click "Finalize Report"
    Then I see the toast "Report finalized"
    And the assessment status becomes "report_complete"
    And the patient status advances off "Intake" (see patient-status-lifecycle.feature)

  @edge @security
  Scenario: A finalized report is locked from further editing
    Given the assessment status is "report_complete"
    When I open the "Assessment Reporting" step
    Then the report editor is read-only
    And "Assessment Report Finalized" is shown
    And the primary action changes to "Proceed to Authorization"

  @edge
  Scenario: Report finalized as report_complete and completed are treated equivalently
    Given an assessment status of "completed"
    Then the "Assessment Reporting" step shows as complete
    And the report remains read-only

  @a11y
  Scenario: The reporting editor exposes its placeholder guidance
    When the "Assessment Reporting" editor is empty
    Then the placeholder reads "Start typing your report or click 'AI Generate' to auto-generate..."

  @permission
  Scenario: A read-only role cannot generate or finalize a report
    Given I am logged in as a role without assessment-edit permission
    When I open the "Assessment Reporting" step
    Then the "AI Generate" and "Finalize Report" actions are unavailable

  @security
  Scenario: Report text with injected markup is stored as inert text
    Given a generated report draft
    When I paste "<script>alert('x')</script>" into the report body and click "Save Report"
    Then the content is persisted as plain report text and never executed on reopen
