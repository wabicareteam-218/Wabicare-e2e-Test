Feature: Clinic Tools — Tasks
  As a clinician (Owner) I manage clinic tasks from the Tools area of the Wabi
  web app (dev.wabicare.com). The Tools screen has three tabs — Documents,
  Tasks, Notes — this feature covers the Tasks tab. Scenarios are grounded in
  the Flutter source (clinic/tools: tasks_screen.dart, tasks_view_model.dart)
  and probe create/validation, status transitions, list/board views, filters,
  permission, and empty states.

  # Source facts embedded below:
  #  - Tools header has pill tabs: "Documents", "Tasks", "Notes" (Documents is index 0/default).
  #  - Tasks tab has a header toggle: "List" / "Board" (Kanban) view.
  #  - Action button label switches per tab: "Upload" / "New Task" / "New Note".
  #  - List-view filter pills: "All", "To Do", "In Progress", "Done".
  #  - Kanban columns: "To Do" (pending+assigned), "In Progress" (in_progress), "Done" (completed).
  #    Empty column shows "Drop tasks here"; drag a card to a column to change status.
  #  - New Task dialog "New Task" fields: Title * (required), Description, Type, Priority.
  #      Type options: Complete assessment, Submit authorization, Review authorization,
  #        Schedule assessment, Document review, Insurance verification, Parent follow-up
  #      Priority options: Urgent, High, Normal (default), Low
  #  - Create toast: "Task created" / "Failed to create task".
  #  - Empty title -> Create button silently does nothing (no toast).
  #  - Task detail panel: status dropdown options pending, assigned, in_progress, completed,
  #      blocked, cancelled; changing status toasts "Task updated to <Status>" / "Failed to update task".
  #  - Detail panel shows Description, Task Type, Due Date, Assigned To, Patient, and Quick Links
  #      ("Open Patient Profile", "Open Assessment", "Open Authorization").
  #  - NOTE / GAPS: the New Task dialog does NOT expose Assignee or Due Date inputs (the view model
  #    supports assigneeId/dueDate but no UI field). There is NO explicit edit or delete-task control;
  #    "complete" and "reopen" are done via the status dropdown or by dragging on the board.
  #    Overdue due dates are shown as plain text with no special overdue highlight.

  Background:
    Given I am logged in as an "Owner" clinician
    And I open "Tools"
    And I select the "Tasks" tab

  # ---------------- Render / views ----------------

  @smoke @positive
  Scenario: Tasks tab renders filter pills and list/board toggle
    Then I see filter pills "All", "To Do", "In Progress", "Done"
    And I see a view toggle with "List" and "Board"
    And I see a "New Task" action button

  @positive
  Scenario: Switch between List and Board views
    When I click the "Board" toggle
    Then I see Kanban columns "To Do", "In Progress", "Done"
    When I click the "List" toggle
    Then I see the task list with a detail panel placeholder "Select a task to view details"

  # ---------------- Create task ----------------

  @smoke @positive
  Scenario: Create a task with the minimum required field
    When I click "New Task"
    Then I see the dialog "New Task"
    When I fill "Title *" with "Review reauth packet for Rujitha"
    And I select Type "Review authorization"
    And I select Priority "High"
    And I click "Create"
    Then I see the toast "Task created"
    And the task appears in the "To Do" column/list

  @positive
  Scenario: Create a task with description
    When I open the New Task dialog
    And I fill "Title *" with "Verify Aetna benefits"
    And I fill "Description" with "Call payer to confirm active coverage and copay"
    And I select Type "Insurance verification"
    And I click "Create"
    Then I see the toast "Task created"

  @positive @data
  Scenario Outline: Type dropdown offers all task types
    When I open the New Task dialog and open "Type"
    Then I can select "<type>"

    Examples:
      | type                   |
      | Complete assessment    |
      | Submit authorization   |
      | Review authorization   |
      | Schedule assessment    |
      | Document review        |
      | Insurance verification |
      | Parent follow-up       |

  @positive @data
  Scenario Outline: Priority dropdown offers all priorities and defaults to Normal
    When I open the New Task dialog
    Then the default priority is "Normal"
    And I can select priority "<priority>"

    Examples:
      | priority |
      | Urgent   |
      | High     |
      | Normal   |
      | Low      |

  @negative
  Scenario: Empty title does not create a task
    When I open the New Task dialog
    And I leave "Title *" empty
    And I click "Create"
    Then no task is created
    And no success toast is shown
    # NOTE: the dialog stays open with no validation message (silent no-op).

  @negative
  Scenario: Whitespace-only title is treated as empty
    When I open the New Task dialog
    And I fill "Title *" with "   "
    And I click "Create"
    Then no task is created

  @edge @security
  Scenario: Very long title and script-like description are handled safely
    When I open the New Task dialog
    And I fill "Title *" with a 3000-character string
    And I fill "Description" with "<script>alert('x')</script>"
    And I click "Create"
    Then the app does not crash and the markup is not executed

  @negative
  Scenario: Backend failure on create shows a failure toast
    Given the create-task request will fail
    When I create a task with a valid title
    Then I see the toast "Failed to create task"

  @edge
  Scenario: New Task dialog exposes no Assignee or Due Date field
    When I open the New Task dialog
    Then there is no "Assignee" input
    And there is no "Due Date" input
    # NOTE / GAP: assignee and due date are supported by the API but not by this dialog.

  # ---------------- Status transitions (complete / reopen / block) ----------------

  @smoke @positive
  Scenario: Complete a task via the status dropdown
    Given I select a task with status "In Progress"
    When I change its status dropdown to "Completed"
    Then I see the toast "Task updated to Completed"
    And the task moves to the "Done" bucket

  @positive
  Scenario: Reopen a completed task
    Given I select a task with status "Completed"
    When I change its status dropdown to "In Progress"
    Then I see the toast "Task updated to In Progress"
    And the task leaves the "Done" bucket

  @positive @data
  Scenario Outline: Status dropdown offers all lifecycle states
    Given I have selected a task
    Then the status dropdown lists "<status>"

    Examples:
      | status      |
      | Pending     |
      | Assigned    |
      | In Progress |
      | Completed   |
      | Blocked     |
      | Cancelled   |

  @positive
  Scenario: Mark a task as blocked
    Given I select a task
    When I change its status to "Blocked"
    Then I see the toast "Task updated to Blocked"

  @negative
  Scenario: Status update failure surfaces an error toast
    Given the update-status request will fail
    When I change a task's status
    Then I see the toast "Failed to update task"

  @edge
  Scenario: Selecting the same status again is a no-op
    Given I select a task with status "Pending"
    When I re-select "Pending" in the status dropdown
    Then no update request is sent

  # ---------------- Board (Kanban) ----------------

  @positive
  Scenario: Drag a card across Kanban columns to change status
    Given I am in "Board" view
    When I drag a task card from "To Do" into "Done"
    Then its status becomes completed
    And I see the toast "Task updated to Completed"

  @edge
  Scenario: Empty Kanban column shows the drop hint
    Given a Kanban column has no tasks
    Then that column shows "Drop tasks here"

  @edge
  Scenario: Blocked and cancelled tasks are absent from the board columns
    Given tasks with status "blocked" and "cancelled" exist
    When I am in "Board" view
    Then they do not appear in "To Do", "In Progress", or "Done"

  # ---------------- Filters ----------------

  @positive @data
  Scenario Outline: List filter pills narrow the task list
    When I click the "<pill>" filter pill
    Then only "<bucket>" tasks are listed

    Examples:
      | pill        | bucket                 |
      | All         | all                    |
      | To Do       | pending and assigned   |
      | In Progress | in_progress            |
      | Done        | completed              |

  @edge
  Scenario: Empty task list shows the inbox empty state
    Given the current filter matches no tasks
    Then I see "No tasks"

  @edge
  Scenario: Detail panel prompts to select a task when none is chosen
    Given no task is selected in list view
    Then the detail panel shows "Select a task to view details"

  # ---------------- Detail panel content ----------------

  @positive
  Scenario: Task detail shows metadata and quick links
    Given I select a task linked to a patient and an assessment
    Then the detail panel shows Description, Task Type, Due Date, Assigned To, and Patient
    And I see Quick Links "Open Patient Profile" and "Open Assessment"

  @edge
  Scenario: A past due date renders as plain text with no overdue styling
    Given I select a task whose due date is in the past
    Then the due date is shown as text without any overdue highlight
    # NOTE / GAP: there is no visual overdue indicator in the source.

  # ---------------- Load / error / permission ----------------

  @negative
  Scenario: Task load failure shows an error state with Retry
    Given the kanban tasks request fails
    When I open the "Tasks" tab
    Then I see "Failed to load data" and a "Retry" button

  @permission
  Scenario: Tasks are scoped to the signed-in user's organization
    Given tasks belong to another organization
    When I open the "Tasks" tab
    Then only my organization's tasks are listed

  @a11y
  Scenario: Filter pills and status dropdown are keyboard reachable
    Then each filter pill and the status dropdown are focusable and announce their labels
