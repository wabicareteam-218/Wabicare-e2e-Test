Feature: Discharge Patient
  As a clinician on the Wabi web app
  I want to discharge a patient with a reason and audit notes
  So that they are removed from the active queue and retained for audit.

  # Source of truth for labels/messages:
  #   lib/features/clinic/intake/widgets/profile_panels.dart (DischargePatientPanel)
  #   lib/services/api/patient_api_service.dart (dischargePatient / unarchive)
  #   lib/features/clinic/intake/data/patient_tabs.dart (tab label "Discharge", id 7)
  #   lib/state/patients_store.dart (Discharged status)
  #   lib/features/clinic/intake/screens/patients_screen.dart (Discharged audit view / Archive menu)
  #
  # IMPORTANT source facts:
  #  - Discharge is a terminal, audit-only state. There is NO reactivation /
  #    un-discharge flow for a discharged patient. The closest analog is the
  #    separate Archive/"Restore from Archive" flow, which restores to Inactive,
  #    not Discharged. Reactivation scenarios below are tagged and note this.
  #  - There is NO required-field validation and NO confirmation dialog: reason
  #    defaults to "Other", notes are optional, discharge date is auto-set to today,
  #    and clicking "Discharge patient" submits immediately.

  Background:
    Given I am logged in to the Wabi clinician web app as an Owner
    And I open an existing patient's profile
    And I select the "Discharge" tab
    And I see the panel title "Discharge patient"
    And I see the subtitle "Mark this patient as discharged or terminated. They will be removed from the active queue."

  # ---------------------------------------------------------------------------
  # Layout / read
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Discharge panel shows the checklist and reason controls
    Then I see the left card title "Discharge checklist"
    And I see the checklist items "Confirm reason for discharge" and "Optional: add notes for audit"
    And I see the info line "Once discharged, the patient will be removed from the patient queue and can be viewed in the Discharged (audit) list."
    And I see the "Reason for discharge" dropdown with hint "Select reason"
    And I see the "Notes (optional)" field with hint "Additional details for audit..."
    And I see the "Discharge patient" button

  @data @positive
  Scenario Outline: Reason dropdown offers the three defined reasons
    When I open the "Reason for discharge" dropdown
    Then I can select "<reason label>"

    Examples:
      | reason label                  |
      | Transfer to another clinic    |
      | Rejection of authorization    |
      | Other                         |

  # ---------------------------------------------------------------------------
  # Positive discharge
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Discharge a patient with a reason and notes
    When I select reason "Transfer to another clinic"
    And I enter "Family relocating out of state" in "Notes (optional)"
    And I click "Discharge patient"
    Then the button briefly shows "Discharging..."
    And I see the success toast "Patient has been discharged and removed from the queue."
    And the patient status becomes "Discharged"
    And the patient no longer appears in the active patient queue

  @positive @edge
  Scenario: Discharge succeeds with the default reason "Other" and no notes
    When I click "Discharge patient" without changing the reason or entering notes
    Then the discharge is submitted with reason "Other" and today's date
    And I see the success toast "Patient has been discharged and removed from the queue."

  @edge
  Scenario: Discharge checklist item ticks when a reason or note is provided
    Given the reason is still the default "Other" and notes are empty
    Then the "Confirm reason for discharge" checklist item is not marked done
    When I select reason "Rejection of authorization"
    Then the "Confirm reason for discharge" checklist item is marked done

  @edge
  Scenario: Discharge date is set automatically to today
    When I discharge the patient
    Then the recorded discharge date equals today's date and is not user-editable

  # ---------------------------------------------------------------------------
  # Discharged patients audit view
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Discharged patient is viewable in the Discharged audit list
    Given a patient has been discharged
    When I open the "Discharged" list on the Patients screen
    Then I see the banner "Viewing discharged patients for audit purposes."
    And the discharged patient appears with status "Discharged"

  # ---------------------------------------------------------------------------
  # Negative / error handling
  # ---------------------------------------------------------------------------

  @negative
  Scenario: Discharge with no patient selected shows an error
    Given no patient id is available in the panel
    When I click "Discharge patient"
    Then I see the inline error "No patient selected"

  @negative @security
  Scenario: Server rejection surfaces the backend error inline
    Given the discharge endpoint returns a failure
    When I click "Discharge patient"
    Then I see the inline error "Discharge failed" or the server-provided message
    And the patient remains in the active queue

  @negative @edge
  Scenario: Document/API service unavailable
    Given the patient API service is not available
    When I click "Discharge patient"
    Then I see the inline error "API not available"

  # ---------------------------------------------------------------------------
  # Reactivation (NOT implemented for discharge — archive analog only)
  # ---------------------------------------------------------------------------

  @edge @negative
  Scenario: No un-discharge / reactivation flow exists for a discharged patient
    Given a patient has status "Discharged"
    Then there is no control to reactivate or un-discharge them
    # NOTE: Discharge is terminal/audit-only in the current source.

  @positive
  Scenario: Archived (not discharged) patient can be restored to Inactive
    Given a patient has been archived
    When I choose "Restore from Archive" from the patient's menu
    Then the patient is restored to "Inactive" status
    # NOTE: This is the Archive/unarchive flow, distinct from Discharge.

  # ---------------------------------------------------------------------------
  # Permissions
  # ---------------------------------------------------------------------------

  @permission @positive
  Scenario Outline: Roles with full tab access can open the Discharge tab
    Given I am logged in as "<role>"
    Then the "Discharge" tab is visible on the patient profile

    Examples:
      | role                    |
      | Owner                   |
      | BCBA                    |
      | Clinical Director       |
      | Administrator           |
      | Clinical Administrator  |

  @permission @negative @security
  Scenario: An RBT cannot access the Discharge tab
    Given I am logged in as an RBT
    When I open a patient's profile
    Then the "Discharge" tab is not available
    # RBTs are limited to Profile, Scheduling, Communication and Documents tabs.
