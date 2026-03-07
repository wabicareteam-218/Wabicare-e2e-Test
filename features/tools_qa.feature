@tools @qa
Feature: Tools
  Clinicians can access practice management tools.

  Background:
    Given I am logged in

  Scenario: Navigate to Tools page
    When I click Tools in the sidebar
    Then I should see the Tools page

  Scenario: Tools page shows available tools
    When I am on the Tools page
    Then I should see available tool options
