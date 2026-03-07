@sessions @qa
Feature: Sessions
  Clinicians can view and manage therapy sessions.

  Background:
    Given I am logged in

  Scenario: Navigate to Sessions page
    When I click Sessions in the sidebar
    Then I should see the Sessions page

  Scenario: Sessions page shows session list or empty state
    When I am on the Sessions page
    Then I should see a list of sessions or an empty state message

  Scenario: Session list has expected columns
    When I am on the Sessions page
    Then I should see relevant session information like patient name, date, and status
