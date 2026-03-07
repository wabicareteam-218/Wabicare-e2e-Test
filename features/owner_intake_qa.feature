# Parent / owner intake (forms sent to parent, parent fills from portal)
@intake @parent @owner @qa
Feature: Owner (parent) intake
  Parents or guardians can complete intake forms sent to them.

  Scenario: Parent can open intake link or form
    Given a parent has been sent an intake form link or email
    When the parent opens the link or form
    Then the parent should see the intake form or login

  Scenario: Parent can fill and submit a form
    Given the parent is on an intake form
    When the parent fills required fields and submits
    Then the form should be submitted or show success
