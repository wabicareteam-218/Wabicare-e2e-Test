Feature: Patient Care Circle
  As a clinician on the Wabi web app
  I want to manage the people assigned to a patient's care team
  So that the right BCBAs, RBTs, guardians, and outside providers are on record
  and can be auto-added as attendees on new appointments.

  # Source of truth for labels/messages:
  #   lib/features/clinic/intake/widgets/care_circle_tab.dart
  #   lib/features/clinic/intake/data/models/care_team_member.dart
  # The Care Circle is a two-column layout: left = role sections, right = assigned people.
  # It is add/remove only (no in-app "edit member" dialog) plus a per-staff
  # "Default attendee" scheduling toggle. There is no in-app email invite flow.

  Background:
    Given I am logged in to the Wabi clinician web app as an Owner
    And I open an existing patient's profile
    And I select the "Care Circle" tab
    And the nav header shows title "Care Circle" with the patient's name as subtitle

  # ---------------------------------------------------------------------------
  # Structure / read
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Care Circle shows all six role sections
    Then I see the role sections "Primary BCBA", "Backup BCBA", "RBTs", "Guardians", "Primary Care Doctor" and "Other Providers"
    And each section shows a member count badge when it has one or more members
    And each section shows its subtitle helper text

  @data @positive
  Scenario Outline: Each role section shows its subtitle
    When I view the "<section>" section
    Then the subtitle reads "<subtitle>"

    Examples:
      | section             | subtitle                                          |
      | Primary BCBA        | Lead supervising behavior analyst                 |
      | Backup BCBA         | Covers when the primary BCBA is unavailable       |
      | RBTs                | Technicians delivering direct therapy             |
      | Guardians           | Parents / caregivers (synced from intake)         |
      | Primary Care Doctor | Pediatrician / primary care physician             |
      | Other Providers     | Teachers, SLPs, care coordinators, and others     |

  @positive @edge
  Scenario: Empty role section shows guidance for an editor
    Given the "RBTs" section has no members
    When I view the "RBTs" section
    Then I see the empty text "No rbts assigned"
    And I see the hint "Use “Add” to assign someone."

  # ---------------------------------------------------------------------------
  # Add staff (BCBA / RBT) — chosen from organization users
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Add a Primary BCBA from organization staff
    When I click "Add" on the "Primary BCBA" section
    Then a dialog titled "Add Primary BCBA" opens
    And it shows the "Staff member" dropdown with hint "Select a bcba"
    When I select a staff member and click "Add"
    Then I see the toast "<member name> added"
    And the new member appears in the "Primary BCBA" section

  @positive
  Scenario: Add an RBT and mark them as a backup
    When I click "Add" on the "RBTs" section
    Then the dialog "Add RBTs" shows a "Backup RBT" checkbox
    When I select a staff member, tick "Backup RBT" and click "Add"
    Then the member appears with a "Backup" pill

  @negative
  Scenario: Add button is disabled until a staff member is picked
    When I open the "Add Primary BCBA" dialog
    Then the "Add" confirm button is disabled while no staff member is selected

  @edge @negative
  Scenario: No eligible staff to add redirects to Settings
    Given there are no unassigned BCBA staff in the organization
    When I click "Add" on the "Primary BCBA" section
    Then I see the message "No available BCBA staff to add. Invite them under Settings → Users first."
    And no "Add" confirm button is shown

  @edge @data
  Scenario Outline: Already-assigned staff are filtered out of the candidate list
    Given "<person>" is already assigned as "<section>"
    When I open the "Add <section>" dialog
    Then "<person>" does not appear in the staff dropdown

    Examples:
      | section      | person       |
      | Primary BCBA | Dr. Alvarez  |
      | RBTs         | Jordan Lee   |

  # ---------------------------------------------------------------------------
  # Add external contact (guardian / doctor / other provider)
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Add an external "Other Provider" with a provider type
    When I click "Add" on the "Other Providers" section
    Then the dialog "Add Other Providers" shows a "Provider type" dropdown with hint "Select a type"
    And the provider-type options are "Teacher / School Staff", "Care Coordinator" and "Other Provider"
    When I choose "Teacher / School Staff", enter "Full name *" and click "Add"
    Then I see the toast "<name> added"

  @positive
  Scenario: Primary Care Doctor relationship defaults to Pediatrician
    When I click "Add" on the "Primary Care Doctor" section
    Then the "Relationship (e.g. Mother, SLP)" field is prefilled with "Pediatrician"
    When I enter a full name and click "Add"
    Then the doctor appears in the "Primary Care Doctor" section

  @negative
  Scenario: Adding a contact with an empty name is silently blocked
    When I open the "Add Guardians" dialog
    And I leave "Full name *" empty
    And I click "Add"
    Then the dialog stays open and no member is added

  @edge @data
  Scenario Outline: Contact fields accept optional email, phone and relationship
    When I add a contact in "Other Providers" with name "<name>", relationship "<rel>", email "<email>", phone "<phone>"
    Then the member row shows the entered details joined by "·"

    Examples:
      | name          | rel           | email                | phone          |
      | Casey Doe     | SLP           | casey@example.com    | 555-0100       |
      | Pat Nguyen    |               |                      |                |
      | Sam O'Neil    | Care Coord    | sam@clinic.org       | +1 555 999 111 |

  # ---------------------------------------------------------------------------
  # Remove
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Remove a member with confirmation
    Given the "RBTs" section has a member "Jordan Lee"
    When I click the "Remove" icon on "Jordan Lee"
    Then a dialog "Remove from care circle?" appears
    And it reads "Remove Jordan Lee from <patient>'s care circle?"
    When I click "Remove"
    Then I see the toast "Jordan Lee removed"
    And "Jordan Lee" no longer appears in the section

  @negative
  Scenario: Cancelling the remove dialog keeps the member
    Given the "RBTs" section has a member "Jordan Lee"
    When I click the "Remove" icon on "Jordan Lee"
    And I click "Cancel"
    Then "Jordan Lee" remains in the "RBTs" section

  # ---------------------------------------------------------------------------
  # Default attendee (scheduling) toggle — staff rows only
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Toggle a staff member as a default appointment attendee
    Given the "RBTs" section has a member "Jordan Lee"
    When I turn on the "Default attendee" switch for "Jordan Lee"
    Then I see the toast "Jordan Lee will be auto-added to new appointments"

  @positive
  Scenario: Turning off the default attendee switch updates the message
    Given "Jordan Lee" is a default attendee
    When I turn off the "Default attendee" switch for "Jordan Lee"
    Then I see the toast "Jordan Lee will no longer auto-add to new appointments"

  @edge
  Scenario: External contacts never show a Default attendee switch
    Given a guardian "Mom Smith" is in the "Guardians" section
    Then the "Guardians" member row shows no "Default attendee" switch

  @edge
  Scenario: "From intake" members are labelled
    Given a guardian was synced from the patient's intake form
    Then that guardian row shows a "From intake" pill

  # ---------------------------------------------------------------------------
  # Permissions
  # ---------------------------------------------------------------------------

  @permission @positive
  Scenario: Owner, Admin, Clinical Director and BCBA can edit
    Given I am logged in as a role in {Owner, Administrator, Clinical Director, BCBA, Clinical Administrator}
    Then each role section shows an "Add" button and "Remove" icons

  @permission @negative
  Scenario: An RBT cannot edit the Care Circle
    Given I am logged in as an RBT
    When I open the "Care Circle" tab
    Then no "Add" button is shown
    And no "Remove" icons are shown
    And the "Default attendee" switch is disabled with tooltip "Only Owner / Admin / Clinical Director / BCBA can change scheduling defaults."

  @permission @security
  Scenario: Add rejected by the server for an unauthorised session
    Given my session lacks care-team edit permission
    When I attempt to add a member
    Then I see the error toast "Could not add member (check your permissions)"

  @security @edge
  Scenario: Injection-style text in a contact name is stored as literal text
    When I add an "Other Providers" contact named "<script>alert('x')</script>"
    Then the member row renders the name as literal text and does not execute script
