# Patient Intake Forms — 9 required sections under the Intake Forms tab
@intake @forms @qa
Feature: Patient Intake Forms
  Clinicians complete 9 intake form sections for a new patient.

  Background:
    Given I am logged in
    And I have opened a patient's Intake Forms tab

  # ── 1. Client Information ──
  Scenario: Navigate to Client Information
    When I click Client Information in the sidebar
    Then I should see fields for preferred name, languages, Medicaid ID, address, siblings, service location, and preferred times

  Scenario: Fill Client Information
    When I fill in Client Information fields
    Then the Client Information section fields are populated

  # ── 2. Caregiver & Provider Info ──
  Scenario: Navigate to Caregiver & Provider Info
    When I click Caregiver & Provider Info in the sidebar
    Then I should see fields for pronouns, contact preference, secondary caregiver, emergency contact, PCP, and referring provider

  Scenario: Fill Caregiver & Provider Info
    When I fill in all caregiver and provider fields
    Then the Caregiver & Provider Info section fields are populated

  # ── 3. ABA Therapy History ──
  Scenario: Navigate to ABA Therapy History
    When I click ABA Therapy History in the sidebar
    Then I should see fields for previous ABA services, duration, and previous provider

  Scenario: Fill ABA Therapy History
    When I fill in ABA therapy history fields
    Then the ABA Therapy History section fields are populated

  # ── 4. Challenging Behaviors ──
  Scenario: Navigate to Challenging Behaviors
    When I click Challenging Behaviors in the sidebar
    Then I should see fields for behavior frequency, duration, triggers, and interventions

  Scenario: Fill Challenging Behaviors
    When I fill in challenging behavior descriptions
    Then the Challenging Behaviors section fields are populated

  # ── 5. Education & Therapies ──
  Scenario: Navigate to Education & Therapies
    When I click Education & Therapies in the sidebar
    Then I should see fields for school name, grade, teacher, additional therapies, and IEP document upload

  Scenario: Fill Education & Therapies
    When I fill in education and therapy information
    Then the Education & Therapies section fields are populated

  # ── 6. Medical History ──
  Scenario: Navigate to Medical History
    When I click Medical History in the sidebar
    Then I should see fields for allergies, reactions, medications, dosage, frequency, and health conditions

  Scenario: Fill Medical History
    When I fill in medical history fields
    Then the Medical History section fields are populated

  # ── 7. Diagnosis & Documents ──
  Scenario: Navigate to Diagnosis & Documents
    When I click Diagnosis & Documents in the sidebar
    Then I should see fields for ASD diagnosis, ICD code, date, and document upload

  Scenario: Fill Diagnosis & Documents
    When I fill in diagnosis details and upload documents
    Then the Diagnosis & Documents section fields are populated

  # ── 8. Availability & Concerns ──
  Scenario: Navigate to Availability & Concerns
    When I click Availability & Concerns in the sidebar
    Then I should see fields for weekly schedule and primary concerns

  Scenario: Fill Availability & Concerns
    When I fill in availability and concerns
    Then the Availability & Concerns section fields are populated

  # ── 9. Consent & Agreements ──
  Scenario: Navigate to Consent & Agreements
    When I click Consent & Agreements in the sidebar
    Then I should see HIPAA notice, treatment consent, parent training agreement, and signature fields

  Scenario: Sign Consent & Agreements
    When I fill in signer name, date, relationship, and provide a signature
    Then the Consent & Agreements section is completed

  # ── Save All ──
  Scenario: Save all completed intake forms
    Given all 9 intake form sections are filled
    When I click Save
    Then the intake forms should show completion progress
