@schedule @qa
Feature: Schedule
  Clinicians can view and manage their schedule and appointments.

  Background:
    Given I am logged in

  Scenario: Navigate to Schedule page
    When I click Schedule in the sidebar
    Then I should see the Schedule page

  Scenario: Schedule shows calendar or appointment view
    When I am on the Schedule page
    Then I should see a calendar view or appointment list

  Scenario: Schedule allows navigation between dates
    When I am on the Schedule page
    Then I should be able to navigate between dates or weeks
