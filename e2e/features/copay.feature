# Grounded in wabi-flutter-dev:
#   lib/features/clinic/intake/widgets/basic_intake_panels.dart  (CopayPanel)
# Co-Pay is the third, OPTIONAL Profile section. Co-Pay Status chips: "Co-Pay Required"
# / "No Co-Pay". When required, an "Co-Pay Amount" input (prefix "$", hint "$25.00")
# and a "Payment Method" card appear with chips: Card / Cash / Check / Waive.
# "Card" shows an integrated-terminal info note; "Waive" reveals a "Reason for Waiving"
# input and swaps the action button to "Record Waiver" (otherwise "Process Payment").
# "No Co-Pay" shows the emerald "No Co-Pay Required" confirmation. Private Pay adds a
# warning banner: "Private pay patient — full session fee applies."

Feature: Patient Profile — Co-Pay Payment
  As a clinician
  I want to record whether a co-pay is required and how it will be collected
  So that front-desk collection and billing are correct.
  Co-Pay is optional (no asterisk) and has no hard save gate.

  Background:
    Given I am logged in as a clinician
    And the patient "Rujitha Kannan" has been created with Insurance pay type
    When I open the "Co-Pay Payment" section
    Then the "Co-Pay Status" card titled "Determine if co-pay is required" is shown
    And the chips "Co-Pay Required" and "No Co-Pay" are visible

  # ── Required / None toggle ───────────────────────────────────────────────
  @smoke @positive
  Scenario: Default state is "No Co-Pay" with the emerald confirmation
    Then the "No Co-Pay" chip is selected
    And I see "No Co-Pay Required"
    And I see "Patient's insurance covers 100% of the visit cost."
    And no "Co-Pay Amount" input is shown

  @positive
  Scenario: Selecting "Co-Pay Required" reveals amount and payment method
    When I select the "Co-Pay Required" chip
    Then a "Co-Pay Amount" input with prefix "$" and hint "$25.00" appears
    And the "Payment Method" card titled "Select how the co-pay will be collected" appears
    And the payment chips "Card", "Cash", "Check" and "Waive" are shown

  @positive
  Scenario: Toggling back to "No Co-Pay" hides amount and payment method
    Given I selected "Co-Pay Required" and entered "25.00"
    When I select the "No Co-Pay" chip
    Then the amount and Payment Method card are hidden
    And the emerald "No Co-Pay Required" confirmation returns

  # ── Amount validation matrix ─────────────────────────────────────────────
  @positive @data
  Scenario Outline: Valid co-pay amounts are accepted
    Given I selected the "Co-Pay Required" chip
    When I enter "<amount>" in "Co-Pay Amount"
    Then the amount is accepted as "<amount>"

    Examples:
      | amount |
      | 25.00  |
      | 0.50   |
      | 40     |
      | 199.99 |

  @negative @edge @data
  Scenario Outline: Boundary and malformed co-pay amounts
    Given I selected the "Co-Pay Required" chip
    When I enter "<amount>" in "Co-Pay Amount"
    And I attempt to proceed
    Then the outcome is "<outcome>"

    Examples:
      | amount        | outcome                                             |
      | 0             | zero co-pay is a degenerate value; flag or block collection |
      | -25           | negative amount must not be collectable             |
      | 999999999     | very large amount should not overflow the terminal  |
      | 25.999        | more than 2 decimals should round or be rejected    |
      | abc           | non-numeric must not be treated as an amount        |
      | 25,00         | comma decimal separator must not be silently mis-parsed |
      | $25           | a duplicate "$" (prefix already present) must not double up |
      |               | empty amount while "Co-Pay Required" is an incomplete state |

  @edge
  Scenario: The "$" prefix is rendered by the field, not stored in the value
    Given I selected "Co-Pay Required"
    When I enter "25.00" in "Co-Pay Amount"
    Then the stored amount is "25.00" without a leading "$"

  # ── Payment method chips ─────────────────────────────────────────────────
  @positive @data
  Scenario Outline: Selecting a payment method updates the panel
    Given I selected the "Co-Pay Required" chip
    When I select the "<method>" payment chip
    Then the "<method>" chip is highlighted as selected
    And the action button reads "<button>"

    Examples:
      | method | button           |
      | Card   | Process Payment  |
      | Cash   | Process Payment  |
      | Check  | Process Payment  |
      | Waive  | Record Waiver    |

  @positive
  Scenario: The Card method shows the integrated-terminal note
    Given I selected "Co-Pay Required"
    When I select the "Card" payment chip
    Then I see "Card payment will be processed through integrated payment terminal."

  @edge
  Scenario: Payment method is single-select (choosing another replaces the first)
    Given I selected the "Card" payment chip
    When I select the "Cash" payment chip
    Then only "Cash" is selected

  # ── Waive + reason ───────────────────────────────────────────────────────
  @positive
  Scenario: Waiving reveals a reason field and the "Record Waiver" action
    Given I selected "Co-Pay Required"
    When I select the "Waive" payment chip
    Then a "Reason for Waiving" input with hint "Enter reason..." appears
    And the action button changes from "Process Payment" to "Record Waiver"

  @negative
  Scenario: Recording a waiver without a reason should be blocked
    Given I selected "Waive"
    When I leave "Reason for Waiving" empty
    And I click "Record Waiver"
    Then the waiver is not recorded until a reason is provided

  @positive
  Scenario: Recording a waiver with a reason
    Given I selected "Waive"
    When I enter "Financial hardship documented" in "Reason for Waiving"
    And I click "Record Waiver"
    Then the waiver reason is captured

  @edge
  Scenario: Switching away from "Waive" hides the reason field
    Given I selected "Waive" and typed a reason
    When I select the "Cash" payment chip
    Then the "Reason for Waiving" input is removed

  # ── Private-pay interaction ──────────────────────────────────────────────
  @positive
  Scenario: Private-pay patients see the full-fee warning above Co-Pay
    Given the patient pay type is "Private Pay"
    When I open "Co-Pay Payment"
    Then I see the warning "Private pay patient — full session fee applies."

  @edge
  Scenario: Co-Pay Status is still shown for a private-pay patient
    Given the patient pay type is "Private Pay"
    When I open "Co-Pay Payment"
    Then the "Co-Pay Status" and payment options remain interactive below the warning

  # ── Save / persistence ───────────────────────────────────────────────────
  @positive
  Scenario: Co-Pay saves and marks the section complete (optional section)
    Given I selected "Co-Pay Required" and entered "25.00" with method "Cash"
    When I click "Save"
    Then the "Co-Pay Payment" section shows a green completion checkmark
    And copay_required persists as true on reload

  @edge
  Scenario: Leaving Co-Pay untouched does not block intake (it is optional)
    Given the "Patient Profile" counter reads "2 / 2 completed" from the two required sections
    Then Co-Pay being incomplete does not stop the intake from proceeding

  @a11y
  Scenario: Co-Pay chips and amount field are keyboard reachable and labelled
    Then the "Co-Pay Required"/"No Co-Pay" chips are focusable controls
    And the "Co-Pay Amount" input exposes an accessible label
