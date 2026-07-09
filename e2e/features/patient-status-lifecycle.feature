Feature: Patient status lifecycle (Intake → Auth Pending → Active)
  As a clinician on the Wabi clinic web app
  I want a patient's lifecycle status to advance automatically as work completes
  So that the patients list, header badge and scheduling gates stay accurate.

  # Grounded in wabi-flutter-dev:
  #   lib/state/patients_store.dart — enum PatientStatus:
  #     intake('Intake', amber), authorization_pending('Auth Pending', blue),
  #     active('Active', green), graduated('Graduated', purple),
  #     discharged('Discharged', slate), archived('Archived', gray)
  #   new_patient_intake_screen.dart — _updatePatientStatusOnAssessmentComplete:
  #     on assessment report_complete/completed:
  #       private_pay  -> 'active'
  #       insurance    -> 'authorization_pending'
  #     on authorization approved -> 'active'
  #   patients_screen.dart — filter pills: Intake, Auth Pending, Active, Discharged, Archived
  #     each with store.countByStatus(...)
  #   intake_header_widgets.dart — header status pill + dot colour by label.

  Background:
    Given I am logged in as a "BCBA"
    And a newly created patient starts in status "Intake"

  # ---------------------------------------------------------------------------
  # Insurance path: Intake → Auth Pending → Active
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Insurance patient advances to Auth Pending when the assessment report is finalized
    Given the patient's pay type is "insurance"
    And the patient is in status "Intake"
    When the assessment report reaches "report_complete"
    Then the patient status becomes "authorization_pending"
    And the header badge reads "Auth Pending"

  @smoke @positive
  Scenario: Insurance patient becomes Active when the authorization is approved
    Given an "insurance" patient in status "authorization_pending"
    When the authorization is completed as "approved"
    Then the patient status becomes "active"
    And the header badge reads "Active" with a green dot

  @positive
  Scenario: Full insurance lifecycle end to end
    Given an "insurance" patient in status "Intake"
    When I finalize the assessment report
    Then the patient status is "authorization_pending"
    When I complete the authorization as "approved"
    Then the patient status is "active"

  # ---------------------------------------------------------------------------
  # Private-pay path: Intake → Active (skips Auth Pending)
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Private-pay patient goes straight to Active on report completion
    Given the patient's pay type is "private_pay"
    And the patient is in status "Intake"
    When the assessment report reaches "report_complete"
    Then the patient status becomes "active"
    And the patient never entered "authorization_pending"

  @edge
  Scenario: Private-pay patient has no authorization gate for scheduling
    Given a "private_pay" patient in status "active"
    Then sessions can be scheduled without an approved authorization

  # ---------------------------------------------------------------------------
  # Denied path and re-authorization
  # ---------------------------------------------------------------------------

  @negative
  Scenario: Denied authorization keeps the patient out of Active
    Given an "insurance" patient in status "authorization_pending"
    When the authorization is completed as "denied"
    Then the patient does not become "active"
    And the patient remains in "authorization_pending"

  @positive
  Scenario: Re-authorization after Active does not regress the lifecycle status
    Given an "insurance" patient in status "active" with an expiring authorization
    When I create a "Re-Auth" authorization
    Then the new authorization enters its own workflow
    And the patient status stays "active" while the re-auth is pending

  # ---------------------------------------------------------------------------
  # Patients list filter counts & header badge
  # ---------------------------------------------------------------------------

  @positive @data
  Scenario Outline: Patients list shows a filter pill and count for each active-queue status
    Given the active patients queue is open
    Then a filter pill "<pill>" shows the count from countByStatus for "<status>"

    Examples:
      | pill         | status                 |
      | Intake       | intake                 |
      | Auth Pending | authorization_pending  |
      | Active       | active                 |
      | Discharged   | discharged             |
      | Archived     | archived               |

  @positive
  Scenario: Moving a patient between statuses updates the list counts
    Given the "Intake" pill shows count N and the "Auth Pending" pill shows count M
    When an insurance patient's report is finalized
    Then the "Intake" count decreases by 1
    And the "Auth Pending" count increases by 1

  @a11y
  Scenario Outline: Header status badge colour matches the lifecycle stage
    Given a patient in status "<status>"
    Then the header badge label is "<label>" with a "<colour>" dot

    Examples:
      | status                | label        | colour |
      | intake                | Intake       | amber  |
      | authorization_pending | Auth Pending | blue   |
      | active                | Active       | green  |
      | discharged            | Discharged   | slate  |
      | archived              | Archived     | gray   |

  # ---------------------------------------------------------------------------
  # Invalid transitions & guards
  # ---------------------------------------------------------------------------

  @negative
  Scenario: Assessment cannot advance a patient past Intake before report completion
    Given an "insurance" patient in status "Intake"
    When the assessment is only "in_progress"
    Then the patient status remains "Intake"

  @negative @security
  Scenario: Authorization approval cannot be applied to a patient with no completed assessment
    Given an "insurance" patient with no finalized assessment report
    Then there is no path to reach "active" until an authorization is approved

  @edge
  Scenario: Unknown backend status strings fall back to Intake
    Given the patient API returns an unrecognised status value
    When the patient record is parsed
    Then the status defaults to "Intake"

  @edge
  Scenario: Re-finalizing an already-complete assessment does not double-advance status
    Given an "insurance" patient already in "authorization_pending"
    When the assessment report is finalized again
    Then the patient status stays "authorization_pending" and is not corrupted

  @permission
  Scenario: A read-only role cannot manually override the patient status
    Given I am logged in as a role without patient-edit permission
    When I open the patient header
    Then no manual status-change control is available

  @positive
  Scenario: Graduated and Discharged are terminal-ish states shown in the queue
    Given patients exist in "graduated" and "discharged" states
    Then the "Discharged" pill and archived views surface them separately from the active queue
