@dashboard @qa
Feature: Dashboard
  Clinicians see an overview dashboard after logging in.

  Background:
    Given I am logged in

  Scenario: Dashboard loads after login
    When I navigate to the Dashboard
    Then I should see the Dashboard page

  Scenario: Dashboard shows navigation sidebar
    When I am on the Dashboard
    Then I should see sidebar links for Dashboard, Patients, Sessions, Schedule, Reports, Tools, Settings

  Scenario: Navigate from Dashboard to Patients
    When I click Patients in the sidebar
    Then I should see the Patients list page
