Feature: Patients list & search
  As a clinician on the Patients screen
  I want to find patients, filter by status, and manage the roster
  So that I can open a patient's workspace and keep the queue accurate.

  # Grounded in wabi-flutter-dev:
  #   lib/features/clinic/intake/screens/patients_screen.dart
  #   lib/state/patients_store.dart (PatientStatus enum)
  #   lib/features/clinic/intake/screens/new_patient_intake_screen.dart (duplicate check)
  # Header card title "Patients", subtitle "Find a patient and open their workspace".
  # Status enum labels: Intake, Auth Pending, Active, Graduated, Discharged, Archived.
  # KNOWN GAPS to probe: the "Search patients..." field is a static WabiInput with no
  # onChanged handler wired in the screen; the Intake/Auth Pending/Active pills expose
  # counts only (no onTap) — only Discharged and Archived pills switch views.

  Background:
    Given I am signed in to Wabi Clinic as an Owner
    And I navigate to the "Patients" section

  # ─────────────────────────── Rendering & smoke ───────────────────────────

  @smoke @positive
  Scenario: Patients screen renders header and roster table
    Then I see the header card titled "Patients"
    And I see the subtitle "Find a patient and open their workspace"
    And I see a search box with placeholder "Search patients..."
    And I see the status pills "Intake", "Auth Pending", "Active", "Discharged" and "Archived" each followed by a count
    And I see the roster table header columns "PATIENT", "GUARDIAN", "PHONE", "NEXT APPOINTMENT" and "STATUS"
    And I see the "Refresh", "Import" and "New Patient" actions

  @positive
  Scenario: Each status pill count equals the number of patients in that status
    When the roster finishes loading
    Then the "Intake" pill count equals the number of rows with status "Intake"
    And the "Active" pill count equals the number of rows with status "Active"
    And the "Auth Pending" pill count equals the number of rows with status "Auth Pending"

  @positive
  Scenario: Empty roster cells render an em dash placeholder
    Given a patient row has no guardian, no phone and no upcoming appointment
    Then the "GUARDIAN", "PHONE" and "NEXT APPOINTMENT" cells each show "—"

  @edge
  Scenario: Empty state when the clinic has zero patients
    Given the clinic has no patients
    When the roster finishes loading
    Then all status pill counts show "0"
    And the roster table shows no patient rows

  @edge
  Scenario: Loading state while the roster is fetched
    When the roster is still loading
    Then the "Refresh" button shows the label "Loading..." and is disabled
    And a circular progress indicator is shown in place of the refresh icon

  @positive
  Scenario: Refresh reloads the roster from the API
    When I click "Refresh"
    Then the roster is re-fetched with forceRefresh
    And the status pill counts are recalculated

  # ─────────────────────────── Status views / filters ──────────────────────

  @smoke @positive
  Scenario: Switch to the Discharged audit view
    When I click the "Discharged" pill
    Then only patients with status "Discharged" are listed
    And I see the notice "Viewing discharged patients for audit purposes."
    And I see a "Back to active queue" link

  @positive
  Scenario: Switch to the Archived view
    When I click the "Archived" pill
    Then only patients with status "Archived" are listed
    And I see the notice "Viewing archived patients. These records are preserved for reference."
    And I see a "Back to active queue" link

  @positive
  Scenario: Return to the active queue from an audit view
    Given I am viewing the "Archived" patients
    When I click "Back to active queue"
    Then the active queue is shown with the "Intake", "Auth Pending" and "Active" pills

  @negative
  Scenario: Intake, Auth Pending and Active pills are counters, not filters
    When I click the "Active" pill
    Then the roster does NOT filter to only Active patients
    # These three pills have no onTap handler — clicking them is a no-op by design.

  # ───────────────────────────── Search ────────────────────────────────────

  @data @positive
  Scenario Outline: Search filters the roster by name (intended behaviour)
    Given the roster contains a patient named "Rujitha Kannan"
    When I type "<query>" into the "Search patients..." box
    Then the roster shows the patient "Rujitha Kannan"

    Examples:
      | query    |
      | Rujitha  |
      | rujitha  |
      | Kannan   |
      | Ruj      |
      | RUJITHA  |

  @negative
  Scenario: Search with no matching patient shows an empty result
    When I type "Zzzxqnomatch" into the "Search patients..." box
    Then no patient rows are shown
    And an appropriate no-results state is displayed

  @edge @security
  Scenario Outline: Search tolerates special characters and injection strings without crashing
    When I type "<query>" into the "Search patients..." box
    Then the app does not crash or throw
    And no rows are returned for a nonsensical query

    Examples:
      | query                         |
      | '                             |
      | "; DROP TABLE patients; --    |
      | <script>alert(1)</script>     |
      | %                             |
      | \                             |
      | 你好                          |
      | 😀                            |
      | João                          |
      |            (whitespace only)  |

  @edge @negative
  Scenario: Search field currently does not filter the roster (suspected defect)
    Given the "Search patients..." field has no onChanged handler wired in patients_screen.dart
    When I type any query into the "Search patients..." box
    Then the visible roster is unchanged
    # Flag as a bug: the search input renders but performs no client-side filtering.

  @edge
  Scenario: Very long search string is accepted without layout breakage
    When I paste a 5000-character string into the "Search patients..." box
    Then the search box remains usable and the layout does not overflow horizontally

  # ─────────────────────── Create-patient entry points ─────────────────────

  @smoke @positive
  Scenario: New Patient button opens the intake wizard
    When I click "New Patient"
    Then a new intake is started
    And I am navigated to the new-patient intake screen

  @positive
  Scenario: Import button opens the patient import screen
    When I click "Import"
    Then I am navigated to the patient import screen

  # ───────────────── Duplicate-name detection ("Create Anyway") ─────────────

  @positive
  Scenario: Duplicate warning appears when a similar patient already exists
    Given a patient "Rujitha Kannan" already exists
    When I create another patient named "Rujitha Kannan" with the same date of birth
    Then I see the dialog titled "Possible Duplicate Found"
    And I see the text "A patient with similar information already exists:"
    And the matching patient's full name, "DOB:" and "Guardian:" are listed
    And I see the prompt "Do you still want to create a new patient?"
    And I see the actions "Cancel" and "Create Anyway"

  @positive
  Scenario: Create Anyway overrides the duplicate check and creates the patient
    Given the "Possible Duplicate Found" dialog is shown
    When I click "Create Anyway"
    Then the patient is created with skipDuplicateCheck set
    And I see a success toast "Patient 'Rujitha Kannan' created successfully"

  @negative
  Scenario: Cancelling the duplicate warning aborts creation
    Given the "Possible Duplicate Found" dialog is shown
    When I click "Cancel"
    Then no new patient is created
    And I remain on the intake screen

  @edge
  Scenario: At most three duplicate matches are listed in the warning
    Given five existing patients match the new patient's details
    When the "Possible Duplicate Found" dialog appears
    Then only the first three matches are displayed

  @edge @negative
  Scenario: Creating a patient with empty names falls back to default names
    When I complete intake leaving first and last name blank
    Then a patient named "New Patient" is created
    # first/last default to 'New'/'Patient' when empty — probe whether this masks a validation gap.

  # ─────────────────────────── Row actions ─────────────────────────────────

  @positive
  Scenario: Opening a patient row navigates to the patient profile
    When I click a patient row
    Then that patient becomes the selected patient
    And I am navigated to that patient's profile workspace

  @positive
  Scenario: Row kebab menu exposes View Profile, Schedule Session and Archive
    When I open the three-dot menu on an active patient row
    Then I see the menu items "View Profile", "Schedule Session" and "Archive Patient"

  @positive
  Scenario: Archive a patient with confirmation
    When I choose "Archive Patient" from a patient row menu
    Then I see a dialog titled "Archive Patient"
    And I see the message "Are you sure you want to archive <name>? They will be removed from the active queue but records will be preserved."
    When I click "Archive"
    Then the patient is removed from the active queue

  @negative
  Scenario: Cancelling archive keeps the patient in the active queue
    Given the "Archive Patient" confirmation dialog is shown
    When I click "Cancel"
    Then the patient remains in the active queue

  @positive
  Scenario: Restore an archived patient
    Given I am viewing the "Archived" patients
    When I open the row menu and choose "Restore from Archive"
    Then the patient is restored and returns to the active queue

  # ─────────────────────── Layout / responsive / scroll ────────────────────

  @edge
  Scenario: Roster collapses to stacked cards on a narrow viewport
    Given the viewport width is below 700 pixels
    Then each patient is shown as a stacked card instead of a table row
    And the search box moves below the header

  @edge
  Scenario: Wide table scrolls horizontally when the viewport is narrower than the table
    Given the viewport is between 700 and 800 pixels wide
    Then the roster table scrolls horizontally without breaking the page layout

  @edge
  Scenario: Large roster renders without pagination
    Given the clinic has 500 patients
    When the roster finishes loading
    Then all patients are rendered in a single scrollable list with no pager control

  # ─────────────────────── Permission / data isolation ─────────────────────

  @security
  Scenario: A patient row shows only patients belonging to my clinic
    Given another clinic has a patient "Other Clinic Child"
    When my roster finishes loading
    Then "Other Clinic Child" is NOT listed in my roster

  @security @permission
  Scenario: Deep-linking to another clinic's patient profile is denied
    When I open a patient profile URL for a patient in another clinic
    Then I am not shown that patient's records
    And I am blocked or redirected

  @permission
  Scenario Outline: Roster actions available to each role
    Given I am signed in as "<role>"
    When I open the Patients screen
    Then the "New Patient" action is "<new_patient>"
    And the archive action on a row is "<archive>"

    Examples:
      | role  | new_patient | archive     |
      | Owner | enabled     | enabled     |
      | BCBA  | enabled     | enabled     |
      | RBT   | hidden      | unavailable |
