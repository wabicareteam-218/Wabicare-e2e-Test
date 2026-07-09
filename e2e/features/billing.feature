Feature: Billing — Insurance Claims
  As a clinician (Owner) managing revenue cycle, I create, submit, and track
  insurance claims from the Billing > Claims area of the Wabi web app
  (dev.wabicare.com). Scenarios are grounded in the Flutter source
  (billing/claims: claims_list_screen.dart, claim_create_screen.dart,
  claim_detail_screen.dart) and probe validation, boundaries, amounts,
  dates, status workflow, permission gating, and empty/error states.

  # Source facts embedded below:
  #  - Claims list header: "Claims" / "Create, submit, and track insurance claims"
  #  - Search box hint: "Search claims..."
  #  - Status filter pills (with counts): All, Draft, Submitted, Pending, Paid, Rejected, Appealed
  #  - Table columns: PATIENT, PAYER, DATE, CPT, UNITS, AMOUNT, STATUS
  #  - Empty state text: "No claims found" (LucideIcons.fileX)
  #  - Create form title: "New Claim" / "Create a new insurance claim"; submit button "Create Claim"
  #  - CPT codes: 97151..97158 (default 97153); Service Location: Clinic, Home, School, Telehealth
  #  - Date picker allows firstDate = today-2yr, lastDate = today (no future dates)
  #  - Validation toasts: "Patient name is required", "Service date is required"
  #  - Success toast: "Claim created successfully"; failure: "Failed to create claim: <error>"
  #  - Detail tabs: Details, Validation, AI Tools, Audit Log; Submit button shown only when status == draft
  #  - NOTE: Pay / Reject / Appeal / Void exist in the view model but are NOT surfaced in the detail UI

  Background:
    Given I am logged in as an "Owner" clinician
    And I navigate to "Billing" > "Claims"
    And the Claims screen has finished loading

  # ---------------- Claims list (read / smoke) ----------------

  @smoke @positive
  Scenario: Claims list renders header, search, filters, and New Claim action
    Then I see the page header "Claims"
    And I see the subtitle "Create, submit, and track insurance claims"
    And I see a search field with placeholder "Search claims..."
    And I see status filter pills "All", "Draft", "Submitted", "Pending", "Paid", "Rejected", "Appealed"
    And I see a "New Claim" button

  @positive @data
  Scenario Outline: Filter claims by status pill
    When I click the "<pill>" status filter
    Then only claims with status "<status>" are shown
    And the "<pill>" pill is visually selected

    Examples:
      | pill      | status    |
      | Draft     | draft     |
      | Submitted | submitted |
      | Pending   | pending   |
      | Paid      | paid      |
      | Rejected  | rejected  |
      | Appealed  | appealed  |

  @positive
  Scenario: Selecting All clears the status filter
    Given I have selected the "Rejected" status filter
    When I click the "All" status filter
    Then claims of every status are shown
    And the pill count on "All" equals the sum of all status counts

  @positive
  Scenario: Search filters the claims table
    When I type "Rujitha" into the "Search claims..." field
    Then the table shows only claims whose patient name contains "Rujitha"

  @edge
  Scenario: Search with no matches shows the empty state
    When I type "zzzz-no-such-patient" into the "Search claims..." field
    Then I see the empty message "No claims found"

  @edge @security
  Scenario: Search input treats markup as a literal string
    When I type "<script>alert(1)</script>" into the "Search claims..." field
    Then no script executes
    And the table shows "No claims found" or only literally-matching rows

  @edge
  Scenario: Empty claims list shows the fileX empty state
    Given the organization has no claims
    Then I see the empty message "No claims found"

  @negative
  Scenario: Backend error while loading claims is surfaced
    Given the claims API returns an error
    Then the list area shows the returned error message in destructive styling

  # ---------------- Create claim (happy path) ----------------

  @smoke @positive
  Scenario: Create a valid claim with all fields
    When I click "New Claim"
    Then I see the form title "New Claim"
    When I fill "Patient Name" with "Rujitha Kannan"
    And I fill "Payer Name" with "Aetna"
    And I fill "Authorization #" with "AUTH-1001"
    And I select CPT Code "97153"
    And I pick a "Service Date" of today
    And I fill "Units" with "8"
    And I fill "Amount ($)" with "240.00"
    And I select Service Location "Clinic"
    And I fill "Place of Service Code" with "11"
    And I fill notes with "Standard direct therapy session"
    And I click "Create Claim"
    Then I see the toast "Claim created successfully"
    And I land on the newly created claim's detail screen

  @positive @data
  Scenario Outline: CPT code dropdown offers all supported ABA codes
    When I click "New Claim"
    And I open the "CPT Code" dropdown
    Then I can select "<code>" labelled "<code> - <description>"

    Examples:
      | code  | description                                            |
      | 97151 | Behavior identification assessment                     |
      | 97152 | Behavior identification supporting assessment          |
      | 97153 | Adaptive behavior treatment by protocol                |
      | 97154 | Group adaptive behavior treatment                      |
      | 97155 | Adaptive behavior treatment with protocol modification |
      | 97156 | Family adaptive behavior treatment guidance            |
      | 97157 | Multiple-family group guidance                         |
      | 97158 | Group behavior follow-up assessment                    |

  @positive @data
  Scenario Outline: Service Location dropdown offers all locations
    When I click "New Claim"
    And I open the "Service Location" dropdown
    Then I can select "<location>"

    Examples:
      | location  |
      | Clinic    |
      | Home      |
      | School    |
      | Telehealth |

  @positive
  Scenario: CPT Code defaults to 97153 and Units/Amount pre-fill
    When I click "New Claim"
    Then the "CPT Code" defaults to "97153"
    And "Units" is pre-filled with "1"
    And "Amount ($)" is pre-filled with "0.00"

  # ---------------- Create claim (validation / negative) ----------------

  @negative
  Scenario: Missing patient name is rejected
    When I click "New Claim"
    And I leave "Patient Name" empty
    And I pick a "Service Date" of today
    And I click "Create Claim"
    Then I see the error toast "Patient name is required"
    And no claim is created

  @negative
  Scenario: Whitespace-only patient name is treated as empty
    When I click "New Claim"
    And I fill "Patient Name" with "   "
    And I pick a "Service Date" of today
    And I click "Create Claim"
    Then I see the error toast "Patient name is required"

  @negative
  Scenario: Missing service date is rejected
    When I click "New Claim"
    And I fill "Patient Name" with "Rujitha Kannan"
    And I leave "Service Date" empty
    And I click "Create Claim"
    Then I see the error toast "Service date is required"

  @edge @data
  Scenario Outline: Amount boundary and malformed values
    When I click "New Claim"
    And I fill "Patient Name" with "Rujitha Kannan"
    And I pick a "Service Date" of today
    And I fill "Amount ($)" with "<amount>"
    And I click "Create Claim"
    Then the submitted amount is "<effective>"

    Examples:
      | amount        | effective | note                                    |
      | 0             | 0         | zero amount currently accepted          |
      | 0.00          | 0         | default                                 |
      | -50.00        | -50       | negative amount — should be rejected    |
      | 999999999.99  | 999999999.99 | very large amount                    |
      | abc           | 0         | non-numeric falls back to 0 (tryParse)  |
      | 12.999        | 12.999    | more than 2 decimals                    |

  @edge @data
  Scenario Outline: Units boundary and malformed values
    When I click "New Claim"
    And I fill "Patient Name" with "Rujitha Kannan"
    And I pick a "Service Date" of today
    And I fill "Units" with "<units>"
    And I click "Create Claim"
    Then the submitted units is "<effective>"

    Examples:
      | units | effective | note                                |
      | 0     | 0         | zero units                          |
      | -3    | -3        | negative units — should be rejected |
      | 1.5   | 1         | decimal truncated by int.tryParse   |
      | abc   | 1         | non-numeric falls back to 1         |
      | 99999 | 99999     | very large units                    |

  @edge
  Scenario: Service Date picker forbids future dates
    When I click "New Claim"
    And I open the "Service Date" picker
    Then dates after today are not selectable
    And dates earlier than two years ago are not selectable

  @edge
  Scenario: Create a claim without optional payer, auth, or notes
    When I click "New Claim"
    And I fill "Patient Name" with "Rujitha Kannan"
    And I pick a "Service Date" of today
    And I click "Create Claim"
    Then I see the toast "Claim created successfully"

  @edge @security
  Scenario: Very long free-text notes and patient name are accepted or trimmed safely
    When I click "New Claim"
    And I fill "Patient Name" with a 5000-character string
    And I fill notes with a 10000-character string
    And I pick a "Service Date" of today
    And I click "Create Claim"
    Then the app does not crash
    And either the claim is created or a graceful error toast is shown

  @negative
  Scenario: Backend failure on create surfaces the reason
    Given the claim create API will fail
    When I submit a valid claim
    Then I see an error toast starting with "Failed to create claim:"
    And I remain on the New Claim form

  @edge
  Scenario: Create button is disabled while saving
    When I submit a valid claim
    Then the action button shows "Saving..." and is disabled until the request resolves

  # ---------------- Claim detail & workflow ----------------

  @smoke @positive
  Scenario: Open a claim shows detail header and tabs
    When I open an existing claim from the list
    Then the header shows the patient name and "Claim #<id> - <Status>"
    And I see the tabs "Details", "Validation", "AI Tools", "Audit Log"

  @positive
  Scenario: Submit is available only for draft claims
    Given I open a claim with status "draft"
    Then I see a "Submit" button
    When I click "Submit"
    Then the claim reloads with an advanced status

  @negative
  Scenario: Submit button is absent for non-draft claims
    Given I open a claim with status "paid"
    Then no "Submit" button is shown

  @positive @data
  Scenario Outline: Status label rendering in detail and list
    Given a claim has backend status "<raw>"
    Then it is displayed as "<label>"

    Examples:
      | raw       | label     |
      | draft     | Draft     |
      | submitted | Submitted |
      | pending   | Pending   |
      | paid      | Paid      |
      | approved  | Approved  |
      | flagged   | Flagged   |
      | rejected  | Rejected  |
      | appealed  | Appealed  |
      | voided    | Voided    |

  @positive
  Scenario: Validation tab reports valid vs issues
    Given I open a claim
    When I select the "Validation" tab
    Then I see "Claim is valid" or "Validation issues found" with listed errors/warnings

  @positive
  Scenario: AI Tools tab exposes audit, denial analysis, and appeal generation
    Given I open a claim
    When I select the "AI Tools" tab
    Then I see actions "AI Audit", "Denial Analysis", and "Appeal Letter"

  @edge
  Scenario: Audit Log empty state
    Given I open a claim with no audit entries
    When I select the "Audit Log" tab
    Then I see "No audit entries"

  @negative
  Scenario: Opening a non-existent claim id
    When I navigate directly to "/billing/claims/does-not-exist"
    Then I see an error state with a "Retry" action or "Claim not found"

  @permission
  Scenario: Non-billing role cannot reach the Claims area
    Given I am logged in as a role without billing access
    When I attempt to open "/billing/claims"
    Then I am blocked or redirected away from the Claims screen

  @security
  Scenario: Direct claim-detail URL from another organization is not accessible
    Given a claim id belonging to a different organization
    When I navigate directly to that claim's detail URL
    Then the claim data is not disclosed and an error is shown

  @a11y
  Scenario: Claims table and pills are keyboard and screen-reader navigable
    Then each status pill is focusable and announces its label and count
    And table rows are reachable via keyboard and expose the patient name
