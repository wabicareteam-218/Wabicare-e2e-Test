@settings @qa
Feature: Settings
  Clinicians can manage application settings and preferences.

  Background:
    Given I am logged in

  Scenario: Navigate to Settings page
    When I click Settings in the sidebar
    Then I should see the Settings page

  Scenario: Settings page shows configuration options
    When I am on the Settings page
    Then I should see settings categories or configuration fields
