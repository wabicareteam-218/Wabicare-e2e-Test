# Patient profile (basic info, edit, view)
@patient @profile @qa
Feature: Patient profile
  Clinicians can view and edit patient profile information.

  Background:
    Given I am logged in

  Scenario: Open patient list
    When I navigate to the Patients area
    Then I should see a list of patients or an empty state

  Scenario: Open a patient profile
    Given there is at least one patient (or I create one)
    When I open a patient from the list
    Then I should see the patient profile or detail view

  Scenario: Patient profile shows basic info
    Given I have opened a patient profile
    Then I should see patient name and basic information
