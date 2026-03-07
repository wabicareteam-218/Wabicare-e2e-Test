# Consent & Agreements - HIPAA, Treatment Consent, Parent Training
@consent @intake @qa
Feature: Consent Forms
  As a clinician or parent I can view and complete consent and agreement forms.

  Background:
    Given I am logged in
    And I am on the Patients list or a patient intake

  Scenario: Open Consent & Agreements section
    When I open the Consent & Agreements form section
    Then I should see consent form options or content

  Scenario: HIPAA notice is available
    When I open the Consent & Agreements form section
    Then I should see HIPAA or privacy-related content

  Scenario: Consent for treatment is available
    When I open the Consent & Agreements form section
    Then I should see treatment consent or agreement content
