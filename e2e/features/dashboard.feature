Feature: Dashboard
  As a signed-in clinic user
  I want a role-based dashboard of stats and cards
  So that I can see key metrics and jump to the right workspace.

  # Grounded in wabi-flutter-dev/lib/features/ai_insights/:
  #   screens/role_based_dashboard_screen.dart  (header + reorderable grid)
  #   widgets/dashboard_quick_stats.dart        (pinned stat cards, per role)
  #   models/dashboard_card_definition.dart     (card titles/subtitles/routes)
  #   widgets/cards/*.dart                       (13 cards, per-card empty/error/loading)
  # The dashboard is ROLE-BASED: visible stats and cards differ by role
  # (owner / bcba / rbt / clinical_director). There is NO time-based greeting.
  # /dashboard route renders RoleBasedDashboardScreen (app_shell.dart:524).

  Background:
    Given I am signed in to Wabi Clinic
    And I am on the "/dashboard" route

  # ─────────────────────────── Header & smoke ──────────────────────────────

  @smoke @positive
  Scenario: Dashboard header renders name, role pill and controls
    Then I see my full name (or "Dashboard" if my name has not loaded)
    And I see a role pill showing one of "Owner", "BCBA", "RBT", "Clinical Director", "Administrator" or "Clinical Administrator"
    And I see a "Refresh" control
    And I see a calendar button with tooltip "View Calendar"

  @edge
  Scenario: Subtitle falls back when org and branch are unavailable
    Given my organization and branch details have not loaded
    Then the subtitle reads "Overview of your organization and key metrics"

  @edge
  Scenario: Role pill shows a placeholder before the user profile loads
    Given my user profile has not yet loaded
    Then the role pill shows "—"

  @negative
  Scenario: Dashboard shows no time-based greeting
    Then no greeting such as "Good morning" or "Welcome back" is displayed

  @edge
  Scenario: Whole-screen loading indicator while the card order loads
    When the dashboard card order is still loading
    Then a centered circular progress indicator is shown instead of the grid

  # ─────────────────────────── Quick stats (per role) ──────────────────────

  @smoke @positive @permission
  Scenario: Owner sees the owner quick-stats row
    Given I am signed in as an "Owner"
    Then I see the quick stats "Active Patients", "Today's Sessions", "Pending Intakes" and "Hours This Week"
    And the "Active Patients" stat subtitle is "Currently enrolled"

  @permission @positive
  Scenario: BCBA sees the caseload-oriented quick stats
    Given I am signed in as a "BCBA"
    Then I see the quick stats "My Patients", "Sessions This Week", "Hours Logged" and "Pending Intakes"

  @permission @positive
  Scenario: RBT sees the therapist quick stats
    Given I am signed in as an "RBT"
    Then I see the quick stats "Sessions Today", "This Week", "Hours Logged" and "Active Patients"

  @permission @positive
  Scenario: Clinical Director sees the org-wide quick stats
    Given I am signed in as a "Clinical Director"
    Then I see the quick stats "Active Patients", "Staff Members", "Pending Intakes" and "Hours This Week"

  @data @positive
  Scenario Outline: Tapping a quick stat navigates to its section
    Given I am signed in as an "Owner"
    When I tap the "<stat>" quick stat
    Then I am navigated to "<route>"

    Examples:
      | stat             | route       |
      | Active Patients  | /patients   |
      | Today's Sessions | /scheduling |
      | Pending Intakes  | /intake     |
      | Hours This Week  | /sessions   |

  # ─────────────────────────── Cards (per role) ────────────────────────────

  @permission @positive
  Scenario: Owner dashboard grid shows the owner card set
    Given I am signed in as an "Owner"
    Then I see the cards "Today's Schedule", "Active Patients", "Staff Utilization", "Authorization Alerts", "Action Items", "Billing Overview" and "Compliance Dashboard"

  @permission @positive
  Scenario: BCBA dashboard grid shows the supervision card set
    Given I am signed in as a "BCBA"
    Then I see the cards "Active Supervised Sessions", "My Caseload", "Today's Schedule", "Pending Session Notes", "Authorization Alerts", "Upcoming Sessions" and "Action Items"

  @permission @positive
  Scenario: RBT dashboard grid shows the minimal therapist card set
    Given I am signed in as an "RBT"
    Then I see the cards "Today's Schedule", "Upcoming Sessions", "Pending Session Notes" and "Action Items"
    And I do NOT see "Billing Overview" or "Staff Utilization"

  @permission @positive
  Scenario: Clinical Director dashboard grid shows the org-management card set
    Given I am signed in as a "Clinical Director"
    Then I see the cards "Staff Overview", "Patient Pipeline", "Authorization Alerts", "Compliance Dashboard", "Today's Schedule" and "Action Items"

  @data @positive
  Scenario Outline: A card's View action navigates to its route
    When I use the View action on the "<card>" card
    Then I am navigated to "<route>"

    Examples:
      | card                  | route          |
      | Patient Pipeline      | /intake        |
      | Today's Schedule      | /scheduling    |
      | Authorization Alerts  | /patients      |
      | Staff Utilization     | /settings/users|
      | Billing Overview      | /billing       |
      | Action Items          | /tasks         |
      | Pending Session Notes | /sessions      |
      | Compliance Dashboard  | /settings      |

  @positive
  Scenario: Patient Pipeline card shows the four funnel stages
    Given I am signed in as a "Clinical Director"
    Then the "Patient Pipeline" card shows stages "Intake", "Assessment", "Authorization" and "Active"

  @positive
  Scenario: Billing Overview card shows its four metrics
    Given I am signed in as an "Owner"
    And the clinic has billing data
    Then the "Billing Overview" card shows "Total Claims", "Outstanding AR", "Denial Rate" and "Collection Rate"

  # ─────────────────────────── Empty states ────────────────────────────────

  @data @edge
  Scenario Outline: Cards render their empty state when there is no data
    Given the "<card>" card has no data
    Then it shows the empty message "<empty_text>"

    Examples:
      | card                       | empty_text                     |
      | Today's Schedule           | No appointments today          |
      | Upcoming Sessions          | No upcoming sessions           |
      | Active Patients            | No active patients yet         |
      | My Caseload                | No patients assigned           |
      | Active Supervised Sessions | No active supervised sessions  |
      | Authorization Alerts       | All authorizations up to date  |
      | Billing Overview           | No claims yet                  |
      | Compliance Dashboard       | All compliant                  |
      | Staff Utilization          | No clinical staff yet          |
      | Staff Overview             | No staff members found         |
      | Pending Session Notes      | All notes completed            |
      | Action Items               | All caught up!                 |

  @edge
  Scenario: Quick-stats row collapses to nothing when unavailable
    Given the quick-stats data is empty
    Then the quick-stats row renders no cards

  # ─────────────────────────── Error states ────────────────────────────────

  @data @negative
  Scenario Outline: Cards show an error message when their metric fails to load
    Given loading the "<card>" card fails
    Then it shows the error message "<error_text>"

    Examples:
      | card                       | error_text                          |
      | Compliance Dashboard       | Could not load compliance metrics   |
      | Staff Utilization          | Could not load utilization          |
      | Active Supervised Sessions | Could not load supervised sessions  |
      | Billing Overview           | Could not load billing metrics      |

  # ─────────────────────────── Loading skeletons ───────────────────────────

  @edge
  Scenario: Individual cards show grey skeletons while loading
    Given a dashboard card's data is still loading
    Then that card shows placeholder skeleton blocks with no text

  # ─────────────────────────── Refresh & reorder ───────────────────────────

  @positive
  Scenario: Refresh reloads the dashboard
    When I click "Refresh"
    Then the card order and metrics are reloaded

  @positive
  Scenario: Calendar button opens the schedule
    When I click the "View Calendar" button
    Then I am navigated to the scheduling screen

  @edge @positive
  Scenario: Reordering cards persists per role
    Given I am signed in as an "Owner"
    When I long-press and drag a card to a new position
    And I reload the dashboard
    Then the cards retain my custom order for the Owner role

  @security @permission
  Scenario: An RBT cannot see owner-only financial cards
    Given I am signed in as an "RBT"
    Then the "Billing Overview" and "Staff Utilization" cards are not rendered
    And no billing figures are exposed anywhere on the dashboard
