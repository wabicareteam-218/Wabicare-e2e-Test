# Document upload in intake or patient context
@documents @intake @qa
Feature: Document upload
  Users can upload documents (e.g. diagnosis, intake docs) in the app.

  Scenario: Upload area or button is visible
    Given I am logged in
    And I am on a screen that supports document upload
    Then I should see an option to upload or add a document

  Scenario: User can select a file to upload
    Given I am on a screen that supports document upload
    When I choose to upload a document
    Then I should be able to select a file (or see upload UI)
