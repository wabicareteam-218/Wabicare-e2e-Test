# Grounded in wabi-flutter-dev:
#   lib/features/clinic/intake/widgets/basic_intake_panels.dart  (InsurancePanel + CardUploadBox)
# Pay Type = Insurance | Private Pay. Insurance path shows: Insurance Card (Front/Back
# upload+scan), Coverage Details, Subscriber Information. Private Pay hides all of them
# and shows an emerald banner. Card picker allows jpg/jpeg/png/pdf only. Success toasts:
# "Front of card uploaded" / "Back of card uploaded". Failure toast: "Upload failed: <err>".
# Card upload + card view are gated to roles: bcba, owner, administrator, super_admin,
# clinical_director (NOT rbt).

Feature: Patient Profile — Insurance Information
  As a clinician
  I want to record how a patient pays and capture their insurance card and coverage
  So that authorization and billing have the data they need.
  Insurance is the second required ("*") Profile section and depends on Basic
  Information having been saved (a real patient id must exist to persist a card).

  Background:
    Given I am logged in as a clinician with the "bcba" role
    And the patient "Rujitha Kannan" has been created (Basic Information saved)
    When I open the "Insurance Information" section
    Then the "Pay Type" card titled "Select how this patient will pay for services" is shown
    And the pay-type chips "Insurance" and "Private Pay" are visible

  # ── Pay Type toggle ──────────────────────────────────────────────────────
  # NOTE: card titles corrected to the live app ("Primary insurance card", and
  # the Coverage card exposes only its "Insurance provider and member
  # information" subtitle).
  @smoke @positive
  Scenario: Insurance is the default pay type and reveals the insurance sub-cards
    Then the "Insurance" sub-cards are shown by default
    And I see the "Primary insurance card" card
    And I see "Insurance provider and member information"
    And I see the "Subscriber Information" card titled "Primary policy holder details"

  @positive
  Scenario: Switching to Private Pay hides all insurance fields and shows the banner
    When I select the "Private Pay" chip
    Then the "Primary insurance card" and "Subscriber Information" cards are hidden
    And I see the banner "This patient will pay out-of-pocket. No insurance authorization is required."

  @positive
  Scenario: Switching back to Insurance restores the insurance sub-cards
    Given I selected "Private Pay"
    When I select the "Insurance" chip
    Then the insurance sub-cards reappear
    And the private-pay banner is gone

  # ── Coverage details ─────────────────────────────────────────────────────
  @smoke @positive
  Scenario: Enter and save coverage details
    When I enter "Blue Cross Blue Shield" in "Insurance Provider"
    And I enter "RK987654321" in "Member ID"
    And I enter "GRP-100" in "Group Number"
    And I click "Save"
    Then the "Insurance Information" section shows a green completion checkmark
    And I see the toast "Insurance Information saved successfully"

  @edge
  Scenario: Coverage details are optional — Insurance saves with the fields blank
    When I leave "Insurance Provider", "Member ID" and "Group Number" empty
    And I click "Save"
    Then the section still saves (no hard validation on coverage fields)

  @edge @data
  Scenario Outline: Coverage fields tolerate boundary and unusual input
    When I enter "<value>" in "<field>"
    And I click "Save"
    Then the value round-trips on reload without a client error

    Examples:
      | field              | value                                   |
      | Member ID          | ABC-000-111-222-333-444                 |
      | Member ID          | 0000000000000000000000000000000000000000|
      | Insurance Provider | Blue Cross Blue Shield of Über-Region ™ |
      | Group Number       | GRP 000 (legacy)                        |

  @security
  Scenario: Coverage fields do not execute injected markup
    When I enter "<img src=x onerror=alert(1)>" in "Insurance Provider"
    And I click "Save"
    Then the value is stored/escaped as text and no script runs

  # ── Subscriber toggle ────────────────────────────────────────────────────
  @positive
  Scenario: "Patient is the subscriber" hides the subscriber name/DOB fields
    When I check "Patient is the subscriber"
    Then the "Subscriber Name" and "Subscriber DOB" inputs are hidden
    And any previously entered subscriber name and DOB are cleared

  @positive
  Scenario: Unchecking "Patient is the subscriber" shows subscriber name and DOB
    Given "Patient is the subscriber" is unchecked
    Then the "Subscriber Name" input (hint "John Doe Sr.") is shown
    And the "Subscriber DOB" input (hint "MM/DD/YYYY") is shown
    When I enter "Priya Kannan" in "Subscriber Name"
    And I enter "07/04/1988" in "Subscriber DOB"
    And I click "Save"
    Then the subscriber details persist

  @edge
  Scenario: Re-checking subscriber after entering details wipes the subscriber fields
    Given I entered "Priya Kannan" in "Subscriber Name" and "07/04/1988" in "Subscriber DOB"
    When I check "Patient is the subscriber"
    Then both subscriber fields are cleared and hidden

  # ── Card upload — happy path ─────────────────────────────────────────────
  @smoke @positive
  Scenario: Upload the front of the insurance card
    When I click "Upload" in the "Front of Card" box
    And I choose the file "insurance-card-front.png"
    Then I see the toast "Front of card uploaded"
    And the "Front of Card" box shows the uploaded card

  @smoke @positive
  Scenario: Upload the back of the insurance card
    When I click "Upload" in the "Back of Card" box
    And I choose the file "insurance-card-back.png"
    Then I see the toast "Back of card uploaded"
    And the "Back of Card" box shows the uploaded card

  @positive
  Scenario: Upload both sides and then save Insurance
    When I upload "insurance-card-front.jpg" to "Front of Card"
    And I upload "insurance-card-back.jpg" to "Back of Card"
    And I click "Save"
    Then both cards persist and reload from the "insurance_cards" folder

  @positive @data
  Scenario Outline: All allowed card file types upload successfully
    When I upload a "<file>" to "Front of Card"
    Then I see the toast "Front of card uploaded"

    Examples:
      | file            |
      | card-front.jpg  |
      | card-front.jpeg |
      | card-front.png  |
      | card-front.pdf  |

  @positive
  Scenario: Replace an already-uploaded front card
    Given "Front of Card" already shows "card-front.png"
    When I click "Upload" in the "Front of Card" box
    And I choose "card-front-v2.png"
    Then the box updates to "card-front-v2.png"
    And I see the toast "Front of card uploaded"

  @positive
  Scenario: The "Scan" affordance opens the same file picker as Upload
    When I trigger "Scan" on the "Front of Card" box
    Then the jpg/jpeg/png/pdf file picker opens (scan reuses the upload flow)

  # ── Card upload — negative / edge / security ─────────────────────────────
  @negative @data
  Scenario Outline: Disallowed file types are filtered out by the picker
    When I open the card file picker for "Front of Card"
    Then the picker only permits extensions jpg, jpeg, png, pdf
    And a "<file>" is not selectable

    Examples:
      | file                |
      | card.gif            |
      | card.bmp            |
      | card.tiff           |
      | card.heic           |
      | evil.exe            |
      | card.svg            |
      | notes.txt           |
      | scan.doc            |

  @negative @security
  Scenario: A renamed executable disguised as .png is rejected on upload failure
    When I upload "malware-renamed.png" whose bytes are an executable
    Then the server rejects it and I see a toast starting "Upload failed:"
    And no card thumbnail is shown for that side

  @negative @edge
  Scenario: An oversized card image surfaces an upload-failure toast
    When I upload a 25 MB "huge-card.png" to "Front of Card"
    Then I see a toast starting "Upload failed:" with the backend size error
    And the "Front of Card" box does not show a persisted card

  @negative @edge
  Scenario: A zero-byte / corrupt file is rejected gracefully
    When I upload a 0-byte "empty.png" to "Back of Card"
    Then the picker or server rejects it and no partial upload state remains

  @negative
  Scenario: Cancelling the file picker leaves the card box unchanged
    When I click "Upload" in the "Front of Card" box
    And I cancel the file chooser
    Then no toast appears and the box shows no file

  @edge @security
  Scenario: A card picked before the patient exists is held and uploaded on create
    Given Basic Information has NOT yet been saved (patient id is "pending-intake")
    When I pick "card-front.png" for "Front of Card"
    Then the box shows the file as selected (bytes held by the screen)
    When I save Basic Information to create the patient
    Then the held front card is uploaded to "insurance_cards" automatically

  @negative
  Scenario: An upload while a patient save fails logs the failure without a fake success
    Given the pending patient never gets a real id
    When the held card upload fails
    Then the failure is logged and the card is not shown as persisted

  # ── Permission / role gating ─────────────────────────────────────────────
  @permission @security
  Scenario: RBT users cannot see or upload the insurance card
    Given I am logged in as an "rbt"
    When I open "Insurance Information" with "Insurance" selected
    Then the "Insurance Card" card is not rendered
    And the Coverage Details and Subscriber cards are also hidden for rbt

  @permission @data
  Scenario Outline: Privileged roles can view and upload the insurance card
    Given I am logged in as a "<role>"
    When I open "Insurance Information" with "Insurance" selected
    Then the "Insurance Card" card is visible and uploadable

    Examples:
      | role               |
      | bcba               |
      | owner              |
      | administrator      |
      | super_admin        |
      | clinical_director  |

  # ── Data isolation / persistence ─────────────────────────────────────────
  @security
  Scenario: Insurance cards load only from the current patient's documents
    When I reopen Insurance for "Rujitha Kannan"
    Then only cards in her "insurance_cards" folder load
    And the most recent front/back are chosen by upload date

  @a11y
  Scenario: Card upload controls are reachable and labelled
    Then each card box exposes an "Upload" button as an accessible control
    And the "Patient is the subscriber" control is a labelled checkbox
