Feature: Insurance Authorization workflow
  As a clinician / authorization coordinator on the Wabi clinic web app
  I want to create, submit and complete insurance authorizations for a patient
  So that an approved authorization activates the patient for scheduling.

  # Grounded in wabi-flutter-dev:
  #   authorization_panels.dart (NewAuthorizationDialog, SubmitToInsurancePanel,
  #     SubmitToInsurancePanelSimple, AuthorizationStatusPanel, CompleteAuthorizationPanel)
  #   new_patient_intake_screen.dart (Authorization tab: empty state, queue, _statusFor)
  # Auth step names: "Submit to Insurance" (Download & send) → "Complete" (Upload & finalize).
  # Auth status machine: draft / pending_documents → submitted / pending_insurance
  #                      → approved / active   (or)   → denied
  # An INITIAL authorization is created from a completed assessment; Re-Auth needs no assessment.

  Background:
    Given I am logged in as a "BCBA" with an assigned patient
    And I open the patient intake workspace
    And I select the "Authorization" tab

  # ---------------------------------------------------------------------------
  # Empty state & assessment gate
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Authorization queue empty state explains the assessment gate
    Given the patient has no authorizations
    When the "Authorization Queue" renders
    Then I see "No authorizations yet"
    And I see "Complete an assessment to create an initial authorization, or click 'New Authorization' to start a re-authorization."
    And a "New Authorization" button is available

  @negative
  Scenario: Submitting to insurance without an assessment is blocked
    Given an authorization exists but the patient has no assessment record
    When I open the "Submit to Insurance" step and click "Submit Request"
    Then I see the error toast "Assessment is required to submit authorization"
    And the authorization is not submitted

  # ---------------------------------------------------------------------------
  # Create authorization — Initial vs Re-Auth
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Create an Initial authorization from a completed assessment
    Given the patient has an assessment with status "report_complete"
    When I click "New Authorization"
    And I keep the type "Initial"
    And the info box reads "Initial authorization will be linked to the patient's assessment report."
    And I click "Create Authorization"
    Then an initial authorization is created and linked to the assessment

  @positive
  Scenario: Create a Re-Authorization without requiring an assessment
    Given the patient already has an active authorization nearing expiry
    When I click "New Authorization"
    And I select the type "Re-Auth"
    And the info box reads "Re-authorization request for an existing patient with expiring authorization."
    And I click "Create Authorization"
    Then a re-authorization is created with status "pending_documents"

  @positive
  Scenario: New Authorization dialog prefills hours and duration from the assessment
    Given the assessment recommends 30 hours/week for 12 months
    When I open the "New Authorization" dialog
    Then "Requested Hours/Week" is prefilled with "30"
    And "Duration (Months)" is prefilled with "12"

  @data @negative @edge
  Scenario Outline: Requested Hours/Week and Duration accept or coerce boundary values
    When I open the "New Authorization" dialog
    And I set "Requested Hours/Week" to "<hours>"
    And I set "Duration (Months)" to "<duration>"
    And I click "Create Authorization"
    Then the request behaves as "<result>"

    Examples:
      | hours   | duration | result                                             |
      | 25      | 6        | accepted as 25 hrs / 6 months                      |
      | 0       | 0        | edge: zero sent to backend, expect backend reject  |
      | -5      | -1       | edge: negative parsed, expect backend reject       |
      | 9999    | 999      | edge: implausibly large value sent to backend      |
      | abc     | xyz      | non-numeric parses to null (no client validation)  |
      |         |          | empty parses to null (no client validation)        |
      | 25.5    | 6.9      | hours accept decimal; duration truncates to int    |

  @negative
  Scenario: Create Authorization surfaces backend errors in the dialog
    Given the authorization service will reject the request
    When I open the "New Authorization" dialog and click "Create Authorization"
    Then the dialog shows the returned error in a red banner
    And the dialog stays open

  # ---------------------------------------------------------------------------
  # Submit to Insurance step
  # ---------------------------------------------------------------------------

  @positive @data
  Scenario Outline: Choose each submission method before submitting
    Given an authorization is ready to submit and an assessment exists
    When I open the "Submit to Insurance" step
    And I choose submission method "<method>"
    And I click "Submit Request"
    Then I see the toast "Authorization submitted successfully"
    And the authorization status becomes "submitted"

    Examples:
      | method       |
      | Electronic   |
      | Payer Portal |
      | Fax          |

  @positive
  Scenario: Download the authorization package (manual submission flow)
    Given the simplified "Submit to Insurance" step is shown
    When I click "Download"
    Then I see the toast "Authorization package downloaded successfully"
    And the button label changes to "Downloaded"

  @positive
  Scenario: Mark an authorization as submitted after manual send
    Given the authorization package has been downloaded
    When I click "Mark Submitted"
    Then the authorization advances to the "Complete" step

  @positive
  Scenario: Record an insurance decision as approved from the status panel
    Given an authorization with status "submitted"
    When I open the authorization status panel
    And I click "Mark Approved"
    Then the authorization moves toward the "Complete" step

  @positive
  Scenario: Record an insurance decision as denied from the status panel
    Given an authorization with status "pending_insurance"
    When I click "Mark Denied"
    Then the authorization status becomes "denied"

  # ---------------------------------------------------------------------------
  # Complete authorization — approved path
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Complete an approved authorization with all required fields
    Given a submitted authorization on the "Complete" step
    When I select "Approved" as the "Insurance Decision"
    And I enter "AUTH-2026-001234" in "Authorization Number"
    And I enter "25" in "Approved Hours/Week"
    And I enter a valid "Start Date" and "End Date"
    And I upload an authorization document
    And I click "Complete Authorization"
    Then the authorization becomes "approved"
    And the patient becomes "active" (see patient-status-lifecycle.feature)

  @negative
  Scenario: Approved completion requires an Authorization Number
    Given an approved-path completion with the "Authorization Number" left blank
    When I click "Complete Authorization"
    Then the field shows the inline error "Authorization number is required to save"
    And I see the toast "Please enter an authorization number (e.g. AUTH-2026-001234)"

  @negative
  Scenario: Approved completion requires Approved Hours/Week
    Given an approved-path completion with a valid auth number but blank "Approved Hours/Week"
    When I click "Complete Authorization"
    Then I see the toast "Please enter approved hours per week"

  @negative
  Scenario: Approved completion with both required fields blank
    Given an approved-path completion with blank "Authorization Number" and "Approved Hours/Week"
    When I click "Complete Authorization"
    Then I see the toast "Please fill in authorization number and approved hours"

  @negative @data
  Scenario Outline: Start/End dates must be a recognised date format
    Given an approved-path completion with auth number and hours filled
    When I enter "<start>" as "Start Date" and "<end>" as "End Date"
    And I click "Complete Authorization"
    Then I see the error toast "<message>"

    Examples:
      | start      | end        | message                                          |
      | 13/40/2026 | 01/01/2026 | Start date must be MM/DD/YYYY or YYYY-MM-DD       |
      | 02/01/2026 | notadate   | End date must be MM/DD/YYYY or YYYY-MM-DD         |

  @edge
  Scenario: End date before start date on an approved authorization
    Given an approved-path completion with auth number and hours filled
    When I set "Start Date" to "07/31/2026" and "End Date" to "02/01/2026"
    And I click "Complete Authorization"
    Then the end-before-start period is flagged as an invalid authorization window

  @positive @data
  Scenario Outline: Authorization document upload accepts the documented file types
    Given an approved-path completion
    When I upload an authorization letter of type "<type>"
    Then the upload card shows "Document Uploaded" and toast "Authorization document uploaded"

    Examples:
      | type |
      | PDF  |
      | JPG  |
      | PNG  |

  @security @negative
  Scenario Outline: Reject unsupported or oversized authorization documents
    Given an approved-path completion
    When I attempt to upload "<file>"
    Then the upload is rejected as an unsupported or oversized document

    Examples:
      | file            |
      | malware.exe     |
      | script.svg      |
      | huge-50mb.pdf   |

  # ---------------------------------------------------------------------------
  # Complete authorization — denied path
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Record a denial on the Complete step
    Given a submitted authorization on the "Complete" step
    When I select "Denied" as the "Insurance Decision"
    Then the primary action becomes "Record Denial"
    When I click "Record Denial"
    Then the authorization status becomes "denied"
    And no Authorization Number is required for the denial

  # ---------------------------------------------------------------------------
  # Multiple authorizations, download, gating & permissions
  # ---------------------------------------------------------------------------

  @edge
  Scenario: A patient can hold multiple authorizations in the queue
    Given the patient has one approved authorization
    When I create another authorization via "New Authorization"
    Then both authorizations are listed in the "Authorization Queue"

  @negative
  Scenario: Sessions cannot be scheduled while an authorization is pending
    Given the patient's authorization is not yet approved
    When I view the authorization panel on the patient header
    Then I see "The authorization is still pending approval. Sessions cannot be scheduled until the authorization is approved."

  @permission
  Scenario: Only an authorized role can mark an authorization approved
    Given I am logged in as a role without authorization-approval permission
    When I open a submitted authorization
    Then the "Mark Approved" and "Complete Authorization" actions are unavailable

  @security
  Scenario: Authorization data is isolated to its own patient
    Given I am viewing patient A's "Authorization Queue"
    Then only patient A's authorizations are returned and never another patient's records

  @a11y
  Scenario: Authorization status pill is distinguishable beyond colour
    Given authorizations with statuses "Draft", "Pending", "Approved" and "Denied"
    Then each row shows a text status label alongside its colour dot
