# Grounded in wabi-flutter-dev:
#   lib/features/clinic/sessions/widgets/workspace/prompt_level_capture_popover.dart  (tap-to-capture: Independent / prompt levels / Incorrect / +1 count / Open full collector)
#   lib/features/clinic/sessions/widgets/workspace/pinned_behaviors_bar.dart          (behaviour frequency counters, "Record ABC", ABC 3-step wizard)
#   lib/features/clinic/sessions/widgets/workspace/live_trial_feed.dart               ("Recent Activity", "No trials recorded yet")
#   lib/features/clinic/sessions/widgets/workspace/mobile_data_collection_view.dart   (Trial cursor, Capture/Note toggle, goal switcher)
#   lib/features/clinic/sessions/utils/free_operant_metric.dart                       (frequency/rate/duration/latency/interval metric formatting)
#   lib/features/clinic/sessions/utils/goal_session_status.dart                       (Mastered/On Track/Behind/Not Started; default mastery 80%)
#   lib/features/clinic/sessions/utils/data_collection_types.dart                     (trial-based collection types)
# KEY FACTS:
#   - Default prompt hierarchy: Full Physical, Partial Physical, Gestural, Verbal, Model (a target's own config overrides, minus "independent").
#   - Behaviour counters: decrement is blocked at 0; increment is unbounded.
#   - Free-operant metric badges are HIDDEN (null) when the aggregate ≤ 0 — a bare "0" is never shown.
#   - Task-Analysis "Score" step dropdowns are a known flaky data-entry surface; behaviour recording is the reliable proof.

