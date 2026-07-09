# Grounded in wabi-flutter-dev:
#   lib/features/clinic/scheduling/screens/new_appointment_dialog.dart   (Add Session / "New Appointment" dialog: title, attendees+patient, date M/D/YYYY, 15-min slots, Save)
#   lib/services/api/appointment_api_service.dart                        (server-side conflict / past-date / duration / auth-hours error strings)
#   lib/features/clinic/sessions/screens/session_workspace_screen.dart   (Check in & Start, EVV, Pause/Resume, End & check out, status badges, "More options" kebab)
#   lib/features/clinic/sessions/widgets/workspace/end_session_review_dialog.dart  (End Session — Review dialog, dispositions, Mark All Not Tracked)
#   lib/features/clinic/scheduling/screens/scheduling_screen.dart        (approved-note lock banner)
# KEY FACTS:
#   - Only the patient is a hard client-side block on Save ("Please add a patient before saving the appointment."); title/date/time all default.
#   - Past dates are selectable in the picker; the SERVER rejects them unless BCBA / Clinical Director / Owner.
#   - Starting a session persists "in_progress" INDEPENDENTLY of geolocation; EVV failure raises a non-blocking "Location Required" dialog (Cancel skips, Retry Location retries).
#   - The gradient "End Session" button and the dialog title are painted on the Flutter canvas (not in the semantics tree); detect the dialog via "Mark All Not Tracked".

