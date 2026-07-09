Feature: Scheduling — calendar, appointments, recurrence & conflict handling
  As a clinician (BCBA / Owner / RBT) on the Wabi clinic web app
  I want to view a calendar and create, edit, reschedule, cancel and delete
  appointments across appointment types, with conflict and authorization guards
  So that sessions are scheduled correctly without double-booking, exhausting
  authorized hours, or leaking data across clinics.

  # Grounded in wabi-flutter-dev/lib/features/clinic/scheduling/*:
  #   scheduling_screen.dart, new_appointment_dialog.dart,
  #   appointment_details_dialog.dart, series_scope_dialog.dart,
  #   ui/scheduling_view_model.dart, data/models/appointment_models.dart,
  #   widgets/recurrence_selector.dart.
  # Appointment-type keys (FR-SC19): intake, assessment, direct_service,
  #   supervision, caregiver_training, consultation, meeting, misc.
  # Calendar view modes: Day / Week / Month, and Calendar / Table display toggle.

  Background:
    Given I am logged in to the Wabi clinic web app as an Owner
    And I have navigated to the "Schedule" section from the left sidebar
    And the calendar has finished loading appointments
    And the default view shows only my own calendar (my team-member is pre-selected)

  # ───────────────────────────────────────────────────────────────────────────
  # Calendar view switching & display toggle
  # ───────────────────────────────────────────────────────────────────────────

  @smoke @positive
  Scenario: Schedule page loads with calendar, view toggles and New button
    Then I see the calendar grid for the current week
    And I see the "Day", "Week" and "Month" view options
    And I see the "Calendar" / "Table" display toggle
    And I see the "New" appointment button
    And I see the "Team Members", "Patients" and "Appointment Types" filter panels

  @positive @data
  Scenario Outline: Switch between calendar time views
    When I select the "<view>" view
    Then the calendar renders the "<view>" layout
    And the date header updates to describe the "<view>" range

    Examples:
      | view  |
      | Day   |
      | Week  |
      | Month |

  @positive
  Scenario: Switch from Calendar display to Table display
    When I select the "Table" display toggle
    Then appointments are listed in a table with columns for date, time, patient, provider, type and status
    When I select the "Calendar" display toggle
    Then the grid calendar is shown again

  @edge
  Scenario: The selected time view persists while paging through dates
    Given I have selected the "Day" view
    When I click "Next" three times
    Then the calendar stays in "Day" view for the new date

  # ───────────────────────────────────────────────────────────────────────────
  # Navigation — Today / Previous / Next / mini-calendar
  # ───────────────────────────────────────────────────────────────────────────

  @smoke @positive
  Scenario: Navigate to Today
    Given I have paged the calendar forward by several weeks
    When I click "Today"
    Then the calendar returns to the week containing the current date
    And today's column is highlighted

  @positive @data
  Scenario Outline: Previous/Next step by one period per view
    Given I have selected the "<view>" view
    When I click "<direction>"
    Then the visible range moves by one <step>

    Examples:
      | view | direction | step |
      | Week | Next      | week |
      | Week | Previous  | week |
      | Day  | Next      | day  |
      | Day  | Previous  | day  |

  @positive
  Scenario: Jump to a date using the mini-calendar
    When I advance the mini-calendar to next month using its "next month" chevron
    And I click a day-of-month in the mini-calendar
    Then the main calendar navigates to that selected date

  @edge
  Scenario: Mini-calendar month navigation across a year boundary
    Given the mini-calendar is showing December of the current year
    When I click the mini-calendar "next month" chevron
    Then the mini-calendar shows January of the next year

  # ───────────────────────────────────────────────────────────────────────────
  # Create appointment — per appointment type
  # ───────────────────────────────────────────────────────────────────────────

  @smoke @positive @data
  Scenario Outline: Create an appointment for each appointment type
    When I click "New" to open the New Appointment dialog
    And I select appointment type "<type>"
    And I select a patient "Demo Patient 2"
    And I select a provider
    And I set the date to today and the start time to a free slot
    And I keep the default duration
    And I save the appointment
    Then the appointment is created and appears on the calendar
    And the appointment block is coloured for the "<type>" type

    Examples:
      | type              |
      | Intake            |
      | Assessment        |
      | Direct Service    |
      | Supervision       |
      | Caregiver Training |
      | Consultation      |
      | Meeting           |
      | Miscellaneous     |

  @positive
  Scenario: Creating a service-type appointment also creates a linked Session
    When I create a "Direct Service" appointment for "Demo Patient 2" today
    Then a Session is created and appears in the Sessions tab for that patient

  @positive @data
  Scenario Outline: Duration options are available when creating
    When I open the New Appointment dialog
    Then I can choose a duration of "<duration>" minutes

    Examples:
      | duration |
      | 30       |
      | 45       |
      | 60       |
      | 90       |
      | 120      |
      | 180      |

  @positive
  Scenario: Create an all-day appointment
    When I open the New Appointment dialog
    And I select appointment type "Meeting"
    And I toggle "All day" on
    Then the start/end time pickers are hidden
    And saving creates an all-day block spanning the day

  @positive
  Scenario: Selecting a time slot on the grid pre-fills the New Appointment dialog
    When I click an empty 10:00 AM slot in the "Day" view
    Then the New Appointment dialog opens pre-filled with that date and start time

  @positive
  Scenario: Title defaults from type and patient when left blank
    When I open the New Appointment dialog
    And I select appointment type "Intake"
    And I select a patient "Demo Patient 2"
    And I leave the "Title" field blank
    And I save the appointment
    Then the appointment title defaults to the type and patient name

  # ───────────────────────────────────────────────────────────────────────────
  # Required-field validation on create
  # ───────────────────────────────────────────────────────────────────────────

  @negative @smoke
  Scenario: Saving without a patient is rejected
    When I open the New Appointment dialog
    And I select appointment type "Direct Service"
    And I do not select a patient
    And I attempt to save the appointment
    Then I see the validation message "Please add a patient before saving the appointment."
    And the appointment is not created

  @negative @data
  Scenario Outline: Required fields block saving a new appointment
    When I open the New Appointment dialog
    And I leave "<field>" empty
    And I attempt to save
    Then the appointment is not saved and "<field>" is flagged as required

    Examples:
      | field             |
      | Appointment type  |
      | Patient           |
      | Provider          |
      | Date & Time       |

  @negative @edge
  Scenario: End time earlier than start time is rejected
    When I open the New Appointment dialog
    And I set the start time to 3:00 PM and the end time to 2:00 PM
    And I attempt to save
    Then the appointment is not created because the duration is invalid

  # ───────────────────────────────────────────────────────────────────────────
  # Recurrence
  # ───────────────────────────────────────────────────────────────────────────

  @positive @data
  Scenario Outline: Create a recurring appointment with each frequency
    When I open the New Appointment dialog
    And I select a patient "Demo Patient 2"
    And I toggle "Recurring" on
    And I set "Repeat every" to 1 "<frequency>"
    And I save the appointment
    Then a recurring series is created described as "Occurs <description>"

    Examples:
      | frequency | description  |
      | day       | every day    |
      | week      | every week   |
      | 2 weeks   | every 2 weeks |
      | month     | every month  |

  @positive
  Scenario: Weekly recurrence with day-of-week chips
    When I open the New Appointment dialog
    And I toggle "Recurring" on
    And the frequency is "week"
    Then the day-of-week chips "M T W T F S S" are shown
    When I select "M" and "W" and "F"
    And I save the appointment
    Then the series recurs on Monday, Wednesday and Friday

  @edge
  Scenario: The last selected day-of-week chip cannot be deselected
    Given a weekly recurring appointment with only "M" selected
    When I tap the "M" chip to deselect it
    Then "M" remains selected because at least one day is required

  @positive
  Scenario: Set a recurrence end date with "Until"
    When I open the New Appointment dialog
    And I toggle "Recurring" on
    And I set the "Until" date to 90 days from today
    Then the recurrence summary ends with "until" that date
    When I click "Remove end date"
    Then the end date shows "No end date"

  @edge
  Scenario: Recurrence "Until" date cannot be before today
    When I open the recurrence "Until" date picker
    Then dates before today are not selectable

  @edge @data
  Scenario Outline: Repeat-every interval accepts values 1 through 12
    When I open the recurrence options
    Then the "Repeat every" interval offers "<interval>"

    Examples:
      | interval |
      | 1        |
      | 2        |
      | 6        |
      | 12       |

  # ───────────────────────────────────────────────────────────────────────────
  # Conflict / double-booking / auth-hours override
  # ───────────────────────────────────────────────────────────────────────────

  @negative @smoke
  Scenario: Double-booking the same patient/time is rejected
    Given "Demo Patient 2" already has an appointment today at 10:00 AM
    When I create another appointment for "Demo Patient 2" today at 10:00 AM
    Then the save is rejected with a conflict message containing "already has an appointment at that time"
    And no duplicate appointment is created

  @negative @edge
  Scenario: Overlapping (not identical) appointments are detected as a conflict
    Given "Demo Patient 2" has a 60-minute appointment today at 10:00 AM
    When I create a 60-minute appointment for "Demo Patient 2" today at 10:30 AM
    Then a scheduling conflict is reported

  @negative
  Scenario: Booking beyond remaining authorized hours prompts an override
    Given the patient has fewer authorized hours remaining than the appointment requires
    When I attempt to save the appointment
    Then I see an insufficient-authorized-hours warning showing hours remaining and hours requested
    And I am prompted with "Save anyway?"

  @permission @positive
  Scenario: Owner overrides the auth-hours guard with a reason
    Given I am an Owner and the auth-hours guard has blocked the save
    When I choose to override
    And I enter text in "Reason for override (required)"
    And I click "Override and save"
    Then the appointment is created despite insufficient authorized hours

  @permission @negative
  Scenario: Override without a reason is blocked
    Given the auth-hours guard has blocked the save
    When I choose to override
    And I leave "Reason for override (required)" empty
    And I click "Override and save"
    Then the override is rejected until a reason is provided

  @permission @security @negative
  Scenario: A non-Owner cannot override the auth-hours guard
    Given I am logged in as a non-Owner clinician
    And the auth-hours guard has blocked the save
    Then the override control is disabled
    And attempting the override returns a permission error (override_not_permitted)

  # ───────────────────────────────────────────────────────────────────────────
  # Appointment details, hover card & locked notes
  # ───────────────────────────────────────────────────────────────────────────

  @positive
  Scenario: Hover card shows appointment summary
    Given an appointment for "Demo Patient 2" exists today
    When I hover over its calendar block
    Then a hover card shows the title, status, time range, patient and provider

  @smoke @positive
  Scenario: Approved-and-locked session shows the BCBA amend banner
    Given a session appointment whose notes have been approved and locked
    When I view it as a non-BCBA on the Schedule
    Then the hover card shows "Notes approved — only a BCBA can amend."
    And it shows the "Completed" status with a "Notes Submitted" badge

  @positive
  Scenario: Locked-notes appointment offers a read-only View Details
    Given an appointment whose notes are approved and locked
    When I open it
    Then it opens read-only via "View Details"
    And editing the note is not available to a non-BCBA

  @a11y
  Scenario: Appointment blocks expose an accessible label
    Given appointments are rendered on the calendar
    Then each block exposes an accessible label including its title and time
    And keyboard focus can reach the "New" button and view toggles

  # ───────────────────────────────────────────────────────────────────────────
  # Edit / reschedule / drag
  # ───────────────────────────────────────────────────────────────────────────

  @positive @smoke
  Scenario: Edit an existing appointment
    Given an appointment for "Demo Patient 2" exists today
    When I open it and choose "Edit"
    And I change the duration to 90 minutes
    And I save the changes
    Then the appointment reflects the new duration on the calendar

  @positive
  Scenario: Drag an appointment to reschedule it to another slot
    Given an appointment exists at 10:00 AM today
    When I drag its block to the 1:00 PM slot
    Then the appointment is rescheduled to 1:00 PM

  @negative @edge
  Scenario: Drag onto a conflicting slot is rejected
    Given "Demo Patient 2" has appointments at 10:00 AM and 1:00 PM today
    When I drag the 10:00 AM block onto the 1:00 PM block
    Then the move fails with a message starting "Failed to move appointment:"
    And the appointment stays at its original time

  @positive @data
  Scenario Outline: Editing one occurrence of a series prompts for scope
    Given I edit an occurrence of a recurring series
    When I choose the scope "<scope>"
    And I confirm with "Update"
    Then only the occurrences matching "<scope>" are updated

    Examples:
      | scope                       |
      | This event                  |
      | This and following events   |
      | All events                  |

  @edge
  Scenario: Series edit can preserve individually-customised occurrences
    Given a series contains occurrences edited individually via "This event"
    When I edit the series with scope "All events"
    Then I see the option "Keep sessions edited individually" enabled by default
    And those occurrences are not overwritten unless I turn it off

  # ───────────────────────────────────────────────────────────────────────────
  # Cancel appointment
  # ───────────────────────────────────────────────────────────────────────────

  @positive @smoke
  Scenario: Cancel an appointment
    Given an appointment for "Demo Patient 2" exists today
    When I open it and choose "Cancel Appointment"
    And I optionally add a cancellation reason
    And I confirm the cancellation
    Then I see "Appointment cancelled"
    And the block is shown with cancelled styling (strikethrough)

  @edge
  Scenario: Cancellation reason is optional
    Given I am cancelling an appointment
    When I leave the cancellation reason empty
    And I confirm the cancellation
    Then the appointment is still cancelled successfully

  @positive
  Scenario: A cancelled appointment remains visible but styled as cancelled
    Given an appointment has been cancelled
    Then it stays on the calendar with a "Cancelled" status and strikethrough text
    And it is not counted as an active conflict for new bookings

  # ───────────────────────────────────────────────────────────────────────────
  # Delete appointment (single vs series)
  # ───────────────────────────────────────────────────────────────────────────

  @positive
  Scenario: Delete a single non-recurring appointment
    Given a one-off appointment exists today
    When I open it and choose "Delete"
    And I confirm the deletion
    Then the appointment is removed from the calendar

  @positive @data
  Scenario Outline: Delete an occurrence of a recurring series with scope
    Given a recurring appointment occurrence is open
    When I choose "Delete"
    And the "Delete recurring appointment" prompt appears
    And I select the scope "<scope>"
    And I confirm with "Delete"
    Then the occurrences matching "<scope>" are deleted

    Examples:
      | scope                       |
      | This event                  |
      | This and following events   |
      | All events                  |

  @edge
  Scenario: Cancelling the series-scope prompt aborts the delete
    Given the "Delete recurring appointment" prompt is open
    When I click "Cancel"
    Then nothing is deleted

  # ───────────────────────────────────────────────────────────────────────────
  # Date-boundary edges
  # ───────────────────────────────────────────────────────────────────────────

  @edge
  Scenario: Booking an appointment in the past
    When I create an appointment dated yesterday
    Then the app either warns about the past date or records it as a historical appointment

  @edge
  Scenario: Booking an appointment far in the future
    When I create an appointment dated one year from today
    Then the appointment is created and reachable by paging the calendar forward

  @edge
  Scenario: Appointment spanning a Daylight Saving Time change
    Given a recurring weekly appointment crosses a DST transition
    Then each occurrence keeps its local wall-clock start time
    And the displayed duration remains correct

  @edge
  Scenario: Appointment times display in the clinic's local timezone
    Given an appointment stored in UTC
    Then it is shown converted to the local timezone on the calendar

  # ───────────────────────────────────────────────────────────────────────────
  # Filters
  # ───────────────────────────────────────────────────────────────────────────

  @positive @smoke
  Scenario: Filter the calendar by team member
    Given multiple team members have appointments today
    When I select only one team member in the "Team Members" filter
    Then only that member's appointments are shown

  @positive
  Scenario: Select-all and Clear on the Team Members filter
    When I click "Clear" in the "Team Members" filter
    Then no team members are selected and the grid shows no member calendars
    When I click "Select all" in the "Team Members" filter
    Then every team member is selected again

  @positive
  Scenario: Team-member selection survives a page refresh
    Given I selected a specific subset of team members
    When I reload the Schedule page
    Then my previous team-member selection is restored

  @positive @data
  Scenario Outline: Filter by appointment type
    Given appointments of several types exist today
    When I deselect all types except "<type>" in the "Appointment Types" filter
    Then only "<type>" appointments are shown on the calendar

    Examples:
      | type              |
      | Intake            |
      | Assessment        |
      | Direct Service    |
      | Supervision       |
      | Caregiver Training |
      | Consultation      |
      | Meeting           |
      | Miscellaneous     |

  @positive
  Scenario: Select-all and Clear on the Appointment Types filter
    When I click "Clear" in the "Appointment Types" filter
    Then no appointment types are shown
    When I click "Select all" in the "Appointment Types" filter
    Then all appointment types are shown again

  @positive
  Scenario: Filter the calendar by patient
    Given appointments for several patients exist today
    When I select "Demo Patient 2" in the "Patients" filter
    Then only that patient's appointments are shown

  # ───────────────────────────────────────────────────────────────────────────
  # Empty state
  # ───────────────────────────────────────────────────────────────────────────

  @edge
  Scenario: Empty calendar on a day with no appointments
    Given I navigate to a day with no appointments
    Then the calendar shows an empty state such as "No appointments scheduled"

  @edge
  Scenario: Table view with no appointments
    Given I am in "Table" display on a range with no appointments
    Then the table shows an empty state and no rows

  # ───────────────────────────────────────────────────────────────────────────
  # Permission gating
  # ───────────────────────────────────────────────────────────────────────────

  @permission @positive
  Scenario: A BCBA can add a Supervision appointment
    Given I am logged in as a BCBA
    When I create a "Supervision" appointment
    Then the "Add Supervision" action is available and the appointment saves

  @permission @negative
  Scenario: A read-only role cannot create appointments
    Given I am logged in with a role that lacks scheduling write access
    Then the "New" appointment action is unavailable or disabled

  @permission
  Scenario: EVV geolocation is required when starting a session from an appointment
    Given a scheduled service appointment for today
    When I start the session from its calendar block
    Then Electronic Visit Verification requires a geolocation check-in before the session starts

  # ───────────────────────────────────────────────────────────────────────────
  # Security — cross-clinic data isolation & injection
  # ───────────────────────────────────────────────────────────────────────────

  @security @negative
  Scenario: Cannot book an appointment for a patient in another clinic
    Given a patient belongs to a clinic I am not a member of
    Then that patient is not listed in the New Appointment patient picker
    And a crafted request to book that patient is rejected by the backend

  @security @negative
  Scenario: Cannot view or edit another clinic's appointment by id
    Given an appointment id belonging to another clinic
    When I attempt to open it directly
    Then access is denied and no appointment details are revealed

  @security @edge
  Scenario: Script-like text in the title is stored and rendered safely
    When I create an appointment with the title "<script>alert(1)</script>"
    Then the title is rendered as inert text on the calendar and hover card
    And no script executes
