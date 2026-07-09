Feature: Communication — Telehealth, Contacts, Phone Calls, Notifications
  As a clinician (Owner) I coordinate virtual visits, look up the contact
  directory, log phone calls, and manage notifications from the Communication
  area of the Wabi web app (dev.wabicare.com). Scenarios are grounded in the
  Flutter source (communication/telehealth, contacts, phone, notifications) and
  probe positive/negative/edge/permission/security and empty/error states.

  # Source facts embedded below:
  #  TELEHEALTH (/communication/telehealth):
  #    - Header "Telehealth" / "Virtual therapy sessions"; button "Schedule Session"
  #    - Tabs: Upcoming, In Progress, Completed, Cancelled
  #    - Summary cards: Upcoming, In Progress, Completed Today, Avg Duration
  #    - Schedule dialog "Schedule Telehealth Session": Patient Name*, Staff / Therapist*,
  #      Session Type* (direct_therapy/supervision/assessment/parent_training), Date*, Time*, Notes
  #    - Card actions: "Start Session" (scheduled), "End Session" (in_progress), "View Notes" (completed)
  #    - Empty: "No <tab> sessions" / "Schedule a new telehealth session to get started"
  #    - NOTE: this is scheduling/tracking only — there is NO in-app video, and NO camera/mic
  #      permission prompt in the source (join = "Start Session" only).
  #  CONTACTS (/communication/contacts):
  #    - Header "Contact Directory" / "N contact(s) in directory"; button "Add Contact"
  #    - Search "Search contacts by name, email, or phone..."; categories: All, Staff, Patient,
  #      Caregiver, Insurance, External; table cols NAME, PHONE, EMAIL, CATEGORY, STATUS
  #    - NOTE: "Add Contact" only shows snackbar "Add contact coming soon" — add/edit/delete NOT implemented
  #    - Empty: "No contacts yet"/"Add your first contact to get started." OR
  #      "No matching contacts"/"Try adjusting your search or filter criteria."
  #  PHONE (/communication/phone):
  #    - Header "Phone Calls" / "Log and track patient communication calls"; button "Log Call"
  #    - Tabs: All, Inbound, Outbound, Missed; summary Total Calls/Inbound/Outbound/Missed
  #    - Log dialog "Log Phone Call": Contact Name*, Phone Number*, Direction* (inbound/outbound), Notes
  #    - Table cols: Contact, Phone Number, Direction, Status, Duration, Date
  #    - Empty: "No phone calls found"/"Start by logging a new call"
  #  NOTIFICATIONS (/communication/notifications):
  #    - Header "Notifications" / "N unread notification(s)" or "All caught up"; button "Mark All Read"
  #    - Tabs: All, Unread, System, Alerts; per-row "Read" + dismiss (x); "High Priority" badge
  #    - Empty: "No <tab>notifications"/"You're all caught up. Check back later for updates."

  Background:
    Given I am logged in as an "Owner" clinician
    And I open the "Communication" area

  # =====================================================================
  # TELEHEALTH
  # =====================================================================

  @smoke @positive
  Scenario: Telehealth screen renders header, tabs, and summary cards
    When I open "Telehealth"
    Then I see the header "Telehealth" and subtitle "Virtual therapy sessions"
    And I see tabs "Upcoming", "In Progress", "Completed", "Cancelled"
    And I see summary cards "Upcoming", "In Progress", "Completed Today", "Avg Duration"
    And I see a "Schedule Session" button

  @smoke @positive
  Scenario: Schedule a telehealth session with all required fields
    When I open "Telehealth" and click "Schedule Session"
    Then I see the dialog "Schedule Telehealth Session"
    When I fill "Patient Name" with "Rujitha Kannan"
    And I fill "Staff / Therapist" with "Dr. Smith"
    And I select "Session Type" "Direct Therapy"
    And I pick a "Date" of tomorrow
    And I pick a "Time" of "10:00"
    And I fill "Notes" with "Initial virtual visit"
    And I click "Schedule"
    Then the dialog closes and the session appears under "Upcoming"

  @positive @data
  Scenario Outline: Session Type dropdown offers all supported types
    When I open the schedule dialog and open "Session Type"
    Then I can select "<label>"

    Examples:
      | label           |
      | Direct Therapy  |
      | Supervision     |
      | Assessment      |
      | Parent Training |

  @negative
  Scenario: Schedule dialog marks Patient Name, Staff, Type, Date, Time as required
    When I open the schedule dialog
    Then "Patient Name", "Staff / Therapist", "Session Type", "Date", and "Time" show a required indicator
    When I click "Schedule" with "Patient Name" empty
    Then the session is not created

  @edge
  Scenario: Date picker restricts scheduling to today through one year ahead
    When I open the schedule dialog and open the "Date" picker
    Then dates before today are not selectable
    And dates more than 365 days ahead are not selectable

  @positive
  Scenario: Start a scheduled session
    Given a session under "Upcoming" with status "scheduled"
    Then its card shows a "Start Session" action
    When I click "Start Session"
    Then the session moves toward "In Progress"

  @positive
  Scenario: End an in-progress session
    Given a session with status "in_progress"
    Then its card shows an "End Session" action
    When I click "End Session"
    Then the session moves toward "Completed"

  @positive
  Scenario: Completed session exposes View Notes
    Given a session with status "completed"
    Then its card shows a "View Notes" action

  @edge
  Scenario Outline: Empty state per telehealth tab
    Given there are no sessions in the "<tab>" tab
    When I open the "<tab>" tab
    Then I see "No <lowertab> sessions"
    And I see "Schedule a new telehealth session to get started"

    Examples:
      | tab         | lowertab    |
      | Upcoming    | upcoming    |
      | In Progress | in progress |
      | Completed   | completed   |
      | Cancelled   | cancelled   |

  @negative
  Scenario: Telehealth load error offers Retry
    Given the telehealth API returns an error
    When I open "Telehealth"
    Then I see the error message and a "Retry" button

  @edge @security
  Scenario: In-app camera/microphone are not requested by the telehealth screen
    When I schedule and start a telehealth session
    Then no browser camera or microphone permission prompt appears
    # NOTE: telehealth here is scheduling/tracking only; there is no embedded video call.

  # =====================================================================
  # CONTACTS
  # =====================================================================

  @smoke @positive
  Scenario: Contact Directory renders header, search, category pills, and table
    When I open "Contacts"
    Then I see the header "Contact Directory"
    And I see the count "N contacts in directory"
    And I see a search field "Search contacts by name, email, or phone..."
    And I see category pills "All", "Staff", "Patient", "Caregiver", "Insurance", "External"

  @positive @data
  Scenario Outline: Filter contacts by category
    When I open "Contacts" and click the "<category>" category
    Then only contacts in the "<category>" category are listed

    Examples:
      | category  |
      | Staff     |
      | Patient   |
      | Caregiver |
      | Insurance |
      | External  |

  @positive
  Scenario: Search contacts by name, email, or phone
    When I type "smith" into the contacts search field
    Then only contacts whose name, email, or phone contains "smith" remain

  @edge
  Scenario: Search + category combine, and no match shows the filtered empty state
    Given the "Insurance" category is selected
    When I type "zzz-none" into the contacts search field
    Then I see "No matching contacts"
    And I see "Try adjusting your search or filter criteria."

  @edge
  Scenario: Empty directory shows the first-time empty state
    Given the organization has no contacts
    When I open "Contacts"
    Then I see "No contacts yet"
    And I see "Add your first contact to get started."

  @negative
  Scenario: Add Contact is not yet implemented
    When I open "Contacts" and click "Add Contact"
    Then I see the snackbar "Add contact coming soon"
    And no add-contact form opens
    # NOTE: add / edit / delete / duplicate-detection are NOT implemented for contacts.

  @negative
  Scenario: Contacts load failure shows an error with Try Again
    Given the contacts API returns a non-200 response
    When I open "Contacts"
    Then I see "Failed to load contacts"
    And I see a "Try Again" button

  @security
  Scenario: Contact search treats input as literal text
    When I type "<img src=x onerror=alert(1)>" into the contacts search field
    Then no script executes and results are filtered literally

  # =====================================================================
  # PHONE CALLS
  # =====================================================================

  @smoke @positive
  Scenario: Phone Calls screen renders header, tabs, and summary cards
    When I open "Phone Calls"
    Then I see the header "Phone Calls" and subtitle "Log and track patient communication calls"
    And I see tabs "All", "Inbound", "Outbound", "Missed"
    And I see summary cards "Total Calls", "Inbound", "Outbound", "Missed"

  @smoke @positive
  Scenario: Log an outbound phone call
    When I open "Phone Calls" and click "Log Call"
    Then I see the dialog "Log Phone Call"
    When I fill "Contact Name" with "Jane Caregiver"
    And I fill "Phone Number" with "+1 415 555 0100"
    And I select "Direction" "Outbound"
    And I fill "Notes" with "Left voicemail about scheduling"
    And I click "Log Call"
    Then the dialog closes and the call appears in the list

  @positive @data
  Scenario Outline: Direction dropdown offers inbound and outbound
    When I open the log-call dialog and open "Direction"
    Then I can select "<direction>"

    Examples:
      | direction |
      | Inbound   |
      | Outbound  |

  @negative
  Scenario: Log-call dialog marks Contact Name, Phone Number, Direction as required
    When I open the log-call dialog
    Then "Contact Name", "Phone Number", and "Direction" show a required indicator
    When I click "Log Call" with "Phone Number" empty
    Then the call is not saved

  @edge @data
  Scenario Outline: Phone number formatting edge cases
    When I log a call with phone number "<number>"
    Then the app handles it without crashing

    Examples:
      | number             |
      | 5550100            |
      | +1 (415) 555-0100  |
      | not-a-number       |
      | 000000000000000    |
      |                    |

  @positive @data
  Scenario Outline: Direction tabs filter the call log
    When I open the "<tab>" tab on Phone Calls
    Then only "<kind>" calls are listed

    Examples:
      | tab      | kind     |
      | Inbound  | inbound  |
      | Outbound | outbound |
      | Missed   | missed   |

  @edge
  Scenario: Empty call log shows the empty state
    Given there are no logged calls
    When I open "Phone Calls"
    Then I see "No phone calls found"
    And I see "Start by logging a new call"

  @negative
  Scenario: Phone call load error offers Retry
    Given the phone API returns an error
    When I open "Phone Calls"
    Then I see the error and a "Retry" button

  # =====================================================================
  # NOTIFICATIONS
  # =====================================================================

  @smoke @positive
  Scenario: Notifications screen renders header, count, and tabs
    When I open "Notifications"
    Then I see the header "Notifications"
    And the subtitle shows the unread count or "All caught up"
    And I see tabs "All", "Unread", "System", "Alerts"

  @positive @data
  Scenario Outline: Notification tabs filter the list
    When I open the "<tab>" notifications tab
    Then only "<kind>" notifications are shown

    Examples:
      | tab    | kind         |
      | All    | all          |
      | Unread | unread only  |
      | System | system type  |
      | Alerts | alert type   |

  @positive
  Scenario: Mark a single notification as read
    Given an unread notification
    When I click its "Read" action
    Then the unread indicator disappears and the unread count decreases

  @positive
  Scenario: Mark all as read
    Given there are unread notifications
    When I click "Mark All Read"
    Then all notifications become read and the subtitle shows "All caught up"

  @negative
  Scenario: Mark All Read is disabled when nothing is unread
    Given there are no unread notifications
    Then the "Mark All Read" button is disabled

  @positive
  Scenario: Dismiss a notification
    Given a notification in the list
    When I click its dismiss (x) action
    Then it is removed from the visible list

  @positive
  Scenario: High-priority notifications show a High Priority badge
    Given a notification with priority "high"
    Then it displays a "High Priority" badge

  @edge
  Scenario Outline: Empty state per notifications tab
    Given there are no notifications in the "<tab>" tab
    When I open the "<tab>" tab
    Then I see "No <lowertab>notifications"
    And I see "You're all caught up. Check back later for updates."

    Examples:
      | tab    | lowertab |
      | All    |          |
      | Unread | unread   |
      | System | system   |
      | Alerts | alert    |

  @negative
  Scenario: Mark-as-read failure surfaces an error toast
    Given the mark-as-read request fails
    When I click "Read" on an unread notification
    Then I see the toast "Failed to mark as read"

  @negative
  Scenario: Mark-all-read failure surfaces an error toast
    Given the mark-all-read request fails
    When I click "Mark All Read"
    Then I see the toast "Failed to mark all as read"

  @negative
  Scenario: Notifications load error offers Try Again
    Given the notifications API returns an error
    When I open "Notifications"
    Then I see "Failed to load notifications" and a "Try Again" button

  # =====================================================================
  # CROSS-CUTTING
  # =====================================================================

  @permission
  Scenario: Communication sub-screens respect role access
    Given I am logged in as a restricted role
    When I attempt to open a Communication sub-screen I lack access to
    Then I am blocked or shown no data rather than another org's records

  @a11y
  Scenario: Pill tabs across Communication are keyboard reachable and labelled
    Then every pill tab (telehealth/phone/notifications/contacts) is focusable and announces its label