Feature: Sessions — schedule, run, and end a therapy session
  As a clinician (RBT/BCBA) delivering ABA therapy
  I want to create a session, check in with EVV, run it, and end/check out
  So that the visit is verified, timed, dispositioned and billable.
  Creating a session opens the "New Appointment" dialog; running it opens the
  Session Workspace where "Check in & Start" performs an Electronic Visit
  Verification (EVV) geolocation capture required by Medicaid/HIPAA; ending it
  opens the "End Session — Review" dialog that forces a disposition on every
  target that had no data collected.

  Background:
    Given I am logged in as a clinician for "Demo Patient 2"
    And I am on the "Sessions" list
    And the list shows an "All (N)" session-count filter and an "Add Session" button

  # ── Create session: happy paths ──────────────────────────────────────────
  @smoke @positive
  Scenario: Create a Direct Service session on a future date
    When I click "Add Session"
    And I type "E2E DP2 Session" into the "Add a title" field
    And I open "Add attendees and patient..." and search "Demo Patient 2"
    And I select the "Demo Patient 2" patient result
    And I click "Expand"
    And I pick a "Start date" 10 days in the future via the M/D/YYYY calendar
    And I pick a free 15-minute "Start time" slot
    And I click "Save"
    Then I see the toast "Appointment created"
    And the "All (N)" session count increases by one

  @positive
  Scenario: Title defaults to "New Appointment" when left blank
    When I click "Add Session"
    And I leave the "Add a title" field empty
    And I add the patient "Demo Patient 2"
    And I pick a free future date and time
    And I click "Save"
    Then the session is created with the title "New Appointment"
    And I see the toast "Appointment created"

  @positive @data
  Scenario Outline: Create sessions of each appointment type
    When I click "Add Session"
    And I add the patient "Demo Patient 2"
    And I select the "<type>" appointment type
    And I pick a free future date and time
    And I click "Save"
    Then I see the toast "Appointment created"

    Examples:
      | type              |
      | Intake            |
      | Assessment        |
      | Direct Service    |
      | Supervision       |
      | Caregiver Training |
      | Misc              |

  # ── Create session: validation / negative ────────────────────────────────
  @negative
  Scenario: Saving without a patient is blocked inline
    When I click "Add Session"
    And I type "No patient session" into the "Add a title" field
    And I do NOT add any patient
    And I click "Save"
    Then the dialog stays open
    And I see the inline red banner "Please add a patient before saving the appointment."
    And no "Appointment created" toast appears
    And the "All (N)" session count is unchanged

  @negative
  Scenario: Booking a patient over an existing appointment is rejected with a conflict
    Given "Demo Patient 2" already has an appointment at the chosen date and time
    When I click "Add Session"
    And I add the patient "Demo Patient 2"
    And I pick that exact date and time
    And I click "Save"
    Then the dialog stays open
    And I see the inline banner "This patient already has an appointment during this time. Please pick a different time."
    And the "All (N)" session count is unchanged

  @negative
  Scenario: Double-booking the same provider is rejected
    Given the provider is already booked during the chosen slot
    When I create a session for a different patient at that slot
    And I click "Save"
    Then I see the inline banner "This provider is already booked during this time. Please pick a different time or provider."
    And the dialog stays open so I can pick another time

  @edge
  Scenario: Choosing a fresh slot after a conflict succeeds without reopening the dialog
    Given a save was rejected with "This patient already has an appointment during this time. Please pick a different time."
    When I change the "Start time" to a free 15-minute slot
    And I click "Save"
    Then I see the toast "Appointment created"

  # ── Date boundaries: past / future ───────────────────────────────────────
  @negative @permission
  Scenario: A non-privileged clinician cannot schedule a past-dated session
    Given I am signed in without BCBA, Clinical Director or Owner role
    When I click "Add Session"
    And I add the patient "Demo Patient 2"
    And I pick a "Start date" in the past via the calendar
    And I click "Save"
    Then the save is rejected with "Only a BCBA, Clinical Director, or Owner can schedule a past-dated appointment."
    And the dialog stays open

  @permission @positive
  Scenario: A BCBA / Owner can back-date a session
    Given I am signed in as an "Owner"
    When I create a session for "Demo Patient 2" on a past date
    And I click "Save"
    Then the session is created
    And I see the toast "Appointment created"

  @edge
  Scenario: A session longer than the maximum duration is rejected
    When I create a session with an "End time" more than 12 hours after "Start time"
    And I click "Save"
    Then the save is rejected with "Appointments can't be longer than 12 hours."

  @edge
  Scenario: Past-date days are selectable in the picker but blocked server-side
    When I open the "Start date" calendar
    Then past day cells are still tappable (not visually disabled)
    But selecting one and saving surfaces the server past-date restriction

  # ── Open the workspace ───────────────────────────────────────────────────
  @smoke @positive
  Scenario: Open a scheduled session into the Session Workspace
    Given a scheduled "Demo Patient 2" session exists in the list
    When I click the session row to the left of its "Session actions" kebab
    Then the Session Workspace opens showing "Demo Patient 2"
    And I see a start control labelled "Check in & Start" (or "Tap to Start Session")
    And the status badge reads "Ready"

  @edge
  Scenario: The empty Session Data tab prompts to start before any collection
    Given I opened a not-yet-started session workspace
    Then the Session Data tab shows "Tap to Start Session"
    And the subtext "Starts the timer and enables data collection"

  # ── Check-in WITH geolocation (EVV granted) ──────────────────────────────
  @smoke @positive
  Scenario: Check in and start with geolocation granted captures EVV
    Given the browser has geolocation permission granted
    When I click "Check in & Start"
    Then the session moves to status "In Progress"
    And the session timer starts counting
    And the stats dropdown shows "EVV Checked In" with the captured coordinates

  # ── Check-in WITHOUT geolocation (EVV denied) ────────────────────────────
  @negative @security
  Scenario: Denied geolocation raises the non-blocking "Location Required" EVV dialog
    Given the browser denies geolocation permission
    When I click "Check in & Start"
    Then a non-dismissible dialog titled "Location Required" appears
    And it warns "We could not access your location. Electronic Visit Verification (EVV) is required by Medicaid and HIPAA for all ABA therapy sessions."
    And it offers "Please enable location permissions in your browser and try again, or cancel to skip Start Session."
    And the dialog has a "Cancel" button and a "Retry Location" button

  @edge @security
  Scenario: Cancelling the EVV dialog still starts the session but flags EVV not captured
    Given the "Location Required" dialog is shown at check-in
    When I click "Cancel"
    Then the session still moves to "In Progress"
    And EVV is recorded as not captured for the visit

  @edge
  Scenario: Retrying location after granting permission captures EVV
    Given the "Location Required" dialog is shown at check-in
    When I grant geolocation permission and click "Retry Location"
    Then the location is captured
    And the stats dropdown shows "EVV Checked In"

  # ── Pause / resume ───────────────────────────────────────────────────────
  @positive
  Scenario: Pause an in-progress session halts trial timing
    Given the session is "In Progress"
    When I open the "More options" kebab and choose "Pause session"
    Then the status shows "Paused"
    And a banner "Session paused" with "Trial timing is halted. Resume from the controls above." is shown
    And the kebab item now reads "Resume session"

  @positive
  Scenario: Resume a paused session continues the timer excluding paused time
    Given the session is paused
    When I choose "Resume session" from the "More options" kebab
    Then the status returns to "In Progress"
    And the paused span is excluded from the billable active duration

  @edge
  Scenario: The paused banner can be dismissed without resuming
    Given the session is paused and the "Session paused" banner is shown
    When I click the "Dismiss" icon on the banner
    Then the banner disappears
    But the session remains paused

  # ── Abandon / navigate away ──────────────────────────────────────────────
  @edge
  Scenario: Leaving an in-progress session and returning preserves "In Progress"
    Given the session is "In Progress" with recorded data
    When I navigate back to the Sessions list and reopen the session
    Then the workspace still shows status "In Progress"
    And the previously recorded data is retained

  # ── End & check out: review dialog ───────────────────────────────────────
  @smoke @positive
  Scenario: End & check out opens the "End Session — Review" dialog
    Given the session is "In Progress"
    When I open the "More options" kebab and choose "End & check out"
    Then the "End Session — Review" dialog opens
    And a "Session Summary" shows "Duration", "Trials" and "Accuracy"
    And it lists "Behaviors: <count>"
    And targets with no data appear under "These targets had no data collected:"
    And a "Mark All Not Tracked" link, a "Cancel" button and an "End Session" button are present

  @positive
  Scenario: Dispositioning every no-data target as zero occurrences records real 0% data points
    Given the "End Session — Review" dialog lists untracked targets
    When I select "Zero occurrences (record as 0%)" for each listed target
    And I click "End Session"
    Then each dispositioned target is saved with a real 0% data point
    And the session reaches status "Completed"

  @positive
  Scenario: Default disposition records untracked targets as no data point
    Given the "End Session — Review" dialog lists untracked targets
    Then every target defaults to "Not tracked (no data point)"
    When I click "End Session" without changing anything
    Then the untracked targets are recorded for audit only with no data point
    And the session reaches "Completed"

  @positive
  Scenario: "Mark All Not Tracked" sets every listed target to the not-tracked disposition
    Given the "End Session — Review" dialog lists several untracked targets
    When I click "Mark All Not Tracked"
    Then all listed targets switch to "Not tracked (no data point)"

  @data
  Scenario Outline: Each no-data target disposition is honoured on end
    Given the "End Session — Review" dialog lists a target with no data
    When I choose "<disposition>" and click "End Session"
    Then the target is stored as "<stored>"

    Examples:
      | disposition                        | stored                       |
      | Zero occurrences (record as 0%)    | 0% data point                |
      | Not tracked (no data point)        | audit-only, no data point    |

  @edge
  Scenario: Cancelling the review dialog returns to the workspace without ending
    Given the "End Session — Review" dialog is open
    When I click "Cancel"
    Then the dialog closes
    And the session is still "In Progress"

  @edge
  Scenario: End Session shows a processing state while persisting
    Given the "End Session — Review" dialog is open
    When I click "End Session"
    Then the button label changes to "Ending…" and both buttons are disabled while it saves

  # ── End with unsaved data / failures ─────────────────────────────────────
  @negative @edge
  Scenario: A note-capture failure blocks ending the session
    Given the session is being ended and the note fails to capture
    Then the session is NOT ended
    And I see the error "Couldn't capture your note — session not ended. Please try again."

  @edge @security
  Scenario: Check-out re-runs EVV geolocation
    Given the session is "In Progress" and geolocation is denied
    When I choose "End & check out"
    Then the "Location Required" dialog appears offering to "cancel to skip End Session"
    And cancelling still lets me proceed to end the session

  # ── Concurrent editing / supervision ─────────────────────────────────────
  @edge @security
  Scenario: A supervisor observing an RBT session sees data read-only and live-polled
    Given I am a supervisor viewing a supervised RBT session in supervision mode
    Then the RBT's data collection is shown read-only
    And the workspace polls for the RBT's updates every few seconds
    And my role is labelled "Supervisor"

  @edge
  Scenario: When the RBT ends the session the supervisor is routed to Supervision Notes
    Given I am observing an RBT session that the RBT then ends
    Then I am taken to the Supervision Notes with "Add and save your Supervision Notes below."

  # ── Permission gating ────────────────────────────────────────────────────
  @permission
  Scenario: Only owner/administrator/clinical_director see "Edit session details"
    Given I opened a session workspace as a role without edit rights
    When I open the "More options" kebab
    Then no "Edit session details" item is present

  @permission @positive
  Scenario: A privileged role sees "Edit session details" in the kebab
    Given I opened a session workspace as an "administrator"
    When I open the "More options" kebab
    Then an "Edit session details" item is present

  @permission
  Scenario: A completed session is read-only
    Given a "Completed" session workspace
    Then start, pause and end controls are hidden or disabled
    And data collection is disabled unless an owner re-opens the service fields

  # ── Accessibility / empty states ─────────────────────────────────────────
  @a11y
  Scenario: The start control and status badge expose accessible labels
    Given the Session Workspace is open
    Then the start control is reachable with an accessible name "Check in & Start"
    And the "More options" kebab exposes an accessible name

  @edge
  Scenario: The Accommodations and Session Settings options are placeholders
    Given the "More options" kebab is open
    When I choose "Accommodations"
    Then a dialog "Accommodations" says "Accommodations settings coming soon." with an "OK" button
    When I choose "Session Settings"
    Then a dialog "Session Settings" says "Session settings coming soon." with an "OK" button

  @security
  Scenario: EVV coordinates and status persist to the visit record for audit
    Given I checked in with geolocation granted
    When I end and check out the session
    Then the captured EVV coordinates and check-in status are retained on the completed visit
