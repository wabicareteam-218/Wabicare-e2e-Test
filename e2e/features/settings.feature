Feature: Settings
  As an Owner of a Wabi organization
  I want to manage org-wide configuration, intake, knowledge base, support and subscription
  So that the clinic runs on the right defaults and can get help when needed.

  # Source of truth for labels/messages:
  #   lib/screens/settings_screen.dart (tabs)
  #   lib/features/settings/presentation/widgets/intake_settings_tab.dart
  #   lib/features/settings/presentation/widgets/appointment_types_section.dart
  #   lib/features/settings/screens/knowledge_base_screen.dart
  #   lib/features/settings/presentation/widgets/support_settings_tab.dart
  #   lib/widgets/ai_support_ticket_form.dart
  #   lib/features/settings/presentation/widgets/subscription_tab.dart
  #
  # Permission note: Settings is NOT role-gated in this UI layer. The only role
  # check is the onboarding "Setup" strip (Owner / Clinical Director only). Any
  # Owner-vs-others enforcement is server-side, not expressed as Flutter strings.

  Background:
    Given I am logged in to the Wabi clinician web app as an Owner
    And I open "Settings"
    And the header reads "Settings" with subtitle "Manage your organization and application settings"

  # ---------------------------------------------------------------------------
  # Tabs / navigation
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Settings shows the primary tabs plus a More overflow
    Then I see the pills "Organization", "Users", "Intake" and "Support"
    And the remaining tabs "Notifications", "Security", "AI Knowledge", "General", "Prompt Levels", "Subscription", "HIPAA Compliance" and "Import" are under "More"

  @permission @edge
  Scenario: Onboarding setup strip is Owner/Clinical Director only
    Given I am logged in as an RBT
    Then the "Setup" / "Finish setup →" onboarding strip is not shown

  # ---------------------------------------------------------------------------
  # Intake settings
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Intake tab offers the two form modes
    When I open the "Intake" tab
    Then I see the card "Intake Form Mode" with subtitle "Choose how parents fill out intake forms"
    And I can choose "Standard Forms" or "Custom Single Form"

  @data @positive
  Scenario Outline: Standard intake includes all nine default forms
    When I open the "Intake" tab in "Standard Forms" mode
    Then I see the default form "<form>"

    Examples:
      | form                        |
      | Client Information          |
      | Caregiver & Provider Info   |
      | ABA Therapy History         |
      | Challenging Behaviors       |
      | Education & Therapies       |
      | Medical History             |
      | Diagnosis & Documents       |
      | Availability & Concerns     |
      | Consent & Agreements        |

  @positive
  Scenario: Enable and disable an intake form
    When I toggle a form's "Enabled" / "Disabled" badge
    And I click "Save"
    Then the button shows "Saving..." then I see the toast "Intake settings saved"
    And the counter updates like "8 / 9 enabled"

  @positive
  Scenario: Add a custom intake form
    When I click "Add Custom Form"
    Then a dialog titled "Add Custom Form" opens with "Form Name" and "Description"
    When I enter a form name and click "Create Form"
    Then the new form is added to the list

  @negative
  Scenario: Save intake settings failure
    Given the intake settings save endpoint fails
    When I click "Save"
    Then I see an error toast beginning with "Failed to save settings:"

  @edge @data
  Scenario Outline: Custom Single Form schema field types
    Given I am editing a "Custom Form Schema"
    When I add a field of type "<type>"
    Then it renders as "<label>"

    Examples:
      | type      | label      |
      | text      | Text       |
      | textarea  | Multi-line |
      | dropdown  | Dropdown   |
      | date      | Date       |
      | checkbox  | Checkbox   |
      | upload    | Upload     |
      | signature | Signature  |

  @negative @edge
  Scenario: Custom form PDF extraction failure
    Given I upload a PDF on "Upload Your Intake Form PDF"
    And the AI extraction fails
    Then I see "Failed to extract schema"

  # ---------------------------------------------------------------------------
  # Appointment type defaults (on the Organization tab)
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Add an appointment type
    Given I am on the "Organization" tab "Appointment types" section
    When I click "Add type"
    Then a dialog "Add appointment type" opens with "Code", "Label", "Color", "Duration (min)", "CPT code" and a "Billable" toggle
    When I enter a code and label and click "Save"
    Then the type is added to the list

  @negative
  Scenario: Appointment type requires code and label
    When I open "Add appointment type" and leave code or label empty
    And I click "Save"
    Then I see "Code and label are required"

  @negative @data
  Scenario Outline: Appointment type colour must be a valid hex
    When I enter colour "<hex>" on an appointment type and click "Save"
    Then I see "<result>"

    Examples:
      | hex      | result                                |
      | #22C55E  | (saved)                               |
      | green    | Enter a valid hex color, e.g. #22C55E |
      | 22C55E   | Enter a valid hex color, e.g. #22C55E |

  @edge
  Scenario: Empty appointment types state
    Given no appointment types exist
    Then I see "No appointment types yet. Add at least one (e.g. Therapy Session, Intake, Assessment)."

  # ---------------------------------------------------------------------------
  # Knowledge base (AI Knowledge tab)
  # ---------------------------------------------------------------------------

  @positive
  Scenario: AI Knowledge shows Documents and Web sources
    When I open the "AI Knowledge" tab
    Then the nav shows "Documents", "Web sources" and (when loaded) "AI settings"
    And the subtitle reads "Documents, web sources, and ingestion controls."

  @edge
  Scenario: Knowledge base empty document state
    Given there are no knowledge documents
    Then I see "No documents yet"
    And "Upload policy documents, payer guidelines, and clinical protocols to power AI insights."

  @data @positive
  Scenario Outline: Documents can be filtered by category
    When I open the "Filter:" dropdown (default "All Categories")
    And I select "<category>"
    Then only documents in "<category>" are shown

    Examples:
      | category            |
      | Payer Guidelines    |
      | Billing & Coding    |
      | Clinical Protocols  |
      | Compliance          |
      | State Regulations   |
      | Other               |

  @negative
  Scenario: Delete a knowledge document is irreversible and confirmed
    When I click "Delete" on a document
    Then a dialog "Delete Document" warns the action "cannot be undone"
    When I confirm "Delete"
    Then the document and its indexed chunks are removed

  @positive
  Scenario: Pause and resume RAG ingestion
    When I toggle "Pause RAG ingestion" on
    Then I see "RAG ingestion paused — new indexing jobs will skip"
    When I toggle it off
    Then I see "RAG ingestion resumed"

  # ---------------------------------------------------------------------------
  # Support ticket / Report a Bug
  # ---------------------------------------------------------------------------

  @smoke @positive
  Scenario: Submit feedback from the Support tab
    When I open the "Support" tab
    Then the "Submit feedback" form shows a "Category" dropdown, "Title", "Description" and "Screenshots (optional)"
    When I enter a title and description and click "Submit"
    Then I see the toast "Thanks — your feedback was submitted. You can track it under “My tickets”."

  @negative
  Scenario: Title is required
    When I submit the feedback form without a title
    Then I see "Please enter a title."

  @negative
  Scenario: Description is required
    When I submit the feedback form without a description
    Then I see "Please enter a description."

  @data @positive
  Scenario Outline: Ticket category changes the form title
    When I select category "<option>"
    Then the form title reads "<title>"

    Examples:
      | option          | title             |
      | Bug Report      | Report a Bug      |
      | Feature Request | Request a Feature |
      | Question        | Ask a Question    |
      | Feedback        | Give Feedback     |

  @negative
  Scenario: Support submission fails when the AI chat service is offline
    Given the AI chat service is unavailable
    Then I see the banner "AI chat service unavailable — feedback submission is offline. Please email support@wabicare.com instead."

  @positive
  Scenario: View and reply to my tickets
    When I open the "My tickets" section and select a ticket
    Then I see "Original report", "Conversation" and a "Reply" box
    When I type a reply and click "Send reply"
    Then I see "Reply sent."

  # ---------------------------------------------------------------------------
  # Subscription
  # ---------------------------------------------------------------------------

  @positive
  Scenario: Subscription tab shows plan sections
    When I open the "Subscription" tab
    Then I see the sections "Plan & Pricing", "Add-on Modules", "Billing & Invoices" and "Usage"

  @positive
  Scenario: Cancel the subscription with confirmation
    When I click "Cancel subscription"
    Then a dialog "Cancel subscription?" appears
    When I click "Schedule cancellation"
    Then I see "Cancellation scheduled."
    And I see "Scheduled to cancel at the end of the current period."

  @negative
  Scenario: Checkout failure when upgrading a plan
    Given the checkout endpoint fails
    When I click "Upgrade to <plan>"
    Then I see "Could not start checkout" or "Checkout failed (<code>)"

  @edge
  Scenario: Usage over budget pauses AI features
    Given AI token usage exceeds the budget
    Then I see "Budget exceeded — AI features are paused until the next billing period or until you upgrade."

  @negative
  Scenario: Subscription details fail to load
    Given the subscription endpoint fails
    Then I see "Could not load subscription details." with a "Retry" button

  # ---------------------------------------------------------------------------
  # Permission
  # ---------------------------------------------------------------------------

  @permission @security
  Scenario: Settings CRUD authorisation is enforced server-side
    Given a non-Owner session attempts to save org-wide settings
    Then any Owner-only restriction is enforced by the backend
    # NOTE: no client-side role gating exists on Settings tabs or save actions.
