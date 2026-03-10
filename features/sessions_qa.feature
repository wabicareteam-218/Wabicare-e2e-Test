@sessions @e2e @qa
Feature: Create and Verify a Session
  Clinicians can create a new therapy session from the Sessions page,
  fill all details in the popup, save, and verify the session appears
  on the Schedule calendar on the correct date.

  Background:
    Given I am logged in as a clinician

  # ── Navigate ──
  Scenario: Navigate to Sessions page
    When I click Sessions in the left navigation
    Then I see the Sessions page with Add Session button

  # ── Create Session ──
  Scenario: Open Add Session popup
    When I click Add Session
    Then the session scheduling popup opens with title, patient, date, time, type, duration, and CPT code fields

  Scenario: Fill session title
    When I enter a session title
    Then the title field is populated

  Scenario: Select a patient
    When I click Select a patient and choose a patient
    Then the patient is attached to the session

  Scenario: Select session type and duration
    When I select Session type and 1h duration
    Then the session type and duration are set

  Scenario: Select CPT code
    When I select CPT code 97153
    Then the CPT code is selected

  Scenario: Save the session
    When I click Save
    Then the session is saved successfully
    And no error toast is shown

  # ── Verify on Schedule Calendar ──
  Scenario: Navigate to Schedule
    When I click Schedule in the left navigation
    Then I see the calendar view

  Scenario: Verify session on calendar
    When I navigate to the session date on the calendar
    Then I see the session title on the calendar for that date
