@intake @e2e @qa
Feature: Complete Patient Intake
  End-to-end patient intake flow: create a new patient, fill profile
  forms (Basic Info + Insurance), complete all 9 intake form sections
  with save validation, and schedule an intake appointment.

  Test data (patient name, guardian, etc.) is parameterized in test-data.ts
  and can be swapped for different patients without changing the feature.

  Background:
    Given I am logged in as a clinician

  # ── Create Patient ──
  Scenario: Navigate to Patients
    Given I navigate to Patients
    Then I see the Patients list

  Scenario: Fill Patient Demographics
    When I click New Patient and fill Patient Demographics
    Then the demographics fields are populated

  Scenario: Fill Guardian Information
    When I fill Guardian information
    Then the guardian fields are populated

  Scenario: Save Basic Information
    When I click Save on Basic Information
    Then the patient is created
    And no error toast is shown

  # ── Insurance ──
  Scenario: Navigate to Insurance
    When I click Insurance Information in the left sidebar
    Then the Insurance form is displayed

  Scenario: Fill Insurance Details
    When I fill insurance provider, member ID, group number, policy holder, and effective date
    Then the insurance fields are populated

  Scenario: Save Insurance
    When I click Save on Insurance Information
    Then insurance is saved successfully
    And no error toast is shown

  # ── Intake Forms (9 sections) ──
  Scenario: Open Intake Forms tab
    When I click the Intake Forms tab
    Then I see all 9 intake form sections listed

  Scenario: Fill and save Client Information
    When I fill Client Information fields and save
    Then no error toast is shown

  Scenario: Fill and save Caregiver & Provider Info
    When I fill Caregiver & Provider Info fields and save
    Then no error toast is shown

  Scenario: Fill and save ABA Therapy History
    When I fill ABA Therapy History fields and save
    Then no error toast is shown

  Scenario: Fill and save Challenging Behaviors
    When I fill Challenging Behaviors fields and save
    Then no error toast is shown

  Scenario: Fill and save Education & Therapies
    When I fill Education & Therapies fields and save
    Then no error toast is shown

  Scenario: Fill and save Medical History
    When I fill Medical History fields and save
    Then no error toast is shown

  Scenario: Fill and save Diagnosis & Documents
    When I fill Diagnosis & Documents fields and save
    Then no error toast is shown

  Scenario: Fill and save Availability & Concerns
    When I fill Availability & Concerns fields and save
    Then no error toast is shown

  Scenario: Fill and save Consent & Agreements
    When I fill Consent & Agreements fields and save
    Then no error toast is shown

  # ── Schedule Intake Appointment ──
  Scenario: Open Scheduling and create appointment
    When I click the Scheduling tab and click +New
    Then the appointment popup opens

  Scenario: Select Intake type and save appointment
    When I select Intake appointment type and save
    Then the appointment is created

  # ── Verify ──
  Scenario: Verify patient appears in Patients list
    When I navigate back to the Patients list
    Then the newly created patient is visible
