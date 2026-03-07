@patient @management @qa
Feature: Patient Management
  Clinicians can create, view, search, and manage patients.

  Background:
    Given I am logged in

  Scenario: View patient list
    When I navigate to the Patients page
    Then I should see the Patients list with columns for Patient, Guardian, Phone, Next Appointment, Status

  Scenario: Search for a patient
    Given I am on the Patients page
    When I type a patient name in the search field
    Then I should see filtered results matching the search

  Scenario: Create a new patient
    Given I am on the Patients page
    When I click New Patient
    And I fill in patient demographics and guardian contact
    And I click Save
    Then the patient should be created and appear in the Patients list

  Scenario: Open a patient profile
    Given I am on the Patients page
    When I click on a patient row
    Then I should see the patient profile with tabs for Profile, Intake Forms, Scheduling, More

  Scenario: Patient list shows status badges
    When I navigate to the Patients page
    Then each patient should show a status badge like Intake, Auth Pending, Active, or Discharged

  Scenario: Refresh patient list
    Given I am on the Patients page
    When I click Refresh
    Then the patient list should reload
