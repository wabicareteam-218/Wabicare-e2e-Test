Feature: Know Your Patient (KYP)
  As a clinician on the Wabi web app
  I want a quick, accurate clinical overview of a patient
  So that RBTs and BCBAs see medications, allergies, sensory needs, accommodations
  and safety plans at a glance, and can acknowledge they reviewed it.

  # Source of truth for labels/messages:
  #   lib/features/clinic/kyc/widgets/kyc_tab.dart
  #   lib/features/clinic/kyc/data/models/kyc_models.dart
  # Notes: There is NO numeric completeness/progress meter. The only "progress"
  # signals are section count badges and the per-user "Mark as Reviewed"
  # acknowledgment. Saving edits and adding meds/allergies do NOT show a toast.

  Background:
    Given I am logged in to the Wabi clinician web app as an Owner
    And I open an existing patient's profile
    And I open the "Know Your Patient" overview
    And the left panel header reads "Know Your Patient" with the patient's name below

  # ---------------------------------------------------------------------------
  # Structure / content
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: KYP shows the core clinical sections
    Then I see the sections "Medications", "Allergies", "Sensory Profile", "Accommodations & Strategies" and "Emergency & Safety"
    And sections with entries show a count badge
    And the "BCBA Notes" section only appears when notes exist

  @data @positive
  Scenario Outline: Sensory Profile lists all sensory channels
    When I view the "Sensory Profile" section
    Then I see the channel "<channel>"

    Examples:
      | channel        |
      | Visual         |
      | Auditory       |
      | Tactile        |
      | Vestibular     |
      | Proprioceptive |

  @data @positive
  Scenario Outline: Accommodations & Strategies lists all fields
    When I view the "Accommodations & Strategies" section
    Then I see the field "<field>"

    Examples:
      | field          |
      | Environment    |
      | Communication  |
      | Triggers       |
      | De-escalation  |
      | Safety Concerns|
      | Reinforcers    |

  @positive
  Scenario: Emergency & Safety shows safety plan fields
    When I view the "Emergency & Safety" section
    Then I see "Safety Protocols", "Elopement Plan", "Crisis Intervention" and "Authorized Pickup"

  @positive
  Scenario: Banner overview shows quick chips for the patient
    Then the banner title reads "Know Your Patient"
    And the banner subtitle reads "Quick overview for <patient>"
    And I see medication and allergy count chips such as "2 medications" and "1 allergy"

  # ---------------------------------------------------------------------------
  # Editing content
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Add a medication
    When I click "Edit Patient Info"
    And in "Add Medication" I enter "Medication name" as "Concerta"
    And I enter "Dosage (e.g. 18 mg)" as "18 mg"
    And I click "Add"
    Then "Concerta" appears in the "Medications" list

  @positive
  Scenario: Add an allergy with a severity
    When I click "Edit Patient Info"
    And in "Add Allergy" I enter "Allergen (e.g. Latex, Peanuts)" as "Peanuts"
    And I select severity "severe"
    And I click "Add"
    Then "Peanuts" appears with a "SEVERE" severity badge

  @data @positive
  Scenario Outline: Allergy severity options
    When I add an allergy with severity "<value>"
    Then the allergy shows badge "<badge>"

    Examples:
      | value    | badge    |
      | mild     | MILD     |
      | moderate | MODERATE |
      | severe   | SEVERE   |

  @positive
  Scenario: Save edits to the sensory profile
    When I click "Edit Patient Info"
    And I describe "Auditory" sensitivities
    And I click "Save"
    Then the button briefly shows "Saving..."
    And my changes persist on reload

  @negative
  Scenario: Cancel discards in-progress edits
    When I click "Edit Patient Info"
    And I type into a field
    And I click "Cancel"
    Then my unsaved text is discarded

  # ---------------------------------------------------------------------------
  # Negative / empty / silent validation
  # ---------------------------------------------------------------------------

  @negative @edge
  Scenario: Adding a medication with an empty name is silently ignored
    When I click "Edit Patient Info"
    And I leave "Medication name" empty
    And I click "Add"
    Then no medication is added and no error toast is shown

  @negative @edge
  Scenario: Adding an allergy with an empty allergen is silently ignored
    When I click "Edit Patient Info"
    And I leave "Allergen (e.g. Latex, Peanuts)" empty
    And I click "Add"
    Then no allergy is added and no error toast is shown

  @edge @data
  Scenario Outline: Empty sections show their placeholder text
    Given the patient has no "<section>" recorded
    Then I see the empty text "<empty text>"

    Examples:
      | section          | empty text                     |
      | Medications      | No medications recorded        |
      | Allergies        | No allergies recorded          |
      | Sensory Profile  | No sensory profile recorded    |
      | Accommodations   | No accommodations recorded     |
      | Emergency        | No emergency contacts          |

  @negative
  Scenario: Failure loading the overview shows an error with retry
    Given the KYP endpoint fails
    When I open the "Know Your Patient" overview
    Then I see the error title "Failed to load patient overview"
    And I see a "Retry" button

  @negative @edge
  Scenario: KYP service unavailable
    Given the KYC service is not available in the app shell
    When I open the "Know Your Patient" overview
    Then I see "Service not available"

  # ---------------------------------------------------------------------------
  # Review acknowledgment
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Mark the KYP as reviewed
    Given I have not yet reviewed this patient's KYP
    Then I see a "Not yet reviewed" call to action
    When I click "Mark as Reviewed"
    Then I see the toast "KYP marked as reviewed."
    And the badge changes to "Reviewed by you"

  @negative
  Scenario: Marking as reviewed fails
    Given the acknowledge endpoint returns an error
    When I click "Mark as Reviewed"
    Then I see the toast "Could not mark KYP as reviewed."

  @edge
  Scenario: Review acknowledgment is per-user
    Given another clinician has already reviewed this patient's KYP
    When I open the overview as a different user who has not reviewed it
    Then I still see "Not yet reviewed" for my own acknowledgment

  # ---------------------------------------------------------------------------
  # Security
  # ---------------------------------------------------------------------------

  @security @edge
  Scenario: Free-text clinical fields are rendered as literal text
    When I save an accommodation note containing "<img src=x onerror=alert(1)>"
    Then the note renders as literal text and does not execute script

  @a11y @positive
  Scenario: Severity badges convey meaning beyond colour
    Then each allergy severity is shown as an uppercase text label, not colour alone
