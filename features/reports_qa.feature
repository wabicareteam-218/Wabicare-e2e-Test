@reports @qa
Feature: Reports
  Clinicians can view and generate reports.

  Background:
    Given I am logged in

  Scenario: Navigate to Reports page
    When I click Reports in the sidebar
    Then I should see the Reports page

  Scenario: Reports page shows available report types
    When I am on the Reports page
    Then I should see report options or categories
