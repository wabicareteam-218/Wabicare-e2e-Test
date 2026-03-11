@hrms @onboarding @e2e @qa
Feature: HRMS Onboarding
  Clinicians can navigate to the HRMS module via the app-switcher menu,
  open the Onboarding section, verify filter tabs, and create a new
  onboarding workflow. Any bugs detected are auto-reported via AI Copilot.

  Background:
    Given I am logged in as a clinician

  Scenario: Navigate to HRMS via the app-switcher menu
    When I click the mesh/app-switcher icon in the top bar
    And I select HRMS from the module list
    Then I see the HRMS Dashboard with Onboarding module

  Scenario: Open the Onboarding module
    When I click the Onboarding module card
    Then I see the Onboarding page with filter tabs

  Scenario: Verify filter tabs are present
    Then I see filter tabs All, In Progress, Completed, and Overdue

  Scenario: Verify New Onboarding button exists
    Then I see the New Onboarding button on the right

  Scenario: Click New Onboarding and verify form loads
    When I click New Onboarding
    Then I should see a new onboarding form with input fields
    And no error or 404 page is shown
    But if a bug is detected, it is auto-reported via AI Copilot
