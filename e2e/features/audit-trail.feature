Feature: Patient Audit Trail
  As a compliance-minded clinician on the Wabi web app
  I want a HIPAA-compliant, read-only change history for each patient
  So that every create/edit/status-change/view is recorded, filterable and exportable.

  # Source of truth for labels/messages:
  #   lib/features/clinic/audit_trail/widgets/audit_trail_tab.dart
  #   lib/features/clinic/audit_trail/data/models/audit_trail_models.dart
  #   lib/services/api/audit_trail_api_service.dart
  # The view is a two-panel layout (left = filters + activity-by-date, right =
  # timeline). It is NOT a table; entries are a timeline. It is strictly
  # read-only (no edit/delete/create of entries anywhere in the UI).

  Background:
    Given I am logged in to the Wabi clinician web app as an Owner
    And I open an existing patient's profile
    And I select the "Audit Trail" tab
    And the left panel shows title "Audit Trail" with subtitle "HIPAA-compliant change history"
    And the right panel shows title "Change History"

  # ---------------------------------------------------------------------------
  # Entries appear for key actions
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: The change history lists entries with actor, action and description
    Then each entry shows a timestamp, the actor name, an action badge, the entity type and a description
    And the right panel shows a total count like "12 entries"

  @data @positive
  Scenario Outline: Key actions are recorded with the correct badge
    When a "<action>" action occurs on this patient's data
    Then a new audit entry appears with badge "<badge>"

    Examples:
      | action         | badge   |
      | created        | CREATED |
      | updated        | UPDATED |
      | deleted        | DELETED |
      | viewed         | VIEWED  |
      | status_changed | STATUS  |

  @positive
  Scenario: Editing a field records old and new values
    When I change a patient field from an old value to a new value
    Then the audit entry shows the field name with the old value struck through and "→" the new value

  @positive
  Scenario: A status change is recorded as a "STATUS" entry
    When the patient's status changes
    Then an entry with the "STATUS" badge appears describing the change

  @edge
  Scenario: An exported action renders an "EXPORTED" badge although it is not a filter option
    Given an export event exists in the history
    Then it renders with the "EXPORTED" badge
    But "Exported" is not offered in the Action filter dropdown

  # ---------------------------------------------------------------------------
  # Filters
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Filter by action type
    When I open the "Action" dropdown with hint "All actions"
    And I select "Status Changed"
    Then only entries with the "STATUS" badge are shown
    And the count updates to "Showing N of <total>"

  @positive
  Scenario: Filter by person
    Given entries exist from more than one actor
    When I open the "Person" dropdown with hint "All people"
    And I select a specific person
    Then only that person's entries are shown

  @data @positive
  Scenario Outline: Filter by entity type
    When I open the "Entity" dropdown with hint "All entities"
    And I select "<entity>"
    Then only "<entity>" entries are shown

    Examples:
      | entity        |
      | patient       |
      | medication    |
      | allergy       |
      | kyc           |
      | session       |
      | authorization |
      | form          |
      | document      |
      | goal          |

  @positive
  Scenario: Filter by date using the Activity by date list
    Given the "Activity by date" list shows "All dates", "Today" and "Yesterday"
    When I select "Today"
    Then only entries from today are shown

  @positive
  Scenario: Search filters entries by text
    When I type into the "Search..." field
    Then after a short debounce the list narrows to matching entries

  @positive
  Scenario: Clear all active filters
    Given I have applied an action and an entity filter
    Then the clear button reads "Clear (2)"
    When I click "Clear (2)"
    Then all filters reset and the full history is shown

  @edge
  Scenario: The active-filter chip counts applied filters
    When I apply one filter
    Then I see "1 active filter"
    When I apply a second filter
    Then I see "2 active filters"

  # ---------------------------------------------------------------------------
  # Pagination
  # ---------------------------------------------------------------------------

  @edge @positive
  Scenario: Load more entries beyond the first page
    Given there are more than 50 audit entries
    Then the first 50 are shown
    When I click "Load more"
    Then the next page of entries is appended

  @a11y @positive
  Scenario: Timeline is grouped by date dividers
    Then entries are grouped under date headers such as "Today", "Yesterday" and "May 4, 2025"

  # ---------------------------------------------------------------------------
  # Export
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Export the audit trail as CSV
    When I click "Export CSV"
    Then the button briefly shows "Exporting…"
    And I see the toast "Exported <filename>"

  @edge
  Scenario: Export respects the active action, person, entity and search filters
    Given I have filtered by action "Updated"
    When I click "Export CSV"
    Then the exported CSV contains only "Updated" entries
    # NOTE: the date filter is NOT passed to the CSV export in the current source.

  @negative
  Scenario: Export failure surfaces an error
    Given the export endpoint returns a server error
    When I click "Export CSV"
    Then I see the error "Export failed (server error)"

  @negative @edge
  Scenario: Export when the audit service is unavailable
    Given the audit trail service is not available
    When I click "Export CSV"
    Then I see the error "Audit trail service not available"

  # ---------------------------------------------------------------------------
  # Empty / error states
  # ---------------------------------------------------------------------------

  @edge
  Scenario: Empty history with no filters
    Given this patient has no recorded activity
    Then I see "No audit entries found"
    And the subtitle "Changes to this patient's data will appear here"
    And the "Activity by date" list shows "No activity yet."

  @edge @negative
  Scenario: No results after filtering
    Given filters exclude every entry
    Then I see "No audit entries found"
    And the subtitle "Try adjusting your filters"

  @negative
  Scenario: Failure loading the audit trail
    Given the audit trail endpoint fails
    When I open the "Audit Trail" tab
    Then I see "Failed to load audit trail"

  # ---------------------------------------------------------------------------
  # Immutability & permission
  # ---------------------------------------------------------------------------

  @security @positive
  Scenario: The audit trail is strictly read-only
    Then there are no controls to edit, delete or create audit entries
    And the only actions available are filtering, searching, loading more and exporting

  @permission @security
  Scenario: Access to a patient's audit trail is enforced server-side
    Given the audit endpoints require authorisation
    When an unauthorised session requests "/api/v1/patients/<id>/audit-trail/"
    Then the server rejects the request
    # NOTE: No client-side role gating exists; enforcement is backend-only.
