Feature: Patient Assessment (runs inside the Sessions workspace)
  As a BCBA / clinician on the Wabi clinic web app (dev.wabicare.com)
  I want to schedule and run an assessment for a patient
  So that a completed assessment drives the authorization + status lifecycle.

  # ⚠️ REWRITTEN 2026-07 — the assessment functionality CHANGED (feature #391).
  # Assessment is no longer a patient-profile tab and there is no separate
  # "Pre-Assessment Checklist / Assessment Meeting / Assessment Reporting" tab
  # flow. Verified live + in wabi-flutter-dev:
  #   - "Assessment" is an appointment/SESSION TYPE (new_appointment_dialog.dart:
  #     type dropdown default "Direct Service" → "Assessment"; sub-types
  #     "Initial" / "Re-Auth" / "Annual Review").
  #   - Assessments appear in the unified Sessions list (data_collection_screen.dart;
  #     type label "Assessment" / "Assessment · <subtype>") and are filterable.
  #   - Opening an assessment session opens the SESSION WORKSPACE, which shows the
  #     assessment as 5 section pills in the header card (session_workspace_screen.dart
  #     _buildAssessmentSectionPills, AsSection enum):
  #       primary pills: "Beneficiary", "Parent interview"
  #       under "More":  "Scoring", "Direct observation", "Report"
  #     Scoring sub-sections (AsScoringSub): VB-MAPP Milestones, VB-MAPP Barriers,
  #     Vineland, ABLLS. Primary action: "Start assessment" (EVV, like a session).
  #   - Assessment was REMOVED from the patient profile pills
  #     (patient_tabs.dart:38; commit 46cc43fc). On completion the patient status
  #     advances (see patient-status-lifecycle.feature).
  # Labels below come from source constants; scenarios tagged @needs-live are
  # drafted and awaiting full BDD automation of the workspace section editor.

  Background:
    Given I am logged in as a clinician
    And I am on the "Sessions" page

  # ─────────────────────── Assessment is a session type ────────────────────
  @smoke @positive
  Scenario: "Assessment" is offered as an appointment type in the New dialog
    When I click "New" to open the appointment dialog
    And I open the appointment "type" dropdown
    Then the type options include "Intake", "Assessment", "Direct Service", "Supervision" and "Caregiver Training"

  @positive @data
  Scenario Outline: Assessment sub-types are available for an Assessment appointment
    When I click "New" to open the appointment dialog
    And I select appointment type "Assessment"
    Then the assessment sub-type "<subtype>" can be chosen

    Examples:
      | subtype       |
      | Initial       |
      | Re-Auth       |
      | Annual Review |

  @negative
  Scenario: Assessment is NOT a patient-profile tab
    Given I open a patient's profile workspace
    Then neither the pill bar nor the "More" menu contains "Assessment"
    # #391 removed Assessment from the profile pills — it runs via the session type.

  # ─────────────────────── Create an assessment session ────────────────────
  @smoke @positive
  Scenario: Schedule an assessment for a patient
    When I click "New" to open the appointment dialog
    And I select appointment type "Assessment"
    And I choose the assessment sub-type "Initial"
    And I add the patient "Demo Patient 2"
    And I set a future date and time
    And I click "Save"
    Then I see the toast "Appointment created"
    And the assessment appears in the Sessions list labelled "Assessment"

  @positive @needs-live
  Scenario: The Sessions list shows assessments alongside sessions and can filter to them
    Given at least one assessment exists in the Sessions list
    When I filter the list by "Assessment"
    Then only items of type "Assessment" are listed

  @negative
  Scenario: An assessment cannot be double-booked at the same time
    Given the patient already has an appointment at the chosen time
    When I try to save an "Assessment" appointment for that slot
    Then the dialog shows an inline conflict error and stays open

  # ─────────────────────── Run the assessment in the workspace ─────────────
  @smoke @positive @needs-live
  Scenario: Opening an assessment session shows the assessment section pills
    Given an assessment session exists for "Demo Patient 2"
    When I open that assessment's session workspace
    Then the header shows the primary section pills "Beneficiary" and "Parent interview"
    And a "More" section control exposes "Scoring", "Direct observation" and "Report"
    And the primary action is "Start assessment"

  @positive @needs-live
  Scenario: Start the assessment (EVV check-in like a session)
    Given I am in an assessment session workspace
    When I click "Start assessment"
    Then the assessment session moves to an in-progress state
    # EVV/geolocation is requested on start, same as a therapy session.

  @positive @data @needs-live
  Scenario Outline: Navigating the assessment section pills switches the editor
    Given I am in an assessment session workspace
    When I select the "<section>" section pill
    Then the "<section>" assessment editor is shown

    Examples:
      | section           |
      | Beneficiary       |
      | Parent interview  |
      | Scoring           |
      | Direct observation|
      | Report            |

  @positive @data @needs-live
  Scenario Outline: The Scoring section exposes the standardized instrument sub-tabs
    Given I am in an assessment session workspace on the "Scoring" section
    Then the scoring instrument "<instrument>" is available

    Examples:
      | instrument        |
      | VB-MAPP Milestones|
      | VB-MAPP Barriers  |
      | Vineland          |
      | ABLLS             |

  @positive @needs-live
  Scenario: The Report section holds the assessment report editor
    Given I am in an assessment session workspace
    When I select the "Report" section
    Then a report editor for the assessment is shown

  # ─────────────────────── Completion → status lifecycle ───────────────────
  @positive @needs-live
  Scenario: Completing the assessment advances the patient status
    Given an assessment session has been run for a patient in "Intake"
    When I complete/end the assessment
    Then the patient status advances off "Intake"
    # Insurance → "authorization_pending"; private-pay → "active".
    # See patient-status-lifecycle.feature.

  @permission @needs-live
  Scenario: Assessment sessions respect session-workspace role gating
    Given I am signed in as an RBT
    When I open an assessment session workspace
    Then editing is limited to the permissions granted for that assessment
