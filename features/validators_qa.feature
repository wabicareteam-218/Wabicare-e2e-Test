# Form validators (name, email, phone, date, required)
@validators @qa
Feature: Validators
  Form fields are validated (name, email, phone, date, required).

  Scenario: Name validator - empty shows error
    Given I am on a form with a name field
    When I leave the name field empty and blur or submit
    Then I should see an error like "Name is required"

  Scenario: Name validator - numbers not allowed
    Given I am on a form with a name field
    When I enter "John123" in the name field
    Then I should see an error about letters only

  Scenario: Email validator - invalid format shows error
    Given I am on a form with an email field
    When I enter "notanemail" in the email field
    Then I should see an email validation error

  Scenario: Email validator - valid email accepted
    Given I am on a form with an email field
    When I enter "user@example.com" in the email field
    Then the email field should show no error

  Scenario: Phone validator - invalid format shows error
    Given I am on a form with a phone field
    When I enter "abc" in the phone field
    Then I should see a phone validation error

  Scenario: Required field validator
    Given I am on a form with a required field
    When I leave the field empty and submit or blur
    Then I should see a required field error
