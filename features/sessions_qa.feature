@sessions @e2e @qa
Feature: Schedule, run, and record a therapy session
  A clinician can create a new therapy session for a patient from the
  Sessions page, open it into the Session Workspace, start the session,
  collect data for treatment goals and challenging behaviours, and then
  end (check out of) the session.

  Background:
    Given I am logged in as a clinician
    And I navigate to the Sessions page

  # ── Create ──
  Scenario: Add a new session for Demo Patient 2 on a future date
    When I click Add Session
    And I enter a session title
    And I select the patient "Demo Patient 2"
    And I set the date to today plus 10 days at a free time slot
    And I click Save
    Then the session is scheduled successfully
    And no scheduling conflict error is shown

  Scenario: The new session appears in the Sessions list
    Then the Sessions count increases by one

  # ── Open / Go to Session ──
  Scenario: Open the session and go to the Session Workspace
    When I open the scheduled session for "Demo Patient 2"
    Then I land on the Session Workspace
    And I see the "Tap to Start Session" / "Check In & Start" control

  # ── Run the session ──
  Scenario: Start the session and collect data for the Handwashing goal
    When I click Check In & Start
    Then the session status becomes "In Progress"
    When I record a Task Analysis trial on the "Handwashing — full routine" goal
    Then the goal data is recorded

  Scenario: Record a challenging behaviour
    When I record a "Tantrum" behaviour occurrence
    Then the Tantrum counter increases

  # ── Stop ──
  Scenario: End the session and check out
    When I open More options and choose "End & check out"
    And I confirm the end-of-session review
    Then the session is no longer In Progress
