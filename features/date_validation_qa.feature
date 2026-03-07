# Date field validation (MM/DD/YYYY)
@validators @date @qa
Feature: Date validation
  Date fields accept valid MM/DD/YYYY and show errors for invalid input.

  Scenario: Valid date is accepted
    Given I am on a form with a date field
    When I enter the date "01/15/2024"
    Then the date field should show no error

  Scenario: Invalid format shows error
    Given I am on a form with a date field
    When I enter the date "2024-01-15"
    Then the date field should show a format or validation error

  Scenario: Invalid date (e.g. Feb 30) shows error
    Given I am on a form with a date field
    When I enter the date "02/30/2024"
    Then the date field should show a validation error
