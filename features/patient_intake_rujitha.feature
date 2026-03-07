@intake @e2e @rujitha
Feature: Complete Patient Intake — Rujitha Kannan
  End-to-end patient intake flow: create a new patient, fill profile forms
  (Basic Info + Insurance), complete all 9 intake form sections with save
  validation, and schedule an intake appointment.

  Background:
    Given I am logged in as a clinician

  # ── Create Patient ──
  Scenario: Navigate to Patients
    Given I am logged in and navigate to Patients
    Then I see the Patients list

  Scenario: Fill Patient Demographics
    When I click New Patient and fill Patient Demographics for Rujitha Kannan
    Then the demographics fields are populated

  Scenario: Fill Guardian Information
    And I fill Guardian info for Priya Kannan (Mother)
    Then the guardian fields are populated

  Scenario: Save Basic Information
    Then I save Basic Information and patient Rujitha Kannan is created
    And no error toast is shown

  # ── Insurance ──
  Scenario: Navigate to Insurance
    When I click Insurance Information in the left sidebar
    Then the Insurance form is displayed

  Scenario: Fill Insurance Details
    And I fill insurance provider, member ID, group number, policy holder, effective date
    Then the insurance fields are populated

  Scenario: Save Insurance
    Then I save Insurance Information successfully
    And no error toast is shown

  # ── Intake Forms (9 sections) ──
  Scenario: Open Intake Forms tab
    When I click Intake Forms tab
    Then I see all 9 intake form sections listed

  Scenario: Fill and save Client Information
    And I fill Client Information and save
    Then no error toast is shown

  Scenario: Fill and save Caregiver & Provider Info
    And I fill Caregiver & Provider Info and save
    Then no error toast is shown

  Scenario: Fill and save ABA Therapy History
    And I fill ABA Therapy History and save
    Then no error toast is shown

  Scenario: Fill and save Challenging Behaviors
    And I fill Challenging Behaviors and save
    Then no error toast is shown

  Scenario: Fill and save Education & Therapies
    And I fill Education & Therapies and save
    Then no error toast is shown

  Scenario: Fill and save Medical History
    And I fill Medical History and save
    Then no error toast is shown

  Scenario: Fill and save Diagnosis & Documents
    And I fill Diagnosis & Documents and save
    Then no error toast is shown

  Scenario: Fill and save Availability & Concerns
    And I fill Availability & Concerns and save
    Then no error toast is shown

  Scenario: Fill and save Consent & Agreements
    And I fill Consent & Agreements and save
    Then no error toast is shown

  # ── Schedule ──
  Scenario: Open Scheduling and create appointment
    When I click Scheduling tab and click +New
    Then the appointment popup opens

  Scenario: Select Intake type and save appointment
    And I select Intake appointment type and save
    Then the appointment is created

  # ── Verify ──
  Scenario: Verify patient in list
    Then I verify Rujitha Kannan in Patients list
