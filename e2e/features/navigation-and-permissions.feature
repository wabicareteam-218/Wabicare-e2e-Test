Feature: Navigation, tabs & permissions
  As a signed-in clinic user
  I want the sidebar, patient tabs and breadcrumbs to route me correctly
  So that I only reach the sections and actions my role permits.

  # Grounded in wabi-flutter-dev:
  #   lib/widgets/app_sidebar.dart          (CLINIC sidebar items + gating)
  #   lib/state/app_shell_scope.dart        (AppSection enum)
  #   lib/config/routes.dart                (AppRoutes constants + deep-link helpers)
  #   lib/features/clinic/intake/data/patient_tabs.dart  (kPatientTabs, kPrimaryPillCount=3)
  #   lib/features/clinic/intake/widgets/intake_shared_types.dart (PatientTabBar, MorePillDropdown "More")
  #   lib/features/clinic/intake/screens/new_patient_intake_screen.dart:1663 (RBT tab gating)
  #   lib/core/data/models/user_models.dart (roleDisplay); lib/state/user_store.dart (role getters)
  #   lib/widgets/top_navigation_bar.dart   (_BreadcrumbNav)
  # Roles: owner, clinical_director, bcba, rbt, administrator, super_admin.
  # NOTE: there is NO "leave page — discard changes?" confirmation modal anywhere;
  # dirty state is only an inline "Unsaved changes" indicator + inline "Discard" buttons.

  Background:
    Given I am signed in to Wabi Clinic as an Owner
    And I am on the Clinic section

  # ─────────────────────── Sidebar navigation (Clinic) ──────────────────────

  @smoke @positive
  Scenario: Clinic sidebar lists the Platform and Reports & Tools groups
    Then under "Platform" I see "Dashboard", "Patients", "Schedule" and "Sessions"
    And under "Reports & Tools" I see "Reports", "Tools" and "Settings"

  @data @positive
  Scenario Outline: Sidebar items route to the correct screen
    When I click "<item>" in the sidebar
    Then I am navigated to "<route>"
    And the breadcrumb shows "<crumb>"

    Examples:
      | item      | route       | crumb      |
      | Dashboard | /dashboard  | Dashboard  |
      | Patients  | /patients   | Patients   |
      | Schedule  | /scheduling | Scheduling |
      | Sessions  | /sessions   | Sessions   |
      | Reports   | /reports    | Reports    |
      | Tools     | /tasks      | Tools      |
      | Settings  | /settings   | Settings   |

  @edge
  Scenario: Locked nav items before an organization is set up
    Given my organization has not been set up
    When I try to open a gated section from the sidebar
    Then the item shows a lock icon with tooltip "Set up organization first"
    And I see the snackbar "Please set up your organization in Settings first"
    And I see the banner "Setup Required" with "Please set up your organization in Settings to access all features."

  @positive
  Scenario: Settings and Admin remain reachable without an organization
    Given my organization has not been set up
    Then the "Settings" route stays enabled

  # ─────────────────────── Section switching ───────────────────────────────

  @positive
  Scenario Outline: Switching app sections changes the sidebar
    When I switch to the "<section>" section
    Then the sidebar reflects that section

    Examples:
      | section       |
      | Clinic        |
      | Communication |
      | Billing       |
      | HRMS          |
      | LMS           |

  # ─────────────────────── Patient top tabs ────────────────────────────────

  @smoke @positive
  Scenario: Patient workspace shows the three primary pills
    Given I open a patient's profile workspace
    Then the primary tab pills are "Profile", "Intake Forms" and "Authorization"
    And a "More" overflow control is shown

  @positive
  Scenario: The More menu contains the remaining tabs
    Given I open a patient's profile workspace as an Owner
    When I open the "More" menu
    Then it lists "Scheduling", "Programming", "Progress Reports", "Documents", "Discharge", "Know Your Patient", "Care Circle", "Audit Trail", "Communication" and "Billing Lite"

  @negative
  Scenario: Assessment and Treatment Plan are not in the patient pill bar
    Given I open a patient's profile workspace
    Then neither "Assessment" nor "Treatment Plan" appears in the pill bar or the "More" menu

  @positive
  Scenario: Selecting an overflow tab activates it under More
    Given I open a patient's profile workspace
    When I choose "Documents" from the "More" menu
    Then the "Documents" tab content is shown

  @edge
  Scenario: Reordering patient tabs persists per role
    Given I open a patient's profile workspace as an Owner
    When I reorder the tabs so "Scheduling" becomes a primary pill
    And I reopen a patient workspace
    Then "Scheduling" is still a primary pill for the Owner role

  # ─────────────────────── Role-gated navigation ───────────────────────────

  @permission @data
  Scenario Outline: Sidebar items visible per role
    Given I am signed in as "<role>"
    Then the sidebar item "<item>" is "<visibility>"

    Examples:
      | role  | item     | visibility |
      | Owner | Settings | visible    |
      | Owner | Reports  | visible    |
      | BCBA  | Settings | hidden     |
      | BCBA  | Reports  | visible    |
      | BCBA  | Patients | visible    |
      | RBT   | Settings | hidden     |
      | RBT   | Reports  | hidden     |
      | RBT   | Patients | visible    |
      | RBT   | Sessions | visible    |
      | RBT   | Schedule | visible    |
      | RBT   | Tools    | visible    |

  @permission @security
  Scenario: RBT patient workspace is restricted to four tabs
    Given I am signed in as an RBT
    When I open a patient's profile workspace
    Then only the tabs "Profile", "Scheduling", "Communication" and "Documents" are available
    And tabs such as "Authorization", "Programming" and "Billing Lite" are not shown

  @permission
  Scenario: Role display label reflects the signed-in role
    Given I am signed in as a user with roles owner and bcba
    Then my role is displayed as "Owner · BCBA"

  @permission
  Scenario: A user with no role is shown a Member label
    Given I am signed in as a user with no assigned role
    Then my role is displayed as "Member"

  # ─────────────────────── Role-gated actions ──────────────────────────────

  @permission @security
  Scenario: RBT session data cells are read-only
    Given I am signed in as an RBT in a session workspace
    Then the data-collection cells for targets I lack permission on are read-only

  @permission @negative
  Scenario: Non-owner cannot override insufficient authorized hours
    Given I am signed in as a BCBA scheduling an appointment
    And the patient has insufficient authorized hours
    Then I see "Insufficient authorized hours for this appointment."
    And I cannot apply the Owner-only override

  @permission @positive
  Scenario: Owner can override insufficient authorized hours
    Given I am signed in as an Owner scheduling an appointment
    And the patient has insufficient authorized hours
    Then I see "Insufficient authorized hours — request authorization or override (Owner role)"
    And an Owner override is available

  @permission @security
  Scenario: Admin API access is denied for non-superadmins
    Given I am signed in as an Owner (not super_admin)
    When an admin-only API call is attempted
    Then the response surfaces "Access denied (403). Requires superadmin permissions."

  # ─────────────────────── Direct-URL authz (deep links) ───────────────────

  @security @permission @data
  Scenario Outline: Direct navigation to a gated route is enforced by role
    Given I am signed in as "<role>"
    When I navigate directly to "<route>"
    Then access is "<result>"

    Examples:
      | role  | route      | result                         |
      | Owner | /settings  | allowed                        |
      | BCBA  | /settings  | blocked (no settings:read)     |
      | RBT   | /reports   | blocked (no reports:read)      |
      | RBT   | /sessions  | allowed                        |
      | Owner | /admin     | allowed only for super_admin   |

  @positive
  Scenario: Deep link to a specific patient profile opens that patient
    When I navigate to "/patients/profile/<id>" for a patient in my clinic
    Then that patient's profile workspace is shown

  @positive
  Scenario: Deep link to a session workspace opens that session
    When I navigate to "/sessions/workspace/<id>"
    Then that session's workspace is shown

  @negative
  Scenario: Deep link to a non-existent patient id is handled gracefully
    When I navigate to "/patients/profile/00000000-0000-0000-0000-000000000000"
    Then I see a not-found or empty state rather than a crash

  # ─────────────────────── Breadcrumbs ─────────────────────────────────────

  @positive
  Scenario: Breadcrumb reflects organization, section and current page
    When I open the Patients screen
    Then the breadcrumb begins with my organization name
    And ends with "Patients"

  @positive
  Scenario: Clicking a parent breadcrumb navigates back up
    Given I am deep inside a patient profile
    When I click the "Patients" breadcrumb crumb
    Then I return to the patients list

  # ─────────────────────── Unsaved changes / back-nav ──────────────────────

  @edge @negative
  Scenario: Navigating away with unsaved edits is NOT guarded by a confirmation modal
    Given I have unsaved edits showing the "Unsaved changes" indicator
    When I navigate to a different section via the sidebar
    Then no "Discard changes?" confirmation is shown
    And my unsaved edits are lost
    # Flag: absence of a leave-page guard is a data-loss risk worth reporting.

  @positive
  Scenario: Inline Discard button abandons edits within the current form
    Given I have started editing an intake note showing "Unsaved changes"
    When I click the inline "Discard" button
    Then my in-progress edits are cleared without leaving the screen

  @edge
  Scenario: Browser back navigation returns to the previous route
    Given I navigated from "/patients" to a patient profile
    When I use the browser back button
    Then I return to "/patients"

  # ─────────────────────── Accessibility ───────────────────────────────────

  @a11y
  Scenario: Sidebar destinations are exposed to assistive technology
    Given accessibility is enabled
    Then the semantics tree contains "Dashboard", "Patients", "Schedule" and "Sessions"
