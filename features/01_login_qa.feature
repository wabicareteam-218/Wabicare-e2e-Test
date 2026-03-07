# Login QA - Run first to verify user can sign in
# All other tests depend on login.
# Flow: in-app email and password fields, submit button.

@login @smoke @qa
Feature: User Login
  User should be able to sign in with email and password before using the app.

  Scenario: Landing page loads
    Given the website is opened
    Then the page title should be "Wabi Clinic" or the app title

  Scenario: User logs in with email and password
    Given the website is opened
    When I enter my email address
    And I enter my password
    And I click Sign in
    Then I am logged in