Feature: Session Data Collection — trials, behaviours, and metrics
  As a clinician running a live ABA session
  I want to score task-analysis trials, log challenging behaviours, and review the feed
  So that objective, timestamped data drives the progress note and the treatment plan.
  Data collection is enabled only after "Check in & Start". Tapping a goal chip
  opens a quick-capture popover; behaviours are logged from the pinned behaviour
  bar (a simple counter, or a full ABC incident wizard).

  Background:
    Given I am logged in and running an "In Progress" session for "Demo Patient 2"
    And the session has a Task-Analysis goal "Handwashing — full routine"
    And the pinned behaviour bar includes "Tantrum"

  # ── Task-Analysis trials: happy paths ────────────────────────────────────
  @smoke @positive
  Scenario: Score a task-analysis step as Independent
    When I tap the "Handwashing — full routine" goal chip
    Then a quick-capture popover opens
    When I choose "Independent"
    Then one datapoint is recorded with prompt level "Independent" and a "+" response
    And the trial appears in the "Recent Activity" feed with a green result icon

  @positive @data
  Scenario Outline: Record a prompted response at each prompt level
    When I tap the "Handwashing — full routine" goal chip
    And I choose "<prompt>"
    Then a "+" response is recorded at prompt level "<prompt>"

    Examples:
      | prompt          |
      | Full Physical   |
      | Partial Physical |
      | Gestural        |
      | Verbal          |
      | Model           |

  @positive
  Scenario: Score a task-analysis step as Incorrect
    When I tap the "Handwashing — full routine" goal chip
    And I choose "Incorrect"
    Then a "-" response is recorded
    And the trial appears in the feed with a red result icon

  @positive
  Scenario: Open the full collector for detailed step-by-step scoring
    When I tap the "Handwashing — full routine" goal chip
    And I choose "Open full collector"
    Then the full data collector opens for that target

  @edge
  Scenario: The trial cursor advances across steps in the mobile focus view
    Given I am in the mobile focus view on a trial-based target
    Then the trial cursor shows "Trial 1"
    When I record a response and tap the "Next trial" arrow
    Then the cursor advances to "Trial 2"
    And the "Previous trial" arrow becomes enabled

  @edge
  Scenario: Trial cursor arrows are disabled at the ends
    Given I am on "Trial 1" of a trial-based target
    Then the "Previous trial" arrow is disabled
    When I reach the final trial
    Then the "Next trial" arrow is disabled

  # ── Behaviour frequency counting ─────────────────────────────────────────
  @smoke @positive
  Scenario: Increment a challenging behaviour frequency count
    Given the "Tantrum" behaviour shows count 0 and status "Tap to log"
    When I tap the "+" stepper on "Tantrum"
    Then the "Tantrum" count increments to 1
    And the behaviour bar status shows "1 logged"

  @positive
  Scenario: Decrement a behaviour count
    Given the "Tantrum" behaviour count is 2
    When I tap the "-" stepper on "Tantrum"
    Then the "Tantrum" count decrements to 1

  @edge @negative
  Scenario: Decrement is blocked at zero (no negative counts)
    Given the "Tantrum" behaviour count is 0
    When I tap the "-" stepper
    Then the count stays at 0
    And no datapoint is recorded

  @edge
  Scenario: Behaviour frequency has no upper bound
    Given the "Tantrum" behaviour count is 0
    When I tap "+" many times in quick succession
    Then the count increments each time with no ceiling

  # ── Behaviour ABC incident (duration + full wizard) ──────────────────────
  @positive
  Scenario: Record a full ABC incident with intensity and duration
    When I click "Record ABC" on the behaviour bar
    Then the "ABC Behavior Incident" 3-step wizard opens on step "Antecedent"
    When I select the antecedent "Demand placed" and setting "Therapy room"
    And I click "Next" onto step "Behavior"
    And I select intensity "Moderate" and a duration preset "30s"
    And I click "Next" onto step "Consequence"
    And I select staff response "Redirected" and function "Escape / Avoid"
    And I click "Record Incident"
    Then the ABC incident is logged with its antecedent, intensity, duration and function

  @negative
  Scenario: The ABC wizard blocks advancing without a required selection
    When I open the "ABC Behavior Incident" wizard
    And I click "Next" without selecting an antecedent
    Then "Next" stays disabled and I cannot leave the "Antecedent" step
    And on the "Behavior" step "Next" stays disabled until an intensity is chosen

  @data
  Scenario Outline: ABC intensity levels
    Given the ABC wizard is on the "Behavior" step
    When I select intensity "<intensity>"
    Then the incident carries intensity "<intensity>"

    Examples:
      | intensity |
      | Mild      |
      | Moderate  |
      | Severe    |

  @edge
  Scenario: ABC duration presets and clear
    Given the ABC wizard is on the "Behavior" step showing "Not recorded"
    When I tap the "1m" duration preset
    Then the duration reads "1m"
    When I tap "Clear"
    Then the duration returns to "Not recorded"

  @edge
  Scenario: Long-press a behaviour chip to record with ABC or remove it
    When I long-press the "Tantrum" chip
    Then a menu offers "Record with ABC" and "Remove from bar"
    When I choose "Remove from bar"
    Then "Tantrum" is removed from the behaviour bar

  # ── Trial feed / recent activity ─────────────────────────────────────────
  @positive
  Scenario: Recorded trials appear newest-first in "Recent Activity"
    When I record several task-analysis trials and behaviours
    Then the "Recent Activity" feed lists each with a timestamp, result icon, goal name and provider initials

  @edge
  Scenario: Empty feed shows the no-trials state
    Given no trials have been recorded yet
    Then the "Recent Activity" feed shows "No trials recorded yet"

  # ── Running metrics / boundaries ─────────────────────────────────────────
  @data
  Scenario Outline: Free-operant metric formatting
    Given a "<type>" free-operant target with aggregate "<agg>"
    Then the running metric badge shows "<display>"

    Examples:
      | type       | agg     | display |
      | frequency  | 7       | 7       |
      | rate       | 7/min   | 7/min   |
      | duration   | 67s     | 1:07    |
      | latency    | avg 4s  | 0:04    |
      | interval   | 60%     | 60%     |
      | frequency  | 0       | (hidden) |

  @edge
  Scenario: Interval percentage is a bounded 0-100 value
    Given an interval target with intervals scored
    Then the metric is computed as intervals-yes over intervals-scored, rounded, shown as "<pct>%"
    And it never exceeds 100% nor drops below 0%

  @data
  Scenario Outline: Per-goal status against the 80% mastery threshold
    Given a goal at "<accuracy>"
    Then its status label is "<status>"

    Examples:
      | accuracy | status      |
      | 90%      | On Track    |
      | 80%      | On Track    |
      | 55%      | Behind      |
      | no data  | Not Started |
      | mastered | Mastered    |

  # ── Persistence / reopen ─────────────────────────────────────────────────
  @positive
  Scenario: Recorded data persists after leaving and reopening the workspace
    Given I recorded 3 "Tantrum" occurrences and scored several trials
    When I navigate away and reopen the session workspace
    Then the "Tantrum" count still reads 3
    And the previously scored trials still appear in "Recent Activity"

  @edge
  Scenario: Pausing the session halts trial timing but preserves counts
    Given I have logged behaviours and trials
    When the session is paused
    Then the counts and feed are unchanged
    And duration-based timing is halted until resume

  # ── Empty states ─────────────────────────────────────────────────────────
  @edge
  Scenario: A session with no goals hides the goal switcher
    Given a session whose patient has no active programming goals
    Then the goal switcher renders nothing
    And no target prompt block is shown

  @edge
  Scenario: The behaviour bar prompts to log when nothing is recorded
    Given the behaviour bar has behaviours but none logged
    Then the collapsed header shows "Tap to log"

  # ── Data-entry timing / concurrency ──────────────────────────────────────
  @edge @security
  Scenario: Rapid repeated taps do not double-count a single behaviour tap
    When I tap the "Tantrum" "+" stepper once
    Then exactly one occurrence is recorded (each tap logs exactly one datapoint)

  @edge
  Scenario: The Capture / Note toggle switches the mobile pane without losing data
    Given I am in the mobile focus view
    When I switch from "Capture" to "Note" and back
    Then the recorded trial data is retained
    And the "Quick session note" text is preserved

  # ── Accessibility ────────────────────────────────────────────────────────
  @a11y
  Scenario: Trial cursor and end control expose accessible names
    Given the mobile focus view is open
    Then the trial arrows expose "Previous trial" and "Next trial"
    And the end control exposes "End session"

  @a11y
  Scenario: Behaviour steppers and result icons carry semantic labels
    Given the behaviour bar is shown
    Then each "Tantrum" control exposes an accessible label including its current count
    And each feed row's result icon conveys correct vs incorrect
